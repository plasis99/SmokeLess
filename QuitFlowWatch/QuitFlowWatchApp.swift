import SwiftUI
import SwiftData
import QuitFlowFeature

@main
struct QuitFlowWatchApp: App {
    let modelContainer: ModelContainer
    @State private var settings = AppSettings()

    init() {
        // Watch has its own local SwiftData store (separate from iPhone)
        // Data syncs via WatchConnectivity
        modelContainer = try! ModelContainer(for: SmokingEntry.self)

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
