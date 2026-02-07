import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
public final class MainViewModel {
    // MARK: - Published State
    public var todayCount: Int = 0
    public var yesterdayCount: Int = 0
    public var timeSinceLast: TimeInterval = 0
    public var averageInterval: TimeInterval = 0
    public var weekData: [DailyStats] = []
    public var weekTrendPercent: Int = 0

    public var goalTarget: Int {
        yesterdayCount
    }

    public var timerProgress: Double {
        guard averageInterval > 0 else { return 0 }
        return min(timeSinceLast / averageInterval, 1.0)
    }

    // MARK: - Private
    private var timer: Timer?
    private var lastEntryDate: Date?
    private var modelContext: ModelContext?

    public init() {}

    // MARK: - Setup

    public func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTodayStats()
        loadWeekData()
        startTimer()
    }

    // MARK: - Actions

    public func logCigarette() {
        guard let modelContext else { return }
        let entry = SmokingEntry(timestamp: .now)
        modelContext.insert(entry)
        try? modelContext.save()
        lastEntryDate = entry.timestamp
        timeSinceLast = 0
        loadTodayStats()
        loadWeekData()
        HapticService.impact(.medium)
    }

    // MARK: - Timer

    public func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimeSinceLast()
            }
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimeSinceLast() {
        if let lastEntryDate {
            timeSinceLast = Date.now.timeIntervalSince(lastEntryDate)
        }
    }

    // MARK: - Data Loading

    public func loadTodayStats() {
        guard let modelContext else { return }
        let todayStart = Date.now.startOfDay
        let tomorrowStart = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!

        let todayPredicate = #Predicate<SmokingEntry> { entry in
            entry.timestamp >= todayStart && entry.timestamp < tomorrowStart
        }
        let descriptor = FetchDescriptor(predicate: todayPredicate, sortBy: [SortDescriptor(\.timestamp)])

        do {
            let todayEntries = try modelContext.fetch(descriptor)
            todayCount = todayEntries.count
            lastEntryDate = todayEntries.last?.timestamp

            if let last = lastEntryDate {
                timeSinceLast = Date.now.timeIntervalSince(last)
            }

            let timestamps = todayEntries.map(\.timestamp)
            let todayStats = DailyStats(date: todayStart, entries: timestamps)
            averageInterval = todayStats.averageInterval
        } catch {
            todayCount = 0
        }

        loadYesterdayStats()
    }

    private func loadYesterdayStats() {
        guard let modelContext else { return }
        let yesterdayStart = Date.now.daysAgo(1).startOfDay
        let todayStart = Date.now.startOfDay

        let predicate = #Predicate<SmokingEntry> { entry in
            entry.timestamp >= yesterdayStart && entry.timestamp < todayStart
        }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let entries = try modelContext.fetch(descriptor)
            yesterdayCount = entries.count
        } catch {
            yesterdayCount = 0
        }
    }

    public func loadWeekData() {
        guard let modelContext else { return }
        let weekStart = Date.now.daysAgo(6).startOfDay

        let predicate = #Predicate<SmokingEntry> { entry in
            entry.timestamp >= weekStart
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])

        do {
            let entries = try modelContext.fetch(descriptor)
            var dailyMap: [String: [Date]] = [:]

            for i in 0..<7 {
                let day = Date.now.daysAgo(6 - i)
                dailyMap[day.dayString] = []
            }

            for entry in entries {
                let key = entry.timestamp.dayString
                dailyMap[key, default: []].append(entry.timestamp)
            }

            weekData = (0..<7).map { i in
                let day = Date.now.daysAgo(6 - i).startOfDay
                let timestamps = dailyMap[day.dayString] ?? []
                return DailyStats(date: day, entries: timestamps)
            }

            calculateWeekTrend()
        } catch {
            weekData = []
        }
    }

    private func calculateWeekTrend() {
        guard let modelContext else { return }
        let prevWeekStart = Date.now.daysAgo(13).startOfDay
        let thisWeekStart = Date.now.daysAgo(6).startOfDay

        let predicate = #Predicate<SmokingEntry> { entry in
            entry.timestamp >= prevWeekStart && entry.timestamp < thisWeekStart
        }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let prevEntries = try modelContext.fetch(descriptor)
            let prevTotal = prevEntries.count
            let thisTotal = weekData.reduce(0) { $0 + $1.count }

            if prevTotal > 0 {
                weekTrendPercent = Int(((Double(thisTotal) - Double(prevTotal)) / Double(prevTotal)) * 100)
            } else {
                weekTrendPercent = 0
            }
        } catch {
            weekTrendPercent = 0
        }
    }
}
