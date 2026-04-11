//
//  SettingsView.swift
//  RecoveryOS
//
//  Created by Richy James on 11/04/2026.
//

import SwiftUI

// MARK: - Bottom nav tabs (updated structure matching design)
enum MainTab: String, CaseIterable {
    case home    = "HOME"
    case trends  = "TRENDS"
    case recover = "RECOVER"
    case coach   = "COACH"
    case you     = "YOU"

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .trends:  return "chart.line.uptrend.xyaxis"
        case .recover: return "arrow.trianglehead.clockwise.rotate.90"
        case .coach:   return "person.wave.2"
        case .you:     return "person.circle.fill"
        }
    }
}

// MARK: - SettingsView
struct SettingsView: View {

    var onBack: () -> Void

    @AppStorage("isLoggedIn")              private var isLoggedIn = false
    @AppStorage("hasCompletedOnboarding")  private var hasCompletedOnboarding = false

    // Toggles (UI only)
    @State private var recoveryReminders = true
    @State private var biometricUnlock   = true

    // Active tab
    @State private var activeTab: MainTab = .you

    // Entrance animations
    @State private var headerOpacity: Double  = 0
    @State private var headerSlide: CGFloat   = -12
    @State private var profileOpacity: Double = 0
    @State private var profileScale: CGFloat  = 0.94
    @State private var sectionsOpacity: Double = 0
    @State private var sectionsSlide: CGFloat  = 20

    // Design tokens
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let bgRow      = Color(red: 0.11, green: 0.11, blue: 0.16)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.38)
    private let valueGray  = Color.white.opacity(0.45)

    var body: some View {
        ZStack {
            bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {

                // Navigation header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Settings")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .opacity(headerOpacity)
                .offset(y: headerSlide)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {

                        // Profile card
                        profileCard
                            .opacity(profileOpacity)
                            .scaleEffect(profileScale)

                        // Sections
                        VStack(spacing: 16) {
                            accountSection
                            recoveryPreferencesSection
                            connectedDevicesSection
                            privacySection
                            signOutButton
                            versionFooter
                        }
                        .opacity(sectionsOpacity)
                        .offset(y: sectionsSlide)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }

                // Bottom nav
                bottomNavBar
            }
        }
        .onAppear { beginAnimations() }
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

            Text("Marcus Holloway")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("ELITE PERFORMER")
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
            settingsRow(icon: "person", iconColor: accentBlue, title: "Profile")
            divider
            settingsRow(icon: "envelope", iconColor: accentBlue, title: "Email", value: "m.holloway@pro.com")
            divider
            settingsRow(icon: "lock", iconColor: accentBlue, title: "Password")
            divider
            HStack {
                iconCircle("star", color: accentBlue)
                Text("Subscription")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("PREMIUM")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.85, green: 0.65, blue: 0.15), Color(red: 0.95, green: 0.78, blue: 0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                chevron
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
    }

    // MARK: - Recovery Preferences section
    private var recoveryPreferencesSection: some View {
        settingsSection(label: "RECOVERY PREFERENCES") {
            settingsRow(icon: "figure.run", iconColor: accentTeal, title: "Training Goals", value: "Hyrox Pro")
            divider
            settingsRow(icon: "moon", iconColor: Color(red: 0.55, green: 0.35, blue: 0.98), title: "Bedtime Target", value: "10:30 PM")
            divider
            settingsRow(icon: "drop", iconColor: Color(red: 0.3, green: 0.6, blue: 1.0), title: "Hydration Target", value: "4.2 Liters")
            divider
            toggleRow(icon: "bell", iconColor: Color(red: 1.0, green: 0.6, blue: 0.2), title: "Recovery Reminders", isOn: $recoveryReminders)
        }
    }

    // MARK: - Connected Devices section
    private var connectedDevicesSection: some View {
        settingsSection(label: "CONNECTED DEVICES") {
            HStack {
                iconCircle("heart.fill", color: Color(red: 1.0, green: 0.25, blue: 0.35))
                Text("Apple Health")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("CONNECTED")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.8)
                    .foregroundColor(accentTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentTeal.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(accentTeal.opacity(0.3), lineWidth: 1))
                chevron
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)

            divider
            settingsRow(icon: "g.circle.fill", iconColor: Color(red: 0.2, green: 0.7, blue: 0.4), title: "Garmin")
            divider
            settingsRow(icon: "bolt.heart.fill", iconColor: Color(red: 0.9, green: 0.3, blue: 0.5), title: "Fitbit")
            divider
            settingsRow(icon: "waveform.path.ecg", iconColor: Color(red: 0.9, green: 0.5, blue: 0.15), title: "WHOOP")
            divider
            settingsRow(icon: "circle.hexagongrid.fill", iconColor: Color(red: 0.45, green: 0.28, blue: 0.98), title: "Oura")
        }
    }

    // MARK: - Privacy & Security section
    private var privacySection: some View {
        settingsSection(label: "PRIVACY & SECURITY") {
            toggleRow(icon: "faceid", iconColor: accentBlue, title: "Biometric Unlock", isOn: $biometricUnlock)
            divider
            settingsRow(icon: "shield", iconColor: accentBlue, title: "Data Sharing Policy")
        }
    }

    // MARK: - Sign out button
    private var signOutButton: some View {
        Button(action: {
            isLoggedIn = false
            hasCompletedOnboarding = false
            onBack()
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

    // MARK: - Bottom nav bar
    private var bottomNavBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button { activeTab = tab } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .kerning(0.5)
                    }
                    .foregroundColor(activeTab == tab ? .white : Color.white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 12)
        .background(
            bgCard
                .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
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
        withAnimation(.easeOut(duration: 0.5)) {
            headerOpacity = 1
            headerSlide   = 0
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
            profileOpacity = 1
            profileScale   = 1.0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3)) {
            sectionsOpacity = 1
            sectionsSlide   = 0
        }
    }
}

#Preview {
    SettingsView(onBack: {})
}
