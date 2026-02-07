import SwiftUI

public struct StatsRowView: View {
    let todayCount: Int
    let yesterdayCount: Int
    let averageInterval: TimeInterval

    public init(todayCount: Int, yesterdayCount: Int, averageInterval: TimeInterval) {
        self.todayCount = todayCount
        self.yesterdayCount = yesterdayCount
        self.averageInterval = averageInterval
    }

    private var difference: Int {
        todayCount - yesterdayCount
    }

    public var body: some View {
        HStack(spacing: 12) {
            statCard(
                title: "СЕГОДНЯ",
                value: "\(todayCount)",
                valueColor: Color.theme.textPrimary
            )

            statCard(
                title: "К ВЧЕРА",
                value: differenceText,
                valueColor: difference <= 0 ? Color.theme.cyan : Color.theme.amber
            )

            statCard(
                title: "ИНТЕРВАЛ ⌀",
                value: averageInterval > 0 ? Date.formattedInterval(averageInterval) : "—",
                valueColor: Color.theme.textPrimary
            )
        }
    }

    private var differenceText: String {
        if yesterdayCount == 0 { return "—" }
        if difference < 0 { return "↓ \(abs(difference))" }
        if difference > 0 { return "↑ \(difference)" }
        return "= 0"
    }

    private func statCard(title: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundStyle(Color.theme.textTertiary)

            Text(value)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard()
    }
}

#Preview {
    ZStack {
        LinearGradient.backgroundGradient.ignoresSafeArea()
        StatsRowView(todayCount: 7, yesterdayCount: 10, averageInterval: 4800)
            .padding()
    }
}
