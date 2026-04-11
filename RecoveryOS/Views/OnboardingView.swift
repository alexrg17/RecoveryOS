//
//  OnboardingView.swift
//  RecoveryOS
//
//  Created by Richy James on 11/04/2026.
//

import SwiftUI

// MARK: - Design tokens (matches DashboardView)
private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
private let accentPurple = Color(red: 0.55, green: 0.35, blue: 0.98)
private let labelGray  = Color.white.opacity(0.45)

// MARK: - OnboardingView
struct OnboardingView: View {

    var onFinished: () -> Void

    @State private var currentPage  = 0
    @State private var dragOffset: CGFloat = 0
    @State private var contentOpacity: Double = 1
    @State private var iconFloat: CGFloat = 0
    @State private var badgePulse: CGFloat = 1.0

    private let totalPages = 3

    var body: some View {
        ZStack {

            // Animated background per page
            pageBackground
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentPage)

            VStack(spacing: 0) {

                // Top bar
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer()

                // Page content
                ZStack {
                    if currentPage == 0 { pageOne }
                    if currentPage == 1 { pageTwo }
                    if currentPage == 2 { pageThree }
                }
                .opacity(contentOpacity)

                Spacer()

                // Dots
                dotsIndicator
                    .padding(.bottom, 20)

                // Primary button
                primaryButton
                    .padding(.horizontal, 28)
                    .padding(.bottom, 14)

                // Skip
                if currentPage < totalPages - 1 {
                    Button("SKIP INTRODUCTION") { onFinished() }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.bottom, 24)
                } else {
                    Spacer().frame(height: 42)
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50, currentPage < totalPages - 1 {
                        advancePage()
                    } else if value.translation.width > 50, currentPage > 0 {
                        retreatPage()
                    }
                }
        )
        .onAppear { startLoopAnimations() }
    }

    // MARK: - Animated background
    @ViewBuilder
    private var pageBackground: some View {
        ZStack {
            bgPrimary

            switch currentPage {
            case 0:
                // Blue ambient top
                RadialGradient(
                    colors: [accentBlue.opacity(0.18), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
            case 1:
                // Purple ambient center
                RadialGradient(
                    colors: [accentPurple.opacity(0.15), Color.clear],
                    center: UnitPoint(x: 0.5, y: 0.35),
                    startRadius: 0,
                    endRadius: 380
                )
            default:
                // Teal ambient bottom-centre with dark top overlay
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.06, blue: 0.10),
                            bgPrimary
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    RadialGradient(
                        colors: [accentBlue.opacity(0.12), Color.clear],
                        center: UnitPoint(x: 0.5, y: 0.6),
                        startRadius: 0,
                        endRadius: 320
                    )
                }
            }
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            Text("READINESS")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            if currentPage == totalPages - 1 {
                Text("STEP 3 OF 3")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))

                    Circle()
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
            }
        }
    }

    // MARK: - Page 1: Track Your Recovery
    private var pageOne: some View {
        VStack(spacing: 28) {

            // Feature card with badges
            ZStack {
                // Glow
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(accentBlue.opacity(0.12))
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)

                // Main card
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(bgCard)
                    .frame(width: 160, height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )

                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentBlue, accentTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // REAL-TIME badge — top
                Text("⬡  REAL-TIME")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.14, green: 0.14, blue: 0.20))
                            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
                    .offset(x: 20, y: -70)
                    .scaleEffect(badgePulse)

                // STRAIN badge — bottom left
                Text("∿  STRAIN")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.14, green: 0.14, blue: 0.20))
                            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
                    .offset(x: -30, y: 70)
            }
            .offset(y: iconFloat)

            // Text
            VStack(spacing: 10) {
                Text("ONBOARDING  •  01")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(1.5)
                    .foregroundColor(.white.opacity(0.35))

                VStack(spacing: 2) {
                    Text("Track Your")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Recovery")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentBlue, accentPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text("Monitor real-time physiological strain and workload.\nOur proprietary OS analyzes your HRV and CNS readiness to prevent burnout.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 10)
            }
        }
        .padding(.horizontal, 24)
        .transition(.asymmetric(
            insertion:  .move(edge: .trailing).combined(with: .opacity),
            removal:    .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Page 2: Optimize Your Sleep
    private var pageTwo: some View {
        VStack(spacing: 28) {

            // Moon icon card
            ZStack(alignment: .topTrailing) {
                ZStack {
                    // Glow
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(accentPurple.opacity(0.18))
                        .frame(width: 160, height: 160)
                        .blur(radius: 22)

                    // Card
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.28, green: 0.18, blue: 0.55),
                                    Color(red: 0.18, green: 0.10, blue: 0.38)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)

                    Image(systemName: "moon.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.white.opacity(0.9))
                }
                .offset(y: iconFloat)

                // Deep sleep badge
                VStack(alignment: .leading, spacing: 2) {
                    Text("DEEP SLEEP")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(1)
                        .foregroundColor(accentTeal)
                    Text("2h 14m")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(bgCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .offset(x: 30, y: -10)
                .scaleEffect(badgePulse)
            }
            .padding(.trailing, 30)

            // Text
            VStack(spacing: 10) {
                VStack(spacing: 2) {
                    Text("Optimize")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Your Sleep")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentPurple, accentBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text("Harness the power of circadian rhythms with advanced deep sleep analysis and restorative recovery insights.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 10)
            }

            // Stat cards
            HStack(spacing: 12) {
                statCard(label: "READY SCORE", value: "92%")
                statCard(label: "HRV BALANCE", value: "Optimal")
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 24)
        .transition(.asymmetric(
            insertion:  .move(edge: .trailing).combined(with: .opacity),
            removal:    .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func statCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .kerning(1)
                .foregroundColor(labelGray)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [accentPurple, accentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Page 3: Train Smarter
    private var pageThree: some View {
        VStack(spacing: 24) {

            // Lightning icon
            ZStack {
                Circle()
                    .fill(accentTeal.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .blur(radius: 16)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentTeal, accentBlue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .offset(y: iconFloat)

            // Text
            VStack(spacing: 10) {
                Text("Train Smarter")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Leverage high-performance data to optimise your recovery. Get personalised insights tailored to your unique circadian rhythm and training load.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 6)
            }

            // Feature rows
            VStack(spacing: 10) {
                featureRow(icon: "brain.head.profile", label: "AI POWERED", value: "Daily Readiness Analysis", color: accentBlue)
                featureRow(icon: "waveform.path.ecg", label: nil, value: "Real-time Vitals Sync", color: accentTeal)
                featureRow(icon: "moon.stars.fill", label: nil, value: "Advanced Sleep Tracking", color: accentPurple)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 24)
        .transition(.asymmetric(
            insertion:  .move(edge: .trailing).combined(with: .opacity),
            removal:    .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func featureRow(icon: String, label: String?, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let label {
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .kerning(1.2)
                        .foregroundColor(color)
                }
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(12)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Dots indicator
    private var dotsIndicator: some View {
        HStack(spacing: 7) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? accentBlue : Color.white.opacity(0.2))
                    .frame(width: i == currentPage ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    // MARK: - Primary button
    private var primaryButton: some View {
        Button(action: {
            if currentPage < totalPages - 1 {
                advancePage()
            } else {
                onFinished()
            }
        }) {
            HStack(spacing: 8) {
                Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                if currentPage < totalPages - 1 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [accentBlue, currentPage == 1 ? accentPurple : accentTeal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: accentBlue.opacity(0.4), radius: 14, y: 4)
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }

    // MARK: - Navigation
    private func advancePage() {
        withAnimation(.easeInOut(duration: 0.15)) { contentOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentPage += 1
            withAnimation(.easeInOut(duration: 0.3)) { contentOpacity = 1 }
            startLoopAnimations()
        }
    }

    private func retreatPage() {
        withAnimation(.easeInOut(duration: 0.15)) { contentOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentPage -= 1
            withAnimation(.easeInOut(duration: 0.3)) { contentOpacity = 1 }
            startLoopAnimations()
        }
    }

    // MARK: - Loop animations
    private func startLoopAnimations() {
        iconFloat   = 0
        badgePulse  = 1.0

        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            iconFloat = -10
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.4)) {
            badgePulse = 1.05
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
