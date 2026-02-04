import WatchConnectivity
import Foundation

@MainActor
final class WatchSyncManager: NSObject, WCSessionDelegate {
    static let shared = WatchSyncManager()

    private var isActivated = false

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
            flushQueue()
        } else {
            session.activate()
            print("➡️ Calling WCSession.activate()")
        }
    }

    func send(_ event: BiteEvent) {
        guard isActivated else {
            print("⏳ Session not activated yet — queueing event")
            WatchStorage.shared.enqueue(event)
            return
        }

        let payload: [String: Any] = [
            "id": event.id.uuidString,
            "timestamp": event.timestamp.timeIntervalSince1970
        ]

        let session = WCSession.default

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: { error in
                print("⚠️ sendMessage failed, queueing:", error.localizedDescription)
                WatchStorage.shared.enqueue(event)
            })
        } else {
            print("📭 iPhone not reachable — queueing event")
            WatchStorage.shared.enqueue(event)
        }
    }

    func flushQueue() {
        guard isActivated else {
            print("⏳ flushQueue called but session not activated")
            return
        }

        let session = WCSession.default
        guard session.isReachable else {
            print("📭 flushQueue aborted — iPhone not reachable")
            return
        }

        let queued = WatchStorage.shared.loadQueue()
        print("🚚 Flushing \(queued.count) queued events")

        for event in queued {
            let payload: [String: Any] = [
                "id": event.id.uuidString,
                "timestamp": event.timestamp.timeIntervalSince1970
            ]

            session.sendMessage(payload, replyHandler: nil, errorHandler: { error in
                print("⚠️ Failed to flush event:", error.localizedDescription)
            })
        }

        WatchStorage.shared.clear()
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
            flushQueue()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("📡 Reachability changed:", session.isReachable)
        if session.isReachable {
            flushQueue()
        }
    }
}
