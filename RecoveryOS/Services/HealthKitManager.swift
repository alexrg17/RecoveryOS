//
//  HealthKitManager.swift
//  RecoveryOS
//

import Foundation
import Combine
import HealthKit
import SwiftData

// A lightweight struct that holds a single day's worth of Apple Health readings.
// All fields are optional because any one of them could be unavailable depending
// on what the user's Apple Watch has recorded and whether they granted permission.
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

// Maps Apple Health's internal integer stage codes to named cases that are
// easier to reason about in the rest of the codebase.
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

    // Used when summing total sleep time so we do not accidentally count
    // "In Bed" or "Awake" segments as actual sleep.
    var isAsleep: Bool {
        switch self {
        case .rem, .core, .deep, .asleepUnspecified: return true
        default: return false
        }
    }

    // Converts the raw HealthKit category value integer back to our enum.
    // Returns nil for any value we do not recognise so callers can skip it safely.
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

// A single continuous segment within a sleep session (for example, one block of REM).
struct SleepInterval: Identifiable {
    let id = UUID()
    let stage: SleepStage
    let start: Date
    let end: Date
    var duration: TimeInterval { end.timeIntervalSince(start) }
}

// Groups all sleep intervals from a single night into one object and
// exposes summary calculations that the sleep detail screen needs.
struct SleepSession {
    let intervals: [SleepInterval]
    let sessionStart: Date
    let sessionEnd: Date

    // Total time actually asleep (excludes "In Bed" and "Awake" segments).
    // Deduplication is applied because multiple sources like Apple Watch and iPhone
    // can produce overlapping samples for the same period.
    var timeAsleep: TimeInterval {
        let asleep = intervals.filter { $0.stage.isAsleep }
        return SleepSession.mergedDuration(asleep)
    }

    // Total time from first to last sample, including time awake in bed.
    var timeInBed: TimeInterval {
        SleepSession.mergedDuration(intervals)
    }

    // Duration for a specific stage after merging overlapping samples.
    func duration(for stage: SleepStage) -> TimeInterval {
        SleepSession.mergedDuration(intervals.filter { $0.stage == stage })
    }

    // Used by the sleep breakdown chart to show how much time was spent
    // in each meaningful stage (excludes "In Bed" to match Apple Health's display).
    var asleepBreakdown: [(stage: SleepStage, duration: TimeInterval)] {
        let stages: [SleepStage] = [.rem, .core, .deep, .asleepUnspecified]
        return stages.compactMap { s in
            let d = duration(for: s)
            return d > 0 ? (s, d) : nil
        }
    }

    // Merges overlapping intervals by sorting them and only counting time that
    // has not already been counted by a previous segment. This prevents double-counting
    // when both the iPhone and Apple Watch record the same sleep period.
    private static func mergedDuration(_ items: [SleepInterval]) -> TimeInterval {
        let sorted = items.sorted { $0.start < $1.start }
        var total: TimeInterval = 0
        var currentEnd = Date.distantPast
        for it in sorted {
            let start = max(it.start, currentEnd)
            if start < it.end {
                total += it.end.timeIntervalSince(start)
                currentEnd = max(currentEnd, it.end)
            }
        }
        return total
    }
}

// MARK: - HealthKitManager

// Singleton that owns all communication with the HealthKit store.
// ObservableObject lets SwiftUI views react automatically when latestSnapshot updates.
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    @Published var latestSnapshot = HealthKitSnapshot()
    @Published var isAuthorized   = false

    private init() {}

    // MARK: - Types to read

    // Builds the set of health data types the app needs to request permission for.
    // Using a computed property rather than a stored constant avoids issues with
    // initialisation order when the singleton is first created.
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let ids: [HKQuantityTypeIdentifier] = [
            .heartRateVariabilitySDNN,  // HRV in milliseconds (SDNN method)
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

    // MARK: - Authorisation

    // HealthKit requires permission to be requested each session on some iOS versions.
    // The callback dispatches back to the main thread before updating isAuthorized
    // because @Published properties must be set on the main thread.
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

    // MARK: - Sync to SwiftData

    // Called when the app becomes active so that any check-in from today
    // gets its biometric fields topped up with the latest HealthKit readings.
    // We only update fields where HealthKit has a value, so manually entered
    // data is never overwritten with nil.
    func syncToContext(_ context: ModelContext) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        Task {
            let snapshot = await fetchTodayData()
            await MainActor.run {
                self.latestSnapshot = snapshot

                // Find today's check-in (if one exists) and patch in the HealthKit values.
                let startOfDay = Calendar.current.startOfDay(for: Date())
                let descriptor = FetchDescriptor<DailyCheckIn>(
                    predicate: #Predicate { $0.date >= startOfDay },
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                if let existing = try? context.fetch(descriptor).first {
                    if let v = snapshot.sleepHours      { existing.sleepHours      = v }
                    if let v = snapshot.hrvMs           { existing.hrvMs           = v }
                    if let v = snapshot.restingHR       { existing.restingHR       = v }
                    if let v = snapshot.workoutLoad     { existing.workoutLoad     = v }
                    if let v = snapshot.activeCalories  { existing.activeCalories  = v }
                    if let v = snapshot.stepCount       { existing.stepCount       = v }
                    if let v = snapshot.restingEnergy   { existing.restingEnergy   = v }
                    if let v = snapshot.exerciseMinutes { existing.exerciseMinutes = v }
                    try? context.save()
                }
            }
        }
    }

    // MARK: - Fetch today's data

    // Fetches all data types in parallel using async let so each HKQuery
    // runs concurrently rather than waiting for the previous one to finish.
    // This cuts the total fetch time from the sum of all queries to the slowest one.
    func fetchTodayData() async -> HealthKitSnapshot {
        async let session  = fetchSleepSession()
        async let hrv      = fetchMostRecentQuantity(.heartRateVariabilitySDNN, unit: HKUnit(from: "ms"))
        async let resting  = fetchMostRecentQuantity(.restingHeartRate, unit: HKUnit(from: "count/min"))
        async let calories = fetchCumulativeSum(.activeEnergyBurned, unit: .kilocalorie())
        async let basal    = fetchCumulativeSum(.basalEnergyBurned, unit: .kilocalorie())
        async let steps    = fetchCumulativeSum(.stepCount, unit: .count())
        async let exercise = fetchCumulativeSum(.appleExerciseTime, unit: .minute())

        let (sess, h, r, c, b, st, ex) = await (session, hrv, resting, calories, basal, steps, exercise)

        // Convert active calories to a 1-10 workout load score.
        // 60 kcal per point is a rough threshold: 600+ kcal = max effort session (10/10).
        let load: Double? = c.map { min(10, max(1, $0 / 60.0)) }

        // Convert total sleep time from seconds to hours and discard zero values
        // (a zero would mean no valid sleep samples were found, not that the user slept 0 hours).
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

    // MARK: - Sleep session fetch

    // Looks back 24 hours rather than just from midnight so overnight sessions
    // that started before midnight are captured correctly.
    // withCheckedContinuation bridges the callback-based HKSampleQuery API into
    // Swift async/await so the caller can use it with async let.
    func fetchSleepSession(end: Date = Date()) async -> SleepSession? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

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

    // MARK: - Quantity helpers

    // Returns the most recent sample recorded today for point-in-time metrics like
    // HRV and resting heart rate, where only the latest reading matters.
    private func fetchMostRecentQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate  = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        // Sort descending so the first result is the most recent sample.
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

    // Returns the total accumulated value for today for cumulative metrics like
    // calories burned and step count, where we want the running total not just the last sample.
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
