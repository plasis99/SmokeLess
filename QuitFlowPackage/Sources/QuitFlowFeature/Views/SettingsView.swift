import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            LinearGradient.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    header

                    // Language
                    languageSection

                    // Price
                    priceSection

                    // Notifications
                    notificationsSection

                    // About
                    aboutSection

                    // Reset
                    resetSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .alert(settings.localized(.settingsResetData), isPresented: $showResetAlert) {
            Button(settings.localized(.settingsResetCancel), role: .cancel) {}
            Button(settings.localized(.settingsResetConfirm), role: .destructive) {
                resetAllData()
            }
        } message: {
            Text(settings.localized(.settingsResetMessage))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.theme.cyan)
            }

            Spacer()

            Text(settings.localized(.settings))
                .font(.system(size: 15, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color.theme.textTertiary)

            Spacer()

            // Balance spacer
            Color.clear.frame(width: 18, height: 18)
        }
        .padding(.top, 8)
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(settings.localized(.settingsLanguage))

            HStack(spacing: 10) {
                @Bindable var settings = settings
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            settings.language = lang
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(lang.flag)
                                .font(.system(size: 16))
                            Text(lang.displayName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(settings.language == lang ? Color.theme.textPrimary : Color.theme.textTertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(settings.language == lang ? Color.theme.cyan.opacity(0.15) : Color.clear)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(settings.language == lang ? Color.theme.cyan.opacity(0.4) : Color.theme.glassBorder, lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Price

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(settings.localized(.settingsPrice))

            @Bindable var settings = settings

            HStack {
                Text(self.settings.localized(.settingsDailyBaseline))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.theme.textSecondary)

                Spacer()

                TextField("20", value: $settings.dailyBaseline, format: .number)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.theme.textPrimary)
                    .frame(width: 70)
            }

            Divider().overlay(Color.theme.glassBorder)

            HStack {
                Text(self.settings.localized(.settingsPrice))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.theme.textSecondary)

                Spacer()

                TextField("0", value: $settings.cigarettePrice, format: .number)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.theme.textPrimary)
                    .frame(width: 70)
            }

            Divider().overlay(Color.theme.glassBorder)

            HStack {
                Text(self.settings.localized(.settingsPackSize))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.theme.textSecondary)

                Spacer()

                TextField("20", value: $settings.packSize, format: .number)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.theme.textPrimary)
                    .frame(width: 70)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .onChange(of: settings.dailyBaseline) { _, newValue in
            if newValue < 1 { settings.dailyBaseline = 1 }
        }
        .onChange(of: settings.packSize) { _, newValue in
            if newValue < 1 { settings.packSize = 1 }
        }
        .onChange(of: settings.cigarettePrice) { _, newValue in
            if newValue < 0 { settings.cigarettePrice = 0 }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            @Bindable var settings = settings

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.localized(.settingsNotifications))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.theme.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $settings.notificationsEnabled)
                    .tint(Color.theme.cyan)
                    .labelsHidden()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - About

    // swiftlint:disable:next force_unwrapping
    private let privacyPolicyURL = URL(string: "https://universum.earth/apps/smokeless/privacy")!

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(settings.localized(.settingsAbout))

            HStack {
                Text(settings.localized(.settingsVersion))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.theme.textSecondary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.theme.textTertiary)
            }

            Divider().overlay(Color.theme.glassBorder)

            Link(destination: privacyPolicyURL) {
                HStack {
                    Text(settings.localized(.settingsPrivacyPolicy))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.theme.textSecondary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.theme.textTertiary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Reset

    private var resetSection: some View {
        Button {
            showResetAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                Text(settings.localized(.settingsResetData))
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Color.theme.redSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .tracking(1)
            .foregroundStyle(Color.theme.textTertiary)
            .textCase(.uppercase)
    }

    private func resetAllData() {
        do {
            try modelContext.delete(model: SmokingEntry.self)
            try modelContext.save()
        } catch {
            // Silently handle - data reset is best-effort
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
        .modelContainer(for: SmokingEntry.self, inMemory: true)
}
