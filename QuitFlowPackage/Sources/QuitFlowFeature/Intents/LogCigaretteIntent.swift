import AppIntents
import SwiftData
import WidgetKit

public struct LogCigaretteIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log a Cigarette"
    public static let description: IntentDescription = "Record that you smoked a cigarette"
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let appGroupID = "group.com.perelygin.quitflow"
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            return .result(dialog: "Could not access shared data.")
        }

        let storeURL = containerURL.appendingPathComponent("default.store")
        let config = ModelConfiguration(url: storeURL)
        let container = try ModelContainer(for: SmokingEntry.self, configurations: config)
        let context = ModelContext(container)

        let entry = SmokingEntry(timestamp: .now)
        context.insert(entry)
        try context.save()

        // Count today's total
        let todayStart = Calendar.current.startOfDay(for: .now)
        let tomorrowStart = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
        let predicate = #Predicate<SmokingEntry> { e in
            e.timestamp >= todayStart && e.timestamp < tomorrowStart
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        let todayCount = (try? context.fetch(descriptor).count) ?? 0

        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: "Logged. Today: \(todayCount)")
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
