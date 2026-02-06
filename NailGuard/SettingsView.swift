import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var biteEvents: [BiteEventModel]
    @State private var exportSuccess = false
    @State private var exportError: String?
    @State private var showExportError = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    
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
                Button("Populate Test Data") {
                    PersistenceController.shared.populateTestData(daysBack: 60, deleteFirst: true)
                }
                Button("Export Timestamps") {
                    exportTimestamps()
                }
                .sheet(isPresented: $showShareSheet) {
                    if let url = exportURL {
                        ShareLink(
                            item: url,
                            preview: SharePreview(
                                "NailGuard Export",
                                image: Image(systemName: "doc.text")
                            )
                        )
                        .presentationDetents([.medium])
                        .onDisappear {
                            showShareSheet = false
                        }
                    }
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
    
    private func exportAndShare(url: URL) {
        let vc = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        // iPad safety
        if let popover = vc.popoverPresentationController {
            popover.sourceView = UIApplication.shared
                .connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first
        }

        UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController?
            .present(vc, animated: true)
    }
    
    private func exportTimestamps() {
        Task { @MainActor in
            do {
                // Sort events by timestamp (descending)
                let sortedEvents = biteEvents.sorted { $0.timestamp > $1.timestamp }
                
                // Create formatted content
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                
                var content = "NailGuard Bite Event Timestamps\n"
                content += "Exported: \(dateFormatter.string(from: Date()))\n"
                content += "Total Events: \(sortedEvents.count)\n"
                content += String(repeating: "-", count: 50) + "\n\n"
                
                for (index, event) in sortedEvents.enumerated() {
                    content += "\(index + 1). \(dateFormatter.string(from: event.timestamp))\n"
                }
                
                // Get Documents directory
                guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    exportError = "Could not access Documents folder."
                    showExportError = true
                    return
                }
                
                // Create file URL
                let fileName = "BiteEventTimestamps_\(Date().timeIntervalSince1970).txt"
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                
                // Write to file
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                print("📁 Exported file path:", fileURL.path)
                print("📁 Exists:", FileManager.default.fileExists(atPath: fileURL.path))
                exportURL = fileURL
                exportSuccess = true
                showShareSheet = true
                
            } catch {
                exportError = "Failed to export timestamps: \(error.localizedDescription)"
                showExportError = true
            }
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
