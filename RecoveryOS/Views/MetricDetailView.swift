//
//  MetricDetailView.swift
//  RecoveryOS
//

import SwiftUI
import Charts

// MARK: - Metric type definition
enum HealthMetric: String, Identifiable, CaseIterable {
    case sleep, hrv, restingHR, activeCalories, steps, restingEnergy, exerciseMinutes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep:           return "Sleep"
        case .hrv:             return "Heart Rate Variability"
        case .restingHR:       return "Resting Heart Rate"
        case .activeCalories:  return "Active Calories"
        case .steps:           return "Steps"
        case .restingEnergy:   return "Resting Energy"
        case .exerciseMinutes: return "Exercise Minutes"
        }
    }

    var shortLabel: String {
        switch self {
        case .sleep:           return "SLEEP"
        case .hrv:             return "HRV"
        case .restingHR:       return "RESTING HR"
        case .activeCalories:  return "ACTIVE CAL"
        case .steps:           return "STEPS"
        case .restingEnergy:   return "RESTING ENERGY"
        case .exerciseMinutes: return "EXERCISE"
        }
    }

    var icon: String {
        switch self {
        case .sleep:           return "moon.fill"
        case .hrv:             return "waveform.path.ecg"
        case .restingHR:       return "heart.fill"
        case .activeCalories:  return "flame.fill"
        case .steps:           return "figure.walk"
        case .restingEnergy:   return "bed.double.fill"
        case .exerciseMinutes: return "stopwatch.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .sleep:           return Color(red: 0.55, green: 0.35, blue: 0.98)
        case .hrv:             return Color(red: 0.25, green: 0.90, blue: 0.69)
        case .restingHR:       return Color(red: 1.0,  green: 0.30, blue: 0.40)
        case .activeCalories:  return Color(red: 1.0,  green: 0.55, blue: 0.15)
        case .steps:           return Color(red: 0.25, green: 0.90, blue: 0.69)
        case .restingEnergy:   return Color(red: 0.28, green: 0.48, blue: 0.98)
        case .exerciseMinutes: return Color(red: 0.40, green: 0.85, blue: 0.55)
        }
    }

    // Use bar chart for cumulative daily totals, line for continuous readings
    var useBarChart: Bool {
        switch self {
        case .activeCalories, .steps, .restingEnergy, .exerciseMinutes, .sleep: return true
        case .hrv, .restingHR: return false
        }
    }

    func value(from checkIn: DailyCheckIn) -> Double? {
        switch self {
        case .sleep:           return checkIn.sleepHours
        case .hrv:             return checkIn.hrvMs
        case .restingHR:       return checkIn.restingHR
        case .activeCalories:  return checkIn.activeCalories
        case .steps:           return checkIn.stepCount
        case .restingEnergy:   return checkIn.restingEnergy
        case .exerciseMinutes: return checkIn.exerciseMinutes
        }
    }

    func formatted(_ value: Double) -> String {
        switch self {
        case .sleep:
            let hrs = Int(value)
            let mins = Int((value - Double(hrs)) * 60)
            return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
        case .hrv:             return "\(Int(value)) ms"
        case .restingHR:       return "\(Int(value)) BPM"
        case .activeCalories:  return "\(Int(value)) kcal"
        case .steps:           return "\(Int(value).formatted())"
        case .restingEnergy:   return "\(Int(value)) kcal"
        case .exerciseMinutes: return "\(Int(value)) min"
        }
    }

    func yDomain(for data: [Double]) -> ClosedRange<Double> {
        let hi = data.max() ?? 10
        let lo = data.min() ?? 0
        switch self {
        case .sleep:           return 0...max(hi * 1.3, 10)
        case .hrv:             return max(lo * 0.7, 0)...(hi * 1.3)
        case .restingHR:       return max(lo * 0.85, 40)...(hi * 1.15)
        case .activeCalories:  return 0...max(hi * 1.3, 100)
        case .steps:           return 0...max(hi * 1.3, 1000)
        case .restingEnergy:   return 0...max(hi * 1.3, 100)
        case .exerciseMinutes: return 0...max(hi * 1.3, 30)
        }
    }
}

// MARK: - MetricDetailView
struct MetricDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let metric: HealthMetric
    let checkIns: [DailyCheckIn]
    var currentValue: Double? = nil

    @State private var selectedPeriod = 7
    @State private var selectedEntry: (Date, Double)? = nil

    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let labelGray  = Color.white.opacity(0.45)

    private var displayData: [(Date, Double)] {
        checkIns
            .prefix(selectedPeriod)
            .reversed()
            .compactMap { ci -> (Date, Double)? in
                guard let v = metric.value(from: ci) else { return nil }
                return (ci.date, v)
            }
    }

    private var values: [Double] { displayData.map(\.1) }
    private var avg: Double? { values.isEmpty ? nil : values.reduce(0, +) / Double(values.count) }
    private var best: Double? { metric == .restingHR ? values.min() : values.max() }
    private var worst: Double? { metric == .restingHR ? values.max() : values.min() }

    private var displayedValue: Double? { selectedEntry?.1 ?? currentValue ?? displayData.last?.1 }
    private var displayedDate: Date? { selectedEntry?.0 ?? displayData.last?.0 }

    var body: some View {
        ZStack {
            bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                dragHandle

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        periodPicker
                        chartSection
                        if !values.isEmpty { statsRow }
                        if !displayData.isEmpty { dayList }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Drag handle
    private var dragHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
            Spacer()
        }
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(metric.accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: metric.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(metric.accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.shortLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(1.4)
                        .foregroundStyle(labelGray)
                    if let v = displayedValue {
                        Text(metric.formatted(v))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.15), value: displayedValue)
                    } else {
                        Text("No data")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(labelGray)
                    }
                }
                Spacer()
                if let date = displayedDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundStyle(labelGray)
                        .animation(.easeInOut(duration: 0.15), value: displayedDate)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Period picker
    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach([7, 14, 30], id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                        selectedEntry = nil
                    }
                } label: {
                    Text("\(period)D")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedPeriod == period ? .white : Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? metric.accentColor.opacity(0.25) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(4)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }

    // MARK: - Chart
    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if displayData.isEmpty {
                Text("No data for this period")
                    .font(.system(size: 14))
                    .foregroundStyle(labelGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
            } else {
                Text("Drag to explore")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(1)
                    .foregroundStyle(Color.white.opacity(0.2))

                Chart {
                    ForEach(displayData, id: \.0) { date, value in
                        chartContent(date: date, value: value)
                    }
                    if let (selDate, selValue) = selectedEntry {
                        RuleMark(x: .value("Selected", selDate))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                        PointMark(x: .value("Date", selDate), y: .value(metric.title, selValue))
                            .foregroundStyle(Color.white)
                            .symbolSize(100)
                            .annotation(position: .top, spacing: 6) {
                                callout(date: selDate, value: selValue)
                            }
                    }
                    if let a = avg, !metric.useBarChart {
                        RuleMark(y: .value("Avg", a))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(Color.white.opacity(0.2))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("avg")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.white.opacity(0.3))
                            }
                    }
                }
                .chartYScale(domain: metric.yDomain(for: values))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
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
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { drag in
                                        guard let plotAnchor = proxy.plotFrame else { return }
                                        let x = drag.location.x - geo[plotAnchor].origin.x
                                        guard x >= 0 else { return }
                                        if let date: Date = proxy.value(atX: x) {
                                            if let nearest = displayData.min(by: {
                                                abs($0.0.timeIntervalSince(date)) < abs($1.0.timeIntervalSince(date))
                                            }) {
                                                withAnimation(.easeInOut(duration: 0.1)) {
                                                    selectedEntry = nearest
                                                }
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeOut(duration: 0.4)) {
                                            selectedEntry = nil
                                        }
                                    }
                            )
                    }
                }
                .frame(height: 200)
                .environment(\.colorScheme, .dark)
            }
        }
        .padding(16)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ChartContentBuilder
    private func chartContent(date: Date, value: Double) -> some ChartContent {
        if metric.useBarChart {
            let isSelected = selectedEntry?.0 == date
            let opacity: Double = isSelected ? 1.0 : (selectedEntry == nil ? 0.75 : 0.3)
            BarMark(x: .value("Date", date, unit: .day), y: .value(metric.title, value))
                .foregroundStyle(metric.accentColor.opacity(opacity))
                .cornerRadius(4)
        } else {
            let isSelected = selectedEntry?.0 == date
            AreaMark(x: .value("Date", date), y: .value(metric.title, value))
                .foregroundStyle(LinearGradient(
                    colors: [metric.accentColor.opacity(0.3), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
            LineMark(x: .value("Date", date), y: .value(metric.title, value))
                .foregroundStyle(metric.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            PointMark(x: .value("Date", date), y: .value(metric.title, value))
                .foregroundStyle(isSelected ? Color.white : metric.accentColor)
                .symbolSize(isSelected ? 80 : 24)
        }
    }

    private func callout(date: Date, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(metric.formatted(value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(red: 0.14, green: 0.14, blue: 0.20))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(metric.accentColor.opacity(0.4), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
    }

    // MARK: - Stats row
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(label: "AVERAGE", value: avg.map { metric.formatted($0) } ?? "—", color: metric.accentColor)
            statCard(label: metric == .restingHR ? "BEST LOW" : "BEST", value: best.map { metric.formatted($0) } ?? "—", color: Color(red: 0.25, green: 0.90, blue: 0.69))
            statCard(label: metric == .restingHR ? "WORST HIGH" : "WORST", value: worst.map { metric.formatted($0) } ?? "—", color: Color(red: 1.0, green: 0.38, blue: 0.38))
        }
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .kerning(1)
                .foregroundStyle(labelGray)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Day list
    private var dayList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HISTORY")
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.5)
                .foregroundStyle(labelGray)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(displayData.reversed(), id: \.0) { date, value in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(date.formatted(.dateTime.weekday(.wide)))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                            Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                                .font(.system(size: 11))
                                .foregroundStyle(labelGray)
                        }
                        Spacer()
                        Text(metric.formatted(value))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(metric.accentColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    if date != displayData.reversed().last?.0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 1)
                            .padding(.leading, 14)
                    }
                }
            }
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
