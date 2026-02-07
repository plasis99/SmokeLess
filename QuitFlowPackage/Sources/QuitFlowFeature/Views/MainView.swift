import SwiftUI
import SwiftData

public struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @State private var viewModel = MainViewModel()
    @State private var appeared = false

    public init() {}

    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            // Ambient blobs
            ambientBlobs

            // Content
            VStack(spacing: 12) {
                    // Title
                    Text(settings.localized(.appTitle))
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Color.theme.textTertiary)
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

                    // Week Chart
                    WeekChartView(
                        weekData: viewModel.weekData,
                        trendPercent: viewModel.weekTrendPercent
                    )
                    .fadeInUp(appeared: appeared, delay: 0.4)

                    Spacer(minLength: 0)

                    // Smoke Button
                    SmokeButtonView {
                        viewModel.logCigarette()
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
