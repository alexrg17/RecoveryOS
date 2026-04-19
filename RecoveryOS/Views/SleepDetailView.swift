//
//  SleepDetailView.swift
//  RecoveryOS
//

import SwiftUI
import Charts

struct SleepDetailView: View {
    let session: SleepSession?
    @Environment(\.dismiss) private var dismiss

    private let bg          = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard      = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let labelGray   = Color.white.opacity(0.45)
    private let dividerGray = Color.white.opacity(0.06)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if let session {
                            summaryCard(session)
                            timelineCard(session)
                            stagesCard(session)
                            intervalsCard(session)
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(.white)
                }
            }
            .toolbarBackground(bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Summary
    private func summaryCard(_ s: SleepSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "moon.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(stageColor(.core))
                Text("ASLEEP")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(labelGray)
                Spacer()
                Text(rangeLabel(s.sessionStart, s.sessionEnd))
                    .font(.system(size: 11))
                    .foregroundStyle(labelGray)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(durationLong(s.timeAsleep))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 24) {
                statColumn(label: "Time in Bed", value: durationShort(s.timeInBed))
                statColumn(label: "Time Asleep", value: durationShort(s.timeAsleep))
                if s.timeInBed > 0 {
                    let eff = Int((s.timeAsleep / s.timeInBed) * 100)
                    statColumn(label: "Efficiency", value: "\(eff)%")
                }
            }
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .kerning(1)
                .foregroundStyle(labelGray)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Timeline (stage-over-time chart, like Apple Health)
    @ViewBuilder
    private func timelineCard(_ s: SleepSession) -> some View {
        let stageOrder: [SleepStage] = [.awake, .rem, .core, .deep]
        // Filter to drawable intervals (collapse asleepUnspecified into core for visualization)
        // Drop zero/negative-duration samples so Charts can build a valid X domain.
        let drawable: [(SleepStage, Date, Date)] = s.intervals.compactMap { iv in
            guard iv.end > iv.start else { return nil }
            switch iv.stage {
            case .inBed:             return nil
            case .asleepUnspecified: return (.core, iv.start, iv.end)
            default:                 return (iv.stage, iv.start, iv.end)
            }
        }

        // Establish a safe X domain. If start == end, pad by 1 minute so Swift Charts
        // doesn't crash with "Range requires lowerBound <= upperBound" on auto axis ticks.
        let domainStart = drawable.map(\.1).min() ?? s.sessionStart
        let rawEnd      = drawable.map(\.2).max() ?? s.sessionEnd
        let domainEnd   = rawEnd > domainStart ? rawEnd : domainStart.addingTimeInterval(60)

        VStack(alignment: .leading, spacing: 12) {
            Text("STAGES")
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(labelGray)

            if drawable.isEmpty {
                Text("No staged sleep data for this session.")
                    .font(.system(size: 12))
                    .foregroundStyle(labelGray)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                Chart {
                    ForEach(Array(drawable.enumerated()), id: \.offset) { _, item in
                        let (stage, start, end) = item
                        BarMark(
                            xStart: .value("Start", start),
                            xEnd:   .value("End", end),
                            y:      .value("Stage", stage.label)
                        )
                        .foregroundStyle(stageColor(stage))
                        .cornerRadius(2)
                    }
                }
                .chartXScale(domain: domainStart...domainEnd)
                .chartYScale(domain: stageOrder.map(\.label))
                .chartYAxis {
                    AxisMarks(position: .leading, values: stageOrder.map(\.label)) { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.hour().minute())
                                    .font(.system(size: 9))
                                    .foregroundStyle(labelGray)
                            }
                        }
                        AxisGridLine().foregroundStyle(dividerGray)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Stage breakdown rows with bars + percentages
    private func stagesCard(_ s: SleepSession) -> some View {
        let total = max(s.timeAsleep, 1)
        let breakdown = s.asleepBreakdown.sorted { $0.duration > $1.duration }

        return VStack(alignment: .leading, spacing: 14) {
            Text("STAGE BREAKDOWN")
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(labelGray)

            ForEach(breakdown, id: \.stage.id) { item in
                stageRow(stage: item.stage, duration: item.duration, total: total)
            }

            let awake = s.duration(for: .awake)
            if awake > 0 {
                Divider().background(dividerGray)
                stageRow(stage: .awake, duration: awake, total: total, suffix: "(of asleep)")
            }
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func stageRow(stage: SleepStage, duration: TimeInterval, total: TimeInterval, suffix: String? = nil) -> some View {
        let safeTotal = total > 0 ? total : 1
        let fraction  = max(0, min(1, duration / safeTotal))
        let pct = Int(fraction * 100)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(stageColor(stage))
                    .frame(width: 8, height: 8)
                Text(stage.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                if let suffix {
                    Text(suffix)
                        .font(.system(size: 10))
                        .foregroundStyle(labelGray)
                }
                Spacer()
                Text(durationShort(duration))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(pct)%")
                    .font(.system(size: 11))
                    .foregroundStyle(labelGray)
                    .frame(width: 32, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.06)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(stageColor(stage))
                        .frame(width: max(0, geo.size.width * CGFloat(fraction)), height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Per-interval list (from-to times)
    private func intervalsCard(_ s: SleepSession) -> some View {
        let visible = s.intervals
            .filter { $0.stage != .inBed }
            .sorted { $0.start < $1.start }

        return VStack(alignment: .leading, spacing: 12) {
            Text("DETAILS")
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.2)
                .foregroundStyle(labelGray)

            ForEach(visible) { iv in
                HStack(spacing: 10) {
                    Circle()
                        .fill(stageColor(iv.stage))
                        .frame(width: 6, height: 6)
                    Text(iv.stage.label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 70, alignment: .leading)
                    Text("\(timeLabel(iv.start)) – \(timeLabel(iv.end))")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(labelGray)
                        .monospacedDigit()
                    Spacer()
                    Text(durationShort(iv.duration))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                if iv.id != visible.last?.id {
                    Divider().background(dividerGray)
                }
            }
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Empty
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 52))
                .foregroundStyle(stageColor(.core).opacity(0.55))
                .padding(.top, 80)
            Text("No Sleep Data")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("No sleep samples were found in Apple Health for the past 24 hours.")
                .font(.system(size: 13))
                .foregroundStyle(labelGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Helpers
    private func stageColor(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake:               return Color(red: 1.0, green: 0.55, blue: 0.20)
        case .rem:                 return Color(red: 0.55, green: 0.65, blue: 1.0)
        case .core:                return Color(red: 0.30, green: 0.55, blue: 1.0)
        case .deep:                return Color(red: 0.25, green: 0.30, blue: 0.85)
        case .asleepUnspecified:   return Color(red: 0.30, green: 0.55, blue: 1.0)
        case .inBed:               return Color.white.opacity(0.25)
        }
    }

    private func durationShort(_ s: TimeInterval) -> String {
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func durationLong(_ s: TimeInterval) -> String {
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        return "\(h)h \(m)m"
    }

    private func timeLabel(_ d: Date) -> String {
        d.formatted(date: .omitted, time: .shortened)
    }

    private func rangeLabel(_ a: Date, _ b: Date) -> String {
        "\(timeLabel(a)) – \(timeLabel(b))"
    }
}
