import WatchConnectivity
import Foundation
import Combine

@MainActor
final class WatchSyncManager: NSObject, WCSessionDelegate {
    static let shared = WatchSyncManager()
    private var isActivated = false
    @Published var todayCount = 0
    var isLoading = false
    var errorMessage: String?
    
    enum SyncStatus {
        case idle, syncing, success(Int), failed(Error)
    }
    
    private override init() {
        super.init()
        activate()
    }

    private func activate() {
        print("🔍 DEBUG: Entering activate()")  // Add breakpoint HERE
        let isSupported = WCSession.isSupported()  // Breakpoint here instead
        print("🔍 WCSession.isSupported = \(isSupported)")
        
        guard WCSession.isSupported() else {
            print("❌ WCSession not supported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self

        print("ℹ️ WCSession state before activate:", session.activationState.rawValue)

        if session.activationState == .activated {
            isActivated = true
            print("✅ WCSession already activated")
            // flushQueue()
        } else {
            session.activate()
            print("➡️ Calling WCSession.activate()")
        }
    }
    func sendBite(_ event: BiteEvent) async throws -> Int {
        let session = WCSession.default

        if !session.isReachable {
            WatchStorage.shared.enqueue(event)
            return self.todayCount + 1
        }
        
        let events = [event]
        return try await sendBiteEventsToPhone(events)
    }
    
    private func sendBiteEventsToPhone(_ events: [BiteEvent]) async throws -> Int {
        // 1. Encode to Data
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let eventsData = try encoder.encode(events)
        
        // 3. Create payload
        let payload: [String: Any] = [
            "syncRecord": eventsData
        ]
        
        // 4. Send and get response
        let session = WCSession.default
        
        if session.isReachable {
            // Use async wrapper for sendMessage
            let response = try await session.sendMessageAsync(payload)
            
            guard let newCount = response["todayCount"] as? Int else {
                throw WatchSyncError.invalidResponse(response)
            }
            
            // Update synced count in storage
            WatchStorage.shared.clear()
            self.todayCount = newCount
            print("✅ Sync successful, today's count: \(newCount)")
            
            return newCount
            
        } else {
            print("📭 iPhone not reachable — queueing event")
            // Fallback: guaranteed delivery (no immediate response)
            let transfer = session.transferUserInfo(payload)
            print("📦 Events queued for guaranteed delivery: \(transfer)")
            
            // Return current count since we don't have updated count
            return self.todayCount
        }
    }
    
   
    func flushQueue() async throws -> Int {
        guard isActivated else {
            print("⏳ flushQueue called but session not activated")
            throw WatchSyncError.sessionNotActivated
        }

        let session = WCSession.default
        guard session.isReachable else {
            print("📭 flushQueue aborted — iPhone not reachable")
            throw WatchSyncError.sessionNotReachable
        }

        let queued = WatchStorage.shared.loadQueue()
        print("🚚 Flushing \(queued.count) queued events")
        
        return try await sendBiteEventsToPhone(queued)
    }

    // MARK: - SYNC
    
    // Receive from iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            // Handle sync request from phone
            if let action = message["action"] as? String, action == "sync" {
                print("⌚ Received sync request from phone")
                Task {
                    do {
                        self.todayCount = try await self.flushQueue()
                        print("✅ Sync completed from phone request")
                    } catch {
                        print("❌ Sync failed:", error.localizedDescription)
                    }
                }
                return
            }
            
            if let text = message["text"] as? String {
                print("Watch received text:\(text)")
            }
        }
        
        // Auto-reply
        session.sendMessage(["ack": "received"], replyHandler: nil)
    }
    
    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {

        if let error = error {
            print("❌ WCSession activation error:", error.localizedDescription)
            return
        }

        print("✅ WCSession activated with state:", activationState.rawValue)

        if activationState == .activated {
            isActivated = true
            Task {
                try await flushQueue()
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("📡 Reachability changed:", session.isReachable)
        if session.isReachable {
            Task {
                try await flushQueue()
            }
        }
    }
}
extension WCSession {
    func sendMessageAsync(_ message: [String: Any]) async throws -> [String: Any] {
        return try await withCheckedThrowingContinuation { continuation in
            sendMessage(message, replyHandler: { reply in
                continuation.resume(returning: reply)
            }, errorHandler: { error in
                continuation.resume(throwing: error)
            })
        }
    }
    
    func sendMessageAsync2(_ message: [String: Any]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            sendMessage(message, replyHandler: { _ in
                continuation.resume()
            }, errorHandler: { error in
                continuation.resume(throwing: error)
            })
        }
    }
}
// Error types
enum WatchSyncError: LocalizedError {
    case sessionNotActivated
    case sessionNotReachable
    case invalidResponse([String: Any])
    case encodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .sessionNotActivated:
            return "Session not activated"
        case .sessionNotReachable:
            return "Watch is not reachable"
        case .invalidResponse(let response):
            return "Invalid response from watch: \(response)"
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        }
    }
}
