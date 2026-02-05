//
//  SyncViewModel.swift
//  NailGuard
//
//  Created by Rick Cheng on 2/4/26.
//

import Foundation
import Combine

@MainActor
class SyncViewModel: ObservableObject {
    @Published var todayCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let syncManager = WatchSyncManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe syncManager's todayCount changes
        syncManager.$todayCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$todayCount)
    }
    
    func updateCount() {
        todayCount += 1
    }
    
    func sendBite() {
        Task {
            do {
                let event = BiteEvent(
                    id: UUID(),              // Generate new UUID
                    timestamp: Date()        // Current date/time
                )
                let newTotal = try await syncManager.sendBite(event)
                todayCount = newTotal
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func performSync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newTotal = try await syncManager.flushQueue()
            todayCount = newTotal
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
