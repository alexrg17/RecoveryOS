//
//  CheckInController.swift
//  RecoveryOS
//

import Foundation
import Combine
import SwiftData

// Handles all the business logic for the morning check-in so that CheckInView
// only has to worry about rendering the UI and forwarding user actions here.
// @MainActor ensures that all @Published updates happen on the main thread,
// which is required when SwiftUI observes these properties for re-rendering.
@MainActor
final class CheckInController: ObservableObject {

    // MARK: - Form state

    // Each slider field is @Published so CheckInView can bind directly to it.
    // Starting at 5 (middle of the 1-10 scale) avoids biasing the score
    // if the user submits without moving a particular slider.
    @Published var soreness:           Double = 5
    @Published var energy:             Double = 5
    @Published var stress:             Double = 5
    @Published var hydration:          Double = 5
    @Published var mood:               Double = 5
    @Published var nutritionAdherence: Double = 5

    // Text fields for biometrics that may be pre-filled from HealthKit.
    // Stored as strings so they can be bound directly to TextField without
    // a formatter, and converted to Double only at submission time.
    @Published var sleepHoursText: String = ""
    @Published var hrvText:        String = ""
    @Published var restingHRText:  String = ""
    @Published var workoutLoad:    Double = 5

    // MARK: - HealthKit prefill

    // Copies values from today's Apple Health snapshot into the form fields.
    // Called by CheckInView on appear so the user does not have to type in
    // data that was already recorded by their Apple Watch.
    func prefill(from snapshot: HealthKitSnapshot?) {
        guard let s = snapshot else { return }
        sleepHoursText = s.sleepHours.map { String(format: "%.1f", $0) } ?? ""
        hrvText        = s.hrvMs.map      { String(format: "%.0f", $0) } ?? ""
        restingHRText  = s.restingHR.map  { String(format: "%.0f", $0) } ?? ""
        workoutLoad    = s.workoutLoad ?? 5
    }

    // MARK: - Reset

    // Returns everything to neutral defaults. Useful if the user cancels and
    // re-opens the check-in form without the sheet being fully dismissed.
    func reset() {
        soreness = 5; energy = 5; stress = 5
        hydration = 5; mood = 5; nutritionAdherence = 5
        sleepHoursText = ""; hrvText = ""; restingHRText = ""
        workoutLoad = 5
    }

    // MARK: - Submit

    // Creates a DailyCheckIn model object from the current form state,
    // persists it via SwiftData, and triggers a notification if recovery is low.
    // The ModelContext is passed in rather than stored as a property because
    // SwiftData contexts are tied to a specific view hierarchy and should not
    // be held onto by non-view objects.
    func submit(into context: ModelContext) {
        // Calculate the score before creating the record so we can pass it in.
        let score = DailyCheckIn.calculateScore(
            soreness:   Int(soreness),
            energy:     Int(energy),
            stress:     Int(stress),
            hydration:  Int(hydration),
            mood:       Int(mood),
            sleepHours: Double(sleepHoursText)
        )

        let checkIn = DailyCheckIn(
            soreness:           Int(soreness),
            energy:             Int(energy),
            stress:             Int(stress),
            hydration:          Int(hydration),
            mood:               Int(mood),
            nutritionAdherence: Int(nutritionAdherence),
            sleepHours:         Double(sleepHoursText),
            hrvMs:              Double(hrvText),
            restingHR:          Double(restingHRText),
            workoutLoad:        workoutLoad,
            readinessScore:     score
        )

        context.insert(checkIn)

        // Delegate notification scheduling so this controller does not need
        // to know anything about the UNUserNotificationCenter API.
        NotificationManager.shared.scheduleRecoveryAlertIfNeeded(score: score)
    }
}
