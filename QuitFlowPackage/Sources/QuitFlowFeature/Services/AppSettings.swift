import Foundation

@MainActor
@Observable
public final class AppSettings {
    private let defaults = UserDefaults.standard

    public var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    public var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: "appLanguage") }
    }

    public init() {
        self.hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        let savedLang = defaults.string(forKey: "appLanguage") ?? AppLanguage.ru.rawValue
        self.language = AppLanguage(rawValue: savedLang) ?? .ru
    }

    public func localized(_ key: L10n) -> String {
        Translations.get(key, language: language)
    }

    public func localized(_ key: L10n, args: any CVarArg...) -> String {
        let template = Translations.get(key, language: language)
        return String(format: template, arguments: args)
    }
}
