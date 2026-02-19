import SwiftUI

/// 3D cigarette icon with cylindrical shading, glowing tip, and depth.
/// Reused on onboarding, Watch LOG button, and widget.
public struct CigaretteIcon: View {
    let height: CGFloat

    public init(height: CGFloat = 10) {
        self.height = height
    }

    public var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Burning tip — glowing orange/red
                RoundedRectangle(cornerRadius: height * 0.25)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.55, blue: 0.0),   // bright orange
                                Color(red: 0.9, green: 0.25, blue: 0.1),   // deep red
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        // Hot glow highlight on top
                        RoundedRectangle(cornerRadius: height * 0.25)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.yellow.opacity(0.6),
                                        Color.clear,
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .padding(.bottom, height * 0.4)
                    }
                    .frame(width: height * 0.8, height: height)
                    .shadow(color: .orange.opacity(0.7), radius: height * 0.4, x: 0, y: 0)

                // White body — cylindrical 3D shading (light top, shadow bottom)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.98),  // highlight
                                Color(white: 0.92),  // mid
                                Color(white: 0.78),  // shadow
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: height * 3, height: height)

                // Filter — 3D beige with paper texture feel
                RoundedRectangle(cornerRadius: height * 0.25)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.82, green: 0.65, blue: 0.44), // highlight
                                Color(red: 0.68, green: 0.48, blue: 0.28), // shadow
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        // Subtle horizontal lines (cork texture)
                        VStack(spacing: height * 0.18) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.06))
                                    .frame(height: 0.5)
                            }
                        }
                        .padding(.horizontal, height * 0.1)
                    }
                    .frame(width: height * 1.4, height: height)
            }
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: height * 0.2, x: 0, y: height * 0.15)
        }
    }
}
