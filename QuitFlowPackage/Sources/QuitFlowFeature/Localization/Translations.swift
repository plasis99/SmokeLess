import Foundation

public enum Translations {
    private static let strings: [AppLanguage: [L10n: String]] = [
        .ru: [
            .appTitle: "SMOKELESS",
            .sinceLastCigarette: "С ПОСЛЕДНЕЙ СИГАРЕТЫ",
            .today: "СЕГОДНЯ",
            .vsYesterday: "К ВЧЕРА",
            .avgInterval: "ИНТЕРВАЛ ⌀",
            .startTracking: "Начни отмечать сигареты",
            .noCigsYesterday: "Вчера ты не курил!",
            .goalLessThanYesterday: "Цель: меньше чем вчера",
            .yesterdayCigs: "Вчера: %@ сигарет",
            .thisWeek: "ЭТА НЕДЕЛЯ",
            .vsLastWeek: "к прошлой",
            .tapWhenSmoke: "Нажми когда закуришь",
            .notifBody: "Ты уже %@ минут без сигареты. Может ещё немного?",
            .hoursShort: "ч",
            .minutesShort: "м",
            .onboardingTitle1: "Отслеживай привычку",
            .onboardingDesc1: "Отмечай каждую сигарету одним нажатием. Мы запомним время и посчитаем статистику.",
            .onboardingTitle2: "Смотри прогресс",
            .onboardingDesc2: "График за неделю, средний интервал и сравнение с прошлым днём — всё на одном экране.",
            .onboardingTitle3: "Двигайся к свободе",
            .onboardingDesc3: "Каждый день без лишней сигареты — это шаг к здоровой жизни. Начни прямо сейчас.",
            .chooseLanguage: "Выбери язык",
            .continueButton: "Продолжить",
            .getStarted: "Начать",
        ],
        .en: [
            .appTitle: "SMOKELESS",
            .sinceLastCigarette: "SINCE LAST CIGARETTE",
            .today: "TODAY",
            .vsYesterday: "VS YESTERDAY",
            .avgInterval: "AVG INTERVAL",
            .startTracking: "Start tracking your cigarettes",
            .noCigsYesterday: "You didn't smoke yesterday!",
            .goalLessThanYesterday: "Goal: less than yesterday",
            .yesterdayCigs: "Yesterday: %@ cigarettes",
            .thisWeek: "THIS WEEK",
            .vsLastWeek: "vs last week",
            .tapWhenSmoke: "Tap when you light up",
            .notifBody: "You've been %@ minutes without a cigarette. Keep going!",
            .hoursShort: "h",
            .minutesShort: "m",
            .onboardingTitle1: "Track Your Habit",
            .onboardingDesc1: "Log every cigarette with a single tap. We'll track the time and calculate your stats.",
            .onboardingTitle2: "See Your Progress",
            .onboardingDesc2: "Weekly chart, average interval, and daily comparison — all on one screen.",
            .onboardingTitle3: "Move Toward Freedom",
            .onboardingDesc3: "Every day with fewer cigarettes is a step to a healthier life. Start now.",
            .chooseLanguage: "Choose Language",
            .continueButton: "Continue",
            .getStarted: "Get Started",
        ],
    ]

    public static func get(_ key: L10n, language: AppLanguage) -> String {
        strings[language]?[key] ?? key.rawValue
    }

    public static func get(_ key: L10n, language: AppLanguage, args: any CVarArg...) -> String {
        let template = get(key, language: language)
        return String(format: template, arguments: args)
    }
}
