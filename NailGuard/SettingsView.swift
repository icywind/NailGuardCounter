import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var biteEvents: [BiteEventModel]
    
    var body: some View {
        List {
            Section("Statistics") {
                HStack {
                    Text("Total Events")
                    Spacer()
                    Text("\(biteEvents.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Data Management") {
                Button("Clear All Data", role: .destructive) {
                    clearAllData()
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func clearAllData() {
        Task { @MainActor in
            PersistenceController.shared.deleteAllBites()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .modelContainer(for: BiteEventModel.self, inMemory: true)
        }
    }
}
