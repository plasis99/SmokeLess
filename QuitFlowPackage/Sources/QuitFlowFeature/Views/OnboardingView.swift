import SwiftUI

struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    let onFinished: () -> Void

    @State private var currentPage = 0
    @State private var appeared = false
    @State private var isFinishing = false

    private let totalPages = 4

    private var pages: [(icon: String, titleKey: L10n, descKey: L10n)] {
        [
            ("cigarette", .onboardingTitle1, .onboardingDesc1),
            ("chart.bar.fill", .onboardingTitle2, .onboardingDesc2),
            ("circle.dotted.circle", .onboardingTitle3, .onboardingDesc3),
        ]
    }

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

            VStack(spacing: 0) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        onboardingPage(
                            iconName: page.icon,
                            title: settings.localized(page.titleKey),
                            description: settings.localized(page.descKey),
                            pageIndex: index
                        )
                        .tag(index)
                    }

                    // 4th screen — setup fields
                    setupPage
                        .tag(3)
                }
                #if os(iOS) || os(watchOS) || os(visionOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .frame(height: 420)
                .opacity(appeared ? 1 : 0)

                // Custom dots
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.theme.cyan : Color.white.opacity(0.2))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)

                Spacer()

                // Button
                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.6)) {
                            isFinishing = true
                        }
                        Task {
                            try? await Task.sleep(for: .milliseconds(700))
                            onFinished()
                        }
                    }
                } label: {
                    Text(currentPage < totalPages - 1 ? settings.localized(.continueButton) : settings.localized(.getStarted))
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
        .opacity(isFinishing ? 0 : 1)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    // MARK: - Setup Page (4th screen)

    private var setupPage: some View {
        VStack(spacing: 20) {
            // Title
            Text(settings.localized(.onboardingTitle4))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(settings.localized(.onboardingDesc4))
                .font(.system(size: 15))
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            @Bindable var settings = settings

            // Daily baseline
            VStack(spacing: 0) {
                setupField(
                    label: self.settings.localized(.onboardingDailyCount),
                    value: $settings.dailyBaseline
                )

                Divider().overlay(Color.theme.glassBorder)

                setupField(
                    label: self.settings.localized(.onboardingPackSize),
                    value: $settings.packSize
                )

                Divider().overlay(Color.theme.glassBorder)

                setupPriceField(
                    label: self.settings.localized(.onboardingPackPrice),
                    value: $settings.cigarettePrice
                )
            }
            .glassCard()
            .padding(.horizontal, 20)
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
        .padding(.horizontal, 20)
    }

    private func setupField(label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.theme.textSecondary)

            Spacer()

            TextField("20", value: value, format: .number)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .multilineTextAlignment(.trailing)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.theme.cyan)
                .frame(width: 80)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func setupPriceField(label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.theme.textSecondary)

            Spacer()

            TextField("0", value: value, format: .number)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.theme.cyan)
                .frame(width: 70)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    // MARK: - Info Pages

    private func onboardingPage(iconName: String, title: String, description: String, pageIndex: Int) -> some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.theme.cyan.opacity(0.08))
                    .frame(width: 100, height: 100)

                onboardingIcon(for: pageIndex)
            }

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.system(size: 15))
                .foregroundStyle(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func onboardingIcon(for index: Int) -> some View {
        switch index {
        case 0:
            // Cigarette icon
            CigaretteIcon()
        case 1:
            // Chart bars
            HStack(alignment: .bottom, spacing: 6) {
                ForEach([0.3, 0.6, 0.45, 0.8, 0.5], id: \.self) { height in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.theme.cyan)
                        .frame(width: 8, height: 40 * height)
                }
            }
        default:
            // Ring / freedom
            ZStack {
                Circle()
                    .stroke(Color.theme.cyan.opacity(0.3), lineWidth: 3)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.theme.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

// CigaretteIcon is now in Components/CigaretteIcon.swift (public, reusable)
