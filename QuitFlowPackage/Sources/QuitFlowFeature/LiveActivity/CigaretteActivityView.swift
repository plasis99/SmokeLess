#if os(iOS)
import ActivityKit
import SwiftUI
import WidgetKit

public struct CigaretteLiveActivity: Widget {
    public init() {}

    private let teal = Color(red: 0.306, green: 0.871, blue: 0.706)

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: CigaretteActivityAttributes.self) { context in
            // Lock Screen / Banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Since last")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(context.state.lastCigaretteDate, style: .timer)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(teal)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Today")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("\(context.state.todayCount)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: LogCigaretteIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("LOG")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.5)
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(teal, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } compactLeading: {
                Image(systemName: "lungs.fill")
                    .foregroundStyle(teal)
                    .font(.system(size: 12))
            } compactTrailing: {
                Text("\(context.state.todayCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(teal)
                    .monospacedDigit()
            } minimal: {
                Text("\(context.state.todayCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(teal)
            }
        }
    }

    // MARK: - Lock Screen View

    private func lockScreenView(context: ActivityViewContext<CigaretteActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            // Timer
            VStack(alignment: .leading, spacing: 4) {
                Text("SMOKELESS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.5))

                Text(context.state.lastCigaretteDate, style: .timer)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(teal)
                    .monospacedDigit()

                Text("since last")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Count + button
            VStack(spacing: 6) {
                Text("\(context.state.todayCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("today")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                Button(intent: LogCigaretteIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("LOG")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(teal, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .activityBackgroundTint(Color(red: 0.04, green: 0.055, blue: 0.09))
    }
}
#endif
