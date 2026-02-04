import SwiftUI
import SwiftData

@main
struct NailGuardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.none) // Allow system to control color scheme
        }
        .modelContainer(PersistenceController.shared.container)
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            
            NavigationView {
                TrendsView()
            }
            .tabItem {
                Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }.onAppear() {
    PersistenceController.shared.populateTestData(daysBack: 60, deleteFirst: true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: BiteEventModel.self, inMemory: true)
    }
}
