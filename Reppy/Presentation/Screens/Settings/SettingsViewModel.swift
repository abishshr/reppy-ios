import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var showSignOutConfirmation = false
    @Published var errorMessage: String?
    @Published var latestBodyFat: Double?

    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Computed Properties

    var healthKitStatus: String {
        container.healthKitService.isAvailable
            ? (container.activityRepository.isHealthKitAuthorized ? "Connected" : "Not Connected")
            : "Not Available"
    }

    // MARK: - Init

    init() {
        Task {
            await loadLatestBodyFat()
        }
    }

    // MARK: - Methods

    func syncSteps() async {
        do {
            _ = try await container.activityRepository.syncTodaySteps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadLatestBodyFat() async {
        do {
            let measurement = try await container.apiClient.getLatestMeasurement()
            latestBodyFat = measurement.bodyFatPercentage
        } catch {
            // No measurements yet, that's ok
            latestBodyFat = nil
        }
    }
}
