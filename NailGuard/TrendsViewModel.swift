import SwiftUI
import SwiftData
import Combine

@MainActor
class TrendsViewModel: ObservableObject {
    @Published var selectedTimeRange: TimeRange = .month
    @Published var dailyData: [DailyBiteData] = []
    @Published var showingInsights = false
    @Published var calendarData: [Date: Int] = [:]
    @Published var selectedMonth: Date? = nil
    
    private var biteEvents: [BiteEventModel] = []
    private let calendar = Calendar.current
    
    init() {
        // Initialize selectedMonth to current month
        selectedMonth = calendar.startOfDay(for: Date())
    }
    
    func updateEvents(_ events: [BiteEventModel]) {
        self.biteEvents = events
        if selectedTimeRange == .month, let month = selectedMonth {
            updateDataForSelectedMonth(month)
        } else {
            updateData()
        }
    }
    
    func setTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        if range == .month {
            selectedMonth = calendar.startOfDay(for: Date())
            if let month = selectedMonth {
                updateDataForSelectedMonth(month)
            }
        } else {
            updateData()
        }
    }
    
    func updateData() {
        loadDataForTimeRange(selectedTimeRange)
    }
    
    // MARK: - Computed Properties
    
    var periodName: String {
        switch selectedTimeRange {
        case .week:
            return "week"
        case .month:
            if let selectedMonth = selectedMonth {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM"
                return formatter.string(from: selectedMonth)
            } else {
                return "month"
            }
        case .year:
            return "year"
        }
    }
    
    var summaryText: String {
        guard !dailyData.isEmpty else {
            return "Loading data..."
        }
        let average = averagePerDay
        return String(format: "Avg %.1f bites per day this %@", average, periodName)
    }
    
    var totalBites: Int {
        dailyData.reduce(0) { $0 + $1.count }
    }
    
    var bestDay: Int {
        let now = Date()
        
        switch selectedTimeRange {
        case .year:
            // For yearly view, find minimum daily count based on actual data period
            // Only count days from the first event to now (not empty future days)
            guard let earliestEvent = biteEvents.map({ $0.timestamp }).min() else {
                return 0
            }
            
            // Get all events from earliest event to now
            let periodEvents = biteEvents.filter { $0.timestamp >= earliestEvent && $0.timestamp <= now }
            
            // Group by day and count
            let grouped = Dictionary(grouping: periodEvents) { event in
                calendar.startOfDay(for: event.timestamp)
            }
            
            // Return minimum count from days with data
            return grouped.values.map { $0.count }.min() ?? 0
            
        default:
            // For week and month, dailyData already contains daily counts
            return dailyData.map { $0.count }.min() ?? 0
        }
    }
    
    var averagePerDay: Double {
        guard !dailyData.isEmpty else {
            return 0
        }
        
        let now = Date()
        let validDays: Int
        let total: Double
        let earliestDataDate = dailyData.map { $0.date }.min()

        switch selectedTimeRange {
        case .week:
            // Weekly: Fixed 7-day period (always the last 7 days including today)
            validDays = 7
            total = Double(totalBites)
            
        case .month:
            // Monthly: Calculate based on the selected month
            // If we have data starting after the month began, start from the first data point
            if let selectedMonth = selectedMonth {
                let actualStart: Date
                let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)!.start
                let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)!.end
                
                // Use the later of: (start of month) OR (first day we have data)
                if let earliest = earliestDataDate, earliest > startOfMonth {
                    actualStart = earliest
                } else {
                    actualStart = startOfMonth
                }
                
                // Use the earlier of: (end of month) OR (today)
                let actualEnd = min(now, endOfMonth)
                
                // Calculate days between actualStart and actualEnd
                let days = calendar.dateComponents([.day], from: actualStart, to: actualEnd).day ?? 0
                
                // If we've reached end of month, days is correct. Otherwise add 1 to include today.
                validDays = (actualEnd == endOfMonth) ? days : days + 1
                
                // Sum bites within the actual period
                total = Double(dailyData
                    .filter { $0.date >= actualStart && $0.date <= actualEnd }
                    .reduce(0) { $0 + $1.count })
            } else {
                validDays = 1
                total = 0
            }
            
        case .year:
            // Yearly: Calculate based on last 12 months or available data
            // Start date is either 1 year ago OR first day we have data (whichever is later)
            guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) else {
                validDays = 365
                total = Double(totalBites)
                break
            }
            
            let actualStart: Date
            if let earliest = earliestDataDate, earliest > oneYearAgo {
                actualStart = earliest
            } else {
                actualStart = oneYearAgo
            }
            
            // Days from actualStart to now (inclusive)
            let days = calendar.dateComponents([.day], from: actualStart, to: now).day ?? 0
            validDays = days + 1
            
            // Sum bites within the actual period
            total = Double(dailyData
                .filter { $0.date >= actualStart && $0.date <= now }
                .reduce(0) { $0 + $1.count })
        }
        
        guard validDays > 0 else {
            return 0
        }
        
        return total / Double(validDays)
    }
    
    var insights: [Insight] {
        var results: [Insight] = []
        guard !dailyData.isEmpty else { return [] }
        
        // Trend analysis
        let recentAvg = dailyData.suffix(3).reduce(0) { $0 + $1.count } / 3
        let previousAvg = dailyData.prefix(max(0, dailyData.count - 3)).reduce(0) { $0 + $1.count } / max(1, dailyData.count - 3)
        
        if recentAvg < previousAvg && previousAvg > 0 {
            let improvement = Int(((Double(previousAvg - recentAvg) / Double(previousAvg)) * 100))
            results.append(Insight(
                icon: "arrow.down.circle.fill",
                title: "Great Progress!",
                description: "You've reduced biting by \(improvement)% in recent days",
                color: .green
            ))
        } else if recentAvg > previousAvg {
            results.append(Insight(
                icon: "exclamationmark.triangle.fill",
                title: "Slight Increase",
                description: "Activity has increased recently. Stay focused!",
                color: .orange
            ))
        }
        
        // Consistency check
        if dailyData.allSatisfy({ $0.count <= 5 }) {
            results.append(Insight(
                icon: "checkmark.circle.fill",
                title: "Consistent Control",
                description: "You've stayed under 5 bites every day",
                color: .blue
            ))
        }
        
        // Best day
        if let minDay = dailyData.min(by: { $0.count < $1.count }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.timeZone = TimeZone.current
            results.append(Insight(
                icon: "star.fill",
                title: "Best Day: \(formatter.string(from: minDay.date))",
                description: "Only \(minDay.count) bites on this day",
                color: .yellow
            ))
        }
        
        return results
    }
    
    var hourlyPatternData: [HourlyData] {
        var hourCounts: [Int: Int] = [:]
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let recentEvents = biteEvents.filter { $0.timestamp >= thirtyDaysAgo }
        
        for event in recentEvents {
            let hour = calendar.component(.hour, from: event.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        
        let maxCount = hourCounts.values.max() ?? 1
        
        return (0..<24).map { hour in
            let count = hourCounts[hour] ?? 0
            let intensity = maxCount > 0 ? Double(count) / Double(maxCount) : 0
            return HourlyData(hour: hour, intensity: intensity)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadDataForTimeRange(_ range: TimeRange) {
        let now = Date()
        let startDate: Date
        
        switch range {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .day, value: -29, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        }
        
        let filteredEvents = biteEvents.filter { $0.timestamp >= startDate }
        
        if range == .month {
            let grouped = Dictionary(grouping: filteredEvents) { event in
                calendar.startOfDay(for: event.timestamp)
            }
            calendarData = grouped.mapValues { $0.count }
            dailyData = grouped.map { date, events in
                DailyBiteData(date: date, count: events.count)
            }.sorted { $0.date < $1.date }
        } else if range == .year {
            let grouped = Dictionary(grouping: filteredEvents) { event in
                calendar.dateInterval(of: .month, for: event.timestamp)!.start
            }
            let earliestMonthWithEvents = grouped.keys.min()
            
            var monthlyData: [DailyBiteData] = []
            var monthOffset = 0
            let maxMonths = 12
            
            while monthOffset < maxMonths {
                if let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now) {
                    if let earliestMonth = earliestMonthWithEvents, monthStart < earliestMonth {
                        break
                    }
                    let monthInterval = calendar.dateInterval(of: .month, for: monthStart)!
                    let monthEvents = filteredEvents.filter { event in
                        event.timestamp >= monthInterval.start && event.timestamp < monthInterval.end
                    }
                    monthlyData.append(DailyBiteData(date: monthInterval.start, count: monthEvents.count))
                }
                monthOffset += 1
            }
            dailyData = monthlyData.sorted { $0.date < $1.date }
        } else if range == .week {
            var weeklyData: [DailyBiteData] = []
            for i in 0..<7 {
                let dayStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -i, to: now)!)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                let dayEvents = filteredEvents.filter { event in
                    event.timestamp >= dayStart && event.timestamp < dayEnd
                }
                weeklyData.append(DailyBiteData(date: dayStart, count: dayEvents.count))
            }
            dailyData = weeklyData.reversed()
        }
    }
    
    func updateDataForSelectedMonth(_ month: Date) {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return }
        let filteredEvents = biteEvents.filter { $0.timestamp >= monthInterval.start && $0.timestamp < monthInterval.end }
        let grouped = Dictionary(grouping: filteredEvents) { event in
            calendar.startOfDay(for: event.timestamp)
        }
        dailyData = grouped.map { date, events in
            DailyBiteData(date: date, count: events.count)
        }.sorted { $0.date < $1.date }
        calendarData = grouped.mapValues { $0.count }
    }
}

// MARK: - Models

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct DailyBiteData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct HourlyData: Identifiable {
    let id = UUID()
    let hour: Int
    let intensity: Double
}

struct Insight {
    let icon: String
    let title: String
    let description: String
    let color: Color
}
