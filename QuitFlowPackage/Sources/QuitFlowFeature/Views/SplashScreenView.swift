import SwiftUI

struct SplashScreenView: View {
    @Environment(AppSettings.self) private var settings
    let onFinished: () -> Void

    @State private var showTitle = false
    @State private var showRing = false
    @State private var ringScale: CGFloat = 0.8

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            // Ambient blobs
            ZStack {
                Circle()
                    .fill(Color.theme.cyan.opacity(0.04))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -40, y: -120)

                Circle()
                    .fill(Color.theme.cyan.opacity(0.03))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: 60, y: 200)
            }

            VStack(spacing: 24) {
                // Pulsing cyan ring
                ZStack {
                    Circle()
                        .stroke(Color.theme.cyan.opacity(0.15), lineWidth: 2)
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(Color.theme.cyan.opacity(0.4), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)
                        .opacity(showRing ? 0.0 : 0.6)

                    Circle()
                        .fill(Color.theme.cyan.opacity(0.06))
                        .frame(width: 120, height: 120)
                }
                .opacity(showTitle ? 1 : 0)

                // Title
                Text("SMOKELESS")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(6)
                    .foregroundStyle(Color.theme.textPrimary)
                    .opacity(showTitle ? 1 : 0)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            withAnimation(.easeOut(duration: 0.8)) {
                showTitle = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                showRing = true
                ringScale = 1.5
            }
            try? await Task.sleep(for: .seconds(2))
            onFinished()
        }
    }
}
