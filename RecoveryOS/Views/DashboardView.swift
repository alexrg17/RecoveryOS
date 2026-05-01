//
//  DashboardView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 03/04/2026.
//

import SwiftUI
import SwiftData
import UIKit

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

// The root view after login. Hosts the tab bar and switches between content areas
// using a ZStack rather than TabView so we can control the transition animations
// and attach a horizontal swipe gesture to the whole screen.
struct DashboardView: View {
    var onSignedOut: (() -> Void)? = nil

    // Injected from RecoveryOSApp so the same controller instance is shared
    // across every tab without needing to recreate it on each tab switch.
    @EnvironmentObject private var dashboardController: DashboardController
    @EnvironmentObject private var healthKit: HealthKitManager
    @Environment(\.modelContext) private var modelContext

    // Sorted newest first so checkIns.first always gives today's entry
    // and checkIns[1] gives yesterday's for comparison calculations.
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query private var profiles: [UserProfile]

    @State private var selectedTab: TabItem = .home
    @State private var showCheckIn            = false
    @State private var showNotificationPicker = false
    @State private var notificationSent: NotificationManager.DemoNotification? = nil

    // Ring + score animation
    @State private var ringProgress: Double = 0
    @State private var displayedScore: Int  = 0

    // MARK: - Computed data (View reads Model, passes to Controller for interpretation)

    private var latestCheckIn:   DailyCheckIn? { checkIns.first }
    private var previousCheckIn: DailyCheckIn? { checkIns.count > 1 ? checkIns[1] : nil }
    private var recoveryScore:   Int           { latestCheckIn?.readinessScore ?? 0 }

    private var hasCheckedInToday: Bool {
        guard let latest = latestCheckIn else { return false }
        return Calendar.current.isDateInToday(latest.date)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            bgPrimary.ignoresSafeArea()

            switch selectedTab {
            case .home:
                homeContent.transition(.opacity)
            case .health:
                HealthView(checkIns: checkIns, snapshot: healthKit.latestSnapshot).transition(.opacity)
            case .trends:
                TrendsView(checkIns: checkIns).transition(.opacity)
            case .insights:
                InsightsView(checkIns: checkIns).transition(.opacity)
            case .profile:
                SettingsView(onSignedOut: { onSignedOut?() }).transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .simultaneousGesture(swipeTabGesture)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomNavBar
        }
        .sheet(isPresented: $showCheckIn) {
            CheckInView(prefill: hasCheckedInToday ? nil : healthKit.latestSnapshot)
        }
        .sheet(isPresented: $showNotificationPicker) {
            NotificationPickerView(sentNotification: $notificationSent)
        }
        .onAppear {
            triggerAnimation()
            healthKit.syncToContext(modelContext)
        }
        // Controller fetches AI advice whenever a new check-in is submitted
        .task {
            await dashboardController.refreshAdvice(profile: profiles.first, checkIns: checkIns)
        }
        .onChange(of: checkIns.first?.id) { _, _ in
            Task { await dashboardController.refreshAdvice(profile: profiles.first, checkIns: checkIns) }
        }
        .onChange(of: checkIns.first?.readinessScore) { _, _ in triggerAnimation() }
        .onChange(of: healthKit.isAuthorized) { _, granted in
            if granted { healthKit.syncToContext(modelContext) }
        }
    }

    // MARK: - Animation

    // Animates the score ring filling up and the number counting from 0 to the target.
    // The ring uses SwiftUI's built-in animation, but the number count-up is done
    // manually with DispatchQueue because SwiftUI's contentTransition(.numericText())
    // only transitions between two values, not across a range of intermediate steps.
    private func triggerAnimation() {
        let target = recoveryScore
        guard target > 0 else { return }

        ringProgress   = 0
        displayedScore = 0

        withAnimation(.easeOut(duration: 1.4).delay(0.2)) {
            ringProgress = Double(target) / 100.0
        }

        // Step through 35 increments spread evenly across 1.4 seconds so the
        // number appears to count up in sync with the ring filling animation.
        let steps = 35
        for i in 1...steps {
            let delay = 0.2 + 1.4 * Double(i) / Double(steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                displayedScore = Int(Double(target) * Double(i) / Double(steps))
            }
        }
    }

    // MARK: - Swipe gesture

    // Lets the user switch tabs by swiping left or right anywhere on the screen,
    // which is more natural than reaching down to tap the tab bar each time.
    // The 1.5x ratio check ensures that a mostly vertical scroll does not
    // accidentally trigger a tab change, and the 50pt minimum adds a threshold
    // so small accidental movements are ignored.
    private var swipeTabGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let h = value.translation.width
                let v = value.translation.height
                guard abs(h) > abs(v) * 1.5, abs(h) > 50 else { return }
                let tabs = TabItem.allCases
                guard let index = tabs.firstIndex(of: selectedTab) else { return }
                if h < 0, index < tabs.count - 1 {
                    selectedTab = tabs[index + 1]
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else if h > 0, index > 0 {
                    selectedTab = tabs[index - 1]
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

            Button { showNotificationPicker = true } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundStyle(accentTeal)
                    .frame(width: 44, height: 44)
            }

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

                // Controller interprets the score into a human-readable status
                Text(dashboardController.recoveryStatus(for: recoveryScore, hasData: latestCheckIn != nil))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(latestCheckIn != nil ? dashboardController.statusColor(for: recoveryScore) : labelGray)
            }
        }
        .frame(width: 210, height: 210)
        .padding(.vertical, 8)
        // Double tap replays the ring fill animation, useful for demo purposes
        // or if the user wants to watch the score animate again.
        .onTapGesture(count: 2) {
            triggerAnimation()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        // Long press reveals share options without cluttering the main UI.
        .contextMenu {
            Button {
                UIPasteboard.general.string = "\(recoveryScore)/100"
            } label: {
                Label("Copy Score", systemImage: "doc.on.doc")
            }
            Button {
                UIPasteboard.general.string = "My RecoveryOS readiness score today: \(recoveryScore)/100 (\(dashboardController.recoveryStatus(for: recoveryScore, hasData: latestCheckIn != nil)))"
            } label: {
                Label("Share Progress", systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: AI insight card
    // View reads display state from DashboardController (MVC)
    private var aiInsightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: dashboardController.usedAI ? "sparkles" : "lightbulb.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(accentBlue)
                Text(dashboardController.usedAI ? "AI COACH" : "RECOVERY INSIGHT")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(Color.white.opacity(0.4))
                Spacer()
                if dashboardController.isGenerating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(accentBlue)
                }
            }
            if dashboardController.isGenerating && dashboardController.aiAdvice.isEmpty {
                Text("Generating your personalised advice...")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if !dashboardController.aiAdvice.isEmpty {
                Text(dashboardController.aiAdvice)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Controller provides fallback insight text
                let fallback = dashboardController.insightText(for: recoveryScore, hasData: latestCheckIn != nil)
                Group {
                    Text("\(fallback.label) ")
                        .foregroundStyle(accentBlue)
                        .fontWeight(.semibold)
                    + Text(fallback.body)
                        .foregroundStyle(.white)
                }
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Metrics row
    // Controller formats raw Model values into display strings
    private var metricsRow: some View {
        let change      = dashboardController.sleepChange(today: latestCheckIn, previous: previousCheckIn)
        let changeColor = dashboardController.sleepChangeColor(for: change)
        return HStack(spacing: 12) {
            metricCard(
                icon: "moon.fill", iconColor: .white.opacity(0.7),
                badge: change, badgeColor: changeColor,
                label: "SLEEP QUALITY",
                value: dashboardController.sleepString(from: latestCheckIn, snapshot: healthKit.latestSnapshot),
                trendIcon: nil
            )
            metricCard(
                icon: "heart", iconColor: .white.opacity(0.7),
                badge: nil, badgeColor: .clear,
                label: "RESTING HR",
                value: dashboardController.restingHRString(from: latestCheckIn, snapshot: healthKit.latestSnapshot),
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
                // Controller formats the HRV value from the Model
                Text(dashboardController.hrvString(from: latestCheckIn, snapshot: healthKit.latestSnapshot))
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
                        .frame(width: geo.size.width * dashboardController.hrvProgress(from: latestCheckIn, snapshot: healthKit.latestSnapshot), height: 6)
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
    // Controller determines the appropriate training phase from the readiness score
    private var nextPhaseCard: some View {
        let phase = dashboardController.nextPhase(for: recoveryScore, hasData: latestCheckIn != nil)
        return VStack(alignment: .leading, spacing: 10) {
            Text("NEXT PHASE")
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.5)
                .foregroundStyle(accentBlue)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(phase.iconBg).frame(width: 52, height: 52)
                    Image(systemName: phase.icon).font(.system(size: 24)).foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(phase.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(phase.subtitle)
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
        .environmentObject(DashboardController())
        .environmentObject(HealthKitManager.shared)
        .modelContainer(for: [DailyCheckIn.self, UserProfile.self], inMemory: true)
}
