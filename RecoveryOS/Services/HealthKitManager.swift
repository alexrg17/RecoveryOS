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
    var sleepHours: Double?    // sum of core + deep + REM from last night
    var hrvMs: Double?         // most recent HRV SDNN sample today
    var restingHR: Double?     // most recent resting HR sample today
    var workoutLoad: Double?   // active kcal today normalised to 1-10 scale
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
            .activeEnergyBurned
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
                // If a check-in exists for today, update its biometric fields
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: Date())
                let descriptor = FetchDescriptor<DailyCheckIn>(
                    predicate: #Predicate { $0.date >= startOfDay },
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                if let existing = try? context.fetch(descriptor).first {
                    if let v = snapshot.sleepHours  { existing.sleepHours  = v }
                    if let v = snapshot.hrvMs        { existing.hrvMs        = v }
                    if let v = snapshot.restingHR    { existing.restingHR    = v }
                    if let v = snapshot.workoutLoad  { existing.workoutLoad  = v }
                    try? context.save()
                }
            }
        }
    }

    // MARK: - Fetch all four types
    func fetchTodayData() async -> HealthKitSnapshot {
        async let sleep    = fetchSleepHours()
        async let hrv      = fetchMostRecentQuantity(.heartRateVariabilitySDNN, unit: HKUnit(from: "ms"))
        async let resting  = fetchMostRecentQuantity(.restingHeartRate, unit: HKUnit(from: "count/min"))
        async let calories = fetchActiveCaloriesToday()

        let (s, h, r, c) = await (sleep, hrv, resting, calories)

        // Normalise active kcal to 1-10 (600 kcal = 10)
        let load: Double? = c.map { min(10, max(1, ($0 / 60.0))) }

        return HealthKitSnapshot(sleepHours: s, hrvMs: h, restingHR: r, workoutLoad: load)
    }

    // MARK: - Sleep (6pm yesterday to now, sum all asleep stages)
    private func fetchSleepHours() async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let calendar  = Calendar.current
        let now       = Date()
        let yesterday = calendar.date(byAdding: .hour, value: -18, to: calendar.startOfDay(for: now))!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                ]
                let totalSeconds = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let hours = totalSeconds / 3600
                continuation.resume(returning: hours > 0 ? hours : nil)
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
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    // MARK: - Active calories today
    private func fetchActiveCaloriesToday() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return nil }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate  = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let kcal = stats?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: kcal)
            }
            store.execute(query)
        }
    }
}
