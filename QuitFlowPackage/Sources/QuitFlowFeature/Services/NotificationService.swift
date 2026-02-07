import UserNotifications

public enum NotificationService {
    public static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public static func scheduleSmartReminder(averageInterval: TimeInterval, language: AppLanguage = .ru) {
        guard averageInterval > 300 else { return } // minimum 5 minutes

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["smart-reminder"])

        let content = UNMutableNotificationContent()
        let minutes = Int(averageInterval * 0.85) / 60
        content.title = "QuitFlow"
        content.body = Translations.get(.notifBody, language: language, args: "\(minutes)")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: averageInterval * 0.85,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "smart-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }
}
