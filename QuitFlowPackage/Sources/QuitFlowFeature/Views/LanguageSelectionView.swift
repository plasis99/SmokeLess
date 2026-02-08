import SwiftUI

struct LanguageSelectionView: View {
    @Environment(AppSettings.self) private var settings
    let onContinue: () -> Void

    @State private var appeared = false

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

            VStack(spacing: 32) {
                Spacer()

                Text(settings.localized(.chooseLanguage))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.theme.textPrimary)
                    .opacity(appeared ? 1 : 0)

                HStack(spacing: 12) {
                    ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                        languageCard(lang)
                    }
                }
                .padding(.horizontal, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text(settings.localized(.continueButton))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.theme.bgTop)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.theme.cyan, in: Capsule())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    private func languageCard(_ lang: AppLanguage) -> some View {
        let isSelected = settings.language == lang
        return Button {
            @Bindable var settings = settings
            settings.language = lang
        } label: {
            VStack(spacing: 10) {
                Text(lang.flag)
                    .font(.system(size: 36))

                Text(lang.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .glassCard()
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.theme.cyan : Color.clear,
                        lineWidth: 2
                    )
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.theme.cyan.opacity(0.3), lineWidth: 4)
                        .blur(radius: 4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
