import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    func shortWeekday(locale: Locale = Locale(identifier: "ru_RU")) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EE"
        return formatter.string(from: self).capitalized
    }

    // Keep the computed property for backward compatibility
    var shortWeekday: String {
        shortWeekday()
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    static func formattedInterval(_ interval: TimeInterval, language: AppLanguage = .ru) -> String {
        guard interval.isFinite, interval >= 0 else {
            return "0" + Translations.get(.secondsShort, language: language)
        }
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let h = Translations.get(.hoursShort, language: language)
        let m = Translations.get(.minutesShort, language: language)
        let s = Translations.get(.secondsShort, language: language)
        if hours > 0 {
            return "\(hours)\(h) \(minutes)\(m) \(seconds)\(s)"
        }
        if minutes > 0 {
            return "\(minutes)\(m) \(seconds)\(s)"
        }
        return "\(seconds)\(s)"
    }
}
