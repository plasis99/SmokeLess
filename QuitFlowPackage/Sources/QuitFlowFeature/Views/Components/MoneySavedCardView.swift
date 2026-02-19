import SwiftUI

public struct MoneySavedCardView: View {
    @Environment(AppSettings.self) private var settings
    let cigarettesAvoided: Int

    public init(cigarettesAvoided: Int) {
        self.cigarettesAvoided = cigarettesAvoided
    }

    private var moneySaved: Double {
        Double(cigarettesAvoided) * settings.pricePerCigarette
    }

    private var hasPriceSet: Bool {
        settings.cigarettePrice > 0
    }

    public var body: some View {
        if hasPriceSet && cigarettesAvoided > 0 {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.theme.cyan.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "banknote")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.theme.cyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.localized(.settingsMoneySaved))
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(Color.theme.textTertiary)
                        .textCase(.uppercase)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formattedMoney)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.theme.cyan)

                        Text("(\(cigarettesAvoided) \(cigaretteSymbol))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.theme.textTertiary)
                    }
                }

                Spacer()
            }
            .padding(14)
            .glassCard()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(settings.localized(.settingsMoneySaved)): \(formattedMoney)")
        }
    }

    private var formattedMoney: String {
        String(format: "%.0f", moneySaved)
    }

    private var cigaretteSymbol: String {
        "🚬"
    }
}

#Preview {
    ZStack {
        LinearGradient.backgroundGradient.ignoresSafeArea()
        VStack(spacing: 16) {
            MoneySavedCardView(cigarettesAvoided: 45)
            MoneySavedCardView(cigarettesAvoided: 0)
        }
        .padding()
        .environment(AppSettings())
    }
}
