import SwiftUI

public struct TimerRingView: View {
    @Environment(AppSettings.self) private var settings
    let timeSinceLast: TimeInterval
    let progress: Double

    @State private var pulsate = false

    public init(timeSinceLast: TimeInterval, progress: Double) {
        self.timeSinceLast = timeSinceLast
        self.progress = progress
    }

    /// Seconds progress: 0..1 over 60 seconds
    private var secondsProgress: Double {
        let seconds = Int(timeSinceLast) % 60
        return Double(seconds) / 60.0
    }

    public var body: some View {
        ZStack {
            // Glass background circle
            Circle()
                .fill(.ultraThinMaterial.opacity(0.06))
                .overlay {
                    Circle()
                        .stroke(Color.theme.glassBorder, lineWidth: 1)
                }

            // Outer track ring (main progress)
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 6)
                .padding(16)

            // Main progress arc glow (behind)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        colors: [Color.theme.cyan.opacity(0.3), Color.theme.cyan.opacity(0.6)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * min(progress, 1.0))
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .blur(radius: 8)
                .padding(16)
                .rotationEffect(.degrees(-90))

            // Main progress arc
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        colors: [Color.theme.cyan.opacity(0.5), Color.theme.cyan],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * min(progress, 1.0))
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .padding(16)
                .rotationEffect(.degrees(-90))
                .opacity(pulsate ? 1.0 : 0.7)

            // Inner seconds track
            Circle()
                .stroke(Color.white.opacity(0.03), lineWidth: 3)
                .padding(30)

            // Seconds arc (completes 1 revolution per 60s)
            Circle()
                .trim(from: 0, to: CGFloat(secondsProgress))
                .stroke(
                    Color.theme.cyan.opacity(0.5),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .padding(30)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: secondsProgress)

            // Center text
            VStack(spacing: 4) {
                Text(Date.formattedInterval(timeSinceLast, language: settings.language))
                    .font(.system(size: 26, weight: .light))
                    .tracking(1)
                    .foregroundStyle(Color.theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: timeSinceLast)

                Text(settings.localized(.sinceLastCigarette))
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.theme.textTertiary)
            }
        }
        .frame(width: 200, height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized(.accessTimeSince, args: Date.formattedInterval(timeSinceLast, language: settings.language)))
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulsate = true
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.backgroundGradient.ignoresSafeArea()
        TimerRingView(timeSinceLast: 10020, progress: 0.65)
            .environment(AppSettings())
    }
}
