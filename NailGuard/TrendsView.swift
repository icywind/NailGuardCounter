import SwiftUI
import Charts
import SwiftData

struct TrendsView: View {
    @Query(sort: \BiteEventModel.timestamp, order: .reverse)
    private var biteEvents: [BiteEventModel]
    
    @State private var selectedTimeRange: TimeRange = .month
    @State private var dailyData: [DailyBiteData] = []
    @State private var showingInsights = false
    @State private var calendarData: [Date: Int] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Time Range Picker
                timeRangePicker
                
                // Main Chart or Calendar
                if selectedTimeRange == .month {
                    calendarSection
                } else {
                    chartSection
                }
                
                // Statistics Cards
                statisticsSection
                
                // Insights
                insightsSection
                
                // Hourly Pattern
                hourlyPatternSection
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            updateDataForTimeRange(selectedTimeRange)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Progress")
                .font(.system(size: 28, weight: .bold))
            
            Text(summaryText)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var summaryText: String {
        guard !dailyData.isEmpty else {
            return "Loading data..."
        }
        let total = dailyData.reduce(0) { $0 + $1.count }
        let average = total / dailyData.count
        return "Avg \(average) bites per day this \(selectedTimeRange.rawValue.lowercased())"
    }
    
    // MARK: - Time Range Picker
    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                TimeRangeButton(
                    title: range.rawValue,
                    isSelected: selectedTimeRange == range
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                        updateDataForTimeRange(range)
                    }
                }
            }
        }
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bite Activity")
                .font(.system(size: 17, weight: .semibold))
            
            Chart {
                ForEach(dailyData) { data in
                    BarMark(
                        x: .value("Day", data.date, unit: selectedTimeRange == .year ? .month : .day),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(Color(red: 10/255, green: 132/255, blue: 255/255))
                    .cornerRadius(4)
                    // Add annotation to this specific mark
                    .annotation(position: .top) {
                        Text("\(data.count)")
                                .font(.caption)
                                .padding(4)
                                .background(Color.yellow)
                                .cornerRadius(4)
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                if selectedTimeRange == .year {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                            .font(.system(size: 12))
                        
                    }
                } else {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                            .font(.system(size: 12))
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 12))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Calendar")
                .font(.system(size: 17, weight: .semibold))
            
            CalendarGridView(biteCountByDate: calendarData)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        
        HStack(spacing: 12) {
            StatCard(
                title: "Total",
                value: "\(totalBites)",
                icon: "chart.bar.fill",
                color: .blue
            )
            
            StatCard(
                title: "Best Day",
                value: "\(bestDay)",
                icon: "star.fill",
                color: .green
            )
            
            StatCard(
                title: "Avg/Day",
                value: String(format: "%.1f", averagePerDay),
                icon: "arrow.down.forward",
                color: .orange
            )
        }
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insights")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    showingInsights.toggle()
                }) {
                    Image(systemName: showingInsights ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            
            if showingInsights {
                VStack(spacing: 12) {
                    ForEach(insights, id: \.title) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Hourly Pattern Section
    private var hourlyPatternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Peak Times")
                .font(.system(size: 17, weight: .semibold))
            
            HourlyHeatmap(data: hourlyPatternData)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    private var totalBites: Int {
        dailyData.reduce(0) { $0 + $1.count }
    }
    
    private var bestDay: Int {
        dailyData.map { $0.count }.min() ?? 0
    }
    
    private var averagePerDay: Double {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .week:
            // For week view, we have exactly 7 days
            return Double(totalBites) / 7.0
        case .month:
            // For month view, check if it's the current month
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            let selectedMonth = calendar.component(.month, from: dailyData.first?.date ?? now)
            let selectedYear = calendar.component(.year, from: dailyData.first?.date ?? now)
            let totalBitesInPeriod = totalBites
            
            if currentMonth == selectedMonth && currentYear == selectedYear {
                // Current month - average up to today's date
                let daysElapsed = calendar.component(.day, from: now)
                return daysElapsed > 0 ? Double(totalBites) / Double(daysElapsed) : 0
            } else {
                // Past month - use full month length
                if let monthInterval = calendar.dateInterval(of: .month, for: dailyData.first?.date ?? now) {
                    let daysInMonth = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 30
                    return Double(totalBitesInPeriod) / Double(daysInMonth)
                } else {
                    return Double(totalBitesInPeriod) / 30.0
                }
            }
        case .year:
            // For year view, check if it's the current year
            let currentYear = calendar.component(.year, from: now)
            let selectedYear = calendar.component(.year, from: dailyData.first?.date ?? now)
            
            if currentYear == selectedYear {
                // Current year - average up to today's date
                let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
                return Double(totalBites) / Double(dayOfYear)
            } else {
                // Past year - use full year length
                let checkDate = dailyData.first?.date ?? now
                let daysInYear = isLeapYear(date: checkDate) ? 366.0 : 365.0
                return Double(totalBites) / daysInYear
            }
        }
    }
    func isLeapYear(date: Date) -> Bool {
        let calendar = Calendar.current

        let components = calendar.dateComponents([.year], from: date)
        let year = components.year ?? 0
        return (year % 400 == 0) || (year % 4 == 0 && year % 100 != 0)
    }
    private var insights: [Insight] {
        var results: [Insight] = []
        
        // Trend analysis
        let recentAvg = dailyData.suffix(3).reduce(0) { $0 + $1.count } / 3
        let previousAvg = dailyData.prefix(dailyData.count - 3).reduce(0) { $0 + $1.count } / max(1, dailyData.count - 3)
        
        if recentAvg < previousAvg {
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
    
    private var hourlyPatternData: [HourlyData] {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        
        // Get events from last 30 days for pattern analysis
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
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch range {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .day, value: -29, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        }
        
        // Filter events by date range
        let filteredEvents = biteEvents.filter { $0.timestamp >= startDate }
        
        if range == .month {
            // For calendar view, create dictionary of date -> count
            let grouped = Dictionary(grouping: filteredEvents) { event in
                calendar.startOfDay(for: event.timestamp)
            }
            
            calendarData = grouped.mapValues { $0.count }
            
            // Also populate dailyData for statistics
            dailyData = grouped.map { date, events in
                DailyBiteData(date: date, count: events.count)
            }.sorted { $0.date < $1.date }
        } else if range == .year {
            // For year view, aggregate by month for the last 12 months or until we find the earliest month with data
            let grouped = Dictionary(grouping: filteredEvents) { event in
                calendar.dateInterval(of: .month, for: event.timestamp)!.start
            }
            
            // Find the earliest month with data
            let earliestMonthWithEvents = grouped.keys.min()
            
            
            // Get months from now backwards, up to 12 months or until we reach the earliest month with data
            var monthlyData: [DailyBiteData] = []
            var monthOffset = 0
            let maxMonths = 12
            
            while monthOffset < maxMonths {
                if let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now) {
                    // Stop if we've reached the earliest month with data
                    if let earliestMonth = earliestMonthWithEvents, monthStart < earliestMonth {
                        break
                    }
                    
                    let monthInterval = calendar.dateInterval(of: .month, for: monthStart)!
                    let monthEvents = filteredEvents.filter { event in
                        event.timestamp >= monthInterval.start && event.timestamp < monthInterval.end
                    }
                    let count = monthEvents.count
                    monthlyData.append(DailyBiteData(date: monthInterval.start, count: count))
                }
                monthOffset += 1
            }
            
            dailyData = monthlyData.sorted { $0.date < $1.date }
        } else if range == .week {
            // For week view, always show the last 7 days
            var weeklyData: [DailyBiteData] = []
            
            // Create data for the last 7 days, including days with zero events
            for i in 0..<7 {
                let dayStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -i, to: now)!)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                // Count events for this specific day
                let dayEvents = filteredEvents.filter { event in
                    event.timestamp >= dayStart && event.timestamp < dayEnd
                }
                
                weeklyData.append(DailyBiteData(date: dayStart, count: dayEvents.count))
            }
            
            dailyData = weeklyData.reversed()
        } else {
            // For other ranges (shouldn't reach here, but kept for safety)
            let grouped = Dictionary(grouping: filteredEvents) { event in
                calendar.startOfDay(for: event.timestamp)
            }
            
            dailyData = grouped.map { date, events in
                DailyBiteData(date: date, count: events.count)
            }.sorted { $0.date < $1.date }
        }
        
        print("biteevent has \(biteEvents.count) items" )
    }
    
    private func updateDataForTimeRange(_ range: TimeRange) {
        loadDataForTimeRange(range)
    }
}

// MARK: - Supporting Views

struct TimeRangeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
                .cornerRadius(8)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct InsightRow: View {
    let insight: Insight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.system(size: 20))
                .foregroundColor(insight.color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(insight.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

struct HourlyHeatmap: View {
    let data: [HourlyData]
    
    var body: some View {
        VStack(spacing: 8) {
            // Hours labels
            HStack(spacing: 0) {
                ForEach([0, 6, 12, 18], id: \.self) { hour in
                    Text("\(hour):00")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Heatmap
            HStack(spacing: 4) {
                ForEach(data) { hourData in
                    Rectangle()
                        .fill(Color.blue.opacity(hourData.intensity))
                        .frame(height: 40)
                        .cornerRadius(2)
                }
            }
            
            // Legend
            HStack {
                Text("Less")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(Color.blue.opacity(Double(i) / 4))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                    }
                }
                
                Text("More")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CalendarGridView: View {
    let biteCountByDate: [Date: Int]
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            if !daysInMonth.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(0..<daysInMonth.count, id: \.self) { index in
                        if let date = daysInMonth[index] {
                            CalendarDayCell(
                                date: date,
                                count: biteCountByDate[calendar.startOfDay(for: date)] ?? 0,
                                isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                isToday: calendar.isDateInToday(date)
                            )
                        } else {
                            Color.clear
                                .frame(height: 44)
                        }
                    }
                }
            } else {
                Text("Unable to load calendar")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        // Get the month interval
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            print("Error: Could not get month interval")
            return []
        }
        
        // Get the first week of the month
        guard let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            print("Error: Could not get first week")
            return []
        }
        
        // Get the last day of the month
        guard let monthLastDay = calendar.date(byAdding: DateComponents(day: -1), to: monthInterval.end) else {
            print("Error: Could not get last day")
            return []
        }
        
        // Get the last week of the month
        guard let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthLastDay) else {
            print("Error: Could not get last week")
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        // Safety limit to prevent infinite loops
        var dayCount = 0
        let maxDays = 42 // Maximum calendar cells (6 weeks * 7 days)
        
        while currentDate < monthLastWeek.end && dayCount < maxDays {
            if calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                print("Error: Could not advance to next date")
                break
            }
            currentDate = nextDate
            dayCount += 1
        }
        
        // Ensure we have a multiple of 7 days for the grid
        while days.count % 7 != 0 && days.count < maxDays {
            days.append(nil)
        }
        
        return days
    }
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let count: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isCurrentMonth ? .primary : .secondary)
            
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(colorForCount(count))
                    .clipShape(Circle())
            } else if isCurrentMonth {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 6, height: 6)
            } else {
                Spacer()
                    .frame(height: 6)
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.blue.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isToday ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private func colorForCount(_ count: Int) -> Color {
        switch count {
        case 0:
            return .gray.opacity(0.2)
        case 1...2:
            return .green
        case 3...5:
            return .yellow
        case 6...8:
            return .orange
        default:
            return .red
        }
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
    let intensity: Double // 0.0 to 1.0
}

struct Insight {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Preview

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TrendsViewWrapper()
        }
        .modelContainer(previewContainer)
        
    }
    
    // Wrapper to set initial state
    private struct TrendsViewWrapper: View {
        var body: some View {
            TrendsView()
        }
    }
    
    @MainActor
    static var previewContainer: ModelContainer = {
        do {
            let schema = Schema([BiteEventModel.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: configuration)
            
            let calendar = Calendar.current
            let now = Date()
            
            // Generate sample data for the last 7 days (simpler for preview)
            for daysAgo in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                    let eventsCount = Int.random(in: 1...5)
                    
                    for eventIndex in 0..<eventsCount {
                        let hour = (eventIndex * 3) % 24
                        if let eventTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) {
                            let event = BiteEventModel(timestamp: eventTime)
                            container.mainContext.insert(event)
                        }
                    }
                }
            }
            
            try container.mainContext.save()
            
            PersistenceController.shared.populateTestData(daysBack: 60, deleteFirst: true)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
}
