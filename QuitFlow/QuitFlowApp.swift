import SwiftUI
import SwiftData
import QuitFlowFeature

@main
struct QuitFlowApp: App {
    let modelContainer: ModelContainer

    init() {
        let appGroupID = "group.com.perelygin.quitflow"
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) {
            let storeURL = containerURL.appendingPathComponent("default.store")
            let config = ModelConfiguration(url: storeURL)
            modelContainer = try! ModelContainer(for: SmokingEntry.self, configurations: config)
        } else {
            modelContainer = try! ModelContainer(for: SmokingEntry.self)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
