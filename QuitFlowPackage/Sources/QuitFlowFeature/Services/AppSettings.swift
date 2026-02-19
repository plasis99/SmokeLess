import Foundation

@MainActor
@Observable
public final class AppSettings {
    private let defaults = UserDefaults(suiteName: "group.com.perelygin.quitflow") ?? .standard

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

    // MARK: - Review Prompt Tracking

    public var firstLaunchDate: Date? {
        didSet {
            if let date = firstLaunchDate {
                defaults.set(date.timeIntervalSince1970, forKey: "firstLaunchDate")
            }
        }
    }

    public var totalCigarettesLogged: Int {
        didSet { defaults.set(totalCigarettesLogged, forKey: "totalCigarettesLogged") }
    }

    public var lastReviewPromptDate: Date? {
        didSet {
            if let date = lastReviewPromptDate {
                defaults.set(date.timeIntervalSince1970, forKey: "lastReviewPromptDate")
            }
        }
    }

    // MARK: - Watch Sync Tracking

    public var lastWatchSyncTimestamp: Date? {
        didSet {
            if let date = lastWatchSyncTimestamp {
                defaults.set(date.timeIntervalSince1970, forKey: "lastWatchSyncTimestamp")
            }
        }
    }

    public func incrementCigaretteCount() {
        totalCigarettesLogged += 1
    }

    public var shouldRequestReview: Bool {
        guard let firstLaunch = firstLaunchDate else { return false }
        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: .now).day ?? 0
        guard daysSinceFirstLaunch >= 3 else { return false }
        guard totalCigarettesLogged >= 10 else { return false }
        if let lastPrompt = lastReviewPromptDate {
            let daysSincePrompt = Calendar.current.dateComponents([.day], from: lastPrompt, to: .now).day ?? 0
            guard daysSincePrompt >= 90 else { return false }
        }
        return true
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

        // Review prompt tracking
        let firstLaunchInterval = defaults.double(forKey: "firstLaunchDate")
        self.firstLaunchDate = firstLaunchInterval > 0 ? Date(timeIntervalSince1970: firstLaunchInterval) : nil
        self.totalCigarettesLogged = defaults.integer(forKey: "totalCigarettesLogged")
        let lastPromptInterval = defaults.double(forKey: "lastReviewPromptDate")
        self.lastReviewPromptDate = lastPromptInterval > 0 ? Date(timeIntervalSince1970: lastPromptInterval) : nil

        // Watch sync tracking
        let lastSyncInterval = defaults.double(forKey: "lastWatchSyncTimestamp")
        self.lastWatchSyncTimestamp = lastSyncInterval > 0 ? Date(timeIntervalSince1970: lastSyncInterval) : nil

        // Set first launch date if not set
        if self.firstLaunchDate == nil {
            self.firstLaunchDate = .now
        }
    }

    public func localized(_ key: L10n) -> String {
        Translations.get(key, language: language)
    }

    public func localized(_ key: L10n, args: any CVarArg...) -> String {
        let template = Translations.get(key, language: language)
        return String(format: template, arguments: args)
    }
}
