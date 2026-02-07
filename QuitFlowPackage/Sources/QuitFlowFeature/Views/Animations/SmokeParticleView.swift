import SwiftUI

struct SmokeParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
}

public struct SmokeParticleView: View {
    let isBurst: Bool

    @State private var particles: [SmokeParticle] = []
    @State private var timer: Timer?

    public init(isBurst: Bool = false) {
        self.isBurst = isBurst
    }

    public var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.white.opacity(particle.opacity))
                    .frame(width: 8 * particle.scale, height: 8 * particle.scale)
                    .blur(radius: 3 * particle.scale)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .frame(width: 50, height: 60)
        .onAppear { startEmitting() }
        .onDisappear { timer?.invalidate() }
        .onChange(of: isBurst) {
            if isBurst { burstEmit() }
        }
    }

    private func startEmitting() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            Task { @MainActor in
                emitParticle()
            }
        }
    }

    private func emitParticle() {
        let particle = SmokeParticle(
            x: 25 + CGFloat.random(in: -8...8),
            y: 55,
            scale: CGFloat.random(in: 0.5...1.0),
            opacity: 0.15
        )
        particles.append(particle)

        withAnimation(.easeOut(duration: 3)) {
            if let idx = particles.firstIndex(where: { $0.id == particle.id }) {
                particles[idx].y -= CGFloat.random(in: 40...70)
                particles[idx].x += CGFloat.random(in: -15...15)
                particles[idx].scale += 1.5
                particles[idx].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            particles.removeAll { $0.id == particle.id }
        }
    }

    private func burstEmit() {
        for _ in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.3)) {
                emitParticle()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SmokeParticleView(isBurst: false)
    }
}
