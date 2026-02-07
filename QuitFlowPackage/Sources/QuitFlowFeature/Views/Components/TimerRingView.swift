import SwiftUI

public struct TimerRingView: View {
    let timeSinceLast: TimeInterval
    let progress: Double

    @State private var pulsate = false

    public init(timeSinceLast: TimeInterval, progress: Double) {
        self.timeSinceLast = timeSinceLast
        self.progress = progress
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

            // Track ring
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 6)
                .padding(16)

            // Progress arc glow (behind)
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

            // Progress arc
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

            // Center text
            VStack(spacing: 4) {
                Text(Date.formattedInterval(timeSinceLast))
                    .font(.system(size: 38, weight: .light))
                    .tracking(2)
                    .foregroundStyle(Color.theme.textPrimary)

                Text("с последней сигареты")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.theme.textTertiary)
            }
        }
        .frame(width: 200, height: 200)
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
    }
}
