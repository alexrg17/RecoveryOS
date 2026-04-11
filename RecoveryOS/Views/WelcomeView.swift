//
//  WelcomeView.swift
//  RecoveryOS
//
//  Created by Richy James on 28/03/2026.
//

import SwiftUI

// MARK: - Particle Model
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var angle: Double
}

// MARK: - WelcomeView
struct WelcomeView: View {

    // Navigation callback
    var onGetStarted: () -> Void
    var onSignIn: () -> Void

    // Orb animations
    @State private var pulseScale: CGFloat      = 1.0
    @State private var pulseOpacity: Double     = 0.5
    @State private var outerRingAngle: Double   = 0
    @State private var innerRingAngle: Double   = 0
    @State private var glowBrightness: Double   = 0.5
    @State private var orbFloat: CGFloat        = 0
    @State private var orbScale: CGFloat        = 0.6
    @State private var scanLineOffset: CGFloat  = -50

    // Halo rings
    @State private var halo1Scale: CGFloat      = 1.0
    @State private var halo1Opacity: Double     = 0.4
    @State private var halo2Scale: CGFloat      = 1.0
    @State private var halo2Opacity: Double     = 0.3
    @State private var halo3Scale: CGFloat      = 1.0
    @State private var halo3Opacity: Double     = 0.2

    // Content reveal
    @State private var contentOpacity: Double   = 0
    @State private var contentSlide: CGFloat    = 40
    @State private var logoOpacity: Double      = 0
    @State private var buttonPressedStart       = false
    @State private var buttonPressedSignIn      = false

    // Particles
    @State private var particles: [Particle]    = WelcomeView.makeParticles()
    @State private var particleTick: Double     = 0

    // Corner dots animation
    @State private var dotOpacities: [Double]   = [0.2, 0.4, 0.6, 0.8, 0.4, 0.2, 0.8, 0.6]

    var body: some View {
        ZStack {

            // ── Background ────────────────────────────────────────────────
            Color(red: 0.04, green: 0.04, blue: 0.06)
                .ignoresSafeArea()

            // Radial ambient glow behind orb
            RadialGradient(
                colors: [
                    Color(red: 0.25, green: 0.75, blue: 0.55).opacity(0.18),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()

            // ── Floating particles ────────────────────────────────────────
            GeometryReader { geo in
                ForEach(particles) { p in
                    Circle()
                        .fill(Color(red: 0.4, green: 0.9, blue: 0.7).opacity(p.opacity))
                        .frame(width: p.size, height: p.size)
                        .position(
                            x: p.x + cos(p.angle + particleTick * p.speed) * 18,
                            y: p.y + sin(p.angle + particleTick * p.speed) * 18
                        )
                        .blur(radius: p.size * 0.4)
                }
            }
            .ignoresSafeArea()

            // ── Main layout ───────────────────────────────────────────────
            VStack(spacing: 0) {

                // Top logo bar
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.2, green: 0.65, blue: 0.5).opacity(0.35))
                            .frame(width: 34, height: 34)
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.98, blue: 0.78),
                                        Color(red: 0.25, green: 0.7, blue: 0.55)
                                    ],
                                    center: .topLeading,
                                    startRadius: 1,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 14, height: 14)
                            .shadow(color: Color(red: 0.4, green: 0.9, blue: 0.7).opacity(0.9), radius: 6)
                    }

                    Text("RecoveryOS")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .opacity(logoOpacity)
                .padding(.top, 20)

                Spacer()

                // ── Central Orb ───────────────────────────────────────────
                ZStack {

                    // Halo ring 1 (outermost pulse)
                    Circle()
                        .stroke(Color(red: 0.4, green: 0.9, blue: 0.65).opacity(halo1Opacity), lineWidth: 1)
                        .frame(width: 220, height: 220)
                        .scaleEffect(halo1Scale)

                    // Halo ring 2
                    Circle()
                        .stroke(Color(red: 0.4, green: 0.85, blue: 0.65).opacity(halo2Opacity), lineWidth: 1)
                        .frame(width: 185, height: 185)
                        .scaleEffect(halo2Scale)

                    // Halo ring 3
                    Circle()
                        .stroke(Color(red: 0.35, green: 0.8, blue: 0.6).opacity(halo3Opacity), lineWidth: 1)
                        .frame(width: 155, height: 155)
                        .scaleEffect(halo3Scale)

                    // Outer rotating arc
                    Circle()
                        .trim(from: 0.05, to: 0.72)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.92, blue: 0.72).opacity(0.9),
                                    Color(red: 0.3, green: 0.7, blue: 0.55).opacity(0.2),
                                    Color.clear
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 158, height: 158)
                        .rotationEffect(.degrees(outerRingAngle))

                    // Inner counter-rotating arc
                    Circle()
                        .trim(from: 0.1, to: 0.45)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.35, green: 0.75, blue: 1.0).opacity(0.7),
                                    Color.clear
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                        )
                        .frame(width: 132, height: 132)
                        .rotationEffect(.degrees(-innerRingAngle))

                    // Orb glow bloom
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.9, blue: 0.7).opacity(glowBrightness),
                                    Color(red: 0.2, green: 0.6, blue: 0.5).opacity(0.25),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 65
                            )
                        )
                        .frame(width: 130, height: 130)
                        .blur(radius: 18)

                    // Orb body
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.96, blue: 0.78),
                                        Color(red: 0.22, green: 0.72, blue: 0.55),
                                        Color(red: 0.1, green: 0.38, blue: 0.32)
                                    ],
                                    center: UnitPoint(x: 0.38, y: 0.3),
                                    startRadius: 4,
                                    endRadius: 52
                                )
                            )
                            .frame(width: 92, height: 92)
                            .shadow(color: Color(red: 0.3, green: 0.85, blue: 0.65).opacity(0.7), radius: 18)

                        // Scan line sweep inside orb
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.white.opacity(0.15),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 92, height: 20)
                            .offset(y: scanLineOffset)
                            .clipShape(Circle().size(width: 92, height: 92).offset(x: 0, y: (92 - 92) / 2))

                        // White core dot
                        Circle()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: 17, height: 17)
                            .shadow(color: Color.white.opacity(0.9), radius: 6)
                            .offset(x: -4, y: -4)

                        // Highlight sheen
                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: 32, height: 32)
                            .blur(radius: 10)
                            .offset(x: -12, y: -12)
                    }
                    .scaleEffect(orbScale)
                    .offset(y: orbFloat)

                    // Tick marks around the outer ring (decorative)
                    ForEach(0..<12) { i in
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.85, blue: 0.65)
                                .opacity(dotOpacities[i % dotOpacities.count]))
                            .frame(width: 1.5, height: i % 3 == 0 ? 8 : 4)
                            .offset(y: -88)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                }
                .frame(height: 230)

                Spacer()

                // ── Text block ────────────────────────────────────────────
                VStack(spacing: 10) {
                    Text("RecoveryOS")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 0.4, green: 0.9, blue: 0.7).opacity(0.4), radius: 12)

                    Text("Your personal recovery coach.\nTrain smarter, recover better.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.bottom, 36)
                .opacity(contentOpacity)
                .offset(y: contentSlide)

                // ── Buttons ───────────────────────────────────────────────
                VStack(spacing: 12) {

                    // Get started
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                            buttonPressedStart = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            buttonPressedStart = false
                            onGetStarted()
                        }
                    }) {
                        Text("Get started")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                ZStack {
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.28, green: 0.48, blue: 0.98),
                                            Color(red: 0.38, green: 0.58, blue: 1.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    // Shimmer overlay
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.0),
                                            Color.white.opacity(0.12),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.5), radius: 12, y: 4)
                            .scaleEffect(buttonPressedStart ? 0.96 : 1.0)
                    }

                    // Sign in
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                            buttonPressedSignIn = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            buttonPressedSignIn = false
                            onSignIn()
                        }
                    }) {
                        Text("Sign in")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .scaleEffect(buttonPressedSignIn ? 0.96 : 1.0)
                    }
                }
                .padding(.horizontal, 28)
                .opacity(contentOpacity)
                .offset(y: contentSlide)

                // Privacy & Terms
                HStack {
                    Spacer()
                    Button("PRIVACY") {}
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))
                    Text("·")
                        .foregroundColor(.white.opacity(0.2))
                        .font(.system(size: 10))
                    Button("TERMS") {}
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.horizontal, 28)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .opacity(contentOpacity)
            }
        }
        .onAppear { beginAnimations() }
    }

    // MARK: - Animations
    private func beginAnimations() {

        // Logo fades in first
        withAnimation(.easeOut(duration: 0.8)) {
            logoOpacity = 1
        }

        // Orb springs in
        withAnimation(.spring(response: 1.1, dampingFraction: 0.55).delay(0.2)) {
            orbScale = 1.0
        }

        // Content slides up
        withAnimation(.easeOut(duration: 0.9).delay(0.5)) {
            contentOpacity = 1
            contentSlide   = 0
        }

        // Orb float (breathing)
        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true).delay(0.5)) {
            orbFloat = -10
        }

        // Glow breathe
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowBrightness = 1.0
        }

        // Halo pulse — staggered so they ripple outward
        withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false)) {
            halo1Scale   = 1.35
            halo1Opacity = 0.0
        }
        withAnimation(.easeOut(duration: 2.4).delay(0.8).repeatForever(autoreverses: false)) {
            halo2Scale   = 1.35
            halo2Opacity = 0.0
        }
        withAnimation(.easeOut(duration: 2.4).delay(1.6).repeatForever(autoreverses: false)) {
            halo3Scale   = 1.35
            halo3Opacity = 0.0
        }

        // Rotating arcs
        withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
            outerRingAngle = 360
        }
        withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: false)) {
            innerRingAngle = 360
        }

        // Scan line sweep
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false)) {
            scanLineOffset = 50
        }

        // Tick mark opacity cycle
        Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.18)) {
                dotOpacities = dotOpacities.map { _ in Double.random(in: 0.1...0.9) }
            }
        }

        // Particle drift
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            particleTick += 0.015
        }
    }

    // MARK: - Particle factory
    static func makeParticles() -> [Particle] {
        (0..<28).map { _ in
            Particle(
                x: CGFloat.random(in: 20...370),
                y: CGFloat.random(in: 60...750),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.08...0.35),
                speed: Double.random(in: 0.3...0.9),
                angle: Double.random(in: 0...(2 * .pi))
            )
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomeView(onGetStarted: {}, onSignIn: {})
}
