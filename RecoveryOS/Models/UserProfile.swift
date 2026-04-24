//
//  UserProfile.swift
//  RecoveryOS
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var createdAt: Date

    // Identity
    var name: String
    var email: String

    // Training profile (onboarding step 1)
    var discipline: String   // "strength" | "endurance"
    var age: Int
    var intensity: Double    // 0.0 = LIT, 1.0 = HIT

    // Body stats (onboarding step 2)
    var height: Double           // cm
    var weight: Double           // kg
    var targetWeight: Double     // kg

    // Fitness goals (onboarding step 2)
    var fitnessGoal: String      // "fat_loss" | "muscle_gain" | "performance" | "general_health"
    var experienceLevel: String  // "beginner" | "intermediate" | "advanced"
    var trainingDaysPerWeek: Int
    var sport: String            // e.g. "Powerlifting", "Running", "CrossFit"

    // Upcoming event
    var hasUpcomingEvent: Bool
    var upcomingEventDate: Date?

    // Baseline values (learned over first 7 days)
    var baselineHRV: Double?
    var baselineRestingHR: Double?

    // Preferences
    var notificationsEnabled: Bool
    var onboardingCompleted: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String = "",
        email: String = "",
        discipline: String = "strength",
        age: Int = 25,
        intensity: Double = 0.5,
        height: Double = 175,
        weight: Double = 75,
        targetWeight: Double = 75,
        fitnessGoal: String = "general_health",
        experienceLevel: String = "intermediate",
        trainingDaysPerWeek: Int = 4,
        sport: String = "",
        hasUpcomingEvent: Bool = false,
        upcomingEventDate: Date? = nil,
        baselineHRV: Double? = nil,
        baselineRestingHR: Double? = nil,
        notificationsEnabled: Bool = true,
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.email = email
        self.discipline = discipline
        self.age = age
        self.intensity = intensity
        self.height = height
        self.weight = weight
        self.targetWeight = targetWeight
        self.fitnessGoal = fitnessGoal
        self.experienceLevel = experienceLevel
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.sport = sport
        self.hasUpcomingEvent = hasUpcomingEvent
        self.upcomingEventDate = upcomingEventDate
        self.baselineHRV = baselineHRV
        self.baselineRestingHR = baselineRestingHR
        self.notificationsEnabled = notificationsEnabled
        self.onboardingCompleted = onboardingCompleted
    }
}
