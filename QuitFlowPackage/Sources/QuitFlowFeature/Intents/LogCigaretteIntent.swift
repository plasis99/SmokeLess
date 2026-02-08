import AppIntents
import SwiftData

public struct LogCigaretteIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log a Cigarette"
    public static let description: IntentDescription = "Record that you smoked a cigarette"
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Cigarette logged. Stay strong!")
    }
}

public struct ShowStatsIntent: AppIntent {
    public static let title: LocalizedStringResource = "Show Smoking Stats"
    public static let description: IntentDescription = "View your smoking statistics"
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

public struct QuitFlowShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogCigaretteIntent(),
            phrases: [
                "Log a cigarette in \(.applicationName)",
                "I smoked in \(.applicationName)",
                "Record cigarette in \(.applicationName)"
            ],
            shortTitle: "Log Cigarette",
            systemImageName: "flame"
        )
        AppShortcut(
            intent: ShowStatsIntent(),
            phrases: [
                "Show my stats in \(.applicationName)",
                "How many cigarettes today in \(.applicationName)"
            ],
            shortTitle: "Show Stats",
            systemImageName: "chart.bar"
        )
    }
}
