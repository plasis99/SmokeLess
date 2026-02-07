import SwiftUI

// MARK: - Cigarette Shape

struct CigaretteShape: View {
    @State private var glowPulsate = false

    var body: some View {
        ZStack {
            // Glow from burning tip
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 24, height: 24)
                .offset(x: -22)
                .opacity(glowPulsate ? 0.8 : 0.5)

            HStack(spacing: 0) {
                // Burning tip (left)
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 6, height: 8)

                // Ash
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 4, height: 8)

                // White body
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 22, height: 8)

                // Gold ring
                Rectangle()
                    .fill(Color(red: 0.85, green: 0.7, blue: 0.3))
                    .frame(width: 3, height: 8)

                // Filter (brown)
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.76, green: 0.56, blue: 0.34), Color(red: 0.65, green: 0.45, blue: 0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 12, height: 8)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulsate = true
            }
        }
    }
}

// MARK: - Smoke Button

public struct SmokeButtonView: View {
    @Environment(AppSettings.self) private var settings
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var smokeBurst = false

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    public var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Smoke particles above button
                SmokeParticleView(isBurst: smokeBurst)
                    .offset(x: -10, y: -40)

                // Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        isPressed = true
                    }
                    smokeBurst = true
                    onTap()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            isPressed = false
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        smokeBurst = false
                    }
                } label: {
                    ZStack {
                        // Glass background
                        Circle()
                            .fill(.ultraThinMaterial.opacity(0.1))
                            .overlay {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.06), Color.clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            }
                            .overlay {
                                Circle()
                                    .stroke(Color.theme.glassBorder, lineWidth: 1)
                            }

                        CigaretteShape()
                    }
                    .frame(width: 76, height: 76)
                }
                .buttonStyle(.plain)
                .scaleEffect(isPressed ? 0.94 : 1.0)
            }

            Text(settings.localized(.tapWhenSmoke))
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(Color.theme.textTertiary)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.backgroundGradient.ignoresSafeArea()
        SmokeButtonView { }
            .environment(AppSettings())
    }
}
