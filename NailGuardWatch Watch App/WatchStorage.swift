//
//  WatchStorage.swift
//  NailGuard
//
//  Created by Rick Cheng on 2/4/26.
//

import Foundation

final class WatchStorage {
    static let shared = WatchStorage()
    
    private let fileURL: URL

    private init() {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.us.bigtimer.rcsw.NailGuard"
        )!
        fileURL = container.appendingPathComponent("watch_events.json")
    }

    func loadQueue() -> [BiteEvent] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([BiteEvent].self, from: data)) ?? []
    }

    func save(_ events: [BiteEvent]) {
        let data = try? JSONEncoder().encode(events)
        try? data?.write(to: fileURL, options: .atomic)
    }

    func enqueue(_ event: BiteEvent) {
        var events = loadQueue()
        events.append(event)
        save(events)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
