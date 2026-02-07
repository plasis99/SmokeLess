import SwiftUI
import SwiftData

public struct ContentView: View {
    @State private var settings = AppSettings()
    @State private var flow: AppFlow = .splash

    public var body: some View {
        ZStack {
            switch flow {
            case .splash:
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        if settings.hasCompletedOnboarding {
                            flow = .main
                        } else {
                            flow = .languageSelection
                        }
                    }
                }
                .transition(.opacity)

            case .languageSelection:
                LanguageSelectionView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        flow = .onboarding
                    }
                }
                .transition(.opacity)

            case .onboarding:
                OnboardingView {
                    settings.hasCompletedOnboarding = true
                    withAnimation(.easeInOut(duration: 0.4)) {
                        flow = .main
                    }
                }
                .transition(.opacity)

            case .main:
                MainView()
                    .transition(.opacity)
            }
        }
        .environment(settings)
    }

    public init() {}
}

#Preview {
    ContentView()
        .modelContainer(for: SmokingEntry.self, inMemory: true)
}
