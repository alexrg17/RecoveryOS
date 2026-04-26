//
//  SupabaseService.swift
//  RecoveryOS
//
//  Handles all Supabase database sync — profiles, check-ins, preferences.
//  Auth is handled separately via SupabaseManager.swift.
//

import Foundation
import Supabase

// MARK: - Codable row types (snake_case matches DB columns)

struct SupabaseUserProfile: Codable {
    var id: UUID
    var name: String
    var email: String
    var discipline: String
    var age: Int
    var intensity: Double
    var height: Double
    var weight: Double
    var targetWeight: Double
    var fitnessGoal: String
    var experienceLevel: String
    var trainingDaysPerWeek: Int
    var sport: String
    var hasUpcomingEvent: Bool
    var upcomingEventDate: Date?
    var baselineHrv: Double?
    var baselineRestingHr: Double?
    var notificationsEnabled: Bool
    var onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case discipline
        case age
        case intensity
        case height
        case weight
        case targetWeight         = "target_weight"
        case fitnessGoal          = "fitness_goal"
        case experienceLevel      = "experience_level"
        case trainingDaysPerWeek  = "training_days_per_week"
        case sport
        case hasUpcomingEvent     = "has_upcoming_event"
        case upcomingEventDate    = "upcoming_event_date"
        case baselineHrv          = "baseline_hrv"
        case baselineRestingHr    = "baseline_resting_hr"
        case notificationsEnabled = "notifications_enabled"
        case onboardingCompleted  = "onboarding_completed"
    }
}

struct SupabaseCheckIn: Codable {
    var id: UUID
    var userId: UUID
    var date: Date
    var soreness: Int
    var energy: Int
    var stress: Int
    var hydration: Int
    var mood: Int
    var nutritionAdherence: Int
    var sleepHours: Double?
    var hrvMs: Double?
    var restingHr: Double?
    var workoutLoad: Double?
    var activeCalories: Double?
    var stepCount: Double?
    var restingEnergy: Double?
    var exerciseMinutes: Double?
    var readinessScore: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId             = "user_id"
        case date
        case soreness
        case energy
        case stress
        case hydration
        case mood
        case nutritionAdherence = "nutrition_adherence"
        case sleepHours         = "sleep_hours"
        case hrvMs              = "hrv_ms"
        case restingHr          = "resting_hr"
        case workoutLoad        = "workout_load"
        case activeCalories     = "active_calories"
        case stepCount          = "step_count"
        case restingEnergy      = "resting_energy"
        case exerciseMinutes    = "exercise_minutes"
        case readinessScore     = "readiness_score"
    }
}

struct SupabasePreferences: Codable {
    var id: UUID
    var bedtimeHour: Int
    var bedtimeMinute: Int
    var bedtimeReminder: Bool
    var windDownMinutes: Double
    var hydrationTargetLiters: Double
    var hydrationUnit: String
    var hydrationReminder: Bool
    var trainingIntensityBias: String
    var dailyStrainTarget: Double
    var autoRestDay: Bool
    var recoveryReminders: Bool
    var biometricUnlock: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case bedtimeHour            = "bedtime_hour"
        case bedtimeMinute          = "bedtime_minute"
        case bedtimeReminder        = "bedtime_reminder"
        case windDownMinutes        = "wind_down_minutes"
        case hydrationTargetLiters  = "hydration_target_liters"
        case hydrationUnit          = "hydration_unit"
        case hydrationReminder      = "hydration_reminder"
        case trainingIntensityBias  = "training_intensity_bias"
        case dailyStrainTarget      = "daily_strain_target"
        case autoRestDay            = "auto_rest_day"
        case recoveryReminders      = "recovery_reminders"
        case biometricUnlock        = "biometric_unlock"
    }
}

// MARK: - Service

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    // MARK: - Profile

    func upsertProfile(_ profile: UserProfile) async throws {
        let user   = try await supabase.auth.session.user
        let userId = user.id
        // Always use the Supabase auth email as the source of truth —
        // never trust the locally-stored email which may be from a stale account.
        let row = SupabaseUserProfile(
            id: userId,
            name: profile.name,
            email: user.email ?? profile.email,
            discipline: profile.discipline,
            age: profile.age,
            intensity: profile.intensity,
            height: profile.height,
            weight: profile.weight,
            targetWeight: profile.targetWeight,
            fitnessGoal: profile.fitnessGoal,
            experienceLevel: profile.experienceLevel,
            trainingDaysPerWeek: profile.trainingDaysPerWeek,
            sport: profile.sport,
            hasUpcomingEvent: profile.hasUpcomingEvent,
            upcomingEventDate: profile.upcomingEventDate,
            baselineHrv: profile.baselineHRV,
            baselineRestingHr: profile.baselineRestingHR,
            notificationsEnabled: profile.notificationsEnabled,
            onboardingCompleted: profile.onboardingCompleted
        )
        try await supabase
            .from("user_profiles")
            .upsert(row)
            .execute()
    }

    func fetchProfile() async throws -> SupabaseUserProfile? {
        let userId = try await supabase.auth.session.user.id
        let rows: [SupabaseUserProfile] = try await supabase
            .from("user_profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Check-ins

    func upsertCheckIn(_ checkIn: DailyCheckIn) async throws {
        let userId = try await supabase.auth.session.user.id
        let row = SupabaseCheckIn(
            id: checkIn.id,
            userId: userId,
            date: checkIn.date,
            soreness: checkIn.soreness,
            energy: checkIn.energy,
            stress: checkIn.stress,
            hydration: checkIn.hydration,
            mood: checkIn.mood,
            nutritionAdherence: checkIn.nutritionAdherence,
            sleepHours: checkIn.sleepHours,
            hrvMs: checkIn.hrvMs,
            restingHr: checkIn.restingHR,
            workoutLoad: checkIn.workoutLoad,
            activeCalories: checkIn.activeCalories,
            stepCount: checkIn.stepCount,
            restingEnergy: checkIn.restingEnergy,
            exerciseMinutes: checkIn.exerciseMinutes,
            readinessScore: checkIn.readinessScore
        )
        try await supabase
            .from("daily_check_ins")
            .upsert(row)
            .execute()
    }

    func fetchCheckIns() async throws -> [SupabaseCheckIn] {
        let userId = try await supabase.auth.session.user.id
        let rows: [SupabaseCheckIn] = try await supabase
            .from("daily_check_ins")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
        return rows
    }

    // MARK: - Preferences
    // Reads all preference keys from UserDefaults and syncs to Supabase.
    // Call this from any preference view's onDisappear.

    func syncAllPreferences() async throws {
        let userId = try await supabase.auth.session.user.id
        let d = UserDefaults.standard
        let row = SupabasePreferences(
            id: userId,
            bedtimeHour:            d.object(forKey: "bedtimeHour") != nil ? d.integer(forKey: "bedtimeHour") : 22,
            bedtimeMinute:          d.integer(forKey: "bedtimeMinute"),
            bedtimeReminder:        d.object(forKey: "bedtimeReminder") != nil ? d.bool(forKey: "bedtimeReminder") : true,
            windDownMinutes:        d.object(forKey: "windDownMinutes") != nil ? d.double(forKey: "windDownMinutes") : 30,
            hydrationTargetLiters:  d.object(forKey: "hydrationTargetLiters") != nil ? d.double(forKey: "hydrationTargetLiters") : 2.5,
            hydrationUnit:          d.string(forKey: "hydrationUnit") ?? "L",
            hydrationReminder:      d.bool(forKey: "hydrationReminder"),
            trainingIntensityBias:  d.string(forKey: "trainingIntensityBias") ?? "LIT",
            dailyStrainTarget:      d.object(forKey: "dailyStrainTarget") != nil ? d.double(forKey: "dailyStrainTarget") : 6.0,
            autoRestDay:            d.object(forKey: "autoRestDay") != nil ? d.bool(forKey: "autoRestDay") : true,
            recoveryReminders:      d.object(forKey: "recoveryReminders") != nil ? d.bool(forKey: "recoveryReminders") : true,
            biometricUnlock:        d.object(forKey: "biometricUnlock") != nil ? d.bool(forKey: "biometricUnlock") : true
        )
        try await supabase
            .from("user_preferences")
            .upsert(row)
            .execute()
    }

    func fetchPreferences() async throws -> SupabasePreferences? {
        let userId = try await supabase.auth.session.user.id
        let rows: [SupabasePreferences] = try await supabase
            .from("user_preferences")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        return rows.first
    }

    // Writes fetched preferences back to UserDefaults so all @AppStorage keys are restored.
    func restorePreferences(_ prefs: SupabasePreferences) {
        let d = UserDefaults.standard
        d.set(prefs.bedtimeHour,           forKey: "bedtimeHour")
        d.set(prefs.bedtimeMinute,         forKey: "bedtimeMinute")
        d.set(prefs.bedtimeReminder,       forKey: "bedtimeReminder")
        d.set(prefs.windDownMinutes,       forKey: "windDownMinutes")
        d.set(prefs.hydrationTargetLiters, forKey: "hydrationTargetLiters")
        d.set(prefs.hydrationUnit,         forKey: "hydrationUnit")
        d.set(prefs.hydrationReminder,     forKey: "hydrationReminder")
        d.set(prefs.trainingIntensityBias, forKey: "trainingIntensityBias")
        d.set(prefs.dailyStrainTarget,     forKey: "dailyStrainTarget")
        d.set(prefs.autoRestDay,           forKey: "autoRestDay")
        d.set(prefs.recoveryReminders,     forKey: "recoveryReminders")
        d.set(prefs.biometricUnlock,       forKey: "biometricUnlock")
    }
}
