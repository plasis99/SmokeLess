import Foundation
import SwiftData

/// Shared data for widget display. Used by both the main app and widget extension.
public struct WidgetData: Sendable {
    public let todayCount: Int
    public let timeSinceLast: TimeInterval
    public let lastEntryDate: Date?

    public init(todayCount: Int = 0, timeSinceLast: TimeInterval = 0, lastEntryDate: Date? = nil) {
        self.todayCount = todayCount
        self.timeSinceLast = timeSinceLast
        self.lastEntryDate = lastEntryDate
    }

    public var formattedTime: String {
        guard timeSinceLast > 0 else { return "—" }
        let hours = Int(timeSinceLast) / 3600
        let minutes = (Int(timeSinceLast) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

/// Provides data for the widget by querying SwiftData
public enum WidgetDataProvider {
    @MainActor
    public static func loadData(modelContext: ModelContext) -> WidgetData {
        let todayStart = Date.now.startOfDay
        let tomorrowStart = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!

        let predicate = #Predicate<SmokingEntry> { entry in
            entry.timestamp >= todayStart && entry.timestamp < tomorrowStart
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])

        do {
            let entries = try modelContext.fetch(descriptor)
            let lastDate = entries.last?.timestamp
            let timeSince = lastDate.map { Date.now.timeIntervalSince($0) } ?? 0

            return WidgetData(
                todayCount: entries.count,
                timeSinceLast: timeSince,
                lastEntryDate: lastDate
            )
        } catch {
            return WidgetData()
        }
    }
}
