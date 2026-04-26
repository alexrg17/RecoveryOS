//
//  SettingsView.swift
//  RecoveryOS
//
//  Created by Richy James on 11/04/2026.
//

import SwiftUI
import SwiftData
import UIKit
import Supabase

// MARK: - SettingsView
struct SettingsView: View {

    var onSignedOut: () -> Void

    @AppStorage("isLoggedIn")             private var isLoggedIn = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("healthKitEnabled")       private var healthKitEnabled = false
    @ObservedObject private var healthKit = HealthKitManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var checkIns: [DailyCheckIn]

    private var profile: UserProfile? { profiles.first }

    // AppStorage — mirrors keys used in the destination preference views
    @AppStorage("bedtimeHour")           private var bedtimeHour: Int = 22
    @AppStorage("bedtimeMinute")         private var bedtimeMinute: Int = 30
    @AppStorage("hydrationTargetLiters") private var hydrationTargetLiters: Double = 2.5
    @AppStorage("hydrationUnit")         private var hydrationUnit: String = "L"
    @AppStorage("trainingIntensityBias") private var trainingIntensityBias: String = "LIT"

    // Toggles — backed by AppStorage so they survive view dismissal
    @AppStorage("recoveryReminders") private var recoveryReminders = true
    @AppStorage("biometricUnlock")   private var biometricUnlock   = true
    @State private var showHealthPermissionsSheet = false

    // Entrance animations
    @State private var profileOpacity: Double = 0
    @State private var profileScale: CGFloat  = 0.94
    @State private var sectionsOpacity: Double = 0
    @State private var sectionsSlide: CGFloat  = 20

    // Design tokens
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.38)
    private let valueGray  = Color.white.opacity(0.45)

    // MARK: - Preference display helpers
    private var bedtimeLabel: String {
        let hour12 = bedtimeHour % 12 == 0 ? 12 : bedtimeHour % 12
        let ampm   = bedtimeHour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, bedtimeMinute, ampm)
    }

    private var hydrationLabel: String {
        if hydrationUnit == "L" {
            return String(format: "%.1f L", hydrationTargetLiters)
        }
        let oz = hydrationTargetLiters * 33.814
        return String(format: "%.0f fl oz", oz)
    }

    private var trainingGoalsLabel: String {
        trainingIntensityBias == "HIT" ? "High Intensity" : "Low Intensity"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {

                    // Page title
                    HStack {
                        Text("Profile")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Profile card
                    profileCard
                        .padding(.horizontal, 16)
                        .opacity(profileOpacity)
                        .scaleEffect(profileScale)

                    // Sections
                    VStack(spacing: 16) {
                        accountSection
                        athleteProfileSection
                        recoveryPreferencesSection
                        connectedDevicesSection
                        privacySection
                        signOutButton
                        versionFooter
                    }
                    .padding(.horizontal, 16)
                    .opacity(sectionsOpacity)
                    .offset(y: sectionsSlide)
                }
                .padding(.bottom, 20)
            }
            .scrollContentBackground(.hidden)
            .background(bgPrimary)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { beginAnimations() }
            .sheet(isPresented: $showHealthPermissionsSheet) {
                healthPermissionsSheet
            }
            // Schedule or cancel the daily 8am reminder whenever the toggle changes.
            // Without this handler the AppStorage value updates but the notification
            // queue is never touched, so the toggle would appear to work but do nothing.
            .onChange(of: recoveryReminders) { _, enabled in
                if enabled {
                    NotificationManager.shared.scheduleDailyCheckInReminder()
                } else {
                    NotificationManager.shared.cancelDailyCheckInReminder()
                }
            }
        }
    }

    // MARK: - Apple Health permissions sheet
    private var healthPermissionsSheet: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Icon + title
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.25, blue: 0.35).opacity(0.15))
                                .frame(width: 70, height: 70)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.35))
                        }
                        Text("Apple Health")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("CONNECTED")
                            .font(.system(size: 10, weight: .bold))
                            .kerning(1.2)
                            .foregroundColor(accentTeal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(accentTeal.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(accentTeal.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.top, 20)

                    // Active permissions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("READING FROM HEALTH")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(1.5)
                            .foregroundColor(Color.white.opacity(0.38))
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            permissionItem(icon: "moon.fill", color: Color(red: 0.55, green: 0.35, blue: 0.98), label: "Sleep Analysis")
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                            permissionItem(icon: "waveform.path.ecg", color: accentTeal, label: "Heart Rate Variability")
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                            permissionItem(icon: "heart.fill", color: Color(red: 1.0, green: 0.3, blue: 0.4), label: "Resting Heart Rate")
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 52)
                            permissionItem(icon: "bolt.fill", color: accentBlue, label: "Active Energy Burned")
                        }
                        .background(bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    }

                    // How to manage
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TO MANAGE PERMISSIONS")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(1.5)
                            .foregroundColor(Color.white.opacity(0.38))
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            manageStep(number: "1", text: "Tap \"Open Health App\" below")
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 48)
                            manageStep(number: "2", text: "Tap your profile picture (top right)")
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 48)
                            manageStep(number: "3", text: "Go to Privacy - Apps")
                            Divider().background(Color.white.opacity(0.06)).padding(.leading, 48)
                            manageStep(number: "4", text: "Select RecoveryOS to adjust access")
                        }
                        .background(bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    }

                    // Open button
                    Button(action: {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 16))
                            Text("Open Health App")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 1.0, green: 0.25, blue: 0.35).opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(bgPrimary.ignoresSafeArea())
    }

    private func manageStep(number: String, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accentBlue.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(accentBlue)
            }
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func permissionItem(icon: String, color: Color, label: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accentTeal)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Profile card
    private var profileCard: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(red: 0.18, green: 0.22, blue: 0.35))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.6))
                    )
                    .shadow(color: accentBlue.opacity(0.3), radius: 10)

                Circle()
                    .fill(accentBlue)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 2, y: 2)
            }

            Text(profile?.name.isEmpty == false ? profile!.name : "Athlete")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let age = profile?.age, age > 0 {
                Text("Age \(age)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.45))
            }

            Text(disciplineBadge)
                .font(.system(size: 10, weight: .bold))
                .kerning(1.5)
                .foregroundColor(accentBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(accentBlue.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(accentBlue.opacity(0.3), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Account section
    private var accountSection: some View {
        settingsSection(label: "ACCOUNT") {
            navRow(icon: "person", iconColor: accentBlue, title: "Profile") {
                EditProfileView()
            }
            divider
            navRow(icon: "envelope", iconColor: accentBlue, title: "Email", value: profile?.email ?? "") {
                ChangeEmailView()
            }
            divider
            navRow(icon: "lock", iconColor: accentBlue, title: "Password") {
                ResetPasswordView()
            }
        }
    }

    // MARK: - Athlete Profile section
    private var athleteProfileSection: some View {
        settingsSection(label: "ATHLETE PROFILE") {
            navRow(icon: "target", iconColor: accentTeal, title: "Goals & Body Stats",
                   value: profile.map { goalLabel($0.fitnessGoal) } ?? "") {
                EditGoalsView()
            }
        }
    }

    private func goalLabel(_ key: String) -> String {
        switch key {
        case "fat_loss":      return "Fat Loss"
        case "muscle_gain":   return "Muscle Gain"
        case "performance":   return "Performance"
        default:              return "General Health"
        }
    }

    // MARK: - Recovery Preferences section
    private var recoveryPreferencesSection: some View {
        settingsSection(label: "RECOVERY PREFERENCES") {
            navRow(icon: "figure.run", iconColor: accentTeal, title: "Training Goals", value: trainingGoalsLabel) {
                TrainingGoalsView()
            }
            divider
            navRow(icon: "moon", iconColor: Color(red: 0.55, green: 0.35, blue: 0.98), title: "Bedtime Target", value: bedtimeLabel) {
                BedtimeTargetView()
            }
            divider
            navRow(icon: "drop", iconColor: Color(red: 0.3, green: 0.6, blue: 1.0), title: "Hydration Target", value: hydrationLabel) {
                HydrationTargetView()
            }
            divider
            toggleRow(icon: "bell", iconColor: Color(red: 1.0, green: 0.6, blue: 0.2), title: "Recovery Reminders", isOn: $recoveryReminders)
        }
    }

    // MARK: - Connected Devices section
    private var connectedDevicesSection: some View {
        settingsSection(label: "CONNECTED DEVICES") {
            Button(action: handleAppleHealthTap) {
                HStack {
                    iconCircle("heart.fill", color: Color(red: 1.0, green: 0.25, blue: 0.35))
                    Text("Apple Health")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    let connected = healthKitEnabled && healthKit.isAuthorized
                    Text(connected ? "CONNECTED" : "NOT CONNECTED")
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.8)
                        .foregroundColor(connected ? accentTeal : Color.white.opacity(0.35))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background((connected ? accentTeal : Color.white).opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke((connected ? accentTeal : Color.white).opacity(0.2), lineWidth: 1))
                    chevron
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
        }
    }

    private func handleAppleHealthTap() {
        if healthKitEnabled && healthKit.isAuthorized {
            showHealthPermissionsSheet = true
        } else {
            healthKitEnabled = true
            HealthKitManager.shared.requestAuthorization()
        }
    }

    // MARK: - Privacy & Security section
    private var privacySection: some View {
        settingsSection(label: "PRIVACY & SECURITY") {
            toggleRow(icon: "faceid", iconColor: accentBlue, title: "Biometric Unlock", isOn: $biometricUnlock)
            divider
            navRow(icon: "shield", iconColor: accentBlue, title: "Data Sharing Policy") {
                DataSharingPolicyView()
            }
        }
    }

    // MARK: - Helpers
    private var disciplineBadge: String {
        switch profile?.discipline {
        case "endurance": return "ENDURANCE ATHLETE"
        case "strength":  return "STRENGTH ATHLETE"
        default:          return "ATHLETE"
        }
    }

    // MARK: - Sign out button
    private var signOutButton: some View {
        Button(action: {
            Task {
                try? await supabase.auth.signOut()
                await MainActor.run {
                    // Clear all local data so next user starts fresh
                    profiles.forEach { modelContext.delete($0) }
                    checkIns.forEach  { modelContext.delete($0) }
                    try? modelContext.save()
                    NotificationManager.shared.cancelAllNotifications()
                    isLoggedIn             = false
                    hasCompletedOnboarding = false
                    healthKitEnabled       = false
                    onSignedOut()
                }
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                Text("Sign Out")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Version footer
    private var versionFooter: some View {
        Text("RECOVERYOS V2.4.0")
            .font(.system(size: 10, weight: .medium))
            .kerning(1.2)
            .foregroundColor(.white.opacity(0.18))
            .padding(.top, 4)
            .padding(.bottom, 8)
    }

    // MARK: - Reusable components

    private func settingsSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.5)
                .foregroundColor(labelGray)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func settingsRow(icon: String, iconColor: Color, title: String, value: String? = nil) -> some View {
        HStack {
            iconCircle(icon, color: iconColor)
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(valueGray)
                    .lineLimit(1)
            }
            chevron
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private func navRow<D: View>(icon: String, iconColor: Color, title: String, value: String? = nil, @ViewBuilder destination: () -> D) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                iconCircle(icon, color: iconColor)
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                if let value {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundColor(valueGray)
                        .lineLimit(1)
                }
                chevron
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(icon: String, iconColor: Color, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            iconCircle(icon, color: iconColor)
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accentBlue)
                .scaleEffect(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func iconCircle(_ icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
        }
        .padding(.trailing, 6)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.2))
            .padding(.leading, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.leading, 52)
    }

    // MARK: - Entrance animations
    private func beginAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            profileOpacity = 1
            profileScale   = 1.0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.15)) {
            sectionsOpacity = 1
            sectionsSlide   = 0
        }
    }
}

#Preview {
    SettingsView(onSignedOut: {})
}
