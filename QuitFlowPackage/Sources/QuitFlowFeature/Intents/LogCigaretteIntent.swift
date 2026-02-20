import AppIntents
#if os(iOS)
@preconcurrency import ActivityKit
#endif
import OSLog
import SwiftData
import WidgetKit

private let logger = Logger(subsystem: "com.perelygin.quitflow", category: "LogIntent")

public struct LogCigaretteIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log a Cigarette"
    public static let description: IntentDescription = "Record that you smoked a cigarette"
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        logger.info("LogCigaretteIntent: perform started")

        let appGroupID = "group.com.perelygin.quitflow"
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            logger.error("LogCigaretteIntent: App Group container not accessible")
            return .result(dialog: "Could not access shared data.")
        }

        let storeURL = containerURL.appendingPathComponent("default.store")
        let todayCount: Int

        do {
            let config = ModelConfiguration(url: storeURL)
            let container = try ModelContainer(for: SmokingEntry.self, configurations: config)
            let context = ModelContext(container)

            let entry = SmokingEntry(timestamp: .now)
            context.insert(entry)
            try context.save()
            logger.info("LogCigaretteIntent: entry saved successfully")

            // Count today's total
            let todayStart = Calendar.current.startOfDay(for: .now)
            let tomorrowStart = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
            let predicate = #Predicate<SmokingEntry> { e in
                e.timestamp >= todayStart && e.timestamp < tomorrowStart
            }
            let descriptor = FetchDescriptor(predicate: predicate)
            todayCount = (try? context.fetch(descriptor).count) ?? 0
        } catch {
            logger.error("LogCigaretteIntent: SwiftData error: \(error.localizedDescription)")
            // Fallback: write to UserDefaults so the main app can pick it up
            let defaults = UserDefaults(suiteName: appGroupID)
            let pending = (defaults?.integer(forKey: "pendingLogCount") ?? 0) + 1
            defaults?.set(pending, forKey: "pendingLogCount")
            defaults?.set(Date.now.timeIntervalSince1970, forKey: "lastPendingLogTimestamp")
            logger.info("LogCigaretteIntent: saved to UserDefaults fallback, pending=\(pending)")
            WidgetCenter.shared.reloadAllTimelines()
            return .result(dialog: "Logged (pending sync).")
        }

        WidgetCenter.shared.reloadAllTimelines()

        // Update Live Activity directly
        #if os(iOS)
        let newState = CigaretteActivityAttributes.ContentState(
            todayCount: todayCount,
            lastCigaretteDate: .now
        )
        let activities = Activity<CigaretteActivityAttributes>.activities
        logger.info("LogCigaretteIntent: updating \(activities.count) live activities")
        for activity in activities {
            await activity.update(ActivityContent(state: newState, staleDate: nil))
        }
        #endif

        logger.info("LogCigaretteIntent: completed, todayCount=\(todayCount)")
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
