//
//  DashboardView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 03/04/2026.
//

import SwiftUI
import SwiftData

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
    var onProfileTapped: (() -> Void)? = nil

    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @State private var selectedTab: TabItem = .home
    @State private var showCheckIn = false

    // Ring + score animation
    @State private var ringProgress: Double = 0
    @State private var displayedScore: Int  = 0

    // MARK: - Computed data
    private var latestCheckIn: DailyCheckIn? { checkIns.first }
    private var previousCheckIn: DailyCheckIn? { checkIns.count > 1 ? checkIns[1] : nil }

    private var hasCheckedInToday: Bool {
        guard let latest = latestCheckIn else { return false }
        return Calendar.current.isDateInToday(latest.date)
    }

    private var recoveryScore: Int { latestCheckIn?.readinessScore ?? 0 }

    private var recoveryStatus: String {
        guard latestCheckIn != nil else { return "NO DATA" }
        switch recoveryScore {
        case 85...100: return "OPTIMAL"
        case 75..<85:  return "GOOD"
        case 60..<75:  return "MODERATE"
        case 40..<60:  return "FAIR"
        default:       return "POOR"
        }
    }

    private var statusColor: Color {
        switch recoveryScore {
        case 85...100: return accentTeal
        case 75..<85:  return Color(red: 0.4, green: 0.85, blue: 0.55)
        case 60..<75:  return Color(red: 1.0, green: 0.75, blue: 0.2)
        case 40..<60:  return Color(red: 1.0, green: 0.55, blue: 0.2)
        default:       return Color(red: 1.0, green: 0.38, blue: 0.38)
        }
    }

    private var sleepString: String {
        guard let h = latestCheckIn?.sleepHours else { return "—" }
        let hrs = Int(h); let mins = Int((h - Double(hrs)) * 60)
        return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
    }

    private var sleepChange: String? {
        guard let today = latestCheckIn?.sleepHours,
              let prev  = previousCheckIn?.sleepHours, prev > 0 else { return nil }
        let pct = ((today - prev) / prev) * 100
        return "\(pct >= 0 ? "+" : "")\(Int(pct.rounded()))%"
    }

    private var sleepChangeColor: Color {
        guard let c = sleepChange else { return .clear }
        return c.hasPrefix("+") ? Color(red: 0.2, green: 0.85, blue: 0.4) : Color(red: 1.0, green: 0.38, blue: 0.38)
    }

    private var hrvString: String {
        guard let hrv = latestCheckIn?.hrvMs else { return "—" }
        return "\(Int(hrv)) ms"
    }

    private var hrvProgress: Double {
        guard let hrv = latestCheckIn?.hrvMs else { return 0 }
        return min(hrv / 100.0, 1.0)
    }

    private var restingHRString: String {
        guard let hr = latestCheckIn?.restingHR else { return "—" }
        return "\(Int(hr)) BPM"
    }

    private var insight: (label: String, body: String) {
        guard latestCheckIn != nil else {
            return ("Complete your first check-in:", "Log your daily metrics to receive personalised recovery insights and training recommendations.")
        }
        switch recoveryScore {
        case 85...100: return ("Optimal Performance Window:", "Your CNS recovery is at peak levels. High intensity training is recommended.")
        case 75..<85:  return ("Good Recovery Status:", "Your body is well recovered. Moderate to high intensity training is appropriate today.")
        case 60..<75:  return ("Moderate Recovery:", "Consider a moderate session today. Prioritise sleep and hydration to boost recovery.")
        case 40..<60:  return ("Fair Recovery:", "Your body needs more rest. Light activity or active recovery is recommended today.")
        default:       return ("Low Recovery Alert:", "Your recovery is compromised. Rest is strongly recommended. Avoid intense training today.")
        }
    }

    private var nextPhase: (icon: String, iconBg: Color, title: String, subtitle: String) {
        guard latestCheckIn != nil else {
            return ("plus.circle", accentBlue, "Log Check-In", "Complete today's check-in first")
        }
        switch recoveryScore {
        case 85...100: return ("figure.run",        accentBlue,                               "High Intensity",    "Suggested duration: 60 minutes")
        case 75..<85:  return ("dumbbell.fill",      Color(red: 0.3, green: 0.45, blue: 0.9), "Strength Training", "Suggested duration: 45 minutes")
        case 60..<75:  return ("figure.walk",        Color(red: 0.45, green: 0.35, blue: 0.22), "Light Training",  "Suggested duration: 30 minutes")
        case 40..<60:  return ("figure.flexibility", accentTeal.opacity(0.9),                 "Active Recovery",   "Suggested duration: 30 minutes")
        default:       return ("bed.double.fill",    Color(red: 0.35, green: 0.2, blue: 0.6), "Full Rest",         "Recommended for today")
        }
    }

    // MARK: - Body
    var body: some View {
        bgPrimary
            .ignoresSafeArea()
            .overlay(
                ZStack {
                    switch selectedTab {
                    case .home:
                        homeContent.transition(.opacity)
                    case .health:
                        HealthView(checkIns: checkIns).transition(.opacity)
                    case .trends:
                        TrendsView(checkIns: checkIns).transition(.opacity)
                    case .insights:
                        InsightsView(checkIns: checkIns).transition(.opacity)
                    case .profile:
                        Color.clear
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomNavBar
            }
            .sheet(isPresented: $showCheckIn) {
                CheckInView()
            }
            .onAppear { triggerAnimation() }
            .onChange(of: checkIns.first?.readinessScore) { _, _ in triggerAnimation() }
    }

    // MARK: - Animation
    private func triggerAnimation() {
        let target = recoveryScore
        guard target > 0 else { return }

        ringProgress   = 0
        displayedScore = 0

        withAnimation(.easeOut(duration: 1.4).delay(0.2)) {
            ringProgress = Double(target) / 100.0
        }

        // Count-up effect: step score 35 times over 1.4s
        let steps = 35
        for i in 1...steps {
            let delay = 0.2 + 1.4 * Double(i) / Double(steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                displayedScore = Int(Double(target) * Double(i) / Double(steps))
            }
        }
    }

    // MARK: - Home content
    private var homeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                topBar
                if !hasCheckedInToday { checkInPrompt }
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
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white.opacity(0.7))
                            .font(.system(size: 20))
                    )

                if latestCheckIn != nil {
                    ZStack {
                        Circle().fill(accentBlue).frame(width: 18, height: 18)
                        Text("\(recoveryScore)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 4, y: 4)
                }
            }

            Spacer()

            Text("RecoveryOS")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button { showCheckIn = true } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(accentBlue)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.top, 8)
    }

    // MARK: Check-in prompt
    private var checkInPrompt: some View {
        Button { showCheckIn = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(accentBlue.opacity(0.15)).frame(width: 42, height: 42)
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(accentBlue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Log Today's Check-In")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Complete your daily log to see real insights")
                        .font(.system(size: 12))
                        .foregroundStyle(labelGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(16)
            .background(bgCard.overlay(RoundedRectangle(cornerRadius: 14).stroke(accentBlue.opacity(0.35), lineWidth: 1)))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: Recovery score ring
    private var recoveryRing: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(135))

            if latestCheckIn != nil {
                Circle()
                    .trim(from: 0, to: 0.75 * ringProgress)
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
            }

            VStack(spacing: 4) {
                Text(latestCheckIn != nil ? "\(displayedScore)" : "—")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(recoveryStatus)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(latestCheckIn != nil ? statusColor : labelGray)
            }
        }
        .frame(width: 210, height: 210)
        .padding(.vertical, 8)
    }

    // MARK: AI insight card
    private var aiInsightCard: some View {
        Group {
            Text(insight.label + " ")
                .foregroundStyle(accentBlue)
                .fontWeight(.semibold)
            + Text(insight.body)
                .foregroundStyle(.white)
        }
        .font(.system(size: 14))
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Metrics row
    private var metricsRow: some View {
        HStack(spacing: 12) {
            metricCard(
                icon: "moon.fill", iconColor: .white.opacity(0.7),
                badge: sleepChange, badgeColor: sleepChangeColor,
                label: "SLEEP QUALITY", value: sleepString, trendIcon: nil
            )
            metricCard(
                icon: "heart", iconColor: .white.opacity(0.7),
                badge: nil, badgeColor: .clear,
                label: "RESTING HR", value: restingHRString,
                trendIcon: latestCheckIn != nil ? "arrow.down.right" : nil
            )
        }
    }

    private func metricCard(
        icon: String, iconColor: Color,
        badge: String?, badgeColor: Color,
        label: String, value: String,
        trendIcon: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(iconColor)
                Spacer()
                if let badge {
                    Text(badge).font(.system(size: 12, weight: .semibold)).foregroundStyle(badgeColor)
                } else if let trendIcon {
                    Image(systemName: trendIcon).font(.system(size: 14, weight: .semibold)).foregroundStyle(accentTeal)
                }
            }
            Text(label).font(.system(size: 10, weight: .medium)).kerning(1).foregroundStyle(labelGray)
            Text(value).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.white)
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
                Text(hrvString)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if latestCheckIn?.hrvMs != nil {
                    Text("ABOVE BASELINE")
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(1)
                        .foregroundStyle(accentTeal)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [accentBlue, accentTeal], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * hrvProgress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("DAY 1").font(.system(size: 10)).foregroundStyle(labelGray)
                Spacer()
                Text("DAY 7").font(.system(size: 10)).foregroundStyle(labelGray)
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
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(nextPhase.iconBg).frame(width: 52, height: 52)
                    Image(systemName: nextPhase.icon).font(.system(size: 24)).foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(nextPhase.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(nextPhase.subtitle)
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
                    if tab == .profile { onProfileTapped?() }
                    else { selectedTab = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon).font(.system(size: 20))
                        Text(tab.rawValue).font(.system(size: 9, weight: .medium)).kerning(0.5)
                    }
                    .foregroundStyle(selectedTab == tab ? .white : Color.white.opacity(0.35))
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
}

#Preview {
    DashboardView()
        .modelContainer(for: DailyCheckIn.self, inMemory: true)
}
