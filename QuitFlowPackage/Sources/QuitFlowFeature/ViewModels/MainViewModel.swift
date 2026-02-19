#if os(iOS)
import ActivityKit
#endif
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
    public var totalCigarettesAvoided: Int = 0
    public var currentStreak: Int = 0
    public var timeSinceFirstEntry: TimeInterval = 0
    public var monthData: [DailyStats] = []

    public var goalTarget: Int {
        yesterdayCount
    }

    public var timerProgress: Double {
        guard averageInterval > 0 else { return 0 }
        return min(timeSinceLast / averageInterval, 1.0)
    }

    // MARK: - Undo
    public var lastLoggedEntry: SmokingEntry?
    public var showUndoToast = false
    private var undoTask: Task<Void, Never>?

    // MARK: - Private
    private var timer: Timer?
    private(set) var lastEntryDate: Date?
    private var modelContext: ModelContext?
    private var dailyBaseline: Int = 0

    public init() {}

    // MARK: - Setup

    public func setup(modelContext: ModelContext, dailyBaseline: Int) {
        self.modelContext = modelContext
        self.dailyBaseline = dailyBaseline
        loadTodayStats()
        loadWeekData()
        loadMoneySavedData()
        loadStreakData()
        loadMonthData()
        startTimer()

        // Start Live Activity if there's data today
        #if os(iOS)
        if todayCount > 0 {
            LiveActivityManager.shared.startOrUpdate(todayCount: todayCount, lastCigaretteDate: lastEntryDate)
        }
        #endif
    }

    // MARK: - Actions

    public func logCigarette(language: AppLanguage = .en, dailyBaseline: Int? = nil, notificationsEnabled: Bool = true) {
        guard let modelContext else { return }
        if let dailyBaseline { self.dailyBaseline = dailyBaseline }
        let entry = SmokingEntry(timestamp: .now)
        modelContext.insert(entry)
        try? modelContext.save()
        lastEntryDate = entry.timestamp
        timeSinceLast = 0
        loadTodayStats()
        loadWeekData()
        loadMoneySavedData()
        loadStreakData()
        #if os(iOS)
        HapticService.impact(.medium)
        #endif

        if notificationsEnabled && averageInterval > 0 {
            NotificationService.scheduleSmartReminder(averageInterval: averageInterval, language: language)
        }

        // Update Live Activity
        #if os(iOS)
        LiveActivityManager.shared.startOrUpdate(todayCount: todayCount, lastCigaretteDate: entry.timestamp)
        #endif

        // Sync to Watch / iPhone
        WatchConnectivityService.shared.sendNewEntry(SmokingEntryTransfer(from: entry))

        // Undo support
        lastLoggedEntry = entry
        withAnimation(.easeInOut(duration: 0.3)) {
            showUndoToast = true
        }
        undoTask?.cancel()
        undoTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self?.showUndoToast = false
            }
            // Clear undo availability after 30 seconds
            try? await Task.sleep(for: .seconds(25))
            guard !Task.isCancelled else { return }
            self?.lastLoggedEntry = nil
        }
    }

    public func undoLastCigarette() {
        guard let modelContext, let entry = lastLoggedEntry else { return }
        let entryId = entry.id
        undoTask?.cancel()
        modelContext.delete(entry)
        try? modelContext.save()
        lastLoggedEntry = nil

        // Sync delete to Watch / iPhone
        WatchConnectivityService.shared.sendDeleteEntry(entryId)
        withAnimation(.easeInOut(duration: 0.3)) {
            showUndoToast = false
        }
        loadTodayStats()
        loadWeekData()
        loadMoneySavedData()
        loadStreakData()
        #if os(iOS)
        HapticService.impact(.light)
        #endif

        // Update Live Activity
        #if os(iOS)
        if todayCount > 0 {
            LiveActivityManager.shared.startOrUpdate(todayCount: todayCount, lastCigaretteDate: lastEntryDate)
        } else {
            LiveActivityManager.shared.endActivity()
        }
        #endif
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

    /// Load 30-day data for detailed statistics
    public func loadMonthData() {
        guard let modelContext else { return }
        let monthStart = Date.now.daysAgo(29).startOfDay

        let predicate = #Predicate<SmokingEntry> { entry in
            entry.timestamp >= monthStart
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])

        do {
            let entries = try modelContext.fetch(descriptor)
            var dailyMap: [String: [Date]] = [:]

            for i in 0..<30 {
                let day = Date.now.daysAgo(29 - i)
                dailyMap[day.dayString] = []
            }

            for entry in entries {
                let key = entry.timestamp.dayString
                dailyMap[key, default: []].append(entry.timestamp)
            }

            monthData = (0..<30).map { i in
                let day = Date.now.daysAgo(29 - i).startOfDay
                let timestamps = dailyMap[day.dayString] ?? []
                return DailyStats(date: day, entries: timestamps)
            }
        } catch {
            monthData = []
        }
    }

    /// Calculate streak: consecutive days (from today backward) where each day
    /// has fewer or equal cigarettes compared to the previous (older) day.
    /// This means the user is reducing their smoking over the streak period.
    public func loadStreakData() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<SmokingEntry>(sortBy: [SortDescriptor(\.timestamp)])

        do {
            let allEntries = try modelContext.fetch(descriptor)
            guard !allEntries.isEmpty else {
                currentStreak = 0
                timeSinceFirstEntry = 0
                return
            }

            timeSinceFirstEntry = Date.now.timeIntervalSince(allEntries.first!.timestamp)

            // Group by day
            var dailyCounts: [String: Int] = [:]
            for entry in allEntries {
                dailyCounts[entry.timestamp.dayString, default: 0] += 1
            }

            // Sort days newest first (today, yesterday, day before, ...)
            let sortedDays = dailyCounts.keys.sorted().reversed().map { $0 }
            var streak = 0

            // Compare pairs: today vs yesterday, yesterday vs day_before, etc.
            // Streak increments if the newer day <= the older day (reducing trend)
            for i in 0..<(sortedDays.count - 1) {
                let newerDayCount = dailyCounts[sortedDays[i]] ?? 0
                let olderDayCount = dailyCounts[sortedDays[i + 1]] ?? 0
                if newerDayCount <= olderDayCount {
                    streak += 1
                } else {
                    break
                }
            }
            currentStreak = streak
        } catch {
            currentStreak = 0
        }
    }

    /// Calculate total cigarettes avoided based on user's daily baseline from settings
    public func loadMoneySavedData() {
        guard let modelContext, dailyBaseline > 0 else {
            totalCigarettesAvoided = 0
            return
        }

        let descriptor = FetchDescriptor<SmokingEntry>(sortBy: [SortDescriptor(\.timestamp)])

        do {
            let allEntries = try modelContext.fetch(descriptor)
            guard !allEntries.isEmpty else {
                // No entries yet — full baseline is saved today
                totalCigarettesAvoided = dailyBaseline
                return
            }

            // Group by day
            var dailyCounts: [String: Int] = [:]
            for entry in allEntries {
                dailyCounts[entry.timestamp.dayString, default: 0] += 1
            }

            // For each day with data: avoided = max(0, baseline - actual)
            var avoided = 0
            for (_, count) in dailyCounts {
                if dailyBaseline > count {
                    avoided += dailyBaseline - count
                }
            }
            totalCigarettesAvoided = avoided
        } catch {
            totalCigarettesAvoided = 0
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
