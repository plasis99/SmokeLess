import SwiftUI

public extension Color {
    static let theme = ThemeColors()
}

public struct ThemeColors: Sendable {
    public let cyan = Color(red: 78/255, green: 205/255, blue: 196/255)       // #4ECDC4
    public let cyanGlow = Color(red: 78/255, green: 205/255, blue: 196/255).opacity(0.3)
    public let amber = Color(red: 244/255, green: 162/255, blue: 97/255)      // #F4A261
    public let redSoft = Color(red: 231/255, green: 111/255, blue: 111/255)   // #E76F6F

    public let bgTop = Color(red: 13/255, green: 19/255, blue: 33/255)       // #0d1321
    public let bgMid = Color(red: 17/255, green: 27/255, blue: 46/255)       // #111b2e
    public let bgBottom = Color(red: 14/255, green: 26/255, blue: 47/255)    // #0e1a2f

    public let glass = Color.white.opacity(0.08)
    public let glassBorder = Color.white.opacity(0.12)

    public let textPrimary = Color.white.opacity(0.95)
    public let textSecondary = Color.white.opacity(0.50)
    public let textTertiary = Color.white.opacity(0.30)
}

public extension ShapeStyle where Self == LinearGradient {
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.theme.bgTop, Color.theme.bgMid, Color.theme.bgBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
