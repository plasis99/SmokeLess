#if os(iOS)
import StoreKit
#endif
import SwiftUI
import SwiftData

public struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if os(iOS)
    @Environment(\.requestReview) private var requestReview
    #endif
    @State private var viewModel = MainViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var appeared = false
    @State private var showSettings = false
    @State private var showAchievements = false
    @State private var showStats = false

    public init() {}

    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            // Ambient blobs (hidden if reduce motion)
            if !reduceMotion {
                ambientBlobs
            }

            // Content
            VStack(spacing: 12) {
                    // Title + Settings
                    HStack {
                        Button {
                            showAchievements = true
                        } label: {
                            Image(systemName: "trophy")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.theme.textTertiary)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                        Text(settings.localized(.appTitle))
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(Color.theme.textTertiary)
                        Spacer()

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .fadeInUp(appeared: appeared, delay: 0.2)

                    // Timer Ring
                    TimerRingView(
                        timeSinceLast: viewModel.timeSinceLast,
                        progress: viewModel.timerProgress
                    )
                    .fadeInUp(appeared: appeared, delay: 0.4)

                    // Stats Row
                    StatsRowView(
                        todayCount: viewModel.todayCount,
                        yesterdayCount: viewModel.yesterdayCount,
                        averageInterval: viewModel.averageInterval
                    )
                    .fadeInUp(appeared: appeared, delay: 0.55)

                    // Goal Card
                    GoalCardView(
                        todayCount: viewModel.todayCount,
                        yesterdayCount: viewModel.yesterdayCount
                    )
                    .fadeInUp(appeared: appeared, delay: 0.7)

                    // Money Saved
                    MoneySavedCardView(cigarettesAvoided: viewModel.totalCigarettesAvoided)
                        .fadeInUp(appeared: appeared, delay: 0.8)

                    // Week Chart (tap for detailed stats)
                    Button {
                        showStats = true
                    } label: {
                        WeekChartView(
                            weekData: viewModel.weekData,
                            trendPercent: viewModel.weekTrendPercent
                        )
                    }
                    .buttonStyle(.plain)
                    .fadeInUp(appeared: appeared, delay: 0.9)

                    Spacer(minLength: 0)

                    // Smoke Button
                    SmokeButtonView {
                        viewModel.logCigarette(
                            language: settings.language,
                            dailyBaseline: settings.dailyBaseline,
                            notificationsEnabled: settings.notificationsEnabled
                        )
                        settings.incrementCigaretteCount()
                        #if os(iOS)
                        if settings.shouldRequestReview {
                            settings.lastReviewPromptDate = .now
                            requestReview()
                        }
                        #endif
                    }
                    .fadeInUp(appeared: appeared, delay: 1.05)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)

            // Undo toast
            if viewModel.showUndoToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.theme.cyan)
                            .font(.system(size: 16))
                        Text(settings.localized(.cigaretteLogged))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.theme.textPrimary)
                        Spacer()
                        Button {
                            viewModel.undoLastCigarette()
                        } label: {
                            Text(settings.localized(.undo))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.theme.cyan)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.theme.glassBorder, lineWidth: 1)
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .allowsHitTesting(true)
            }
        }
        .preferredColorScheme(.dark)
        #if os(iOS)
        .persistentSystemOverlays(.hidden)
        #endif
        .task {
            viewModel.setup(modelContext: modelContext, dailyBaseline: settings.dailyBaseline)
            setupWatchSync()
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
        .onDisappear {
            viewModel.stopTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Process any entries logged via Lock Screen fallback
                viewModel.processPendingLogs()
                viewModel.loadTodayStats()
                viewModel.loadWeekData()
                #if os(iOS)
                let count = viewModel.todayCount
                let date = viewModel.lastEntryDate
                Task { await LiveActivityManager.shared.startOrUpdate(todayCount: count, lastCigaretteDate: date) }
                #endif
                // Push entries logged via widget/Siri that Watch hasn't seen
                sendPendingEntriesToWatch()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(settings)
        }
        .sheet(isPresented: $showStats) {
            StatsDetailView(monthData: viewModel.monthData)
                .environment(settings)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView(
                currentStreak: viewModel.currentStreak,
                timeSinceFirstEntry: viewModel.timeSinceFirstEntry
            )
            .environment(settings)
        }
    }

    // MARK: - Watch Sync

    private func setupWatchSync() {
        WatchConnectivityService.shared.onEntriesReceived = { transfers in
            for transfer in transfers {
                let existingId = transfer.id
                let predicate = #Predicate<SmokingEntry> { entry in
                    entry.id == existingId
                }
                let descriptor = FetchDescriptor(predicate: predicate)
                let exists = (try? modelContext.fetch(descriptor))?.first != nil
                if !exists {
                    let entry = SmokingEntry(timestamp: transfer.timestamp)
                    entry.id = transfer.id
                    modelContext.insert(entry)
                }
            }
            try? modelContext.save()
            viewModel.loadTodayStats()
            viewModel.loadWeekData()
        }
        WatchConnectivityService.shared.onEntryDeleted = { id in
            let predicate = #Predicate<SmokingEntry> { entry in
                entry.id == id
            }
            let descriptor = FetchDescriptor(predicate: predicate)
            if let entry = try? modelContext.fetch(descriptor).first {
                modelContext.delete(entry)
                try? modelContext.save()
                viewModel.loadTodayStats()
                viewModel.loadWeekData()
            }
        }
        WatchConnectivityService.shared.onSyncRequested = {
            sendAllEntriesToWatch()
        }
    }

    /// Send last 30 days of entries to Watch for initial/full sync
    private func sendAllEntriesToWatch() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        let predicate = #Predicate<SmokingEntry> { entry in
            entry.timestamp >= thirtyDaysAgo
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        guard let entries = try? modelContext.fetch(descriptor), !entries.isEmpty else { return }
        let transfers = entries.map { SmokingEntryTransfer(from: $0) }
        WatchConnectivityService.shared.sendAllEntries(transfers)
    }

    /// Send entries logged via widget/Siri since last Watch sync
    private func sendPendingEntriesToWatch() {
        guard let lastSync = settings.lastWatchSyncTimestamp else {
            // Never synced — send all recent entries
            sendAllEntriesToWatch()
            settings.lastWatchSyncTimestamp = .now
            return
        }
        let predicate = #Predicate<SmokingEntry> { entry in
            entry.timestamp > lastSync
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        guard let entries = try? modelContext.fetch(descriptor), !entries.isEmpty else { return }
        let transfers = entries.map { SmokingEntryTransfer(from: $0) }
        WatchConnectivityService.shared.sendAllEntries(transfers)
        settings.lastWatchSyncTimestamp = .now
    }

    // MARK: - Ambient Blobs

    @State private var blobAnimate = false

    private var ambientBlobs: some View {
        ZStack {
            Circle()
                .fill(Color.theme.cyan.opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(
                    x: blobAnimate ? -30 : -60,
                    y: blobAnimate ? -100 : -150
                )

            Circle()
                .fill(Color.theme.cyan.opacity(0.03))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(
                    x: blobAnimate ? 80 : 50,
                    y: blobAnimate ? 200 : 250
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                blobAnimate = true
            }
        }
    }
}

// MARK: - Fade In Up Animation Modifier

struct FadeInUpModifier: ViewModifier {
    let appeared: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(delay), value: appeared)
    }
}

extension View {
    func fadeInUp(appeared: Bool, delay: Double) -> some View {
        modifier(FadeInUpModifier(appeared: appeared, delay: delay))
    }
}

#Preview {
    MainView()
        .environment(AppSettings())
        .modelContainer(for: SmokingEntry.self, inMemory: true)
}
