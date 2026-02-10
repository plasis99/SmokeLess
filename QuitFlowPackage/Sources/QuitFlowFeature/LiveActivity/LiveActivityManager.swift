#if os(iOS)
import ActivityKit
import Foundation

@MainActor
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private var currentActivity: Activity<CigaretteActivityAttributes>?

    private init() {}

    public func startOrUpdate(todayCount: Int, lastCigaretteDate: Date?) {
        let state = CigaretteActivityAttributes.ContentState(
            todayCount: todayCount,
            lastCigaretteDate: lastCigaretteDate ?? .now
        )

        if let activity = currentActivity, activity.activityState == .active {
            Task {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        } else {
            startActivity(state: state)
        }
    }

    public func endActivity() {
        guard let activity = currentActivity else { return }
        let finalState = activity.content.state
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        currentActivity = nil
    }

    private func startActivity(state: CigaretteActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        do {
            let attributes = CigaretteActivityAttributes()
            let content = ActivityContent(state: state, staleDate: nil)
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
        } catch {
            // Activity couldn't be started — user may have disabled Live Activities
        }
    }
}
#endif
