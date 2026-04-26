//
//  UserProfile.swift
//  RecoveryOS
//

import Foundation
import SwiftData

// A single UserProfile record is created during onboarding and updated whenever
// the user changes their goals or body stats in Settings.
// The app assumes there is only ever one profile, so views always read profiles.first.
@Model
final class UserProfile {
    var id: UUID
    var createdAt: Date

    // Basic identity fields populated from the Supabase auth session after sign-in.
    var name: String
    var email: String

    // Collected on onboarding step 1 (HealthSyncView).
    // discipline is stored as a string key ("strength" or "endurance") rather than
    // an enum so SwiftData can persist it without a custom transformer.
    var discipline: String
    var age: Int
    // intensity is a 0.0-1.0 continuous value so it can drive a slider directly
    // without any conversion. 0.0 = low intensity training, 1.0 = high intensity.
    var intensity: Double

    // Body stats collected on onboarding step 2 (GoalsSetupView).
    // Stored in metric units (cm, kg) to avoid conversion errors when displaying data.
    var height: Double
    var weight: Double
    var targetWeight: Double

    // The fitnessGoal string key maps to one of four options:
    // "fat_loss", "muscle_gain", "performance", or "general_health".
    // Using string keys makes it easy to add new goal types later without a migration.
    var fitnessGoal: String
    var experienceLevel: String   // "beginner", "intermediate", or "advanced"
    var trainingDaysPerWeek: Int
    var sport: String             // free-text field, e.g. "Powerlifting" or "Running"

    // Optional upcoming competition that the AI coach uses to adjust its advice,
    // for example recommending a taper week if the event is within two weeks.
    var hasUpcomingEvent: Bool
    var upcomingEventDate: Date?  // nil when hasUpcomingEvent is false

    // Baseline biometrics are learned over the first 7 days of use.
    // They are optional because new users have not yet built up enough data.
    // Once established, they let the app detect meaningful deviations rather than
    // comparing against population averages.
    var baselineHRV: Double?
    var baselineRestingHR: Double?

    // Simple flags to track whether the user has completed setup.
    var notificationsEnabled: Bool
    var onboardingCompleted: Bool

    // Sensible defaults are set here so a fresh profile is valid straight away,
    // even if the user skips certain onboarding steps.
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
