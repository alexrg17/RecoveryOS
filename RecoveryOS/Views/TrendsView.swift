//
//  TrendsView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 11/04/2026.
//

import SwiftUI
import Charts

struct TrendsView: View {
    let checkIns: [DailyCheckIn]

    @State private var selectedPeriod = 7

    private let bgCard       = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue   = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal   = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let accentPurple = Color(red: 0.55, green: 0.35, blue: 0.98)
    private let labelGray    = Color.white.opacity(0.45)

    private var displayData: [DailyCheckIn] {
        Array(checkIns.prefix(selectedPeriod).reversed())
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                headerRow.padding(.top, 8)

                if displayData.isEmpty {
                    emptyState
                } else {
                    recoveryChart
                    sleepChart
                    if displayData.contains(where: { $0.hrvMs != nil }) {
                        hrvChart
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Header + period picker
    private var headerRow: some View {
        HStack {
            Text("Trends")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 0) {
                ForEach([7, 30], id: \.self) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPeriod = period }
                    } label: {
                        Text("\(period)D")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedPeriod == period ? .white : Color.white.opacity(0.4))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedPeriod == period ? accentBlue : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                }
            }
            .padding(3)
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 52))
                .foregroundStyle(accentBlue.opacity(0.55))
                .padding(.top, 60)
            Text("No Trend Data Yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Log at least 2 check-ins to start seeing your trends.")
                .font(.system(size: 14))
                .foregroundStyle(labelGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recovery score chart
    private var recoveryChart: some View {
        let data = displayData.compactMap { ci -> (Date, Int)? in
            guard let s = ci.readinessScore else { return nil }
            return (ci.date, s)
        }
        let avg = data.isEmpty ? 0 : data.map(\.1).reduce(0, +) / data.count

        return chartCard(icon: "bolt.fill", iconColor: accentBlue, label: "RECOVERY SCORE",
                         summary: data.isEmpty ? nil : "Avg \(avg)") {
            Chart {
                ForEach(data, id: \.0) { date, score in
                    AreaMark(x: .value("Date", date), y: .value("Score", score))
                        .foregroundStyle(LinearGradient(
                            colors: [accentBlue.opacity(0.35), .clear],
                            startPoint: .top, endPoint: .bottom
                        ))
                    LineMark(x: .value("Date", date), y: .value("Score", score))
                        .foregroundStyle(accentBlue)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    PointMark(x: .value("Date", date), y: .value("Score", score))
                        .foregroundStyle(accentBlue)
                        .symbolSize(28)
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .frame(height: 160)
            .environment(\.colorScheme, .dark)
        }
    }

    // MARK: - Sleep chart
    private var sleepChart: some View {
        let data = displayData.compactMap { ci -> (Date, Double)? in
            guard let s = ci.sleepHours else { return nil }
            return (ci.date, s)
        }
        let avg = data.isEmpty ? 0.0 : data.map(\.1).reduce(0, +) / Double(data.count)

        return chartCard(icon: "moon.fill", iconColor: accentPurple, label: "SLEEP",
                         summary: data.isEmpty ? nil : "Avg \(String(format: "%.1f", avg))h") {
            if data.isEmpty {
                Text("No sleep data logged yet")
                    .font(.system(size: 13))
                    .foregroundStyle(labelGray)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(data, id: \.0) { date, hours in
                        BarMark(x: .value("Date", date, unit: .day), y: .value("Hours", hours))
                            .foregroundStyle(LinearGradient(
                                colors: [accentPurple, accentBlue],
                                startPoint: .bottom, endPoint: .top
                            ))
                    }
                    RuleMark(y: .value("Target", 8.0))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(accentTeal.opacity(0.6))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("8h target")
                                .font(.system(size: 9))
                                .foregroundStyle(accentTeal.opacity(0.7))
                        }
                }
                .chartYScale(domain: 0...12)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
                    }
                }
                .frame(height: 140)
                .environment(\.colorScheme, .dark)
            }
        }
    }

    // MARK: - HRV chart
    private var hrvChart: some View {
        let data = displayData.compactMap { ci -> (Date, Double)? in
            guard let h = ci.hrvMs else { return nil }
            return (ci.date, h)
        }
        let avg = data.isEmpty ? 0.0 : data.map(\.1).reduce(0, +) / Double(data.count)

        return chartCard(icon: "waveform.path.ecg", iconColor: accentTeal, label: "HRV",
                         summary: avg > 0 ? "Avg \(Int(avg)) ms" : nil) {
            Chart {
                ForEach(data, id: \.0) { date, hrv in
                    AreaMark(x: .value("Date", date), y: .value("HRV", hrv))
                        .foregroundStyle(LinearGradient(
                            colors: [accentTeal.opacity(0.3), .clear],
                            startPoint: .top, endPoint: .bottom
                        ))
                    LineMark(x: .value("Date", date), y: .value("HRV", hrv))
                        .foregroundStyle(accentTeal)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    PointMark(x: .value("Date", date), y: .value("HRV", hrv))
                        .foregroundStyle(accentTeal)
                        .symbolSize(28)
                }
                if avg > 0 {
                    RuleMark(y: .value("Baseline", avg))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(accentBlue.opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .frame(height: 140)
            .environment(\.colorScheme, .dark)
        }
    }

    // MARK: - Chart card wrapper
    @ViewBuilder
    private func chartCard<Content: View>(
        icon: String, iconColor: Color,
        label: String, summary: String?,
        @ViewBuilder chart: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(labelGray)
                Spacer()
                if let summary {
                    Text(summary)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            chart()
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ZStack {
        Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()
        TrendsView(checkIns: [])
    }
}
