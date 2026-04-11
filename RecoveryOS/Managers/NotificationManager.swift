//
//  NotificationManager.swift
//  RecoveryOS
//

import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Daily 8am check-in reminder (production)
    func scheduleDailyCheckInReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])

        let content       = UNMutableNotificationContent()
        content.title     = "Morning Check-In"
        content.body      = "Log your recovery metrics and get today's readiness score."
        content.sound     = .default

        var components    = DateComponents()
        components.hour   = 8
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-checkin",
                                            content: content,
                                            trigger: trigger)
        center.add(request)
    }

    // MARK: - Low recovery alert after check-in (production)
    func scheduleRecoveryAlertIfNeeded(score: Int) {
        guard score < 50 else { return }
        send(
            id:    "recovery-alert-\(Int(Date().timeIntervalSince1970))",
            title: "Low Recovery Detected",
            body:  "Your readiness score is \(score)/100. Rest is strongly recommended - avoid intense training today.",
            delay: 5
        )
    }

    // MARK: - On-demand demo notifications (fires after 5 s)
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

    func sendDemo(_ type: DemoNotification) {
        send(id: "demo-\(type.rawValue)", title: type.title, body: type.body, delay: 5)
    }

    // MARK: - Cancel all
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Private helper
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
