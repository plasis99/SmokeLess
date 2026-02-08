import SwiftUI

public struct GoalCardView: View {
    @Environment(AppSettings.self) private var settings
    let todayCount: Int
    let yesterdayCount: Int

    public init(todayCount: Int, yesterdayCount: Int) {
        self.todayCount = todayCount
        self.yesterdayCount = yesterdayCount
    }

    private var progress: Double {
        guard yesterdayCount > 0 else { return 0 }
        return Double(todayCount) / Double(yesterdayCount)
    }

    private var progressGradient: LinearGradient {
        if progress < 0.7 {
            return LinearGradient(colors: [Color.theme.cyan, Color.theme.cyan.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        } else if progress < 0.9 {
            return LinearGradient(colors: [Color.theme.cyan, Color.theme.amber], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [Color.theme.amber, Color.theme.redSoft], startPoint: .leading, endPoint: .trailing)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if yesterdayCount == 0 && todayCount == 0 {
                // First day
                HStack {
                    Text("▼")
                        .foregroundStyle(Color.theme.cyan)
                    Text(settings.localized(.startTracking))
                        .foregroundStyle(Color.theme.textPrimary)
                }
                .font(.system(size: 14, weight: .medium))
            } else if yesterdayCount == 0 {
                Text(settings.localized(.noCigsYesterday))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.theme.cyan)
            } else {
                // Normal state
                HStack {
                    HStack(spacing: 4) {
                        Text("▼")
                            .foregroundStyle(Color.theme.cyan)
                        Text(settings.localized(.goalLessThanYesterday))
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .font(.system(size: 12, weight: .medium))

                    Spacer()

                    HStack(spacing: 2) {
                        Text("\(todayCount)")
                            .foregroundStyle(progress >= 1.0 ? Color.theme.redSoft : Color.theme.textPrimary)
                        Text("/ <\(yesterdayCount)")
                            .foregroundStyle(Color.theme.textTertiary)
                    }
                    .font(.system(size: 14, weight: .semibold))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Color.white.opacity(0.06))

                        // Fill
                        Capsule()
                            .fill(progressGradient)
                            .frame(width: max(0, geo.size.width * min(progress, 1.0)))
                            .overlay(alignment: .trailing) {
                                // Glowing dot
                                Circle()
                                    .fill(progress < 0.9 ? Color.theme.cyan : Color.theme.amber)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: (progress < 0.9 ? Color.theme.cyan : Color.theme.amber).opacity(0.6), radius: 4)
                                    .offset(x: 2)
                            }
                    }
                }
                .frame(height: 6)

                Text(settings.localized(.yesterdayCigs, args: "\(yesterdayCount)"))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.theme.textTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(yesterdayCount > 0
            ? settings.localized(.accessGoalProgress, args: "\(todayCount)", "\(yesterdayCount)")
            : settings.localized(.startTracking))
    }
}

#Preview {
    ZStack {
        LinearGradient.backgroundGradient.ignoresSafeArea()
        VStack(spacing: 16) {
            GoalCardView(todayCount: 7, yesterdayCount: 10)
            GoalCardView(todayCount: 0, yesterdayCount: 0)
            GoalCardView(todayCount: 5, yesterdayCount: 0)
        }
        .padding()
        .environment(AppSettings())
    }
}
