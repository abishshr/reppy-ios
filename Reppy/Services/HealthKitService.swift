import Foundation
import HealthKit

/// Service for HealthKit integration (steps tracking)
final class HealthKitService {
    private let healthStore = HKHealthStore()
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    /// Check if HealthKit is available
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Request authorization for step count
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let typesToRead: Set<HKObjectType> = [stepType]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    /// Check authorization status
    var isAuthorized: Bool {
        healthStore.authorizationStatus(for: stepType) == .sharingAuthorized
    }

    /// Get steps for a specific date
    func getSteps(for date: Date) async throws -> Int {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }

            healthStore.execute(query)
        }
    }

    /// Get steps for the last N days
    func getStepsHistory(days: Int) async throws -> [Date: Int] {
        var results: [Date: Int] = [:]

        for dayOffset in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            let steps = try await getSteps(for: date)
            results[date.startOfDay] = steps
        }

        return results
    }

    /// Get today's steps
    func getTodaySteps() async throws -> Int {
        try await getSteps(for: Date())
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        }
    }
}
