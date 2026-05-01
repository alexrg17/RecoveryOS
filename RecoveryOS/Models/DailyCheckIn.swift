//
//  DailyCheckIn.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import Foundation
import SwiftData

// @Model tells SwiftData to persist this class to the on-device SQLite store automatically.
// Using a class rather than a struct is required by SwiftData so it can track changes by reference.
@Model
final class DailyCheckIn {
    // UUID gives each record a guaranteed unique ID even if two check-ins are created
    // at the same millisecond, which can happen during testing or rapid input.
    var id: UUID
    var date: Date

    // Subjective wellbeing scores collected through the morning check-in form.
    // All are on a 1-10 scale so they can be normalised consistently in calculateScore().
    var soreness: Int
    var energy: Int
    var stress: Int
    var hydration: Int
    var mood: Int

    // Biometric fields are optional because HealthKit data may not be available
    // (user could decline permission, or the Apple Watch may not have synced yet).
    // Storing nil is better than storing 0, which would skew the trend charts.
    var sleepHours: Double?
    var hrvMs: Double?
    var restingHR: Double?
    var workoutLoad: Double?
    var activeCalories: Double?
    var stepCount: Double?
    var restingEnergy: Double?
    var exerciseMinutes: Double?

    // How well the user stuck to their nutrition plan today, logged as part of the check-in.
    // Kept separate from the biometrics block because it is always manually entered.
    var nutritionAdherence: Int

    // The readiness score is calculated after submission and stored here so it can be
    // displayed on the dashboard and used in trend charts without recalculating each time.
    var readinessScore: Int?

    // All parameters default to neutral values so callers only need to pass what they have.
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        soreness: Int = 5,
        energy: Int = 5,
        stress: Int = 5,
        hydration: Int = 5,
        mood: Int = 5,
        nutritionAdherence: Int = 5,
        sleepHours: Double? = nil,
        hrvMs: Double? = nil,
        restingHR: Double? = nil,
        workoutLoad: Double? = nil,
        activeCalories: Double? = nil,
        stepCount: Double? = nil,
        restingEnergy: Double? = nil,
        exerciseMinutes: Double? = nil,
        readinessScore: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.soreness = soreness
        self.energy = energy
        self.stress = stress
        self.hydration = hydration
        self.mood = mood
        self.nutritionAdherence = nutritionAdherence
        self.sleepHours = sleepHours
        self.hrvMs = hrvMs
        self.restingHR = restingHR
        self.workoutLoad = workoutLoad
        self.activeCalories = activeCalories
        self.stepCount = stepCount
        self.restingEnergy = restingEnergy
        self.exerciseMinutes = exerciseMinutes
        self.readinessScore = readinessScore
    }

    // Produces a single 0-100 readiness score from the check-in inputs.
    // This is a static function so it can be called without a saved instance,
    // for example to preview the score before deciding whether to submit.
    static func calculateScore(
        soreness: Int, energy: Int, stress: Int,
        hydration: Int, mood: Int,
        sleepHours: Double? = nil
    ) -> Int {
        // Each metric is first normalised to 0.0-1.0 before applying the weight.
        // Soreness and stress are inverted because a LOW score on those is actually good.
        let s  = Double(10 - soreness) / 9.0
        let e  = Double(energy - 1)    / 9.0
        let st = Double(10 - stress)   / 9.0
        let h  = Double(hydration - 1) / 9.0
        let m  = Double(mood - 1)      / 9.0

        // Energy carries the most weight (25%) because it is the clearest signal
        // of how ready the central nervous system is for training.
        // Soreness, stress, and mood share the remaining weight roughly equally.
        // Hydration gets 15% because it influences performance but is easy to fix.
        var score = s * 0.20 + e * 0.25 + st * 0.20 + h * 0.15 + m * 0.20

        // Sleep is treated as a bonus input because it is not always available.
        // When present it adjusts the score by up to 20%, treating 8 hours as the
        // target based on general sports science recommendations.
        if let sleep = sleepHours {
            let sleepNorm = min(sleep / 8.0, 1.0)
            score = score * 0.80 + sleepNorm * 0.20
        }

        // Clamp to 0-100 and round before returning so callers always get a clean integer.
        return max(0, min(100, Int((score * 100).rounded())))
    }
}
