//
//  NailGuardWatchApp.swift
//  NailGuardWatch Watch App
//
//  Created by Rick Cheng on 2/4/26.
//

import SwiftUI

@main
struct NailGuardWatch_Watch_AppApp: App {
    init() {
        _ = WatchSyncManager.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}
