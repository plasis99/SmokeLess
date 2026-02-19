#if os(iOS)
@preconcurrency import ActivityKit
import Foundation

@MainActor
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private var currentActivity: Activity<CigaretteActivityAttributes>?

    private init() {}

    public func startOrUpdate(todayCount: Int, lastCigaretteDate: Date?) async {
        let state = CigaretteActivityAttributes.ContentState(
            todayCount: todayCount,
            lastCigaretteDate: lastCigaretteDate ?? .now
        )

        // Restore currentActivity from system if process was restarted
        if currentActivity == nil {
            currentActivity = Activity<CigaretteActivityAttributes>.activities.first
        }

        // End all duplicate activities (keep only currentActivity)
        let allActivities = Activity<CigaretteActivityAttributes>.activities
        for activity in allActivities where activity.id != currentActivity?.id {
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        if let activity = currentActivity, activity.activityState == .active {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        } else {
            startActivity(state: state)
        }
    }

    public func endActivity() async {
        // End all activities (including orphans from previous process)
        let allActivities = Activity<CigaretteActivityAttributes>.activities
        for activity in allActivities {
            let finalState = activity.content.state
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
