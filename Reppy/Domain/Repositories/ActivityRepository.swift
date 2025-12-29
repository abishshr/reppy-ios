import Foundation

/// Protocol for activity repository
protocol ActivityRepository {
    func requestHealthKitAuthorization() async throws
    func syncTodaySteps() async throws -> DailyActivity
    func getActivitySummary() async throws -> ActivitySummary
    var isHealthKitAuthorized: Bool { get }
}

/// Implementation of ActivityRepository
final class ActivityRepositoryImpl: ActivityRepository {
    private let apiClient: APIClient
    private let healthKitService: HealthKitService

    init(apiClient: APIClient, healthKitService: HealthKitService) {
        self.apiClient = apiClient
        self.healthKitService = healthKitService
    }

    func requestHealthKitAuthorization() async throws {
        try await healthKitService.requestAuthorization()
    }

    func syncTodaySteps() async throws -> DailyActivity {
        // Get steps from HealthKit
        let steps = try await healthKitService.getTodaySteps()

        // Sync to backend
        return try await apiClient.syncSteps(date: Date(), steps: steps)
    }

    func getActivitySummary() async throws -> ActivitySummary {
        try await apiClient.getActivitySummary()
    }

    var isHealthKitAuthorized: Bool {
        healthKitService.isAuthorized
    }
}
