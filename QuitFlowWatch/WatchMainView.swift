import SwiftUI
import SwiftData
import WidgetKit
import QuitFlowFeature
import WatchKit

struct WatchMainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var todayCount: Int = 0
    @State private var timeSinceLast: TimeInterval = 0
    @State private var lastEntryDate: Date?
    @State private var smokeProgress: CGFloat = 0
    @State private var lastSyncTimestamp: Date? = UserDefaults.standard.object(forKey: "lastWatchSyncTimestamp") as? Date
    @State private var lastLoggedEntry: SmokingEntry?
    @State private var showUndo = false
    @State private var undoTask: Task<Void, Never>?

    private let bronzeText = Color(red: 0.863, green: 0.686, blue: 0.216)
    private let bronze = Color(red: 0.769, green: 0.604, blue: 0.235)

    var body: some View {
        VStack(spacing: 4) {
            // Time since last
            Text(formattedTime)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(bronzeText)
                .monospacedDigit()

            Text("since last")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            // Big circular LOG button
            Button {
                logCigarette()
            } label: {
                ZStack {
                    Circle()
                        .fill(bronze.opacity(0.1))
                        .frame(width: 105, height: 105)

                    Circle()
                        .fill(Color(white: 0.03))
                        .frame(width: 95, height: 95)

                    // Bronze spiral dots
                    SpiralDots(color: bronze, dotCount: 18, turns: 2,
                               innerRadius: 7.5, outerRadius: 41, minSize: 2.5, maxSize: 5)
                        .frame(width: 95, height: 95)

                    CigaretteIcon(height: 14)

                    // Smoke wisps from cigarette tip
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: smokeDotSize(i), height: smokeDotSize(i))
                            .blur(radius: 1)
                            .offset(x: -25 + smokeXOff(i),
                                    y: -3 - smokeProgress * smokeYRange(i))
                            .opacity(0.25 * Double(1 - smokeProgress))
                    }
                }
            }
            .buttonStyle(.plain)

            // Today count
            HStack(spacing: 4) {
                Text("TODAY")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.4))
                Text("\(todayCount)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Undo button (visible for 5 seconds after log)
            if showUndo {
                Button {
                    undoLastEntry()
                } label: {
                    Text("Undo")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(bronzeText)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 8)
        .background(Color.black)
        .task {
            loadTodayStats()
            setupSyncCallbacks()
            await runTimer()
        }
    }

    // MARK: - Smoke Helpers

    private func smokeDotSize(_ i: Int) -> CGFloat { [3, 4, 3][i] }
    private func smokeXOff(_ i: Int) -> CGFloat { [(-3) as CGFloat, 1, 5][i] }
    private func smokeYRange(_ i: Int) -> CGFloat { [22, 34, 26][i] }

    // MARK: - Formatted Time

    private var formattedTime: String {
        guard lastEntryDate != nil else { return "—" }
        let total = Int(timeSinceLast)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            let seconds = total % 60
            return "\(minutes)m \(seconds)s"
        }
    }

    // MARK: - Actions

    private func logCigarette() {
        let entry = SmokingEntry(timestamp: .now)
        modelContext.insert(entry)
        try? modelContext.save()
        lastEntryDate = entry.timestamp
        timeSinceLast = 0
        loadTodayStats()

        // Smoke animation
        smokeProgress = 0
        withAnimation(.easeOut(duration: 1.2)) {
            smokeProgress = 1
        }

        // Haptic on Watch
        WKInterfaceDevice.current().play(.click)

        // Sync to iPhone
        WatchConnectivityService.shared.sendNewEntry(SmokingEntryTransfer(from: entry))

        // Update Watch complication
        WidgetCenter.shared.reloadAllTimelines()

        // Undo support — show button for 5 seconds
        lastLoggedEntry = entry
        undoTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            showUndo = true
        }
        undoTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                showUndo = false
            }
            lastLoggedEntry = nil
        }
    }

    private func undoLastEntry() {
        guard let entry = lastLoggedEntry else { return }
        let entryId = entry.id
        undoTask?.cancel()
        modelContext.delete(entry)
        try? modelContext.save()
        lastLoggedEntry = nil
        withAnimation(.easeInOut(duration: 0.3)) {
            showUndo = false
        }
        loadTodayStats()

        // Sync delete to iPhone
        WatchConnectivityService.shared.sendDeleteEntry(entryId)

        // Update Watch complication
        WidgetCenter.shared.reloadAllTimelines()

        // Success haptic
        WKInterfaceDevice.current().play(.success)
    }

    // MARK: - Data Loading

    private func loadTodayStats() {
        let todayStart = Calendar.current.startOfDay(for: .now)
        let tomorrowStart = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!

        let predicate = #Predicate<SmokingEntry> { entry in
            entry.timestamp >= todayStart && entry.timestamp < tomorrowStart
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])

        do {
            let entries = try modelContext.fetch(descriptor)
            todayCount = entries.count
            lastEntryDate = entries.last?.timestamp
            if let last = lastEntryDate {
                timeSinceLast = Date.now.timeIntervalSince(last)
            }
        } catch {
            todayCount = 0
        }
    }

    // MARK: - Timer

    private func runTimer() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            if let last = lastEntryDate {
                timeSinceLast = Date.now.timeIntervalSince(last)
            }
        }
    }

    // MARK: - Sync

    private func setupSyncCallbacks() {
        let service = WatchConnectivityService.shared
        service.onEntriesReceived = { transfers in
            mergeEntries(transfers)
        }
        service.onEntryDeleted = { id in
            deleteEntry(id: id)
        }
        service.onReachabilityRestored = {
            requestSyncIfNeeded()
        }

        // Request initial sync if never synced or stale (>15 min)
        requestSyncIfNeeded()
    }

    private func requestSyncIfNeeded() {
        let isStale = lastSyncTimestamp.map { Date.now.timeIntervalSince($0) > 900 } ?? true
        guard isStale, WatchConnectivityService.shared.isReachable else { return }
        WatchConnectivityService.shared.requestSync()
    }

    private func mergeEntries(_ transfers: [SmokingEntryTransfer]) {
        for transfer in transfers {
            // Check if entry already exists by UUID
            let existingId = transfer.id
            let predicate = #Predicate<SmokingEntry> { entry in
                entry.id == existingId
            }
            let descriptor = FetchDescriptor(predicate: predicate)
            let existing = (try? modelContext.fetch(descriptor))?.first

            if existing == nil {
                let entry = SmokingEntry(timestamp: transfer.timestamp)
                // Set the same UUID for dedup
                entry.id = transfer.id
                modelContext.insert(entry)
            }
        }
        try? modelContext.save()
        loadTodayStats()

        // Update Watch complication
        WidgetCenter.shared.reloadAllTimelines()

        // Update sync timestamp
        lastSyncTimestamp = .now
        UserDefaults.standard.set(Date.now, forKey: "lastWatchSyncTimestamp")
    }

    private func deleteEntry(id: UUID) {
        let predicate = #Predicate<SmokingEntry> { entry in
            entry.id == id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        if let entry = try? modelContext.fetch(descriptor).first {
            modelContext.delete(entry)
            try? modelContext.save()
            loadTodayStats()
        }
    }
}
