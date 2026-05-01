//
//  DashboardController.swift
//  RecoveryOS
//

import SwiftUI
import SwiftData
import Combine

// Sits between DashboardView and the underlying data so the view does not
// contain any interpretation logic. It handles AI advice, recovery status
// labels, colour coding, and metric formatting.
// Injected from RecoveryOSApp as an @EnvironmentObject so all child views
// share the same instance and do not trigger redundant AI requests.
@MainActor
final class DashboardController: ObservableObject {

    // MARK: - AI coaching state

    // These three properties mirror the AI service's state so that DashboardView
    // only needs to observe this controller rather than knowing about AICoachService.
    @Published var aiAdvice:     String = ""
    @Published var isGenerating: Bool   = false
    @Published var usedAI:       Bool   = false

    private let aiService    = AICoachService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to the AI service's published properties and forward them here.
        // This means the view gets live updates during generation without being
        // coupled to the service directly.
        aiService.$advice      .assign(to: &$aiAdvice)
        aiService.$isGenerating.assign(to: &$isGenerating)
        aiService.$usedAI      .assign(to: &$usedAI)
    }

    // MARK: - AI coaching

    // Asks the AI service for personalised advice based on the latest check-in.
    // The service caches by check-in ID so calling this repeatedly is safe
    // and will not trigger extra network or model calls.
    func refreshAdvice(profile: UserProfile?, checkIns: [DailyCheckIn]) async {
        guard let profile, !checkIns.isEmpty else { return }
        await aiService.generateIfNeeded(profile: profile, checkIns: checkIns)
    }

    // MARK: - Recovery status

    // Converts a raw 0-100 score into a word that is easier for the user to understand.
    // The thresholds are based on general sports science readiness categories
    // rather than arbitrary percentages.
    func recoveryStatus(for score: Int, hasData: Bool) -> String {
        guard hasData else { return "NO DATA" }
        switch score {
        case 85...100: return "OPTIMAL"
        case 75..<85:  return "GOOD"
        case 60..<75:  return "MODERATE"
        case 40..<60:  return "FAIR"
        default:       return "POOR"
        }
    }

    // The colour gives an instant visual signal without the user needing to read
    // the text, following a traffic light pattern that most people intuitively understand.
    func statusColor(for score: Int) -> Color {
        switch score {
        case 85...100: return Color(red: 0.25, green: 0.90, blue: 0.69)  // teal = optimal
        case 75..<85:  return Color(red: 0.40, green: 0.85, blue: 0.55)  // green = good
        case 60..<75:  return Color(red: 1.00, green: 0.75, blue: 0.20)  // yellow = moderate
        case 40..<60:  return Color(red: 1.00, green: 0.55, blue: 0.20)  // orange = fair
        default:       return Color(red: 1.00, green: 0.38, blue: 0.38)  // red = poor
        }
    }

    // MARK: - Fallback insight text

    // Used on the dashboard when the AI service has not generated advice yet
    // (first load, no check-ins, or Apple Intelligence not available on the device).
    func insightText(for score: Int, hasData: Bool) -> (label: String, body: String) {
        guard hasData else {
            return (
                "Complete your first check-in:",
                "Log your daily metrics to receive personalised recovery insights and training recommendations."
            )
        }
        switch score {
        case 85...100: return ("Optimal Performance Window:", "Your CNS recovery is at peak levels. High intensity training is recommended.")
        case 75..<85:  return ("Good Recovery Status:", "Your body is well recovered. Moderate to high intensity training is appropriate today.")
        case 60..<75:  return ("Moderate Recovery:", "Consider a moderate session today. Prioritise sleep and hydration to boost recovery.")
        case 40..<60:  return ("Fair Recovery:", "Your body needs more rest. Light activity or active recovery is recommended today.")
        default:       return ("Low Recovery Alert:", "Your recovery is compromised. Rest is strongly recommended. Avoid intense training today.")
        }
    }

    // MARK: - Training phase recommendation

    // Suggests a type of session based on the readiness score so the user
    // gets an actionable recommendation rather than just a number.
    func nextPhase(for score: Int, hasData: Bool) -> (icon: String, iconBg: Color, title: String, subtitle: String) {
        let blue = Color(red: 0.28, green: 0.48, blue: 0.98)
        let teal = Color(red: 0.25, green: 0.90, blue: 0.69)
        guard hasData else {
            return ("plus.circle", blue, "Log Check-In", "Complete today's check-in first")
        }
        switch score {
        case 85...100: return ("figure.run",        blue,                                        "High Intensity",    "Suggested duration: 60 minutes")
        case 75..<85:  return ("dumbbell.fill",      Color(red: 0.30, green: 0.45, blue: 0.90), "Strength Training", "Suggested duration: 45 minutes")
        case 60..<75:  return ("figure.walk",        Color(red: 0.45, green: 0.35, blue: 0.22), "Light Training",    "Suggested duration: 30 minutes")
        case 40..<60:  return ("figure.flexibility", teal.opacity(0.9),                          "Active Recovery",   "Suggested duration: 30 minutes")
        default:       return ("bed.double.fill",    Color(red: 0.35, green: 0.20, blue: 0.60), "Full Rest",         "Recommended for today")
        }
    }

    // MARK: - Metric formatting

    // Formats sleep as "7h 30m" rather than a decimal like "7.5" because that is
    // how people naturally think and talk about sleep duration.
    // Falls back to the HealthKit snapshot if today's check-in has no sleep data entered.
    func sleepString(from checkIn: DailyCheckIn?, snapshot: HealthKitSnapshot?) -> String {
        guard let h = checkIn?.sleepHours ?? snapshot?.sleepHours else { return "—" }
        let hrs = Int(h); let mins = Int((h - Double(hrs)) * 60)
        return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
    }

    func restingHRString(from checkIn: DailyCheckIn?, snapshot: HealthKitSnapshot?) -> String {
        guard let hr = checkIn?.restingHR ?? snapshot?.restingHR else { return "—" }
        return "\(Int(hr)) BPM"
    }

    func hrvString(from checkIn: DailyCheckIn?, snapshot: HealthKitSnapshot?) -> String {
        guard let hrv = checkIn?.hrvMs ?? snapshot?.hrvMs else { return "—" }
        return "\(Int(hrv)) ms"
    }

    // Normalises HRV to a 0-1 progress value using 100 ms as the ceiling.
    // 100 ms is roughly the upper end of what recreational athletes achieve,
    // so this keeps the bar from always sitting near 100% for elite users.
    func hrvProgress(from checkIn: DailyCheckIn?, snapshot: HealthKitSnapshot?) -> Double {
        guard let hrv = checkIn?.hrvMs ?? snapshot?.hrvMs else { return 0 }
        return min(hrv / 100.0, 1.0)
    }

    // Calculates the percentage change in sleep compared to the previous day
    // and formats it as "+12%" or "-8%" to give context beyond just the raw hours.
    func sleepChange(today: DailyCheckIn?, previous: DailyCheckIn?) -> String? {
        guard let todaySleep = today?.sleepHours,
              let prevSleep  = previous?.sleepHours, prevSleep > 0 else { return nil }
        let pct = ((todaySleep - prevSleep) / prevSleep) * 100
        return "\(pct >= 0 ? "+" : "")\(Int(pct.rounded()))%"
    }

    // Green for an improvement, red for a decline. Clear when there is no comparison data.
    func sleepChangeColor(for change: String?) -> Color {
        guard let c = change else { return .clear }
        return c.hasPrefix("+")
            ? Color(red: 0.20, green: 0.85, blue: 0.40)
            : Color(red: 1.00, green: 0.38, blue: 0.38)
    }
}
