//
//  HealthView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 11/04/2026.
//

import SwiftUI

struct HealthView: View {
    let checkIns: [DailyCheckIn]
    var snapshot: HealthKitSnapshot = HealthKitSnapshot()

    @State private var activeMetric: HealthMetric? = nil
    @State private var showSleepDetail = false

    private let bgCard       = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue   = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal   = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let accentPurple = Color(red: 0.55, green: 0.35, blue: 0.98)
    private let labelGray    = Color.white.opacity(0.45)

    private var latest: DailyCheckIn? { checkIns.first }
    private var last7: [DailyCheckIn] { Array(checkIns.prefix(7)) }

    // Biometrics: check-in first, fall back to live snapshot
    private var sleepHours: Double?      { latest?.sleepHours      ?? snapshot.sleepHours }
    private var hrvMs: Double?           { latest?.hrvMs            ?? snapshot.hrvMs }
    private var restingHR: Double?       { latest?.restingHR        ?? snapshot.restingHR }
    private var activeCalories: Double?  { latest?.activeCalories   ?? snapshot.activeCalories }
    private var stepCount: Double?       { latest?.stepCount        ?? snapshot.stepCount }
    private var restingEnergy: Double?   { latest?.restingEnergy    ?? snapshot.restingEnergy }
    private var exerciseMinutes: Double? { latest?.exerciseMinutes  ?? snapshot.exerciseMinutes }

    private var avgSleep: Double? {
        let v = last7.compactMap(\.sleepHours)
        guard !v.isEmpty else { return nil }
        return v.reduce(0, +) / Double(v.count)
    }

    private var avgHRV: Double? {
        let v = last7.compactMap(\.hrvMs)
        guard !v.isEmpty else { return nil }
        return v.reduce(0, +) / Double(v.count)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header
                if checkIns.isEmpty && snapshot.sleepHours == nil {
                    emptyState
                } else {
                    todayCard
                    sleepCard
                    heartRow
                    activityRow
                    wellbeingCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .sheet(item: $activeMetric) { metric in
            MetricDetailView(
                metric: metric,
                checkIns: checkIns,
                currentValue: snapshotValue(for: metric)
            )
        }
        .sheet(isPresented: $showSleepDetail) {
            SleepDetailView(session: snapshot.sleepSession)
        }
    }

    private func snapshotValue(for metric: HealthMetric) -> Double? {
        switch metric {
        case .sleep:           return snapshot.sleepHours
        case .hrv:             return snapshot.hrvMs
        case .restingHR:       return snapshot.restingHR
        case .activeCalories:  return snapshot.activeCalories
        case .steps:           return snapshot.stepCount
        case .restingEnergy:   return snapshot.restingEnergy
        case .exerciseMinutes: return snapshot.exerciseMinutes
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Health")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "hand.tap")
                .font(.system(size: 13))
                .foregroundStyle(labelGray)
            Text("Tap any card")
                .font(.system(size: 12))
                .foregroundStyle(labelGray)
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 52))
                .foregroundStyle(accentBlue.opacity(0.55))
                .padding(.top, 60)
            Text("No Health Data Yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Complete your first daily check-in to see your health metrics here.")
                .font(.system(size: 14))
                .foregroundStyle(labelGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Today card
    private var todayCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY'S RECOVERY")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(labelGray)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(latest?.readinessScore ?? 0)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(statusLabel(latest?.readinessScore ?? 0))
                        .font(.system(size: 12, weight: .bold))
                        .kerning(1.5)
                        .foregroundStyle(statusColor(latest?.readinessScore ?? 0))
                        .padding(.bottom, 6)
                }
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(labelGray)
            }
            Spacer()
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: 0.75 * Double(latest?.readinessScore ?? 0) / 100.0)
                    .stroke(
                        AngularGradient(colors: [accentBlue, accentTeal, accentBlue], center: .center,
                                        startAngle: .degrees(135), endAngle: .degrees(405)),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
            }
            .frame(width: 66, height: 66)
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Sleep card (tappable)
    private var sleepCard: some View {
        Button { showSleepDetail = true } label: {
            VStack(alignment: .leading, spacing: 12) {
                metricHeader(icon: "moon.fill", color: accentPurple, label: "SLEEP", chevron: true)

                Text(formatSleep(sleepHours))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if let avg = avgSleep {
                    HStack {
                        Text("7-day average")
                            .font(.system(size: 12))
                            .foregroundStyle(labelGray)
                        Spacer()
                        Text(formatSleep(avg))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                if let hours = sleepHours {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)).frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [accentPurple, accentBlue], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * min(hours / 9.0, 1.0), height: 6)
                        }
                    }
                    .frame(height: 6)
                    HStack {
                        Text("0h").font(.system(size: 10)).foregroundStyle(labelGray)
                        Spacer()
                        Text("9h+").font(.system(size: 10)).foregroundStyle(labelGray)
                    }
                }
            }
            .padding(16)
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - HRV + Resting HR row
    private var heartRow: some View {
        HStack(spacing: 12) {
            tappableMetricCard(metric: .hrv, value: hrvMs.map { "\(Int($0)) ms" } ?? "—") {
                metricHeader(icon: "waveform.path.ecg", color: accentTeal, label: "HRV", chevron: true)
                if let hrv = hrvMs, let avg = avgHRV {
                    Text(hrv >= avg ? "ABOVE BASELINE" : "BELOW BASELINE")
                        .font(.system(size: 9, weight: .bold)).kerning(1)
                        .foregroundStyle(hrv >= avg ? accentTeal : Color(red: 1.0, green: 0.55, blue: 0.2))
                }
            }
            tappableMetricCard(metric: .restingHR, value: restingHR.map { "\(Int($0)) BPM" } ?? "—") {
                metricHeader(icon: "heart.fill", color: Color(red: 1.0, green: 0.3, blue: 0.4), label: "RESTING HR", chevron: true)
                if let hr = restingHR {
                    let label = hr < 60 ? "ATHLETE RANGE" : hr < 80 ? "NORMAL RANGE" : "ELEVATED"
                    let color = hr < 60 ? accentTeal : hr < 80 ? accentBlue : Color(red: 1.0, green: 0.55, blue: 0.2)
                    Text(label).font(.system(size: 9, weight: .bold)).kerning(1).foregroundStyle(color)
                }
            }
        }
    }

    // MARK: - Activity row (calories, steps, exercise, resting energy)
    private var activityRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                tappableMetricCard(
                    metric: .activeCalories,
                    value: activeCalories.map { "\(Int($0))" } ?? "—",
                    unit: "kcal"
                ) {
                    metricHeader(icon: "flame.fill", color: Color(red: 1.0, green: 0.55, blue: 0.15), label: "ACTIVE CAL", chevron: true)
                }
                tappableMetricCard(
                    metric: .steps,
                    value: stepCount.map { Int($0).formatted() } ?? "—",
                    unit: "steps"
                ) {
                    metricHeader(icon: "figure.walk", color: accentTeal, label: "STEPS", chevron: true)
                }
            }
            HStack(spacing: 12) {
                tappableMetricCard(
                    metric: .exerciseMinutes,
                    value: exerciseMinutes.map { "\(Int($0))" } ?? "—",
                    unit: "min"
                ) {
                    metricHeader(icon: "stopwatch.fill", color: Color(red: 0.40, green: 0.85, blue: 0.55), label: "EXERCISE", chevron: true)
                }
                tappableMetricCard(
                    metric: .restingEnergy,
                    value: restingEnergy.map { "\(Int($0))" } ?? "—",
                    unit: "kcal"
                ) {
                    metricHeader(icon: "bed.double.fill", color: accentBlue, label: "RESTING ENERGY", chevron: true)
                }
            }
        }
    }

    // MARK: - Wellbeing card
    private var wellbeingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WELLBEING")
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.5)
                .foregroundStyle(labelGray)

            wellbeingRow("Energy",    value: latest?.energy ?? 0,    invert: false)
            wellbeingRow("Soreness",  value: latest?.soreness ?? 0,  invert: true)
            wellbeingRow("Stress",    value: latest?.stress ?? 0,    invert: true)
            wellbeingRow("Hydration", value: latest?.hydration ?? 0, invert: false)
            wellbeingRow("Mood",      value: latest?.mood ?? 0,      invert: false)
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Reusable subviews

    private func metricHeader(icon: String, color: Color, label: String, chevron: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color)
            Text(label).font(.system(size: 10, weight: .semibold)).kerning(1.2).foregroundStyle(labelGray)
            Spacer()
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.2))
            }
        }
    }

    @ViewBuilder
    private func tappableMetricCard<Header: View>(
        metric: HealthMetric,
        value: String,
        unit: String? = nil,
        @ViewBuilder header: () -> Header
    ) -> some View {
        Button { activeMetric = metric } label: {
            VStack(alignment: .leading, spacing: 8) {
                header()
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if let unit {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(labelGray)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func wellbeingRow(_ label: String, value: Int, invert: Bool) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 74, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(value: value, invert: invert))
                        .frame(width: geo.size.width * (Double(value) / 10.0), height: 6)
                }
            }
            .frame(height: 6)
            Text("\(value)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, alignment: .trailing)
                .monospacedDigit()
        }
    }

    // MARK: - Helpers
    private func formatSleep(_ hours: Double?) -> String {
        guard let h = hours else { return "—" }
        let hrs = Int(h); let mins = Int((h - Double(hrs)) * 60)
        return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
    }

    private func statusLabel(_ score: Int) -> String {
        switch score {
        case 85...100: return "OPTIMAL"
        case 75..<85:  return "GOOD"
        case 60..<75:  return "MODERATE"
        case 40..<60:  return "FAIR"
        default:       return "POOR"
        }
    }

    private func statusColor(_ score: Int) -> Color {
        switch score {
        case 85...100: return accentTeal
        case 75..<85:  return Color(red: 0.4, green: 0.85, blue: 0.55)
        case 60..<75:  return Color(red: 1.0, green: 0.75, blue: 0.2)
        case 40..<60:  return Color(red: 1.0, green: 0.55, blue: 0.2)
        default:       return Color(red: 1.0, green: 0.38, blue: 0.38)
        }
    }

    private func barColor(value: Int, invert: Bool) -> Color {
        let n = invert ? (11 - value) : value
        switch n {
        case 9...10: return accentTeal
        case 7...8:  return Color(red: 0.4, green: 0.85, blue: 0.55)
        case 5...6:  return Color(red: 1.0, green: 0.75, blue: 0.2)
        default:     return Color(red: 1.0, green: 0.38, blue: 0.38)
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()
        HealthView(checkIns: [])
    }
}
