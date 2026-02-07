import Foundation

public enum L10n: String, CaseIterable, Sendable {
    // Main
    case appTitle

    // Timer
    case sinceLastCigarette

    // Stats
    case today
    case vsYesterday
    case avgInterval

    // Goal
    case startTracking
    case noCigsYesterday
    case goalLessThanYesterday
    case yesterdayCigs

    // Week
    case thisWeek
    case vsLastWeek

    // Button
    case tapWhenSmoke

    // Notifications
    case notifBody

    // Time
    case hoursShort
    case minutesShort

    // Onboarding
    case onboardingTitle1
    case onboardingDesc1
    case onboardingTitle2
    case onboardingDesc2
    case onboardingTitle3
    case onboardingDesc3

    // Language
    case chooseLanguage

    // Common
    case continueButton
    case getStarted
}
