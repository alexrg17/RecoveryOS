//
//  DashboardView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 03/04/2026.
//

import SwiftUI

// MARK: - Colours
private let bgPrimary   = Color(red: 0.04, green: 0.04, blue: 0.07)
private let bgCard      = Color(red: 0.09, green: 0.09, blue: 0.13)
private let accentBlue  = Color(red: 0.28, green: 0.48, blue: 0.98)
private let accentTeal  = Color(red: 0.25, green: 0.90, blue: 0.69)
private let labelGray   = Color.white.opacity(0.45)

// MARK: - Tab model
private enum TabItem: String, CaseIterable {
    case home     = "HOME"
    case health   = "HEALTH"
    case trends   = "TRENDS"
    case insights = "INSIGHTS"
    case profile  = "PROFILE"

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .health:   return "heart"
        case .trends:   return "chart.line.uptrend.xyaxis"
        case .insights: return "lightbulb"
        case .profile:  return "person"
        }
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @State private var selectedTab: TabItem = .home
    private let recoveryScore = 88

    var body: some View {
        bgPrimary
            .ignoresSafeArea()
            .overlay(
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        topBar
                        recoveryRing
                        aiInsightCard
                        metricsRow
                        hrvTrendCard
                        nextPhaseCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomNavBar
            }
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack {
            // Avatar + score badge
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.system(size: 20))
                    )

                ZStack {
                    Circle()
                        .fill(accentBlue)
                        .frame(width: 18, height: 18)
                    Text("\(recoveryScore)")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: 4, y: 4)
            }

            Spacer()

            Text("RecoveryOS")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "bell")
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 44, height: 44)
        }
        .padding(.top, 8)
    }

    // MARK: Recovery score ring
    private var recoveryRing: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(135))

            // Filled arc with teal-at-top, blue-at-sides gradient
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    AngularGradient(
                        colors: [accentBlue, accentTeal, accentBlue],
                        center: .center,
                        startAngle: .degrees(135),
                        endAngle: .degrees(405)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(135))

            // Center text
            VStack(spacing: 4) {
                Text("\(recoveryScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("OPTIMAL")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(accentTeal)
            }
        }
        .frame(width: 210, height: 210)
        .padding(.vertical, 8)
    }

    // MARK: AI insight card
    private var aiInsightCard: some View {
        HStack(alignment: .top, spacing: 0) {
            Group {
                Text("Optimal Performance Window: ")
                    .foregroundStyle(accentBlue)
                    .fontWeight(.semibold)
                +
                Text("Your CNS recovery is at peak levels. High intensity training is recommended.")
                    .foregroundStyle(.white)
            }
            .font(.system(size: 14))
            .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Metrics row (Sleep + HR)
    private var metricsRow: some View {
        HStack(spacing: 12) {
            metricCard(
                icon: "moon.fill",
                iconColor: .white.opacity(0.7),
                badge: "+12%",
                badgeColor: Color(red: 0.2, green: 0.85, blue: 0.4),
                label: "SLEEP QUALITY",
                value: "8h 42m",
                trendIcon: nil
            )

            metricCard(
                icon: "heart",
                iconColor: .white.opacity(0.7),
                badge: nil,
                badgeColor: .clear,
                label: "RESTING HR",
                value: "54 BPM",
                trendIcon: "arrow.down.right"
            )
        }
    }

    private func metricCard(
        icon: String,
        iconColor: Color,
        badge: String?,
        badgeColor: Color,
        label: String,
        value: String,
        trendIcon: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(badgeColor)
                } else if let trendIcon {
                    Image(systemName: trendIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentTeal)
                }
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .kerning(1)
                .foregroundStyle(labelGray)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: HRV Trend card
    private var hrvTrendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HRV TREND")
                .font(.system(size: 10, weight: .medium))
                .kerning(1)
                .foregroundStyle(labelGray)

            HStack(alignment: .bottom) {
                Text("72 ms")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("ABOVE BASELINE")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(1)
                    .foregroundStyle(accentTeal)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [accentBlue, accentTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.78, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("DAY 1")
                    .font(.system(size: 10))
                    .foregroundStyle(labelGray)
                Spacer()
                Text("DAY 7")
                    .font(.system(size: 10))
                    .foregroundStyle(labelGray)
            }
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Next Phase card
    private var nextPhaseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEXT PHASE")
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.5)
                .foregroundStyle(accentBlue)

            HStack(spacing: 14) {
                // Shoe icon tile
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.45, green: 0.35, blue: 0.22))
                        .frame(width: 52, height: 52)

                    Image(systemName: "figure.walk")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Recovery")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Suggested duration: 45 minutes")
                        .font(.system(size: 13))
                        .foregroundStyle(labelGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Bottom nav bar
    private var bottomNavBar: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))

                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .kerning(0.5)
                    }
                    .foregroundStyle(selectedTab == tab ? .white : Color.white.opacity(0.35))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 12)
        .background(
            bgCard
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    DashboardView()
}
