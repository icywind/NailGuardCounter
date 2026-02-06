import SwiftUI
import Charts
import SwiftData

struct TrendsView: View {
    @Query(sort: \BiteEventModel.timestamp, order: .reverse)
    private var biteEvents: [BiteEventModel]
    
    @StateObject private var viewModel = TrendsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Time Range Picker
                timeRangePicker
                
                // Main Chart or Calendar
                if viewModel.selectedTimeRange == .month {
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
        .background(Color(.systemBackground))
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.updateEvents(biteEvents)
        }
        .onChange(of: biteEvents) { _, newEvents in
            viewModel.updateEvents(newEvents)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Progress")
                .font(.system(size: 28, weight: .bold))
            
            Text(viewModel.summaryText)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Time Range Picker
    private var timeRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                TimeRangeButton(
                    title: range.rawValue,
                    isSelected: viewModel.selectedTimeRange == range
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.setTimeRange(range)
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
                ForEach(viewModel.dailyData) { data in
                    BarMark(
                        x: .value("Day", data.date, unit: viewModel.selectedTimeRange == .year ? .month : .day),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(Color(red: 10/255, green: 132/255, blue: 255/255))
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        Text("\(data.count)")
                            .font(.caption)
                            .padding(4)
                            .background(Color.yellow)
                            .foregroundColor(Color(.secondarySystemBackground))
                            .cornerRadius(4)
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                if viewModel.selectedTimeRange == .year {
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
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.systemGray).opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Calendar")
                .font(.system(size: 17, weight: .semibold))
            
            CalendarGridView(
                biteCountByDate: viewModel.calendarData,
                selectedMonth: $viewModel.selectedMonth,
                onMonthChanged: { viewModel.updateDataForSelectedMonth($0) }
            )
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.systemGray).opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total",
                value: "\(viewModel.totalBites)",
                icon: "chart.bar.fill",
                color: .blue
            )
            
            StatCard(
                title: "Best Day",
                value: "\(viewModel.bestDay)",
                icon: "star.fill",
                color: .green
            )
            
            StatCard(
                title: "Avg/Day",
                value: String(format: "%.1f", viewModel.averagePerDay),
                icon: "waveform.path.ecg",
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
                    viewModel.showingInsights.toggle()
                }) {
                    Image(systemName: viewModel.showingInsights ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.showingInsights {
                VStack(spacing: 12) {
                    ForEach(viewModel.insights, id: \.title) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.systemGray).opacity(0.3), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Hourly Pattern Section
    private var hourlyPatternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Peak Times")
                .font(.system(size: 17, weight: .semibold))
            
            HourlyHeatmap(data: viewModel.hourlyPatternData)
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.systemGray).opacity(0.3), radius: 8, x: 0, y: 2)
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
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.systemGray).opacity(0.3), radius: 8, x: 0, y: 2)
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
    @Binding var selectedMonth: Date?
    let onMonthChanged: (Date) -> Void
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
            selectedMonth = currentMonth
            onMonthChanged(currentMonth)
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
            selectedMonth = currentMonth
            onMonthChanged(currentMonth)
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
                    .foregroundColor(Color(.secondarySystemBackground))
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
