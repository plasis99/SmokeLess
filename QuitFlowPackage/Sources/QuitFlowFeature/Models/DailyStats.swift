import Foundation

public struct DailyStats: Identifiable, Sendable {
    public let date: Date
    public let count: Int
    public let averageInterval: TimeInterval
    public let firstEntry: Date?
    public let lastEntry: Date?

    public var id: String { date.dayString }

    public init(date: Date, entries: [Date]) {
        self.date = date
        self.count = entries.count
        self.firstEntry = entries.min()
        self.lastEntry = entries.max()

        if entries.count >= 2 {
            let sorted = entries.sorted()
            let intervals = zip(sorted, sorted.dropFirst()).map { $1.timeIntervalSince($0) }
            self.averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        } else {
            self.averageInterval = 0
        }
    }

    public static let empty = DailyStats(date: .now, entries: [])
}
