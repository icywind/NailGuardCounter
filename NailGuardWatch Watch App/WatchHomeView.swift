//
//  ContentView.swift
//  NailGuardWatch Watch App
//
//  Created by Rick Cheng on 2/4/26.
//

import SwiftUI
import WatchKit

struct WatchHomeView: View {
    @State private var currentDate = Date()
    @StateObject private var viewModel = SyncViewModel()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 2) {
                Spacer()
                Text("Today: "+dateFormatter.string(from: currentDate))
                    .font(.caption)
                    //.foregroundStyle(.secondary)

                Text("\(viewModel.todayCount)")
                    .font(.system(size: 42, weight: .bold))
                
                CircularButton(action: logBite,
                               backgroundColor: .blue, centerColor: .red, frameSize: 100)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // Initialize today's count from synced count
            Task {
              await viewModel.performSync()
            }
            // Update date every minute to handle day changes
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentDate = Date()
            }
        }
    }

    private func logBite() {
        viewModel.sendBite()
        WKInterfaceDevice.current().play(.success)
    }
}

#Preview("Watch Preview", traits: .defaultLayout) {
    WatchHomeView()
}
