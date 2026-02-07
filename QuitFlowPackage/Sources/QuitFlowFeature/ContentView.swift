import SwiftUI
import SwiftData

public struct ContentView: View {
    public var body: some View {
        MainView()
    }

    public init() {}
}

#Preview {
    ContentView()
        .modelContainer(for: SmokingEntry.self, inMemory: true)
}
