//
//  PhoneSyncManager.swift
//  NailGuard
//
//  Created by Rick Cheng on 2/4/26.
//

import WatchConnectivity
import Foundation
import SwiftData

@MainActor
final class PhoneSyncManager: NSObject, WCSessionDelegate {

    static let shared = PhoneSyncManager()

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
                 didReceiveMessage message: [String : Any]) {

        guard
            let idString = message["id"] as? String,
            let id = UUID(uuidString: idString),
            let timestampSeconds = message["timestamp"] as? TimeInterval
        else {
            print("⚠️ Invalid payload from Watch:", message)
            return
        }

        let date = Date(timeIntervalSince1970: timestampSeconds)

        Task { @MainActor in
            insertBite(id: id, timestamp: date)
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

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
