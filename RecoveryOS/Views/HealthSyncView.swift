//
//  HealthSyncView.swift
//  RecoveryOS
//
//  Created by Richy James on 11/04/2026.
//

import SwiftUI
import SwiftData

struct HealthSyncView: View {

    var onSynced: () -> Void
    var onSkipped: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("healthKitEnabled")       private var healthKitEnabled = false

    // Discipline selection
    @State private var selectedDiscipline: Discipline = .strength
    enum Discipline { case endurance, strength }

    // Age (visual only)
    @State private var age: Double = 28

    // Intensity (visual only — 0 = LIT, 1 = HIT)
    @State private var intensity: Double = 0.45

    // Permission toggles (visual only)
    @State private var heartRateOn  = true
    @State private var sleepOn      = false
    @State private var workoutsOn   = false
    @State private var stepsOn      = true

    // Entrance animations
    @State private var headerOpacity: Double  = 0
    @State private var headerSlide: CGFloat   = -16
    @State private var cardOpacity: Double    = 0
    @State private var cardSlide: CGFloat     = 24
    @State private var buttonOpacity: Double  = 0

    // Design tokens
    private let bgPrimary    = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard       = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue   = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal   = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let accentPurple = Color(red: 0.55, green: 0.35, blue: 0.98)
    private let labelGray    = Color.white.opacity(0.4)

    var body: some View {
        ZStack {

            // Background
            bgPrimary.ignoresSafeArea()

            // Subtle left-side blue accent line
            HStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accentBlue.opacity(0.5), accentBlue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)
                    .ignoresSafeArea()
                Spacer()
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Top bar
                    HStack {
                        Text("READINESS")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(accentBlue)

                        Spacer()

                        HStack(spacing: 10) {
                            Text("STEP 02/03")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))

                            ZStack {
                                Circle()
                                    .fill(bgCard)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .opacity(headerOpacity)
                    .offset(y: headerSlide)

                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Calibrate Your")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Engine.")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [accentBlue, accentPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Connect your biometric stream to unlock high-precision recovery scoring and workload optimisation.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.45))
                            .lineSpacing(3)
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .opacity(headerOpacity)
                    .offset(y: headerSlide)

                    // Discipline picker
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("PRIMARY DISCIPLINE")

                        HStack(spacing: 12) {
                            disciplineCard(
                                icon: "figure.run",
                                label: "Endurance",
                                selected: selectedDiscipline == .endurance
                            ) { selectedDiscipline = .endurance }

                            disciplineCard(
                                icon: "dumbbell.fill",
                                label: "Strength",
                                selected: selectedDiscipline == .strength
                            ) { selectedDiscipline = .strength }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .opacity(cardOpacity)
                    .offset(y: cardSlide)

                    // Age
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("AGE")
                        Text("\(Int(age))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Slider(value: $age, in: 16...60, step: 1)
                            .tint(accentBlue)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .opacity(cardOpacity)
                    .offset(y: cardSlide)

                    // Intensity
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("INTENSITY")

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [accentTeal, accentBlue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * intensity, height: 6)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        intensity = max(0, min(1, value.location.x / geo.size.width))
                                    }
                            )
                        }
                        .frame(height: 6)

                        HStack {
                            Text("LIT")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(labelGray)
                            Spacer()
                            Text("HIT")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(labelGray)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .opacity(cardOpacity)
                    .offset(y: cardSlide)

                    // Data Permissions
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Data Permissions")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        permissionRow(
                            icon: "heart.fill",
                            iconColor: Color(red: 1.0, green: 0.3, blue: 0.4),
                            title: "Heart Rate",
                            subtitle: "Variability & Resting metrics",
                            isOn: $heartRateOn
                        )
                        permissionRow(
                            icon: "moon.fill",
                            iconColor: accentPurple,
                            title: "Sleep",
                            subtitle: "Phases and efficiency levels",
                            isOn: $sleepOn
                        )
                        permissionRow(
                            icon: "bolt.fill",
                            iconColor: accentBlue,
                            title: "Workouts",
                            subtitle: "Strain and caloric expenditure",
                            isOn: $workoutsOn
                        )
                        permissionRow(
                            icon: "figure.walk",
                            iconColor: accentTeal,
                            title: "Steps",
                            subtitle: "Daily baseline activity",
                            isOn: $stepsOn
                        )
                    }
                    .padding(20)
                    .background(bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .opacity(cardOpacity)
                    .offset(y: cardSlide)

                    // Sync button
                    Button(action: syncAndFinish) {
                        HStack(spacing: 10) {
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.85))
                            Text("SYNC WITH APPLE HEALTH")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .kerning(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [accentBlue, Color(red: 0.35, green: 0.55, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: accentBlue.opacity(0.4), radius: 14, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .opacity(buttonOpacity)

                    // Configure manually
                    Button(action: skipAndFinish) {
                        Text("CONFIGURE MANUALLY")
                            .font(.system(size: 12, weight: .semibold))
                            .kerning(1)
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                    .opacity(buttonOpacity)

                    // Footer
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.2))
                        Text("END-TO-END ENCRYPTED BIOMETRIC STORAGE")
                            .font(.system(size: 9, weight: .medium))
                            .kerning(0.8)
                            .foregroundColor(.white.opacity(0.2))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                    .opacity(buttonOpacity)
                }
            }
        }
        .onAppear { beginAnimations() }
    }

    // MARK: - Subviews

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .kerning(1.5)
            .foregroundColor(labelGray)
    }

    private func disciplineCard(icon: String, label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(selected ? .white : .white.opacity(0.45))
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(selected ? .white : .white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(selected ? accentBlue.opacity(0.18) : bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        selected ? accentBlue.opacity(0.7) : Color.white.opacity(0.07),
                        lineWidth: selected ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: selected)
        }
    }

    private func permissionRow(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.38))
            }

            Spacer()

            // Toggle circle
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isOn.wrappedValue.toggle() } }) {
                ZStack {
                    Circle()
                        .stroke(isOn.wrappedValue ? accentBlue : Color.white.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if isOn.wrappedValue {
                        Circle()
                            .fill(accentBlue)
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
    }

    // MARK: - Persist onboarding data
    private func saveProfile() {
        let disciplineString = selectedDiscipline == .endurance ? "endurance" : "strength"
        if let profile = profiles.first {
            profile.discipline          = disciplineString
            profile.age                 = Int(age)
            profile.intensity           = intensity
            profile.onboardingCompleted = true
        }
        hasCompletedOnboarding = true
        NotificationManager.shared.requestPermission()
        NotificationManager.shared.scheduleDailyCheckInReminder()
    }

    private func syncAndFinish() {
        saveProfile()
        healthKitEnabled = true
        HealthKitManager.shared.requestAuthorization()
        onSynced()
    }

    private func skipAndFinish() {
        saveProfile()
        healthKitEnabled = false
        onSkipped()
    }

    // MARK: - Entrance animations
    private func beginAnimations() {
        withAnimation(.easeOut(duration: 0.6)) {
            headerOpacity = 1
            headerSlide   = 0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2)) {
            cardOpacity = 1
            cardSlide   = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            buttonOpacity = 1
        }
    }
}

#Preview {
    HealthSyncView(onSynced: {}, onSkipped: {})
}
