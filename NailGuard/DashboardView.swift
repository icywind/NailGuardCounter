import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \BiteEventModel.timestamp, order: .reverse)
    private var biteEvents: [BiteEventModel]
    
    @State private var todayCount: Int = 0
    @State private var weekData: [Int] = Array(repeating: 0, count: 7)
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Color(red: 242/255, green: 242/255, blue: 247/255)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Text("NailGuard")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Spacer()
                    
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                    .frame(height: 40)
                
                // Today Section
                VStack(spacing: 12) {
                    Text("TODAY")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 170/255, green: 170/255, blue: 170/255))
                    
                    Text("\(todayCount)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                
                Spacer()
                    .frame(height: 60)
                
                // Center Button
                ZStack {
                    CircularButton(action: {
                            print("Tapped, todayCount: \(todayCount) add 1")
                            PersistenceController.shared.addBite()
                        },
                        backgroundColor: .blue, centerColor: Color.pink.opacity(0.7)
                    )
                }
                
                Spacer()
                    .frame(height: 60)
                
                // This Week Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("This Week")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.systemGray))
                        .padding(.horizontal, 24)
                    
                    // Bar Chart
                    let maxCount = weekData.max() ?? 1
                    HStack(alignment: .bottom, spacing: 20) {
                        ForEach(0..<weekData.count, id: \.self) { index in
                            BarView(height: CGFloat(weekData[index]), maxHeight: CGFloat(maxCount))
                        }
                    }
                    .padding(.horizontal, 40)
                    .frame(height: 100)
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
        .onAppear {
            updateDashboardData()
        }
        .onChange(of: biteEvents.count) { _, _ in
            updateDashboardData()
        }
    }
    
    private func updateDashboardData() {
        // Calculate today's count
        let today = calendar.startOfDay(for: Date())
        todayCount = biteEvents.filter { event in
            calendar.isDate(event.timestamp, inSameDayAs: today)
        }.count
        
        // Calculate this week's data
        var newWeekData = Array(repeating: 0, count: 7)
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            
            let count = biteEvents.filter { event in
                calendar.isDate(event.timestamp, inSameDayAs: dayStart)
            }.count
            
            newWeekData[6 - i] = count
        }
        weekData = newWeekData
    }
}

struct BarView: View {
    let height: CGFloat
    let maxHeight: CGFloat
    
    var body: some View {
        // Scale the height to fit within a chart that's 2x the max height
        let scaledHeight = maxHeight > 0 ? (height / maxHeight) * 100 : 0
        
        Rectangle()
            .fill(Color(red: 10/255, green: 132/255, blue: 255/255))
            .frame(width: 20, height: scaledHeight)
            .cornerRadius(2)
    }
}

// Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .modelContainer(previewContainer)
    }
    
    @MainActor
    static var previewContainer: ModelContainer = {
        let schema = Schema([BiteEventModel.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        
        let calendar = Calendar.current
        let now = Date()
        
        // Add sample events for today
        for _ in 0..<3 {
            let event = BiteEventModel(timestamp: now)
            container.mainContext.insert(event)
        }
        
        // Add sample events for the past week
        for daysAgo in 1..<7 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            let eventsCount = Int.random(in: 1...8)
            
            for _ in 0..<eventsCount {
                let hour = Int.random(in: 0...23)
                if let eventTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) {
                    let event = BiteEventModel(timestamp: eventTime)
                    container.mainContext.insert(event)
                }
            }
        }
        
        return container
    }()
}
