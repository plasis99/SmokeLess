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

    public var cigarettePrice: Double {
        didSet {
            if cigarettePrice < 0 { cigarettePrice = 0 }
            defaults.set(cigarettePrice, forKey: "cigarettePrice")
        }
    }

    public var packSize: Int {
        didSet {
            if packSize < 1 { packSize = 1 }
            defaults.set(packSize, forKey: "packSize")
        }
    }

    public var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    public var dailyBaseline: Int {
        didSet {
            if dailyBaseline < 1 { dailyBaseline = 1 }
            defaults.set(dailyBaseline, forKey: "dailyBaseline")
        }
    }

    public var pricePerCigarette: Double {
        guard packSize > 0 else { return 0 }
        return cigarettePrice / Double(packSize)
    }

    public init() {
        self.hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        let savedLang = defaults.string(forKey: "appLanguage") ?? AppLanguage.ru.rawValue
        self.language = AppLanguage(rawValue: savedLang) ?? .ru
        self.cigarettePrice = defaults.double(forKey: "cigarettePrice")
        let savedPack = defaults.integer(forKey: "packSize")
        self.packSize = savedPack > 0 ? savedPack : 20
        self.notificationsEnabled = defaults.object(forKey: "notificationsEnabled") == nil ? true : defaults.bool(forKey: "notificationsEnabled")
        let savedBaseline = defaults.integer(forKey: "dailyBaseline")
        self.dailyBaseline = savedBaseline > 0 ? savedBaseline : 20
    }

    public func localized(_ key: L10n) -> String {
        Translations.get(key, language: language)
    }

    public func localized(_ key: L10n, args: any CVarArg...) -> String {
        let template = Translations.get(key, language: language)
        return String(format: template, arguments: args)
    }
}
