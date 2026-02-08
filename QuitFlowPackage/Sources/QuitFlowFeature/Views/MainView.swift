import SwiftUI
import SwiftData

public struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = MainViewModel()
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
                    .fadeInUp(appeared: appeared, delay: 0)

                    // Timer Ring
                    TimerRingView(
                        timeSinceLast: viewModel.timeSinceLast,
                        progress: viewModel.timerProgress
                    )
                    .fadeInUp(appeared: appeared, delay: 0.1)

                    // Stats Row
                    StatsRowView(
                        todayCount: viewModel.todayCount,
                        yesterdayCount: viewModel.yesterdayCount,
                        averageInterval: viewModel.averageInterval
                    )
                    .fadeInUp(appeared: appeared, delay: 0.2)

                    // Goal Card
                    GoalCardView(
                        todayCount: viewModel.todayCount,
                        yesterdayCount: viewModel.yesterdayCount
                    )
                    .fadeInUp(appeared: appeared, delay: 0.3)

                    // Money Saved
                    MoneySavedCardView(cigarettesAvoided: viewModel.totalCigarettesAvoided)
                        .fadeInUp(appeared: appeared, delay: 0.35)

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
                    .fadeInUp(appeared: appeared, delay: 0.4)

                    Spacer(minLength: 0)

                    // Smoke Button
                    SmokeButtonView {
                        viewModel.logCigarette(language: settings.language)
                    }
                    .fadeInUp(appeared: appeared, delay: 0.5)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
        .task {
            viewModel.setup(modelContext: modelContext)
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
        .onDisappear {
            viewModel.stopTimer()
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
            .animation(.easeOut(duration: 0.5).delay(delay), value: appeared)
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
