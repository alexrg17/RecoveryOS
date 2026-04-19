//
//  DailyCheckIn.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import Foundation
import SwiftData

@Model
final class DailyCheckIn {
    var id: UUID
    var date: Date

    // Manual check-in fields (1–10 scale)
    var soreness: Int
    var energy: Int
    var stress: Int
    var hydration: Int
    var mood: Int

    // Biometric fields (optional — auto-filled from HealthKit or entered manually)
    var sleepHours: Double?
    var hrvMs: Double?
    var restingHR: Double?
    var workoutLoad: Double?

    // Readiness score (0–100, calculated after check-in)
    var readinessScore: Int?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        soreness: Int = 5,
        energy: Int = 5,
        stress: Int = 5,
        hydration: Int = 5,
        mood: Int = 5,
        sleepHours: Double? = nil,
        hrvMs: Double? = nil,
        restingHR: Double? = nil,
        workoutLoad: Double? = nil,
        readinessScore: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.soreness = soreness
        self.energy = energy
        self.stress = stress
        self.hydration = hydration
        self.mood = mood
        self.sleepHours = sleepHours
        self.hrvMs = hrvMs
        self.restingHR = restingHR
        self.workoutLoad = workoutLoad
        self.readinessScore = readinessScore
    }

    /// Calculates a 0–100 recovery score from check-in inputs.
    /// Soreness and stress are inverted (lower = better).
    static func calculateScore(
        soreness: Int, energy: Int, stress: Int,
        hydration: Int, mood: Int,
        sleepHours: Double? = nil
    ) -> Int {
        let s  = Double(10 - soreness) / 9.0  // invert: low soreness = good
        let e  = Double(energy - 1)    / 9.0
        let st = Double(10 - stress)   / 9.0  // invert: low stress = good
        let h  = Double(hydration - 1) / 9.0
        let m  = Double(mood - 1)      / 9.0

        var score = s * 0.20 + e * 0.25 + st * 0.20 + h * 0.15 + m * 0.20

        if let sleep = sleepHours {
            let sleepNorm = min(sleep / 8.0, 1.0)  // 8h = perfect
            score = score * 0.80 + sleepNorm * 0.20
        }

        return max(0, min(100, Int((score * 100).rounded())))
    }
}
