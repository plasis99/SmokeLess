#if os(iOS)
import ActivityKit
import Foundation

public struct CigaretteActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var todayCount: Int
        public var lastCigaretteDate: Date

        public init(todayCount: Int, lastCigaretteDate: Date) {
            self.todayCount = todayCount
            self.lastCigaretteDate = lastCigaretteDate
        }
    }

    public init() {}
}
#endif
