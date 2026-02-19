import SwiftUI

/// Archimedean spiral of dots with growing size and opacity.
/// Used as the LOG button background on Apple Watch.
public struct SpiralDots: View {
    let color: Color
    let dotCount: Int
    let turns: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let minSize: CGFloat
    let maxSize: CGFloat

    public init(color: Color, dotCount: Int = 18, turns: Double = 2,
                innerRadius: CGFloat = 7.5, outerRadius: CGFloat = 41,
                minSize: CGFloat = 2.5, maxSize: CGFloat = 5) {
        self.color = color
        self.dotCount = dotCount
        self.turns = turns
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.minSize = minSize
        self.maxSize = maxSize
    }

    public var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let thetaEnd = turns * 2 * .pi

            for i in 0..<dotCount {
                let t = Double(i) / Double(dotCount - 1)
                let theta = t * thetaEnd
                let r = innerRadius + (outerRadius - innerRadius) * theta / thetaEnd
                let x = cx + r * cos(theta)
                let y = cy + r * sin(theta)
                let dotSize = minSize + (maxSize - minSize) * t
                let opacity = 0.4 + 0.6 * t

                let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2,
                                  width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: rect),
                             with: .color(color.opacity(opacity)))
            }
        }
    }
}
