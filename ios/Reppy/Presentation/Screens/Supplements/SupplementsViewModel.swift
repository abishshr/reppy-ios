import Foundation
import SwiftUI

/// ViewModel for supplement management
@MainActor
class SupplementsViewModel: ObservableObject {
    @Published var supplements: [Supplement] = []
    @Published var todayLogs: [SupplementLog] = []
    @Published var todaySummary: TodaySupplementSummary?
    @Published var isLoading = false
    @Published var error: String?

    private let apiClient = DependencyContainer.shared.apiClient

    // MARK: - Load Data

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let supplementsTask = apiClient.getSupplements(activeOnly: true)
            async let summaryTask = apiClient.getTodaySupplementSummary()

            let (loadedSupplements, summary) = try await (supplementsTask, summaryTask)

            self.supplements = loadedSupplements
            self.todaySummary = summary
        } catch {
            self.error = error.localizedDescription
            print("[SupplementsViewModel] Error loading data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Supplement CRUD

    func createSupplement(_ request: SupplementCreateRequest) async throws {
        let supplement = try await apiClient.createSupplement(request)
        supplements.append(supplement)
        supplements.sort { $0.name < $1.name }
    }

    func updateSupplement(id: String, update: SupplementUpdateRequest) async throws {
        let updated = try await apiClient.updateSupplement(id: id, update: update)
        if let index = supplements.firstIndex(where: { $0.id == id }) {
            supplements[index] = updated
        }
    }

    func deleteSupplement(_ supplement: Supplement) async {
        do {
            try await apiClient.deleteSupplement(id: supplement.id)
            supplements.removeAll { $0.id == supplement.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Logging

    func logSupplement(supplementId: String, servings: Double, notes: String?) async throws {
        let request = SupplementLogRequest(
            supplementId: supplementId,
            servings: servings,
            loggedAt: Date(),
            notes: notes
        )

        _ = try await apiClient.logSupplement(request)

        // Reload summary
        do {
            self.todaySummary = try await apiClient.getTodaySupplementSummary()
        } catch {
            print("[SupplementsViewModel] Error reloading summary: \(error)")
        }
    }
}
