import SwiftUI
import SwiftData
import QuitFlowFeature

@main
struct QuitFlowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SmokingEntry.self)
    }
}
