import Foundation

public enum AppLanguage: String, CaseIterable, Sendable {
    case ru
    case en

    public var displayName: String {
        switch self {
        case .ru: "Русский"
        case .en: "English"
        }
    }

    public var flag: String {
        switch self {
        case .ru: "🇷🇺"
        case .en: "🇬🇧"
        }
    }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }
}
