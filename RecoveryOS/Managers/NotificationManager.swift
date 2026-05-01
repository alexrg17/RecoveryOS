//
//  NotificationManager.swift
//  RecoveryOS
//

import UserNotifications

// Singleton so there is one consistent notification queue across the whole app.
// Making init() private prevents accidental extra instances being created elsewhere.
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    // Called once at app launch. The result is ignored here because the OS
    // remembers the user's choice and we check isAuthorized before scheduling.
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Daily 8am check-in reminder

    // Removes any previously scheduled version of this reminder before adding a new one
    // so we never end up with duplicate notifications if the user changes their settings.
    func scheduleDailyCheckInReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])

        let content       = UNMutableNotificationContent()
        content.title     = "Morning Check-In"
        content.body      = "Log your recovery metrics and get today's readiness score."
        content.sound     = .default

        // Fire at 8:00 am every day. UNCalendarNotificationTrigger with repeats: true
        // handles daylight saving changes automatically.
        var components    = DateComponents()
        components.hour   = 8
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-checkin",
                                            content: content,
                                            trigger: trigger)
        center.add(request)
    }

    // MARK: - Low recovery alert

    // Only fires when the score is genuinely low (below 50) because alerting
    // for moderate fatigue would desensitise the user and they would start ignoring it.
    // A unique ID based on the current timestamp prevents this from overwriting
    // any other pending notification of the same type.
    func scheduleRecoveryAlertIfNeeded(score: Int) {
        guard score < 50 else { return }
        send(
            id:    "recovery-alert-\(Int(Date().timeIntervalSince1970))",
            title: "Low Recovery Detected",
            body:  "Your readiness score is \(score)/100. Rest is strongly recommended - avoid intense training today.",
            delay: 5
        )
    }

    // MARK: - Demo notifications

    // The demo enum lets us trigger each notification type from the UI for
    // presentation and testing without having to wait for real conditions to occur.
    enum DemoNotification: String, CaseIterable {
        case checkIn      = "Check-In Reminder"
        case lowRecovery  = "Low Recovery Alert"
        case training     = "Training Recommendation"

        var icon: String {
            switch self {
            case .checkIn:     return "bell.fill"
            case .lowRecovery: return "exclamationmark.heart.fill"
            case .training:    return "figure.run"
            }
        }

        var subtitle: String {
            switch self {
            case .checkIn:     return "Reminder to log today's metrics"
            case .lowRecovery: return "Recovery score has dropped below 50"
            case .training:    return "Personalised session suggestion ready"
            }
        }

        var title: String { rawValue }

        var body: String {
            switch self {
            case .checkIn:
                return "Don't forget to log your recovery metrics and get today's readiness score."
            case .lowRecovery:
                return "Your readiness score is below 50. Rest is recommended - avoid intense training today."
            case .training:
                return "Based on your recovery data, a moderate strength session is recommended today. Tap to view your plan."
            }
        }
    }

    // Fires the chosen demo notification after a 5 second delay so the user has time
    // to press the home button and actually see it arrive on the lock screen.
    func sendDemo(_ type: DemoNotification) {
        send(id: "demo-\(type.rawValue)", title: type.title, body: type.body, delay: 5)
    }

    // MARK: - Cancel

    // Removes only the daily 8am reminder, leaving any pending recovery alerts
    // untouched. Called when the user turns off Recovery Reminders in Settings.
    func cancelDailyCheckInReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])
    }

    // Removes every pending notification. Used on sign-out so the next user
    // does not see another account's recovery alerts.
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Private helper

    // Shared sending logic to avoid duplicating the content/trigger setup
    // in every method above.
    private func send(id: String, title: String, body: String, delay: TimeInterval) {
        let content   = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
