import SwiftUI

struct StatsDetailView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let monthData: [DailyStats]

    private var totalCigs: Int {
        monthData.reduce(0) { $0 + $1.count }
    }

    private var dailyAvg: Double {
        let daysWithData = monthData.filter { $0.count > 0 }.count
        guard daysWithData > 0 else { return 0 }
        return Double(totalCigs) / Double(daysWithData)
    }

    private var bestDay: DailyStats? {
        monthData.filter { $0.count > 0 }.min(by: { $0.count < $1.count })
    }

    private var worstDay: DailyStats? {
        monthData.max(by: { $0.count < $1.count })
    }

    private var maxCount: Int {
        max(monthData.map(\.count).max() ?? 1, 1)
    }

    private var trendPercent: Int {
        let firstHalf = monthData.prefix(15).reduce(0) { $0 + $1.count }
        let secondHalf = monthData.suffix(15).reduce(0) { $0 + $1.count }
        guard firstHalf > 0 else { return 0 }
        return Int(((Double(secondHalf) - Double(firstHalf)) / Double(firstHalf)) * 100)
    }

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header

                    // Summary cards
                    summaryCards

                    // 30-day chart
                    monthChart

                    // Trend
                    trendCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.theme.cyan)
            }

            Spacer()

            Text(settings.localized(.statistics))
                .font(.system(size: 15, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color.theme.textTertiary)

            Spacer()

            Color.clear.frame(width: 18, height: 18)
        }
        .padding(.top, 8)
    }

    // MARK: - Summary

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: settings.localized(.totalCigs),
                value: "\(totalCigs)",
                color: Color.theme.textPrimary
            )

            summaryCard(
                title: settings.localized(.dailyAvg),
                value: String(format: "%.1f", dailyAvg),
                color: Color.theme.cyan
            )
        }
    }

    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundStyle(Color.theme.textTertiary)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }

    // MARK: - Month Chart

    private var monthChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(settings.localized(.last30days))
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundStyle(Color.theme.textTertiary)

            // Mini bar chart (30 bars)
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(monthData) { stats in
                    let isToday = stats.id == Date.now.dayString
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            isToday
                            ? Color.theme.cyan
                            : Color.theme.cyan.opacity(barOpacity(for: stats.count))
                        )
                        .frame(height: barHeight(for: stats.count))
                }
            }
            .frame(height: 80)

            // Best / Worst
            if let best = bestDay, let worst = worstDay {
                HStack(spacing: 12) {
                    dayLabel(
                        title: settings.localized(.bestDay),
                        day: best,
                        color: Color.theme.cyan
                    )
                    dayLabel(
                        title: settings.localized(.worstDay),
                        day: worst,
                        color: Color.theme.amber
                    )
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    private func dayLabel(title: String, day: DailyStats, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.theme.textTertiary)
            HStack(spacing: 4) {
                Text("\(day.count)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
                Text(day.date.shortWeekday(locale: settings.language.locale))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trend

    private var trendCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(settings.localized(.trend30d))
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(Color.theme.textTertiary)
                    .textCase(.uppercase)

                Text(trendPercent < 0 ? "↓ \(abs(trendPercent))%" : trendPercent > 0 ? "↑ \(trendPercent)%" : "— 0%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(trendPercent <= 0 ? Color.theme.cyan : Color.theme.amber)
            }

            Spacer()

            Image(systemName: trendPercent <= 0 ? "arrow.down.right" : "arrow.up.right")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(trendPercent <= 0 ? Color.theme.cyan.opacity(0.3) : Color.theme.amber.opacity(0.3))
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Helpers

    private func barHeight(for count: Int) -> CGFloat {
        guard count > 0 else { return 2 }
        return CGFloat(count) / CGFloat(maxCount) * 70 + 4
    }

    private func barOpacity(for count: Int) -> Double {
        guard maxCount > 0, count > 0 else { return 0.1 }
        return 0.2 + (Double(count) / Double(maxCount)) * 0.5
    }
}

#Preview {
    StatsDetailView(
        monthData: (0..<30).map { i in
            DailyStats(date: Date.now.daysAgo(29 - i), entries: Array(repeating: Date.now, count: Int.random(in: 0...15)))
        }
    )
    .environment(AppSettings())
}
