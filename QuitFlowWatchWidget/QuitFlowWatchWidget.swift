import WidgetKit
import SwiftUI
import SwiftData
import QuitFlowFeature

// MARK: - App Group

private let watchAppGroupID = "group.com.perelygin.quitflow"

// MARK: - Timeline Entry

struct WatchSmokingEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let lastCigaretteDate: Date?
}

// MARK: - Timeline Provider

struct WatchSmokingProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchSmokingEntry {
        WatchSmokingEntry(date: .now, todayCount: 3, lastCigaretteDate: .now.addingTimeInterval(-3600))
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchSmokingEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchSmokingEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> WatchSmokingEntry {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: watchAppGroupID
        ) else {
            return WatchSmokingEntry(date: .now, todayCount: 0, lastCigaretteDate: nil)
        }

        do {
            let storeURL = containerURL.appendingPathComponent("watch.store")
            let config = ModelConfiguration(url: storeURL)
            let container = try ModelContainer(for: SmokingEntry.self, configurations: config)
            let context = ModelContext(container)

            let todayStart = Calendar.current.startOfDay(for: .now)
            let tomorrowStart = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!

            let predicate = #Predicate<SmokingEntry> { entry in
                entry.timestamp >= todayStart && entry.timestamp < tomorrowStart
            }
            let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
            let entries = try context.fetch(descriptor)

            return WatchSmokingEntry(
                date: .now,
                todayCount: entries.count,
                lastCigaretteDate: entries.last?.timestamp
            )
        } catch {
            return WatchSmokingEntry(date: .now, todayCount: 0, lastCigaretteDate: nil)
        }
    }
}

// MARK: - Circular Complication View

struct WatchComplicationCircularView: View {
    let entry: WatchSmokingEntry

    private let bronze = Color(red: 0.769, green: 0.604, blue: 0.235)

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "flame")
                    .font(.system(size: 10))
                    .foregroundStyle(bronze)
                Text("\(entry.todayCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Rectangular Complication View

struct WatchComplicationRectangularView: View {
    let entry: WatchSmokingEntry

    private let bronze = Color(red: 0.769, green: 0.604, blue: 0.235)

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SmokeLess")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                HStack(spacing: 4) {
                    CigaretteIcon(height: 8, showSmoke: true)
                    Text("\(entry.todayCount) today")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            if let lastDate = entry.lastCigaretteDate {
                Text(lastDate, style: .timer)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(bronze)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Router View

struct WatchComplicationView: View {
    let entry: WatchSmokingEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            WatchComplicationRectangularView(entry: entry)
        default:
            WatchComplicationCircularView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct QuitFlowWatchWidget: Widget {
    let kind = "QuitFlowWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchSmokingProvider()) { entry in
            WatchComplicationView(entry: entry)
        }
        .configurationDisplayName("SmokeLess")
        .description("Today's cigarette count.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Widget Entry Point

@main
struct QuitFlowWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuitFlowWatchWidget()
    }
}
