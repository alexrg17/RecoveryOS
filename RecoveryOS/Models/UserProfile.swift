//
//  UserProfile.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var createdAt: Date

    // Identity (set during sign up)
    var name: String
    var email: String

    // Training profile (set during health sync)
    var discipline: String   // "strength" | "endurance"
    var age: Int
    var intensity: Double    // 0.0 = LIT, 1.0 = HIT

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
        self.baselineHRV = baselineHRV
        self.baselineRestingHR = baselineRestingHR
        self.notificationsEnabled = notificationsEnabled
        self.onboardingCompleted = onboardingCompleted
    }
}
