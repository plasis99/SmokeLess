import Testing
import Foundation
@testable import QuitFlowFeature

// MARK: - SmokingEntryTransfer Tests

@Suite("SmokingEntryTransfer")
struct SmokingEntryTransferTests {
    @Test("Round-trip dictionary conversion preserves data")
    func roundTrip() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1700000000)
        let transfer = SmokingEntryTransfer(id: id, timestamp: timestamp)

        let dict = transfer.toDictionary()
        let restored = SmokingEntryTransfer.from(dictionary: dict)

        #expect(restored != nil)
        #expect(restored?.id == id)
        #expect(restored?.timestamp == timestamp)
    }

    @Test("Missing keys return nil")
    func missingKeys() {
        let noId: [String: Any] = ["timestamp": 1700000000.0]
        #expect(SmokingEntryTransfer.from(dictionary: noId) == nil)

        let noTimestamp: [String: Any] = ["id": UUID().uuidString]
        #expect(SmokingEntryTransfer.from(dictionary: noTimestamp) == nil)

        let empty: [String: Any] = [:]
        #expect(SmokingEntryTransfer.from(dictionary: empty) == nil)
    }

    @Test("Invalid UUID string returns nil")
    func invalidUUID() {
        let dict: [String: Any] = [
            "id": "not-a-valid-uuid",
            "timestamp": 1700000000.0
        ]
        #expect(SmokingEntryTransfer.from(dictionary: dict) == nil)
    }

    @Test("Init from SmokingEntry preserves fields")
    func initFromEntry() {
        let entry = SmokingEntry(timestamp: Date(timeIntervalSince1970: 1700000000))
        let transfer = SmokingEntryTransfer(from: entry)

        #expect(transfer.id == entry.id)
        #expect(transfer.timestamp == entry.timestamp)
    }
}

// MARK: - Date+Helpers Tests

@Suite("Date+Helpers")
struct DateHelpersTests {
    @Test("startOfDay returns midnight")
    func startOfDay() {
        let date = Date(timeIntervalSince1970: 1700050000) // some mid-day time
        let start = date.startOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)

        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("dayString returns yyyy-MM-dd format")
    func dayString() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = Calendar.current.timeZone
        let date = formatter.date(from: "2025-03-15 14:30:00")!

        #expect(date.dayString == "2025-03-15")
    }

    @Test("daysAgo(0) returns same day")
    func daysAgoZero() {
        let now = Date.now
        let result = now.daysAgo(0)

        #expect(result.dayString == now.dayString)
    }

    @Test("daysAgo(1) is approximately 24 hours back")
    func daysAgoOne() {
        let now = Date.now
        let yesterday = now.daysAgo(1)
        let interval = now.timeIntervalSince(yesterday)

        // Should be ~86400 seconds (24 hours), allow 2 hours for DST
        #expect(interval > 79200) // 22 hours
        #expect(interval < 93600) // 26 hours
    }
}

// MARK: - Date.formattedInterval Tests

@Suite("Date.formattedInterval")
struct FormattedIntervalTests {
    @Test("Zero seconds")
    func zeroSeconds() {
        let result = Date.formattedInterval(0, language: .en)
        #expect(result == "0s")
    }

    @Test("90 seconds formats as minutes and seconds")
    func ninetySeconds() {
        let result = Date.formattedInterval(90, language: .en)
        #expect(result == "1m 30s")
    }

    @Test("3661 seconds includes hours")
    func hoursMinutesSeconds() {
        let result = Date.formattedInterval(3661, language: .en)
        #expect(result.contains("1"))  // 1 hour
        #expect(result.contains("1"))  // 1 minute or 1 second
    }

    @Test("Negative interval returns 0s")
    func negativeInterval() {
        let result = Date.formattedInterval(-10, language: .en)
        #expect(result == "0s")
    }

    @Test("NaN interval returns 0s")
    func nanInterval() {
        let result = Date.formattedInterval(Double.nan, language: .en)
        #expect(result == "0s")
    }
}

// MARK: - DailyStats Tests

@Suite("DailyStats")
struct DailyStatsTests {
    @Test("Count equals entries count")
    func countMatchesEntries() {
        let entries: [Date] = [
            Date(timeIntervalSince1970: 1700000000),
            Date(timeIntervalSince1970: 1700003600),
            Date(timeIntervalSince1970: 1700007200)
        ]
        let stats = DailyStats(date: .now, entries: entries)

        #expect(stats.count == 3)
    }

    @Test("Single entry has zero average interval")
    func singleEntry() {
        let entries = [Date(timeIntervalSince1970: 1700000000)]
        let stats = DailyStats(date: .now, entries: entries)

        #expect(stats.count == 1)
        #expect(stats.averageInterval == 0)
    }

    @Test("Two entries compute correct average interval")
    func twoEntries() {
        let first = Date(timeIntervalSince1970: 1700000000)
        let second = Date(timeIntervalSince1970: 1700003600) // +1 hour
        let stats = DailyStats(date: .now, entries: [first, second])

        #expect(stats.count == 2)
        #expect(stats.averageInterval == 3600)
    }

    @Test("Three entries compute correct average interval")
    func threeEntries() {
        let entries: [Date] = [
            Date(timeIntervalSince1970: 1700000000),
            Date(timeIntervalSince1970: 1700001800), // +30 min
            Date(timeIntervalSince1970: 1700005400)  // +60 min
        ]
        let stats = DailyStats(date: .now, entries: entries)

        #expect(stats.count == 3)
        // Two intervals: 1800s and 3600s → average = 2700s
        #expect(stats.averageInterval == 2700)
    }

    @Test("Empty entries produce zero count")
    func emptyEntries() {
        let stats = DailyStats(date: .now, entries: [])

        #expect(stats.count == 0)
        #expect(stats.averageInterval == 0)
    }

    @Test("First and last entry are correct")
    func firstAndLast() {
        let first = Date(timeIntervalSince1970: 1700000000)
        let middle = Date(timeIntervalSince1970: 1700003600)
        let last = Date(timeIntervalSince1970: 1700007200)
        let stats = DailyStats(date: .now, entries: [middle, first, last]) // unsorted input

        #expect(stats.firstEntry == first)
        #expect(stats.lastEntry == last)
    }

    @Test("Static empty has zero count")
    func staticEmpty() {
        let stats = DailyStats.empty
        #expect(stats.count == 0)
        #expect(stats.averageInterval == 0)
    }
}
