//
//  ContentView.swift
//  NailGuardWatch Watch App
//
//  Created by Rick Cheng on 2/4/26.
//

import SwiftUI
import WatchKit

struct WatchHomeView: View {
    @State private var todayCount = 0
    @State private var currentDate = Date()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        ZStack {
            // Date display in top-left corner
            VStack {
                HStack {
                    Text(dateFormatter.string(from: currentDate))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            }
            .padding()
            
            // Main content
            VStack(spacing: 12) {
                Spacer()
                Text("TODAY's BITES")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(todayCount)")
                    .font(.system(size: 42, weight: .bold))
                
                CircularButton(action: logBite,
                               backgroundColor: .blue, centerColor: .red)
            }
            .padding()
        }
        .onAppear {
            WatchSyncManager.shared.flushQueue()
            // Update date every minute to handle day changes
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentDate = Date()
            }
        }
    }

    private func logBite() {
        let event = BiteEvent(
            id: UUID(),              // Generate new UUID
            timestamp: Date()        // Current date/time
        )
        WatchSyncManager.shared.send(event)
        todayCount += 1
        WKInterfaceDevice.current().play(.success)
    }
    

}

#Preview("Watch Preview", traits: .sizeThatFitsLayout) {
    WatchHomeView()
}
