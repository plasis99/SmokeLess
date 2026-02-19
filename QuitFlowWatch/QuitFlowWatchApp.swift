import SwiftUI
import SwiftData
import WatchKit
import QuitFlowFeature

@main
struct QuitFlowWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var appDelegate
    let modelContainer: ModelContainer
    @State private var settings = AppSettings()

    init() {
        // Watch stores data in App Group so Watch Widget can read it
        let appGroupID = "group.com.perelygin.quitflow"
        do {
            if let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupID
            ) {
                let storeURL = containerURL.appendingPathComponent("watch.store")
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

        WatchConnectivityService.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .environment(settings)
        }
        .modelContainer(modelContainer)
    }
}
