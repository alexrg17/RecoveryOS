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

    // Baseline values (learned over first 7 days)
    var baselineHRV: Double?
    var baselineRestingHR: Double?

    // Preferences
    var notificationsEnabled: Bool
    var onboardingCompleted: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        baselineHRV: Double? = nil,
        baselineRestingHR: Double? = nil,
        notificationsEnabled: Bool = true,
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.baselineHRV = baselineHRV
        self.baselineRestingHR = baselineRestingHR
        self.notificationsEnabled = notificationsEnabled
        self.onboardingCompleted = onboardingCompleted
    }
}
