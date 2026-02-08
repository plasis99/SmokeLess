import SwiftUI

struct AchievementsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    let currentStreak: Int
    let timeSinceFirstEntry: TimeInterval

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    header

                    // Streak card
                    streakCard

                    // Health Timeline
                    healthTimelineSection
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

            Text(settings.localized(.achievements))
                .font(.system(size: 15, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color.theme.textTertiary)

            Spacer()

            Color.clear.frame(width: 18, height: 18)
        }
        .padding(.top, 8)
    }

    // MARK: - Streak

    private var streakCard: some View {
        VStack(spacing: 8) {
            Text("\(currentStreak)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(currentStreak > 0 ? Color.theme.cyan : Color.theme.textTertiary)

            Text(settings.localized(.streakDays))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.theme.textSecondary)

            Text(settings.localized(.streakDesc))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard()
    }

    // MARK: - Health Timeline

    private var healthTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settings.localized(.healthTimeline))
                .font(.system(size: 10, weight: .medium))
                .tracking(1)
                .foregroundStyle(Color.theme.textTertiary)
                .textCase(.uppercase)

            let milestones = HealthMilestone.milestones(timeSinceFirstReduction: timeSinceFirstEntry)

            ForEach(milestones) { milestone in
                milestoneRow(milestone)
            }
        }
        .padding(14)
        .glassCard()
    }

    private func milestoneRow(_ milestone: HealthMilestone) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(milestone.isUnlocked ? Color.theme.cyan.opacity(0.15) : Color.white.opacity(0.04))
                    .frame(width: 36, height: 36)

                Image(systemName: milestone.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(milestone.isUnlocked ? Color.theme.cyan : Color.theme.textTertiary)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(timeLabel(milestone.requiredInterval))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(milestone.isUnlocked ? Color.theme.textPrimary : Color.theme.textTertiary)

                Text(settings.localized(milestone.titleKey))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(milestone.isUnlocked ? Color.theme.textSecondary : Color.theme.textTertiary.opacity(0.5))
            }

            Spacer()

            // Checkmark
            if milestone.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.theme.cyan)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.theme.textTertiary.opacity(0.4))
            }
        }
        .padding(.vertical, 4)
    }

    private func timeLabel(_ interval: TimeInterval) -> String {
        if interval < 3600 {
            return "\(Int(interval / 60)) min"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h"
        } else if interval < 86400 * 30 {
            return "\(Int(interval / 86400))d"
        } else if interval < 86400 * 365 {
            return "\(Int(interval / (86400 * 30)))m"
        } else {
            return "\(Int(interval / (86400 * 365)))y"
        }
    }
}

#Preview {
    AchievementsView(currentStreak: 5, timeSinceFirstEntry: 72 * 3600)
        .environment(AppSettings())
}
