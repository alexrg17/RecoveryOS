//
//  ContentView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 16/03/2026.
//

import SwiftUI
import SwiftData
import Supabase

// All possible screens the app can show, used to drive navigation from a single
// state variable rather than pushing/popping a navigation stack. This makes it
// straightforward to jump directly to any screen from anywhere in the app.
enum AppScreen {
    case welcome, login, signUp, onboarding, healthSync, goalsSetup, dashboard
}

struct ContentView: View {
    @State private var screen: AppScreen

    @Environment(\.modelContext) private var modelContext
    // These queries let ContentView sync cloud data into SwiftData on launch
    // without needing to pass a context down through multiple view layers.
    @Query private var profiles: [UserProfile]
    @Query private var checkIns: [DailyCheckIn]

    init() {
        // Decide the starting screen before the view appears so there is no
        // visible flash between the welcome screen and the dashboard on relaunch.
        // UserDefaults is used here rather than SwiftData because @Query results
        // are not available inside init().
        let loggedIn  = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let onboarded = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if loggedIn && onboarded {
            _screen = State(initialValue: .dashboard)
        } else if loggedIn {
            // User signed in previously but never finished onboarding, so send them back.
            _screen = State(initialValue: .onboarding)
        } else {
            _screen = State(initialValue: .welcome)
        }
    }

    var body: some View {
        // ZStack is used instead of NavigationStack because we need full control
        // over transitions and want to be able to jump back to welcome from anywhere
        // without unwinding a navigation hierarchy.
        ZStack {
            switch screen {

            case .welcome:
                WelcomeView(
                    onGetStarted: { transition(to: .signUp) },
                    onSignIn:     { transition(to: .login)  }
                )
                // Simple fade for the root screen since there is no "direction" to convey.
                .transition(.opacity)

            case .login:
                LoginView(
                    onSignedIn:      { transitionToDashboard() },
                    onCreateAccount: { transition(to: .signUp) }
                )
                // Slides in from the right and exits to the left to give a sense of
                // moving forward through a linear flow.
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .signUp:
                SignUpView(
                    onAccountCreated: { transition(to: .onboarding) },
                    onSignIn:         { transition(to: .login) }
                )
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .onboarding:
                OnboardingView(onFinished: { transition(to: .healthSync) })
                    .transition(.asymmetric(
                        insertion:  .move(edge: .trailing).combined(with: .opacity),
                        removal:    .move(edge: .leading).combined(with: .opacity)
                    ))

            case .healthSync:
                HealthSyncView(
                    onSynced:  { transition(to: .goalsSetup) },
                    onSkipped: { transition(to: .goalsSetup) }
                )
                .transition(.asymmetric(
                    insertion:  .move(edge: .trailing).combined(with: .opacity),
                    removal:    .move(edge: .leading).combined(with: .opacity)
                ))

            case .goalsSetup:
                GoalsSetupView(onFinished: { transitionToDashboard() })
                    .transition(.asymmetric(
                        insertion:  .move(edge: .trailing).combined(with: .opacity),
                        removal:    .move(edge: .leading).combined(with: .opacity)
                    ))

            case .dashboard:
                DashboardView(onSignedOut: { transition(to: .welcome) })
                    // Fade rather than slide for the dashboard because it is not part
                    // of the onboarding sequence and the direction would be ambiguous.
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: screen)
        // Check the Supabase session token is still valid every time the app launches.
        // This catches expired sessions without waiting for the user to try an action.
        .task { await verifySession() }
    }

    // MARK: - Navigation

    private func transition(to next: AppScreen) {
        withAnimation(.easeInOut(duration: 0.4)) { screen = next }
    }

    // Navigates to the dashboard and immediately kicks off a cloud sync in the background.
    // Doing both together means the dashboard data is as fresh as possible by the time
    // the user starts interacting with it.
    private func transitionToDashboard() {
        transition(to: .dashboard)
        Task { await restoreUserData() }
    }

    // MARK: - Session verification

    // Supabase JWT tokens expire after a set period. Trying to fetch the session
    // throws an error when it has expired, which we use as the signal to log out.
    // This prevents the app getting stuck on the dashboard with an invalid token.
    private func verifySession() async {
        guard screen == .dashboard else { return }
        do {
            _ = try await supabase.auth.session
            await restoreUserData()
        } catch {
            await MainActor.run {
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                transition(to: .welcome)
            }
        }
    }

    // MARK: - Cloud data restore

    // Pulls the user's profile, check-ins, and preferences from Supabase and
    // merges them into the local SwiftData store. Safe to call on every launch
    // because it checks for existing records before inserting new ones.
    private func restoreUserData() async {
        do {
            // ── Profile ───────────────────────────────────────────────────────
            // Fetch the auth user's real email first so we always use it as truth
            let authEmail = (try? await supabase.auth.session.user.email) ?? ""

            if let remote = try await SupabaseService.shared.fetchProfile() {
                await MainActor.run {
                    // Wipe any profiles that don't belong to the current auth user
                    let mismatch = profiles.filter { $0.email != authEmail }
                    mismatch.forEach { modelContext.delete($0) }
                    if !mismatch.isEmpty { try? modelContext.save() }

                    // Always overwrite the email field with the real auth email
                    var correctedRemote = remote
                    correctedRemote.email = authEmail

                    if let local = profiles.first {
                        // Update existing local record from cloud
                        local.name                = correctedRemote.name
                        local.email               = correctedRemote.email
                        local.discipline          = correctedRemote.discipline
                        local.age                 = correctedRemote.age
                        local.intensity           = correctedRemote.intensity
                        local.height              = correctedRemote.height
                        local.weight              = correctedRemote.weight
                        local.targetWeight        = correctedRemote.targetWeight
                        local.fitnessGoal         = correctedRemote.fitnessGoal
                        local.experienceLevel     = correctedRemote.experienceLevel
                        local.trainingDaysPerWeek = correctedRemote.trainingDaysPerWeek
                        local.sport               = correctedRemote.sport
                        local.hasUpcomingEvent    = correctedRemote.hasUpcomingEvent
                        local.upcomingEventDate   = correctedRemote.upcomingEventDate
                        local.baselineHRV         = correctedRemote.baselineHrv
                        local.baselineRestingHR   = correctedRemote.baselineRestingHr
                        local.notificationsEnabled = correctedRemote.notificationsEnabled
                        local.onboardingCompleted = correctedRemote.onboardingCompleted
                    } else {
                        // No local profile — create from cloud data
                        let profile = UserProfile(
                            name:                 correctedRemote.name,
                            email:                correctedRemote.email,
                            discipline:           correctedRemote.discipline,
                            age:                  correctedRemote.age,
                            intensity:            correctedRemote.intensity,
                            height:               correctedRemote.height,
                            weight:               correctedRemote.weight,
                            targetWeight:         correctedRemote.targetWeight,
                            fitnessGoal:          correctedRemote.fitnessGoal,
                            experienceLevel:      correctedRemote.experienceLevel,
                            trainingDaysPerWeek:  correctedRemote.trainingDaysPerWeek,
                            sport:                correctedRemote.sport,
                            hasUpcomingEvent:     correctedRemote.hasUpcomingEvent,
                            upcomingEventDate:    correctedRemote.upcomingEventDate,
                            baselineHRV:          correctedRemote.baselineHrv,
                            baselineRestingHR:    correctedRemote.baselineRestingHr,
                            notificationsEnabled: correctedRemote.notificationsEnabled,
                            onboardingCompleted:  correctedRemote.onboardingCompleted
                        )
                        modelContext.insert(profile)
                    }
                    try? modelContext.save()
                }
            }

            // ── Preferences ───────────────────────────────────────────────────
            if let prefs = try await SupabaseService.shared.fetchPreferences() {
                await MainActor.run {
                    SupabaseService.shared.restorePreferences(prefs)
                }
            }

            // ── Check-ins ─────────────────────────────────────────────────────
            let remoteCheckIns = try await SupabaseService.shared.fetchCheckIns()
            await MainActor.run {
                let existingIds = Set(checkIns.map(\.id))
                for remote in remoteCheckIns where !existingIds.contains(remote.id) {
                    let checkIn = DailyCheckIn(
                        id:                 remote.id,
                        date:               remote.date,
                        soreness:           remote.soreness,
                        energy:             remote.energy,
                        stress:             remote.stress,
                        hydration:          remote.hydration,
                        mood:               remote.mood,
                        nutritionAdherence: remote.nutritionAdherence,
                        sleepHours:         remote.sleepHours,
                        hrvMs:              remote.hrvMs,
                        restingHR:          remote.restingHr,
                        workoutLoad:        remote.workoutLoad,
                        activeCalories:     remote.activeCalories,
                        stepCount:          remote.stepCount,
                        restingEnergy:      remote.restingEnergy,
                        exerciseMinutes:    remote.exerciseMinutes,
                        readinessScore:     remote.readinessScore
                    )
                    modelContext.insert(checkIn)
                }
                try? modelContext.save()
            }
        } catch {
            // Non-fatal — local SwiftData is still the source of truth while offline
            print("[SupabaseService] restoreUserData failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DailyCheckIn.self, inMemory: true)
}
