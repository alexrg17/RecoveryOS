//
//  AnimatedLogoOrb.swift
//  RecoveryOS
//
//  Created by Richy James on 28/03/2026.
//

import SwiftUI

struct AnimatedLogoOrb: View {

    // Halo pulse
    @State private var haloScale: CGFloat   = 1.0
    @State private var haloOpacity: Double  = 0.45

    // Rotating arc
    @State private var arcAngle: Double     = 0

    // Glow breathe
    @State private var glowSize: CGFloat    = 44
    @State private var glowOpacity: Double  = 0.3

    // Subtle float
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        ZStack {

            // Outer pulsing halo ring
            Circle()
                .stroke(Color(red: 0.4, green: 0.9, blue: 0.7).opacity(haloOpacity), lineWidth: 1)
                .frame(width: 72, height: 72)
                .scaleEffect(haloScale)

            // Rotating arc
            Circle()
                .trim(from: 0.05, to: 0.65)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.45, green: 0.92, blue: 0.72).opacity(0.85),
                            Color.clear
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(arcAngle))

            // Glow bloom behind orb
            Circle()
                .fill(Color(red: 0.4, green: 0.9, blue: 0.7).opacity(glowOpacity))
                .frame(width: glowSize, height: glowSize)
                .blur(radius: 10)

            // Outer orb background
            Circle()
                .fill(Color(red: 0.2, green: 0.65, blue: 0.5).opacity(0.35))
                .frame(width: 48, height: 48)

            // Inner dot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.55, green: 0.98, blue: 0.78),
                            Color(red: 0.25, green: 0.7, blue: 0.55)
                        ],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 20
                    )
                )
                .frame(width: 20, height: 20)
                .shadow(color: Color(red: 0.4, green: 0.9, blue: 0.7).opacity(0.9), radius: 8)
        }
        .offset(y: floatOffset)
        .onAppear { startAnimations() }
    }

    private func startAnimations() {

        // Halo pulse — expands and fades out, repeating
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            haloScale   = 1.45
            haloOpacity = 0.0
        }

        // Arc rotation
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            arcAngle = 360
        }

        // Glow breathe
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowSize    = 56
            glowOpacity = 0.6
        }

        // Float
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            floatOffset = -5
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()
        AnimatedLogoOrb()
    }
}
