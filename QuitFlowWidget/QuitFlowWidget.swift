import ActivityKit
import WidgetKit
import SwiftUI
import SwiftData
import AppIntents
import QuitFlowFeature

// MARK: - App Group

private let appGroupID = "group.com.perelygin.quitflow"

// MARK: - Timeline Entry

struct SmokeLessEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let timeSinceLast: String
    let hasData: Bool
}

// MARK: - Timeline Provider

struct SmokeLessTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmokeLessEntry {
        SmokeLessEntry(date: .now, todayCount: 3, timeSinceLast: "1h 24m", hasData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SmokeLessEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmokeLessEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> SmokeLessEntry {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            return SmokeLessEntry(date: .now, todayCount: 0, timeSinceLast: "—", hasData: false)
        }

        let storeURL = containerURL.appendingPathComponent("default.store")

        do {
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

            let lastDate = entries.last?.timestamp
            let timeSince: String
            if let last = lastDate {
                let interval = Date.now.timeIntervalSince(last)
                let hours = Int(interval) / 3600
                let minutes = (Int(interval) % 3600) / 60
                if hours > 0 {
                    timeSince = "\(hours)h \(minutes)m"
                } else {
                    timeSince = "\(minutes)m"
                }
            } else {
                timeSince = "—"
            }

            return SmokeLessEntry(
                date: .now,
                todayCount: entries.count,
                timeSinceLast: timeSince,
                hasData: true
            )
        } catch {
            return SmokeLessEntry(date: .now, todayCount: 0, timeSinceLast: "—", hasData: false)
        }
    }
}

// MARK: - Widget Views

struct SmokeLessWidgetView: View {
    var entry: SmokeLessEntry
    @Environment(\.widgetFamily) var family

    private let teal = Color(red: 0.306, green: 0.871, blue: 0.706)
    private let bgDark = Color(red: 0.04, green: 0.055, blue: 0.09)
    private let bgCard = Color(red: 0.08, green: 0.1, blue: 0.14)

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(spacing: 6) {
            HStack {
                Text("SMOKELESS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }

            Spacer()

            Text(entry.timeSinceLast)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(teal)
                .minimumScaleFactor(0.6)

            Text("since last")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            HStack {
                HStack(spacing: 4) {
                    Text("TODAY")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("\(entry.todayCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button(intent: LogCigaretteIntent()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(teal)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .containerBackground(bgDark, for: .widget)
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left: Timer
            VStack(spacing: 6) {
                Text(entry.timeSinceLast)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(teal)
                    .minimumScaleFactor(0.6)

                Text("since last cigarette")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            // Divider
            RoundedRectangle(cornerRadius: 1)
                .fill(teal.opacity(0.3))
                .frame(width: 2, height: 50)

            // Right: Today count + button
            VStack(spacing: 8) {
                Text("\(entry.todayCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("today")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Button(intent: LogCigaretteIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("LOG")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(bgDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(teal, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .containerBackground(bgDark, for: .widget)
    }
}

// MARK: - Widget Configuration

struct SmokeLessWidget: Widget {
    let kind = "SmokeLessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmokeLessTimelineProvider()) { entry in
            SmokeLessWidgetView(entry: entry)
        }
        .configurationDisplayName("SmokeLess")
        .description("Track cigarettes and time since last one.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct SmokeLessWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmokeLessWidget()
        CigaretteLiveActivity()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    SmokeLessWidget()
} timeline: {
    SmokeLessEntry(date: .now, todayCount: 5, timeSinceLast: "1h 24m", hasData: true)
}

#Preview("Medium", as: .systemMedium) {
    SmokeLessWidget()
} timeline: {
    SmokeLessEntry(date: .now, todayCount: 5, timeSinceLast: "1h 24m", hasData: true)
}
