import Foundation

public enum AppLanguage: String, CaseIterable, Sendable {
    case ru
    case en
    case uk

    public var displayName: String {
        switch self {
        case .ru: "Русский"
        case .en: "English"
        case .uk: "Українська"
        }
    }

    public var flag: String {
        switch self {
        case .ru: "🇷🇺"
        case .en: "🇬🇧"
        case .uk: "🇺🇦"
        }
    }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }
}
