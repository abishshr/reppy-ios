import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var showSignOutConfirmation = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Computed Properties

    var healthKitStatus: String {
        container.healthKitService.isAvailable
            ? (container.activityRepository.isHealthKitAuthorized ? "Connected" : "Not Connected")
            : "Not Available"
    }

    // MARK: - Methods

    func syncSteps() async {
        do {
            _ = try await container.activityRepository.syncTodaySteps()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
