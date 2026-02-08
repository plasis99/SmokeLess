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
    case secondsShort

    // Onboarding
    case onboardingTitle1
    case onboardingDesc1
    case onboardingTitle2
    case onboardingDesc2
    case onboardingTitle3
    case onboardingDesc3

    // Language
    case chooseLanguage

    // Statistics Detail
    case statistics
    case last30days
    case bestDay
    case worstDay
    case totalCigs
    case dailyAvg
    case trend30d

    // Achievements
    case achievements
    case healthTimeline
    case streakDays
    case streakDesc
    case health20min
    case health8h
    case health48h
    case health2w
    case health3m
    case health1y
    case achievementLocked

    // Settings
    case settings
    case settingsLanguage
    case settingsPrice
    case settingsPackSize
    case settingsNotifications
    case settingsCurrency
    case settingsAbout
    case settingsVersion
    case settingsResetData
    case settingsResetConfirm
    case settingsResetCancel
    case settingsResetMessage
    case settingsMoneySaved
    case settingsPrivacyPolicy

    // Accessibility
    case accessLogCigarette
    case accessTimeSince
    case accessTodayCount
    case accessVsYesterday
    case accessAvgInterval
    case accessGoalProgress
    case accessWeekTrend

    // Common
    case continueButton
    case getStarted
}
