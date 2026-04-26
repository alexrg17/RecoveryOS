//
//  TrendsView.swift
//  RecoveryOS
//
//  Created by Alex Radu on 11/04/2026.
//

import SwiftUI
import Charts

// Shows recovery score, sleep, and HRV trends over 7 or 30 days.
// Each chart supports drag-to-scrub so the user can inspect individual data points
// without tapping, which keeps the interaction gesture-based throughout.
struct TrendsView: View {
    // checkIns is passed in from DashboardView which already has the @Query result.
    // This avoids running a duplicate query and keeps this view simpler.
    let checkIns: [DailyCheckIn]

    @State private var selectedPeriod = 7

    // Each chart tracks its own selected point independently so scrubbing one chart
    // does not affect the others. Tuples store both the date and value together
    // so the callout bubble can display both pieces of information at once.
    @State private var scoreSelection: (Date, Int)?    = nil
    @State private var sleepSelection: (Date, Double)? = nil
    @State private var hrvSelection:   (Date, Double)? = nil

    private let bgCard       = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue   = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal   = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let accentPurple = Color(red: 0.55, green: 0.35, blue: 0.98)
    private let labelGray    = Color.white.opacity(0.45)

    // Takes the most recent N check-ins and reverses them so the chart reads
    // left to right chronologically, with the oldest date on the left.
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

    // MARK: - Header
    private var headerRow: some View {
        HStack {
            Text("Trends")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 0) {
                ForEach([7, 30], id: \.self) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                            // Clear all scrub selections when switching period so the
                            // callout bubbles from the previous period do not persist.
                            scoreSelection = nil
                            sleepSelection = nil
                            hrvSelection   = nil
                        }
                    } label: {
                        Text("\(period)D")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedPeriod == period ? .white : Color.white.opacity(0.4))
                            .padding(.horizontal, 14).padding(.vertical, 7)
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
        // compactMap filters out check-ins that have no readiness score yet,
        // which can happen if the record was inserted before the score was calculated.
        let data = displayData.compactMap { ci -> (Date, Int)? in
            guard let s = ci.readinessScore else { return nil }
            return (ci.date, s)
        }
        let avg = data.isEmpty ? 0 : data.map(\.1).reduce(0, +) / data.count
        // When nothing is scrubbed, show the period average as a useful default summary.
        let summaryValue = scoreSelection.map { "\($0.1)" } ?? (data.isEmpty ? nil : "Avg \(avg)")

        return chartCard(
            icon: "bolt.fill", iconColor: accentBlue, label: "RECOVERY SCORE",
            summary: summaryValue,
            summaryDate: scoreSelection?.0
        ) {
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
                        .foregroundStyle(scoreSelection?.0 == date ? .white : accentBlue)
                        .symbolSize(scoreSelection?.0 == date ? 80 : 24)
                }
                if let (selDate, selScore) = scoreSelection {
                    RuleMark(x: .value("Selected", selDate))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    PointMark(x: .value("Date", selDate), y: .value("Score", selScore))
                        .foregroundStyle(.white).symbolSize(100)
                        .annotation(position: .top, spacing: 6) {
                            scrubCallout(value: "\(selScore)", date: selDate, color: accentBlue)
                        }
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis { AxisMarks { _ in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
            }}
            .chartYAxis { AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
            }}
            .chartOverlay { proxy in scrubOverlay(proxy: proxy) { x in
                if let date: Date = proxy.value(atX: x) {
                    scoreSelection = data.min { abs($0.0.timeIntervalSince(date)) < abs($1.0.timeIntervalSince(date)) }
                }
            } onEnd: { scoreSelection = nil } }
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
        let summaryValue = sleepSelection.map { formatSleep($0.1) } ?? (data.isEmpty ? nil : "Avg \(String(format: "%.1f", avg))h")

        return chartCard(
            icon: "moon.fill", iconColor: accentPurple, label: "SLEEP",
            summary: summaryValue,
            summaryDate: sleepSelection?.0
        ) {
            if data.isEmpty {
                Text("No sleep data logged yet")
                    .font(.system(size: 13)).foregroundStyle(labelGray)
                    .frame(height: 120).frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(data, id: \.0) { date, hours in
                        BarMark(x: .value("Date", date, unit: .day), y: .value("Hours", hours))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: sleepSelection?.0 == date ? [accentPurple, accentPurple] : [accentPurple, accentBlue],
                                    startPoint: .bottom, endPoint: .top
                                )
                            )
                    }
                    RuleMark(y: .value("Target", 8.0))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(accentTeal.opacity(0.6))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("8h target").font(.system(size: 9)).foregroundStyle(accentTeal.opacity(0.7))
                        }
                    if let (selDate, selHours) = sleepSelection {
                        BarMark(x: .value("Date", selDate, unit: .day), y: .value("Hours", selHours))
                            .foregroundStyle(accentPurple)
                            .annotation(position: .top, spacing: 4) {
                                scrubCallout(value: formatSleep(selHours), date: selDate, color: accentPurple)
                            }
                    }
                }
                .chartYScale(domain: 0...12)
                .chartXAxis { AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
                }}
                .chartYAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
                }}
                .chartOverlay { proxy in scrubOverlay(proxy: proxy) { x in
                    if let date: Date = proxy.value(atX: x) {
                        sleepSelection = data.min { abs($0.0.timeIntervalSince(date)) < abs($1.0.timeIntervalSince(date)) }
                    }
                } onEnd: { sleepSelection = nil } }
                .frame(height: 140)
                .environment(\.colorScheme, .dark)
            }
        }
    }

    // MARK: - HRV chart
    // The HRV chart is only shown when at least one check-in has HRV data logged,
    // checked in the parent VStack. This avoids displaying an empty placeholder
    // for users who have not granted Apple Watch heart rate permission.
    private var hrvChart: some View {
        let data = displayData.compactMap { ci -> (Date, Double)? in
            guard let h = ci.hrvMs else { return nil }
            return (ci.date, h)
        }
        let avg = data.isEmpty ? 0.0 : data.map(\.1).reduce(0, +) / Double(data.count)
        let summaryValue = hrvSelection.map { "\(Int($0.1)) ms" } ?? (avg > 0 ? "Avg \(Int(avg)) ms" : nil)

        return chartCard(
            icon: "waveform.path.ecg", iconColor: accentTeal, label: "HRV",
            summary: summaryValue,
            summaryDate: hrvSelection?.0
        ) {
            Chart {
                ForEach(data, id: \.0) { date, hrv in
                    AreaMark(x: .value("Date", date), y: .value("HRV", hrv))
                        .foregroundStyle(LinearGradient(
                            colors: [accentTeal.opacity(0.3), .clear],
                            startPoint: .top, endPoint: .bottom
                        ))
                    LineMark(x: .value("Date", date), y: .value("HRV", hrv))
                        .foregroundStyle(accentTeal).lineStyle(StrokeStyle(lineWidth: 2.5))
                    PointMark(x: .value("Date", date), y: .value("HRV", hrv))
                        .foregroundStyle(hrvSelection?.0 == date ? .white : accentTeal)
                        .symbolSize(hrvSelection?.0 == date ? 80 : 24)
                }
                if avg > 0 {
                    RuleMark(y: .value("Baseline", avg))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(accentBlue.opacity(0.5))
                }
                if let (selDate, selHrv) = hrvSelection {
                    RuleMark(x: .value("Selected", selDate))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    PointMark(x: .value("Date", selDate), y: .value("HRV", selHrv))
                        .foregroundStyle(.white).symbolSize(100)
                        .annotation(position: .top, spacing: 6) {
                            scrubCallout(value: "\(Int(selHrv)) ms", date: selDate, color: accentTeal)
                        }
                }
            }
            .chartXAxis { AxisMarks { _ in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
            }}
            .chartYAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                AxisValueLabel().foregroundStyle(Color.white.opacity(0.4))
            }}
            .chartOverlay { proxy in scrubOverlay(proxy: proxy) { x in
                if let date: Date = proxy.value(atX: x) {
                    hrvSelection = data.min { abs($0.0.timeIntervalSince(date)) < abs($1.0.timeIntervalSince(date)) }
                }
            } onEnd: { hrvSelection = nil } }
            .frame(height: 140)
            .environment(\.colorScheme, .dark)
        }
    }

    // MARK: - Chart card wrapper
    @ViewBuilder
    private func chartCard<Content: View>(
        icon: String, iconColor: Color,
        label: String, summary: String?,
        summaryDate: Date?,
        @ViewBuilder chart: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11)).foregroundStyle(iconColor)
                Text(label).font(.system(size: 10, weight: .semibold)).kerning(1.2).foregroundStyle(labelGray)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    if let summary {
                        Text(summary)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.1), value: summary)
                    }
                    if let date = summaryDate {
                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.system(size: 11))
                            .foregroundStyle(labelGray)
                            .transition(.opacity)
                    }
                }
            }
            Text("Drag to explore")
                .font(.system(size: 10, weight: .medium)).kerning(1)
                .foregroundStyle(Color.white.opacity(0.2))
            chart()
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Shared scrub overlay

    // A transparent rectangle is laid on top of the chart so the whole area is
    // draggable, not just the data points. minimumDistance: 0 means the gesture
    // fires immediately on touch rather than waiting for movement, which makes
    // the scrubbing feel responsive.
    // proxy.plotFrame gives us the exact rect of the chart's data area so we can
    // subtract the left edge and get an x coordinate relative to the data, not the card.
    private func scrubOverlay(
        proxy: ChartProxy,
        onChanged: @escaping (CGFloat) -> Void,
        onEnd: @escaping () -> Void
    ) -> some View {
        GeometryReader { geo in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            guard let plotAnchor = proxy.plotFrame else { return }
                            let x = drag.location.x - geo[plotAnchor].origin.x
                            // Ignore coordinates to the left of the plot area to avoid
                            // the selected point jumping to the wrong data entry.
                            guard x >= 0 else { return }
                            withAnimation(.easeInOut(duration: 0.08)) { onChanged(x) }
                        }
                        .onEnded { _ in
                            // Fade the selection out slowly so the user can see where
                            // they last touched before the callout disappears.
                            withAnimation(.easeOut(duration: 0.4)) { onEnd() }
                        }
                )
        }
    }

    // MARK: - Scrub callout bubble
    private func scrubCallout(value: String, date: Date, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color(red: 0.14, green: 0.14, blue: 0.20))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(color.opacity(0.4), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
    }

    private func formatSleep(_ hours: Double) -> String {
        let hrs = Int(hours); let mins = Int((hours - Double(hrs)) * 60)
        return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
    }
}

#Preview {
    ZStack {
        Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()
        TrendsView(checkIns: [])
    }
}
