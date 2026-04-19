//
//  InsightsView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 11/04/2026.
//

import SwiftUI
import UIKit

struct InsightsView: View {
    let checkIns: [DailyCheckIn]

    private let bgCard      = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue  = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal  = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let accentPurple = Color(red: 0.55, green: 0.35, blue: 0.98)
    private let labelGray   = Color.white.opacity(0.45)

    private var latest: DailyCheckIn? { checkIns.first }

    // MARK: - Insight model
    struct Insight {
        let icon: String
        let iconColor: Color
        let badge: String
        let badgeColor: Color
        let title: String
        let body: String
    }

    private var insights: [Insight] {
        guard let latest else { return [] }
        var result: [Insight] = []
        let score = latest.readinessScore ?? 0

        result.append(recoveryInsight(score: score))
        if let sleep = latest.sleepHours  { result.append(sleepInsight(hours: sleep)) }
        if let hrv   = latest.hrvMs       { result.append(hrvInsight(latest: hrv)) }
        result.append(trainingInsight(score: score))
        let streak = calculateStreak()
        if streak > 1 { result.append(streakInsight(days: streak)) }

        return result
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack {
                    Text("Insights")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.top, 8)

                if checkIns.isEmpty {
                    emptyState
                } else {
                    ForEach(insights.indices, id: \.self) { insightCard(insights[$0]) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Insight card
    private func insightCard(_ item: Insight) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.iconColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(item.iconColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(item.badge)
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.8)
                        .foregroundStyle(item.badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.badgeColor.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(item.body)
                    .font(.system(size: 13))
                    .foregroundStyle(labelGray)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            Button {
                UIPasteboard.general.string = "\(item.title): \(item.body)"
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label("Copy Insight", systemImage: "doc.on.doc")
            }
            Button {
                UIPasteboard.general.string = "RecoveryOS Insight — \(item.title): \(item.body)"
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label("Share Insight", systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.55))
                .padding(.top, 60)
            Text("No Insights Yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Complete your first check-in to get personalised recovery insights.")
                .font(.system(size: 14))
                .foregroundStyle(labelGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Insight generators

    private func recoveryInsight(score: Int) -> Insight {
        switch score {
        case 85...100:
            return Insight(icon: "bolt.fill", iconColor: accentTeal, badge: "OPTIMAL", badgeColor: accentTeal,
                title: "Peak Performance Window",
                body: "Your CNS is fully recovered. This is an ideal window for high intensity training, PRs, or skill work requiring maximum output.")
        case 75..<85:
            return Insight(icon: "checkmark.circle.fill", iconColor: Color(red: 0.4, green: 0.85, blue: 0.55), badge: "GOOD", badgeColor: Color(red: 0.4, green: 0.85, blue: 0.55),
                title: "Good Recovery Status",
                body: "Your body is well recovered. Moderate to high intensity training is appropriate. Monitor fatigue levels throughout your session.")
        case 60..<75:
            return Insight(icon: "minus.circle.fill", iconColor: Color(red: 1.0, green: 0.75, blue: 0.2), badge: "MODERATE", badgeColor: Color(red: 1.0, green: 0.75, blue: 0.2),
                title: "Partial Recovery",
                body: "Your body is partially recovered. Consider a moderate intensity session and prioritise sleep and hydration today to bounce back.")
        case 40..<60:
            return Insight(icon: "exclamationmark.circle.fill", iconColor: Color(red: 1.0, green: 0.55, blue: 0.2), badge: "WARNING", badgeColor: Color(red: 1.0, green: 0.55, blue: 0.2),
                title: "Low Recovery Detected",
                body: "Your recovery is below optimal. Light movement or active recovery only. Pushing hard today risks injury and prolonged fatigue.")
        default:
            return Insight(icon: "xmark.circle.fill", iconColor: Color(red: 1.0, green: 0.38, blue: 0.38), badge: "ALERT", badgeColor: Color(red: 1.0, green: 0.38, blue: 0.38),
                title: "Recovery Alert",
                body: "Your body is significantly under-recovered. Full rest is strongly recommended. Focus on sleep, hydration, and nutrition today.")
        }
    }

    private func sleepInsight(hours: Double) -> Insight {
        let formatted = formatHours(hours)
        if hours >= 8 {
            return Insight(icon: "moon.stars.fill", iconColor: accentPurple, badge: "GREAT", badgeColor: Color(red: 0.4, green: 0.85, blue: 0.55),
                title: "Excellent Sleep Duration",
                body: "You got \(formatted) of sleep — above the recommended 8 hours. Your body has had ample time to repair tissue and consolidate memory.")
        } else if hours >= 6.5 {
            return Insight(icon: "moon.fill", iconColor: accentPurple, badge: "FAIR", badgeColor: Color(red: 1.0, green: 0.75, blue: 0.2),
                title: "Adequate Sleep",
                body: "You got \(formatted) of sleep. Aim for 7.5–9 hours for optimal recovery. Consider an earlier bedtime tonight to build your sleep debt back.")
        } else {
            return Insight(icon: "moon.zzz.fill", iconColor: accentPurple, badge: "LOW", badgeColor: Color(red: 1.0, green: 0.38, blue: 0.38),
                title: "Sleep Deficit Detected",
                body: "Only \(formatted) of sleep logged. Sleep deprivation significantly impairs recovery and cognitive performance. Prioritise 8+ hours tonight.")
        }
    }

    private func hrvInsight(latest hrv: Double) -> Insight {
        let recent = checkIns.prefix(7).compactMap(\.hrvMs)
        let avg = recent.isEmpty ? hrv : recent.reduce(0, +) / Double(recent.count)
        let diff = hrv - avg
        let pct = avg > 0 ? Int(abs(diff / avg) * 100) : 0

        if diff > 5 {
            return Insight(icon: "waveform.path.ecg", iconColor: accentTeal, badge: "ABOVE", badgeColor: accentTeal,
                title: "HRV Above Baseline",
                body: "Your HRV of \(Int(hrv))ms is \(pct)% above your recent average. Strong autonomic recovery — your nervous system is responding well to your training load.")
        } else if diff >= -5 {
            return Insight(icon: "waveform.path.ecg", iconColor: accentBlue, badge: "STABLE", badgeColor: accentBlue,
                title: "HRV At Baseline",
                body: "Your HRV of \(Int(hrv))ms is in line with your recent average. Normal recovery — maintain your current training and lifestyle balance.")
        } else {
            return Insight(icon: "waveform.path.ecg", iconColor: Color(red: 1.0, green: 0.55, blue: 0.2), badge: "BELOW", badgeColor: Color(red: 1.0, green: 0.55, blue: 0.2),
                title: "HRV Below Baseline",
                body: "Your HRV of \(Int(hrv))ms is \(pct)% below your recent average. This may indicate accumulated fatigue, stress, or illness. Reduce training intensity.")
        }
    }

    private func trainingInsight(score: Int) -> Insight {
        switch score {
        case 80...100:
            return Insight(icon: "figure.run", iconColor: accentBlue, badge: "GO", badgeColor: accentBlue,
                title: "Cleared for High Intensity",
                body: "Your recovery supports peak output today. Target strength PRs, speed work, or high-intensity intervals for maximum adaptation.")
        case 60..<80:
            return Insight(icon: "figure.walk", iconColor: Color(red: 1.0, green: 0.75, blue: 0.2), badge: "MODERATE", badgeColor: Color(red: 1.0, green: 0.75, blue: 0.2),
                title: "Moderate Training Recommended",
                body: "Keep RPE at 6–7/10. Skill work, technique sessions, or tempo efforts are ideal. Avoid all-out efforts and prioritise form over intensity.")
        default:
            return Insight(icon: "figure.flexibility", iconColor: Color(red: 1.0, green: 0.55, blue: 0.2), badge: "EASY", badgeColor: Color(red: 1.0, green: 0.55, blue: 0.2),
                title: "Active Recovery Day",
                body: "Light movement, stretching, yoga, or a slow walk will support recovery without adding additional stress to your system. Let your body rebuild.")
        }
    }

    private func streakInsight(days: Int) -> Insight {
        Insight(icon: "flame.fill", iconColor: Color(red: 1.0, green: 0.55, blue: 0.2), badge: "STREAK", badgeColor: Color(red: 1.0, green: 0.75, blue: 0.2),
            title: "\(days) Day Recovery Streak",
            body: "You've scored above 70 for \(days) consecutive days. Consistent recovery habits compound over time — keep prioritising sleep, nutrition, and daily check-ins.")
    }

    // MARK: - Helpers
    private func calculateStreak() -> Int {
        var count = 0
        for ci in checkIns {
            if (ci.readinessScore ?? 0) >= 70 { count += 1 } else { break }
        }
        return count
    }

    private func formatHours(_ h: Double) -> String {
        let hrs = Int(h); let mins = Int((h - Double(hrs)) * 60)
        return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
    }
}

#Preview {
    ZStack {
        Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()
        InsightsView(checkIns: [])
    }
}
