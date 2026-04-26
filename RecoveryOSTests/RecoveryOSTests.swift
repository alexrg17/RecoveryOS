//
//  RecoveryOSTests.swift
//  RecoveryOSTests
//
//  Created by Alex Radu on 16/03/2026.
//

import Testing
import Foundation
import UserNotifications
@testable import RecoveryOS

// MARK: - Score Calculation Tests

// Tests for DailyCheckIn.calculateScore(), which is a pure static function
// so it is easy to test in isolation without any SwiftData setup.
@Suite("Readiness Score Calculation")
struct ScoreCalculationTests {

    // When every slider is at the midpoint (5) and no sleep data is available,
    // the score should land just under 50 because soreness and stress are inverted
    // (10 - 5 = 5) while energy, hydration, and mood are direct (5 - 1 = 4).
    @Test func neutralInputsProduceMidrangeScore() {
        let score = DailyCheckIn.calculateScore(
            soreness: 5, energy: 5, stress: 5, hydration: 5, mood: 5
        )
        // Expected: ~49 based on the weighted formula in DailyCheckIn
        #expect(score == 49)
    }

    // All inputs at their most positive values (low soreness/stress, high everything
    // else) should give a perfect 100.
    @Test func bestPossibleInputsGive100() {
        let score = DailyCheckIn.calculateScore(
            soreness: 1, energy: 10, stress: 1, hydration: 10, mood: 10
        )
        #expect(score == 100)
    }

    // All inputs at their worst values should give 0 — the formula must not
    // allow a negative result when all metrics are at the minimum.
    @Test func worstPossibleInputsGive0() {
        let score = DailyCheckIn.calculateScore(
            soreness: 10, energy: 1, stress: 10, hydration: 1, mood: 1
        )
        #expect(score == 0)
    }

    // 8 hours of sleep is the science-backed target used in the formula,
    // so passing 8.0 should add the full 20% sleep bonus on top of the base score.
    @Test func eightHourSleepBoostsNeutralScoreTo59() {
        let score = DailyCheckIn.calculateScore(
            soreness: 5, energy: 5, stress: 5, hydration: 5, mood: 5,
            sleepHours: 8.0
        )
        #expect(score == 59)
    }

    // Four hours is half the target, so the bonus should be 10% rather than
    // the full 20%, leaving the score just below the neutral-with-full-sleep result.
    @Test func fourHourSleepGivesPartialBonus() {
        let score = DailyCheckIn.calculateScore(
            soreness: 5, energy: 5, stress: 5, hydration: 5, mood: 5,
            sleepHours: 4.0
        )
        #expect(score == 49)
    }

    // Sleep beyond 8 hours is capped at 1.0 in the normalisation step,
    // so 10 hours should produce the same result as 8 hours.
    @Test func sleepBeyondEightHoursIsCapped() {
        let withEight = DailyCheckIn.calculateScore(
            soreness: 5, energy: 5, stress: 5, hydration: 5, mood: 5,
            sleepHours: 8.0
        )
        let withTen = DailyCheckIn.calculateScore(
            soreness: 5, energy: 5, stress: 5, hydration: 5, mood: 5,
            sleepHours: 10.0
        )
        #expect(withEight == withTen)
    }

    // The clamp should prevent the score from going below 0 or above 100
    // regardless of what combination of inputs is passed in.
    @Test func scoreIsAlwaysWithin0To100() {
        for value in 1...10 {
            let score = DailyCheckIn.calculateScore(
                soreness: value, energy: value, stress: value,
                hydration: value, mood: value
            )
            #expect(score >= 0)
            #expect(score <= 100)
        }
    }

    // Without sleep data the formula should behave identically to the version
    // that explicitly passes nil, since nil is the default parameter value.
    @Test func omittingSleepMatchesPassingNil() {
        let withoutSleep = DailyCheckIn.calculateScore(
            soreness: 6, energy: 7, stress: 4, hydration: 8, mood: 7
        )
        let withNil = DailyCheckIn.calculateScore(
            soreness: 6, energy: 7, stress: 4, hydration: 8, mood: 7,
            sleepHours: nil
        )
        #expect(withoutSleep == withNil)
    }
}

// MARK: - Dashboard Controller Tests

// Tests for the pure interpretation logic in DashboardController.
// No async setup is needed because none of these methods touch SwiftData or AI.
@Suite("Dashboard Controller")
@MainActor
struct DashboardControllerTests {

    let controller = DashboardController()

    // MARK: Recovery status label

    @Test func recoveryStatusReturnsNoDataWhenFlagIsFalse() {
        #expect(controller.recoveryStatus(for: 80, hasData: false) == "NO DATA")
    }

    @Test func recoveryStatusOptimalAt85AndAbove() {
        #expect(controller.recoveryStatus(for: 85,  hasData: true) == "OPTIMAL")
        #expect(controller.recoveryStatus(for: 100, hasData: true) == "OPTIMAL")
    }

    @Test func recoveryStatusGoodBetween75And84() {
        #expect(controller.recoveryStatus(for: 75, hasData: true) == "GOOD")
        #expect(controller.recoveryStatus(for: 84, hasData: true) == "GOOD")
    }

    @Test func recoveryStatusModerateBetween60And74() {
        #expect(controller.recoveryStatus(for: 60, hasData: true) == "MODERATE")
        #expect(controller.recoveryStatus(for: 74, hasData: true) == "MODERATE")
    }

    @Test func recoveryStatusFairBetween40And59() {
        #expect(controller.recoveryStatus(for: 40, hasData: true) == "FAIR")
        #expect(controller.recoveryStatus(for: 59, hasData: true) == "FAIR")
    }

    @Test func recoveryStatusPoorBelow40() {
        #expect(controller.recoveryStatus(for: 39, hasData: true) == "POOR")
        #expect(controller.recoveryStatus(for: 0,  hasData: true) == "POOR")
    }

    // MARK: Insight text labels

    @Test func insightLabelPromptFirstCheckInWhenNoData() {
        let result = controller.insightText(for: 50, hasData: false)
        #expect(result.label == "Complete your first check-in:")
    }

    @Test func insightLabelOptimalForHighScore() {
        let result = controller.insightText(for: 90, hasData: true)
        #expect(result.label == "Optimal Performance Window:")
    }

    @Test func insightLabelGoodForScore80() {
        let result = controller.insightText(for: 80, hasData: true)
        #expect(result.label == "Good Recovery Status:")
    }

    @Test func insightLabelModerateForScore70() {
        let result = controller.insightText(for: 70, hasData: true)
        #expect(result.label == "Moderate Recovery:")
    }

    @Test func insightLabelFairForScore50() {
        let result = controller.insightText(for: 50, hasData: true)
        #expect(result.label == "Fair Recovery:")
    }

    @Test func insightLabelLowAlertForScore30() {
        let result = controller.insightText(for: 30, hasData: true)
        #expect(result.label == "Low Recovery Alert:")
    }

    // MARK: Next phase recommendation icons

    @Test func nextPhaseShowsLogPromptWhenNoData() {
        let phase = controller.nextPhase(for: 50, hasData: false)
        #expect(phase.icon == "plus.circle")
        #expect(phase.title == "Log Check-In")
    }

    @Test func nextPhaseHighIntensityForOptimalScore() {
        let phase = controller.nextPhase(for: 90, hasData: true)
        #expect(phase.icon == "figure.run")
        #expect(phase.title == "High Intensity")
    }

    @Test func nextPhaseStrengthForGoodScore() {
        let phase = controller.nextPhase(for: 80, hasData: true)
        #expect(phase.icon == "dumbbell.fill")
        #expect(phase.title == "Strength Training")
    }

    @Test func nextPhaseLightTrainingForModerateScore() {
        let phase = controller.nextPhase(for: 70, hasData: true)
        #expect(phase.icon == "figure.walk")
        #expect(phase.title == "Light Training")
    }

    @Test func nextPhaseActiveRecoveryForFairScore() {
        let phase = controller.nextPhase(for: 50, hasData: true)
        #expect(phase.icon == "figure.flexibility")
        #expect(phase.title == "Active Recovery")
    }

    @Test func nextPhaseFullRestForPoorScore() {
        let phase = controller.nextPhase(for: 30, hasData: true)
        #expect(phase.icon == "bed.double.fill")
        #expect(phase.title == "Full Rest")
    }

    // MARK: Sleep formatting

    // When neither the check-in nor the HealthKit snapshot has sleep data,
    // the formatted string should be an em dash to indicate data is missing.
    @Test func sleepStringReturnsDashWhenBothNil() {
        #expect(controller.sleepString(from: nil, snapshot: nil) == "—")
    }

    @Test func sleepStringFormatsHoursAndMinutes() {
        let checkIn = DailyCheckIn(sleepHours: 7.5)
        #expect(controller.sleepString(from: checkIn, snapshot: nil) == "7h 30m")
    }

    @Test func sleepStringOmitsMinutesWhenExactHour() {
        let checkIn = DailyCheckIn(sleepHours: 8.0)
        #expect(controller.sleepString(from: checkIn, snapshot: nil) == "8h")
    }

    @Test func sleepStringFallsBackToSnapshotWhenCheckInHasNoSleep() {
        let checkIn  = DailyCheckIn(sleepHours: nil)
        let snapshot = HealthKitSnapshot(sleepHours: 6.0)
        #expect(controller.sleepString(from: checkIn, snapshot: snapshot) == "6h")
    }

    // MARK: Resting HR formatting

    @Test func restingHRStringReturnsDashWhenBothNil() {
        #expect(controller.restingHRString(from: nil, snapshot: nil) == "—")
    }

    @Test func restingHRStringFormatsWithBPMSuffix() {
        let checkIn = DailyCheckIn(restingHR: 58.0)
        #expect(controller.restingHRString(from: checkIn, snapshot: nil) == "58 BPM")
    }

    // MARK: HRV formatting

    @Test func hrvStringReturnsDashWhenBothNil() {
        #expect(controller.hrvString(from: nil, snapshot: nil) == "—")
    }

    @Test func hrvStringFormatsWithMsSuffix() {
        let checkIn = DailyCheckIn(hrvMs: 65.0)
        #expect(controller.hrvString(from: checkIn, snapshot: nil) == "65 ms")
    }

    // Decimal values should be truncated, not rounded, because Int() truncates.
    @Test func hrvStringTruncatesDecimal() {
        let checkIn = DailyCheckIn(hrvMs: 65.9)
        #expect(controller.hrvString(from: checkIn, snapshot: nil) == "65 ms")
    }

    // MARK: HRV progress bar

    @Test func hrvProgressIsZeroWhenNil() {
        #expect(controller.hrvProgress(from: nil, snapshot: nil) == 0.0)
    }

    @Test func hrvProgressNormalisesTo100ms() {
        let checkIn = DailyCheckIn(hrvMs: 60.0)
        #expect(controller.hrvProgress(from: checkIn, snapshot: nil) == 0.6)
    }

    @Test func hrvProgressCapsAt1() {
        let checkIn = DailyCheckIn(hrvMs: 120.0)
        #expect(controller.hrvProgress(from: checkIn, snapshot: nil) == 1.0)
    }

    // MARK: Sleep change percentage

    // No previous data means there is nothing to compare, so nil is returned
    // rather than showing a misleading "0%" change.
    @Test func sleepChangeReturnsNilWhenEitherEntryMissing() {
        #expect(controller.sleepChange(today: nil,                       previous: nil)                       == nil)
        #expect(controller.sleepChange(today: DailyCheckIn(),            previous: nil)                       == nil)
        #expect(controller.sleepChange(today: nil,                       previous: DailyCheckIn())            == nil)
        #expect(controller.sleepChange(today: DailyCheckIn(sleepHours: nil), previous: DailyCheckIn(sleepHours: 7.0)) == nil)
    }

    @Test func sleepChangeShowsPlusSignForIncrease() {
        let today    = DailyCheckIn(sleepHours: 9.0)
        let previous = DailyCheckIn(sleepHours: 6.0)
        // ((9 - 6) / 6) * 100 = 50%
        #expect(controller.sleepChange(today: today, previous: previous) == "+50%")
    }

    @Test func sleepChangeShowsMinusSignForDecrease() {
        let today    = DailyCheckIn(sleepHours: 6.0)
        let previous = DailyCheckIn(sleepHours: 8.0)
        // ((6 - 8) / 8) * 100 = -25%
        #expect(controller.sleepChange(today: today, previous: previous) == "-25%")
    }

    @Test func sleepChangeIsZeroWhenSleep() {
        let today    = DailyCheckIn(sleepHours: 7.0)
        let previous = DailyCheckIn(sleepHours: 7.0)
        #expect(controller.sleepChange(today: today, previous: previous) == "+0%")
    }
}

// MARK: - CheckIn Controller Tests

@Suite("CheckIn Controller")
@MainActor
struct CheckInControllerTests {

    // All sliders should default to 5 (the midpoint of the 1-10 scale) so
    // the user can submit without touching anything and get a neutral score.
    @Test func defaultValuesAreNeutral() {
        let controller = CheckInController()
        #expect(controller.soreness           == 5)
        #expect(controller.energy             == 5)
        #expect(controller.stress             == 5)
        #expect(controller.hydration          == 5)
        #expect(controller.mood               == 5)
        #expect(controller.nutritionAdherence == 5)
        #expect(controller.workoutLoad        == 5)
    }

    // Text fields should be empty by default because we don't want to prefill
    // biometric fields with placeholder text that could be submitted as real data.
    @Test func defaultBiometricFieldsAreEmpty() {
        let controller = CheckInController()
        #expect(controller.sleepHoursText.isEmpty)
        #expect(controller.hrvText.isEmpty)
        #expect(controller.restingHRText.isEmpty)
    }

    // Passing nil should be a no-op — the default values must remain unchanged.
    @Test func prefillWithNilSnapshotLeavesDefaultsUnchanged() {
        let controller = CheckInController()
        controller.prefill(from: nil)
        #expect(controller.sleepHoursText.isEmpty)
        #expect(controller.hrvText.isEmpty)
        #expect(controller.restingHRText.isEmpty)
        #expect(controller.workoutLoad == 5)
    }

    // A full snapshot should populate all three text fields and update workoutLoad.
    @Test func prefillWithCompleteSnapshotFillsAllFields() {
        let controller = CheckInController()
        let snapshot   = HealthKitSnapshot(
            sleepHours:  7.5,
            hrvMs:       65.0,
            restingHR:   58.0,
            workoutLoad: 7.0
        )
        controller.prefill(from: snapshot)
        #expect(controller.sleepHoursText == "7.5")
        #expect(controller.hrvText        == "65")
        #expect(controller.restingHRText  == "58")
        #expect(controller.workoutLoad    == 7.0)
    }

    // When the snapshot has only some values the controller should fill what
    // is available and leave the rest empty/at defaults.
    @Test func prefillWithPartialSnapshotOnlyFillsAvailableFields() {
        let controller = CheckInController()
        // Only sleep is present; HRV and resting HR are nil
        let snapshot = HealthKitSnapshot(sleepHours: 8.0, hrvMs: nil, restingHR: nil)
        controller.prefill(from: snapshot)
        #expect(controller.sleepHoursText == "8.0")
        #expect(controller.hrvText.isEmpty)
        #expect(controller.restingHRText.isEmpty)
        // workoutLoad should fall back to default 5 because snapshot has nil here
        #expect(controller.workoutLoad == 5)
    }

    // reset() should return everything to factory defaults even after the
    // user has changed every slider.
    @Test func resetRestoresAllDefaultValues() {
        let controller = CheckInController()
        // Simulate user input
        controller.soreness           = 3
        controller.energy             = 8
        controller.stress             = 2
        controller.hydration          = 9
        controller.mood               = 7
        controller.nutritionAdherence = 6
        controller.workoutLoad        = 8
        controller.sleepHoursText     = "7.5"
        controller.hrvText            = "65"
        controller.restingHRText      = "58"

        controller.reset()

        #expect(controller.soreness           == 5)
        #expect(controller.energy             == 5)
        #expect(controller.stress             == 5)
        #expect(controller.hydration          == 5)
        #expect(controller.mood               == 5)
        #expect(controller.nutritionAdherence == 5)
        #expect(controller.workoutLoad        == 5)
        #expect(controller.sleepHoursText.isEmpty)
        #expect(controller.hrvText.isEmpty)
        #expect(controller.restingHRText.isEmpty)
    }
}

// MARK: - User Profile Model Tests

// Tests for the UserProfile model defaults and key business rules.
// These run without a SwiftData container because @Model instances can be
// created in memory and their properties read without a persistent store.
@Suite("User Profile Model")
struct UserProfileTests {

    // The onboarding flow relies on onboardingCompleted starting as false —
    // if it were true by default the user would be sent straight to the dashboard
    // on first launch and skip the setup screens entirely.
    @Test func onboardingCompletedDefaultsToFalse() {
        let profile = UserProfile()
        #expect(profile.onboardingCompleted == false)
    }

    // Notifications are opt-in by design, but the default is true so new users
    // receive the morning check-in reminder without needing to dig into Settings.
    @Test func notificationsEnabledDefaultsToTrue() {
        let profile = UserProfile()
        #expect(profile.notificationsEnabled == true)
    }

    // Baseline biometrics must be nil for a new user because the app needs at
    // least 7 days of data before it can calculate a personal baseline.
    // A non-nil default would make the deviation detection meaningless from day one.
    @Test func baselineBiometricsAreNilForNewProfile() {
        let profile = UserProfile()
        #expect(profile.baselineHRV       == nil)
        #expect(profile.baselineRestingHR == nil)
    }

    // intensity drives a slider bound directly to this value, so it must sit in
    // the middle (0.5) by default — not at an extreme that would misrepresent
    // the user's training load before they have completed the onboarding slider.
    @Test func defaultIntensityIsMidpoint() {
        let profile = UserProfile()
        #expect(profile.intensity == 0.5)
    }

    // intensity must stay within 0.0-1.0 for the slider binding to work correctly.
    @Test func defaultIntensityIsWithinValidRange() {
        let profile = UserProfile()
        #expect(profile.intensity >= 0.0)
        #expect(profile.intensity <= 1.0)
    }

    // No upcoming event should be assumed for new users — the event date fields
    // are only relevant after the user explicitly enables this in the goals screen.
    @Test func hasUpcomingEventDefaultsToFalse() {
        let profile = UserProfile()
        #expect(profile.hasUpcomingEvent  == false)
        #expect(profile.upcomingEventDate == nil)
    }

    // Every profile must have a unique ID so the app can distinguish records
    // when multiple profiles exist temporarily during a cloud sync.
    @Test func eachProfileGetsAUniqueID() {
        let a = UserProfile()
        let b = UserProfile()
        #expect(a.id != b.id)
    }

    // The default goal key must be a valid option that the UI knows how to render.
    // An unexpected key would silently fall through to the wrong UI state.
    @Test func defaultFitnessGoalIsValidKey() {
        let validGoals = ["fat_loss", "muscle_gain", "performance", "general_health"]
        let profile    = UserProfile()
        #expect(validGoals.contains(profile.fitnessGoal))
    }

    // Verify the default experience level is one of the three accepted string keys.
    @Test func defaultExperienceLevelIsValidKey() {
        let validLevels = ["beginner", "intermediate", "advanced"]
        let profile     = UserProfile()
        #expect(validLevels.contains(profile.experienceLevel))
    }

    // Custom values passed to the initialiser should always override the defaults
    // so onboarding data is not silently ignored.
    @Test func customInitValuesAreStoredCorrectly() {
        let profile = UserProfile(
            name:            "Alex",
            email:           "alex@example.com",
            discipline:      "endurance",
            age:             28,
            intensity:       0.8,
            height:          180,
            weight:          80,
            fitnessGoal:     "performance",
            experienceLevel: "advanced"
        )
        #expect(profile.name            == "Alex")
        #expect(profile.email           == "alex@example.com")
        #expect(profile.discipline      == "endurance")
        #expect(profile.age             == 28)
        #expect(profile.intensity       == 0.8)
        #expect(profile.height          == 180)
        #expect(profile.weight          == 80)
        #expect(profile.fitnessGoal     == "performance")
        #expect(profile.experienceLevel == "advanced")
    }
}

// MARK: - Notification Manager Tests

// Tests for the pure, side-effect-free parts of NotificationManager and for
// the scheduling threshold (score < 50) using the live notification center.
@Suite("Notification Manager")
struct NotificationManagerTests {

    // MARK: DemoNotification enum

    // The icon names are passed directly to Image(systemName:), so a typo would
    // cause a missing icon at runtime with no compile-time error. Testing them
    // here catches that class of mistake early.
    @Test func demoNotificationIcons() {
        #expect(NotificationManager.DemoNotification.checkIn.icon     == "bell.fill")
        #expect(NotificationManager.DemoNotification.lowRecovery.icon == "exclamationmark.heart.fill")
        #expect(NotificationManager.DemoNotification.training.icon    == "figure.run")
    }

    // Titles come from the rawValue of the enum, so this also verifies
    // that the rawValues have not been accidentally changed.
    @Test func demoNotificationTitles() {
        #expect(NotificationManager.DemoNotification.checkIn.title     == "Check-In Reminder")
        #expect(NotificationManager.DemoNotification.lowRecovery.title == "Low Recovery Alert")
        #expect(NotificationManager.DemoNotification.training.title    == "Training Recommendation")
    }

    // The low-recovery subtitle explicitly mentions the "50" threshold so users
    // understand why they are receiving the alert.
    @Test func lowRecoverySubtitleMentionsThreshold() {
        let subtitle = NotificationManager.DemoNotification.lowRecovery.subtitle
        #expect(subtitle.contains("50"))
    }

    // CaseIterable conformance is used in the Settings screen to build the demo
    // notification list dynamically, so all three cases must be present.
    @Test func demoNotificationHasThreeCases() {
        #expect(NotificationManager.DemoNotification.allCases.count == 3)
    }

    // All notification bodies must be non-empty — a blank notification body
    // would look broken on the lock screen.
    @Test func demoNotificationBodiesAreNotEmpty() {
        for type in NotificationManager.DemoNotification.allCases {
            #expect(!type.body.isEmpty, "Body for \(type.rawValue) must not be empty")
        }
    }

    // MARK: Recovery alert threshold

    // The core business rule: a score below 50 should produce a pending
    // notification request, and the body should contain the exact score.
    @Test func lowScoreSchedulesRecoveryAlert() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        NotificationManager.shared.scheduleRecoveryAlertIfNeeded(score: 30)

        // getPendingNotificationRequests is callback-based so we bridge it to async.
        let pending = await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }

        let alerts = pending.filter { $0.identifier.hasPrefix("recovery-alert-") }
        #expect(!alerts.isEmpty, "A recovery alert should be scheduled when score is 30")
        // Verify the score number is embedded in the notification body so the
        // user sees their actual score, not a generic message.
        #expect(alerts.first?.content.body.contains("30/100") == true)
    }

    // A score of exactly 50 sits at the boundary of the guard condition (< 50),
    // so no alert should fire — this is the most important edge case to verify.
    @Test func scoreOf50DoesNotScheduleAlert() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        NotificationManager.shared.scheduleRecoveryAlertIfNeeded(score: 50)

        let pending = await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }

        let alerts = pending.filter { $0.identifier.hasPrefix("recovery-alert-") }
        #expect(alerts.isEmpty, "No alert should be scheduled when score is exactly 50")
    }

    // A perfect score should definitely not trigger a low-recovery alert.
    @Test func highScoreDoesNotScheduleAlert() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        NotificationManager.shared.scheduleRecoveryAlertIfNeeded(score: 95)

        let pending = await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }

        let alerts = pending.filter { $0.identifier.hasPrefix("recovery-alert-") }
        #expect(alerts.isEmpty, "No alert should be scheduled when score is 95")
    }
}
