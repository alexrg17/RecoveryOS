//
//  HealthKitManager.swift
//  RecoveryOS
//

import Foundation
import Combine
import HealthKit
import SwiftData

// MARK: - Snapshot of today's HealthKit data
struct HealthKitSnapshot {
    var sleepHours: Double?
    var hrvMs: Double?
    var restingHR: Double?
    var workoutLoad: Double?
    var activeCalories: Double?
    var stepCount: Double?
    var restingEnergy: Double?
    var exerciseMinutes: Double?
    var sleepSession: SleepSession?
}

// MARK: - Sleep stage modeling
enum SleepStage: Int, CaseIterable, Identifiable {
    case inBed, awake, rem, core, deep, asleepUnspecified
    var id: Int { rawValue }

    var label: String {
        switch self {
        case .inBed:              return "In Bed"
        case .awake:              return "Awake"
        case .rem:                return "REM"
        case .core:               return "Core"
        case .deep:               return "Deep"
        case .asleepUnspecified:  return "Asleep"
        }
    }

    var isAsleep: Bool {
        switch self {
        case .rem, .core, .deep, .asleepUnspecified: return true
        default: return false
        }
    }

    static func from(_ value: Int) -> SleepStage? {
        switch value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:              return .inBed
        case HKCategoryValueSleepAnalysis.awake.rawValue:              return .awake
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:          return .rem
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:         return .core
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:         return .deep
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:  return .asleepUnspecified
        default: return nil
        }
    }
}

struct SleepInterval: Identifiable {
    let id = UUID()
    let stage: SleepStage
    let start: Date
    let end: Date
    var duration: TimeInterval { end.timeIntervalSince(start) }
}

struct SleepSession {
    let intervals: [SleepInterval]
    let sessionStart: Date
    let sessionEnd: Date

    /// Total time asleep (REM + Core + Deep + asleepUnspecified), deduplicated.
    var timeAsleep: TimeInterval {
        let asleep = intervals.filter { $0.stage.isAsleep }
        return SleepSession.mergedDuration(asleep)
    }

    /// Total in-bed window, deduplicated.
    var timeInBed: TimeInterval {
        SleepSession.mergedDuration(intervals)
    }

    /// Per-stage merged duration (deduped across overlapping samples).
    func duration(for stage: SleepStage) -> TimeInterval {
        SleepSession.mergedDuration(intervals.filter { $0.stage == stage })
    }

    /// Stage breakdown for asleep stages only — used for Apple Health-style summary.
    var asleepBreakdown: [(stage: SleepStage, duration: TimeInterval)] {
        let stages: [SleepStage] = [.rem, .core, .deep, .asleepUnspecified]
        return stages.compactMap { s in
            let d = duration(for: s)
            return d > 0 ? (s, d) : nil
        }
    }

    private static func mergedDuration(_ items: [SleepInterval]) -> TimeInterval {
        let sorted = items.sorted { $0.start < $1.start }
        var total: TimeInterval = 0
        var currentEnd = Date.distantPast
        for it in sorted {
            let s = max(it.start, currentEnd)
            if s < it.end {
                total += it.end.timeIntervalSince(s)
                currentEnd = max(currentEnd, it.end)
            }
        }
        return total
    }
}

// MARK: - HealthKitManager
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    @Published var latestSnapshot = HealthKitSnapshot()
    @Published var isAuthorized   = false

    private init() {}

    // MARK: - Types to read
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let ids: [HKQuantityTypeIdentifier] = [
            .heartRateVariabilitySDNN,
            .restingHeartRate,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .stepCount,
            .appleExerciseTime
        ]
        for id in ids {
            if let t = HKObjectType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        types.insert(HKObjectType.workoutType())
        return types
    }

    // MARK: - Request authorisation
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        store.requestAuthorization(toShare: [], read: readTypes) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
            guard granted, let self else { return }
            Task {
                let snapshot = await self.fetchTodayData()
                await MainActor.run { self.latestSnapshot = snapshot }
            }
        }
    }

    // MARK: - Sync to SwiftData context
    func syncToContext(_ context: ModelContext) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        Task {
            let snapshot = await fetchTodayData()
            await MainActor.run {
                self.latestSnapshot = snapshot
                let startOfDay = Calendar.current.startOfDay(for: Date())
                let descriptor = FetchDescriptor<DailyCheckIn>(
                    predicate: #Predicate { $0.date >= startOfDay },
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                if let existing = try? context.fetch(descriptor).first {
                    if let v = snapshot.sleepHours     { existing.sleepHours     = v }
                    if let v = snapshot.hrvMs          { existing.hrvMs          = v }
                    if let v = snapshot.restingHR      { existing.restingHR      = v }
                    if let v = snapshot.workoutLoad    { existing.workoutLoad    = v }
                    if let v = snapshot.activeCalories { existing.activeCalories = v }
                    if let v = snapshot.stepCount      { existing.stepCount      = v }
                    if let v = snapshot.restingEnergy  { existing.restingEnergy  = v }
                    if let v = snapshot.exerciseMinutes { existing.exerciseMinutes = v }
                    try? context.save()
                }
            }
        }
    }

    // MARK: - Fetch all data types
    func fetchTodayData() async -> HealthKitSnapshot {
        async let session  = fetchSleepSession()
        async let hrv      = fetchMostRecentQuantity(.heartRateVariabilitySDNN, unit: HKUnit(from: "ms"))
        async let resting  = fetchMostRecentQuantity(.restingHeartRate, unit: HKUnit(from: "count/min"))
        async let calories = fetchCumulativeSum(.activeEnergyBurned, unit: .kilocalorie())
        async let basal    = fetchCumulativeSum(.basalEnergyBurned, unit: .kilocalorie())
        async let steps    = fetchCumulativeSum(.stepCount, unit: .count())
        async let exercise = fetchCumulativeSum(.appleExerciseTime, unit: .minute())

        let (sess, h, r, c, b, st, ex) = await (session, hrv, resting, calories, basal, steps, exercise)

        let load: Double? = c.map { min(10, max(1, $0 / 60.0)) }
        let sleepHours: Double? = sess.map { $0.timeAsleep / 3600 }.flatMap { $0 > 0 ? $0 : nil }

        return HealthKitSnapshot(
            sleepHours: sleepHours,
            hrvMs: h,
            restingHR: r,
            workoutLoad: load,
            activeCalories: c,
            stepCount: st,
            restingEnergy: b,
            exerciseMinutes: ex,
            sleepSession: sess
        )
    }

    // MARK: - Sleep session (full stage breakdown, last 24h window)
    func fetchSleepSession(end: Date = Date()) async -> SleepSession? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        // Look back 24h from `end` to capture the most recent sleep period
        // (overnight or daytime). Deduplication handles multi-source overlap.
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: end)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil); return
                }
                let intervals: [SleepInterval] = samples.compactMap { sample in
                    guard let stage = SleepStage.from(sample.value) else { return nil }
                    return SleepInterval(stage: stage, start: sample.startDate, end: sample.endDate)
                }
                guard !intervals.isEmpty else {
                    continuation.resume(returning: nil); return
                }
                let sStart = intervals.map(\.start).min() ?? start
                let sEnd   = intervals.map(\.end).max()   ?? end
                continuation.resume(returning: SleepSession(intervals: intervals, sessionStart: sStart, sessionEnd: sEnd))
            }
            store.execute(query)
        }
    }

    // MARK: - Most recent quantity sample today
    private func fetchMostRecentQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate  = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        let sort       = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil); return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    // MARK: - Cumulative sum for today
    private func fetchCumulativeSum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate  = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }
}
