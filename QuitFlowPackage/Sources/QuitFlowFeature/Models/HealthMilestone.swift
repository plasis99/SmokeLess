import Foundation

public struct HealthMilestone: Identifiable, Sendable {
    public let id: String
    public let icon: String
    public let titleKey: L10n
    public let requiredInterval: TimeInterval
    public let isUnlocked: Bool

    public static func milestones(timeSinceFirstReduction: TimeInterval) -> [HealthMilestone] {
        [
            HealthMilestone(
                id: "20min",
                icon: "heart.fill",
                titleKey: .health20min,
                requiredInterval: 20 * 60,
                isUnlocked: timeSinceFirstReduction >= 20 * 60
            ),
            HealthMilestone(
                id: "8h",
                icon: "lungs.fill",
                titleKey: .health8h,
                requiredInterval: 8 * 3600,
                isUnlocked: timeSinceFirstReduction >= 8 * 3600
            ),
            HealthMilestone(
                id: "48h",
                icon: "nose",
                titleKey: .health48h,
                requiredInterval: 48 * 3600,
                isUnlocked: timeSinceFirstReduction >= 48 * 3600
            ),
            HealthMilestone(
                id: "2w",
                icon: "drop.fill",
                titleKey: .health2w,
                requiredInterval: 14 * 86400,
                isUnlocked: timeSinceFirstReduction >= 14 * 86400
            ),
            HealthMilestone(
                id: "3m",
                icon: "wind",
                titleKey: .health3m,
                requiredInterval: 90 * 86400,
                isUnlocked: timeSinceFirstReduction >= 90 * 86400
            ),
            HealthMilestone(
                id: "1y",
                icon: "heart.circle.fill",
                titleKey: .health1y,
                requiredInterval: 365 * 86400,
                isUnlocked: timeSinceFirstReduction >= 365 * 86400
            ),
        ]
    }
}
