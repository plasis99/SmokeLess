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
    let lastCigaretteDate: Date?
    let hasData: Bool
}

// MARK: - Timeline Provider

struct SmokeLessTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmokeLessEntry {
        SmokeLessEntry(date: .now, todayCount: 3, lastCigaretteDate: .now.addingTimeInterval(-5040), hasData: true)
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
            return SmokeLessEntry(date: .now, todayCount: 0, lastCigaretteDate: nil, hasData: false)
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

            return SmokeLessEntry(
                date: .now,
                todayCount: entries.count,
                lastCigaretteDate: entries.last?.timestamp,
                hasData: true
            )
        } catch {
            return SmokeLessEntry(date: .now, todayCount: 0, lastCigaretteDate: nil, hasData: false)
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

            // Live timer with seconds
            if let lastDate = entry.lastCigaretteDate {
                Text(lastDate, style: .timer)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(teal)
                    .monospacedDigit()
            } else {
                Text("—")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(teal)
            }

            Text("since last")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            // Cigarette button
            Button(intent: LogCigaretteIntent()) {
                CigaretteIcon(height: 8)
            }
            .buttonStyle(.plain)

            Spacer()

            // Today count
            HStack(spacing: 4) {
                Text("TODAY")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.4))
                Text("\(entry.todayCount)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
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
                if let lastDate = entry.lastCigaretteDate {
                    Text(lastDate, style: .timer)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(teal)
                        .monospacedDigit()
                } else {
                    Text("—")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(teal)
                }

                Text("since last cigarette")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            // Divider
            RoundedRectangle(cornerRadius: 1)
                .fill(teal.opacity(0.3))
                .frame(width: 2, height: 50)

            // Right: Today count + cigarette button
            VStack(spacing: 8) {
                Text("\(entry.todayCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("today")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Button(intent: LogCigaretteIntent()) {
                    ZStack {
                        Circle()
                            .fill(teal.opacity(0.15))
                            .frame(width: 40, height: 40)
                        CigaretteIcon(height: 8)
                    }
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
    SmokeLessEntry(date: .now, todayCount: 5, lastCigaretteDate: .now.addingTimeInterval(-5040), hasData: true)
}

#Preview("Medium", as: .systemMedium) {
    SmokeLessWidget()
} timeline: {
    SmokeLessEntry(date: .now, todayCount: 5, lastCigaretteDate: .now.addingTimeInterval(-5040), hasData: true)
}
