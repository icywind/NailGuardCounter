//
//  PersistenceController.swift
//  NailGuard
//
//  Created by Rick Cheng on 2/3/26.
//

import SwiftData
import Foundation

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    private init() {
        do {
            // Register all SwiftData @Model types here
            container = try ModelContainer(for: BiteEventModel.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // Main thread context for SwiftUI Views
    var context: ModelContext {
        container.mainContext
    }
    
    // Convenience method to save context
    func save() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // Add a new BiteEventModel instance
    func addBite(timestamp: Date = Date()) {
        let event = BiteEventModel(timestamp: timestamp)
        context.insert(event)
        save()
    }
    
    // Fetch all events sorted by timestamp
    func fetchAllBites() -> [BiteEventModel] {
        let request = FetchDescriptor<BiteEventModel>(sortBy:[SortDescriptor(\.timestamp)])
        return (try? context.fetch(request)) ?? []
    }
    
    // Delete all events
    func deleteAllBites() {
        let events = fetchAllBites()
        for event in events {
            context.delete(event)
        }
        save()
    }
    
    /// Creates ~40–60 days of fake bite events with realistic daily variation
    func populateTestData(daysBack: Int = 60, deleteFirst: Bool = true) {
        if deleteFirst {
            deleteAllBites()
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // How many bites per day on average (with variation)
        let patterns: [(weekendMultiplier: Double, base: Int, extraRand: Int)] = [
            (1.0,  8,  6),   // normal weekdays
            (0.4,  3,  4),   // low-bite calm days
            (1.8, 15, 10),   // high-stress / binge days
        ]
        
        for dayOffset in 0..<daysBack {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            let isWeekend = calendar.component(.weekday, from: day) == 1 || calendar.component(.weekday, from: day) == 7
            
            // Choose pattern
            let pattern = isWeekend ? patterns[2] : patterns[Int.random(in: 0...1)]
            
            let baseCount = pattern.base
            let randomExtra = Int.random(in: 0...pattern.extraRand)
            var count = baseCount + randomExtra
            
            // weekend → more variation
            if isWeekend && Double.random(in: 0..<1) < 0.25 {
                count = Int(Double(count) * pattern.weekendMultiplier * Double.random(in: 0.6...1.4))
            }
            
            count = max(0, min(35, count))  // sane limits
            
            // Spread bites throughout the day
            for _ in 0..<count {
                // Most bites between 08:00–23:00, few at night
                let hourWeight: ClosedRange<Double> = {
                    let r = Double.random(in: 0..<1)
                    switch r {
                    case 0..<0.03:  return 0...5     // night
                    case 0.03..<0.12: return 6...9   // morning
                    case 0.12..<0.75: return 10...20 // main day
                    default:          return 21...23.8
                    }
                }()
                
                let hour = Double.random(in: hourWeight)
                let minute = Double.random(in: 0..<60)
                let second = Double.random(in: 0..<60)
                
                let timeInterval = hour * 3600 + minute * 60 + second
                guard let biteDate = calendar.date(byAdding: .second, value: Int(timeInterval), to: day) else { continue }
                
                // sometimes add tiny jitter so same-second events are possible but rare
                let jitter = Double.random(in: -8...8)
                let finalDate = biteDate.addingTimeInterval(jitter)
                
                addBite(timestamp: finalDate)
            }
            print("Date \(day): added \(count) bites")
        }
        
        print("Created \(fetchAllBites().count) fake bite events")
    }
}
