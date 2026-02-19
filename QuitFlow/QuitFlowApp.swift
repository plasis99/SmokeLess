import SwiftUI
import SwiftData
import QuitFlowFeature

@main
struct QuitFlowApp: App {
    let modelContainer: ModelContainer

    init() {
        let appGroupID = "group.com.perelygin.quitflow"
        do {
            if let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupID
            ) {
                let storeURL = containerURL.appendingPathComponent("default.store")
                let config = ModelConfiguration(url: storeURL)
                modelContainer = try ModelContainer(for: SmokingEntry.self, configurations: config)
            } else {
                modelContainer = try ModelContainer(for: SmokingEntry.self)
            }
        } catch {
            // Fallback to in-memory store if persistent store corrupted
            modelContainer = try! ModelContainer(
                for: SmokingEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        // Activate Watch connectivity for iPhone ↔ Watch sync
        WatchConnectivityService.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
