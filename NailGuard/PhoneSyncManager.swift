//
//  PhoneSyncManager.swift
//  NailGuard
//
//  Created by Rick Cheng on 2/4/26.
//

import WatchConnectivity
import Foundation
import SwiftData
import Combine

@MainActor
final class PhoneSyncManager: NSObject, WCSessionDelegate {

    static let shared = PhoneSyncManager()
    @Published var isWatchConnected = false
    
    private override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Incoming Messages from Watch

    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {

        // Handle sync record from watch
        if let syncData = message["syncRecord"] as? Data {
            handleSyncRecord(from: syncData, replyHandler: replyHandler)
            return
        }
    }

    private func handleSyncRecord(from data: Data, replyHandler: @escaping ([String : Any]) -> Void) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601  // Must match encoding!
            
            let biteEvents = try decoder.decode([BiteEvent].self, from: data)
            
            // Merge the between-sync bites into persistent storage
            for bite in biteEvents {
                insertBite(id: bite.id, timestamp: bite.timestamp)
            }
            
            // Get updated today's count
            Task {
                let todayCount = await getTodayBiteCount()
                
                replyHandler([
                    "success": true,
                    "todayCount": todayCount
                ])
            }
        } catch {
            print("❌ Failed to decode sync record:", error)
            replyHandler([
                "success": false,
                "error": error.localizedDescription
            ])
        }
    }

    // MARK: - SwiftData Insert

    private func insertBite(id: UUID, timestamp: Date) {
        let context = PersistenceController.shared.context

        let event = BiteEventModel(id: id, timestamp: timestamp)
        context.insert(event)

        do {
            try context.save()
            print("✅ Bite saved:", timestamp)
        } catch {
            print("❌ Failed to save bite:", error)
        }
    }

    // MARK: - Today's Bite Count

    private func getTodayBiteCount() async -> Int {
        let bites = PersistenceController.shared.getTodayBites()
        return bites.count
    }
    
    // MARK: - Sync

    // Send to watch
    func sendToWatch(_ text: String) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        
        if session.isReachable {
            // Immediate delivery
            session.sendMessage(["text": text], replyHandler: nil)
        } else {
            // Guaranteed delivery
            session.transferUserInfo(["text": text, "timestamp": Date()])
        }
    }

    // MARK: - Required stubs (Xcode 26+)

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("WCSession activation failed:", error)
        } else {
            print("WCSession activated:", activationState.rawValue)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
    }
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
