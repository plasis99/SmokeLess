import SwiftUI

public struct WeekChartView: View {
    @Environment(AppSettings.self) private var settings
    let weekData: [DailyStats]
    let trendPercent: Int

    public init(weekData: [DailyStats], trendPercent: Int) {
        self.weekData = weekData
        self.trendPercent = trendPercent
    }

    private var maxCount: Int {
        max(weekData.map(\.count).max() ?? 1, 1)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text(settings.localized(.thisWeek))
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(Color.theme.textTertiary)

                Spacer()

                if trendPercent != 0 {
                    Text(trendPercent < 0 ? "↓ \(abs(trendPercent))%" : "↑ \(trendPercent)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(trendPercent < 0 ? Color.theme.cyan : Color.theme.amber)
                    Text(settings.localized(.vsLastWeek))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.theme.textTertiary)
                }
            }

            // Bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weekData.enumerated()), id: \.offset) { index, stats in
                    let isToday = index == weekData.count - 1

                    VStack(spacing: 6) {
                        // Count label
                        Text("\(stats.count)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isToday ? Color.theme.cyan : Color.theme.textTertiary)
                            .opacity(stats.count > 0 ? 1 : 0)

                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                isToday
                                ? LinearGradient(colors: [Color.theme.cyan, Color.theme.cyan.opacity(0.7)], startPoint: .bottom, endPoint: .top)
                                : LinearGradient(colors: [Color.theme.cyan.opacity(0.4), Color.theme.cyan.opacity(0.2)], startPoint: .bottom, endPoint: .top)
                            )
                            .frame(height: barHeight(for: stats.count))
                            .shadow(color: isToday ? Color.theme.cyan.opacity(0.3) : .clear, radius: 6)

                        // Day label
                        Text(stats.date.shortWeekday(locale: settings.language.locale))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isToday ? Color.theme.cyan : Color.theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 85)
        }
        .padding(14)
        .glassCard()
    }

    private func barHeight(for count: Int) -> CGFloat {
        guard count > 0 else { return 4 }
        return CGFloat(count) / CGFloat(maxCount) * 60 + 4
    }
}

#Preview {
    ZStack {
        LinearGradient.backgroundGradient.ignoresSafeArea()
        WeekChartView(
            weekData: (0..<7).map { i in
                DailyStats(date: Date.now.daysAgo(6 - i), entries: Array(repeating: Date.now, count: [5, 8, 3, 10, 7, 6, 4][i]))
            },
            trendPercent: -23
        )
        .padding()
        .environment(AppSettings())
    }
}
