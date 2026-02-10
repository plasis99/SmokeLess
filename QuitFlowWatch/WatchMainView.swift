import SwiftUI
import SwiftData
import QuitFlowFeature
import WatchKit

struct WatchMainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var todayCount: Int = 0
    @State private var timeSinceLast: TimeInterval = 0
    @State private var lastEntryDate: Date?
    @State private var timer: Timer?

    private let teal = Color(red: 0.306, green: 0.871, blue: 0.706)
    private let bgDark = Color(red: 0.04, green: 0.055, blue: 0.09)

    var body: some View {
        VStack(spacing: 8) {
            // Time since last
            Text(formattedTime)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(teal)
                .monospacedDigit()

            Text("since last")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            Spacer().frame(height: 4)

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

            Spacer().frame(height: 4)

            // LOG button
            Button {
                logCigarette()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("LOG")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(teal, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .background(bgDark)
        .task {
            loadTodayStats()
            startTimer()
            setupSyncCallbacks()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

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

        // Haptic on Watch
        WKInterfaceDevice.current().play(.click)

        // Sync to iPhone
        WatchConnectivityService.shared.sendNewEntry(SmokingEntryTransfer(from: entry))
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

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let last = lastEntryDate {
                timeSinceLast = Date.now.timeIntervalSince(last)
            }
        }
    }

    // MARK: - Sync

    private func setupSyncCallbacks() {
        WatchConnectivityService.shared.onEntriesReceived = { transfers in
            mergeEntries(transfers)
        }
        WatchConnectivityService.shared.onEntryDeleted = { id in
            deleteEntry(id: id)
        }
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
