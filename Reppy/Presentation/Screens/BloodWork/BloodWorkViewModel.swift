import Foundation
import SwiftUI
import UIKit

/// ViewModel for blood work tracking
@MainActor
final class BloodWorkViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var panels: [BloodWorkPanel] = []
    @Published var selectedPanel: BloodWorkPanel?
    @Published var analysis: BloodWorkAnalysis?
    @Published var summary: BloodWorkSummary?
    @Published var ocrResponse: BloodWorkOCRResponse?
    @Published var trend: BloodWorkTrend?

    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var isUploading = false
    @Published var error: String?

    // Manual entry state
    @Published var manualEntryData = BloodWorkPanelCreate(testDate: Date())

    // OCR review state
    @Published var ocrReviewValues: [String: Double] = [:]
    @Published var ocrLabName: String = ""
    @Published var ocrTestDate: Date = Date()

    private let apiClient = DependencyContainer.shared.apiClient

    // MARK: - Load Data

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let panelsTask = apiClient.getBloodWorkPanels(limit: 10)
            async let summaryTask = apiClient.getBloodWorkSummary()

            let (loadedPanels, loadedSummary) = try await (panelsTask, summaryTask)

            self.panels = loadedPanels
            self.summary = loadedSummary
        } catch {
            self.error = error.localizedDescription
            print("[BloodWorkViewModel] Error loading data: \(error)")
        }

        isLoading = false
    }

    func loadSummary() async {
        do {
            self.summary = try await apiClient.getBloodWorkSummary()
        } catch {
            print("[BloodWorkViewModel] Error loading summary: \(error)")
        }
    }

    // MARK: - Panel CRUD

    func createPanel(_ data: BloodWorkPanelCreate) async throws -> BloodWorkPanel {
        let panel = try await apiClient.createBloodWorkPanel(data)
        panels.insert(panel, at: 0)
        await loadSummary()
        return panel
    }

    func deletePanel(_ panel: BloodWorkPanel) async {
        do {
            try await apiClient.deleteBloodWorkPanel(id: panel.id)
            panels.removeAll { $0.id == panel.id }
            await loadSummary()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - OCR Upload

    func uploadImage(_ image: UIImage) async {
        isUploading = true
        error = nil

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            error = "Failed to process image"
            isUploading = false
            return
        }

        let base64 = imageData.base64EncodedString()

        do {
            let response = try await apiClient.extractBloodWorkOCR(
                imageBase64: base64,
                imageUrl: nil,
                mimeType: "image/jpeg"
            )
            self.ocrResponse = response

            if response.success {
                // Populate OCR review values
                self.ocrReviewValues = response.extractedValues
                self.ocrLabName = response.labName ?? ""
                self.ocrTestDate = response.testDate ?? Date()

                // Add uncertain values
                for (key, uncertain) in response.uncertainValues {
                    self.ocrReviewValues[key] = uncertain.value
                }
            } else {
                self.error = response.warnings.first ?? "OCR extraction failed"
            }
        } catch {
            self.error = error.localizedDescription
            print("[BloodWorkViewModel] OCR error: \(error)")
        }

        isUploading = false
    }

    func confirmOCRResults(imageUrl: String? = nil) async throws -> BloodWorkPanel {
        let request = BloodWorkConfirmOCRRequest(
            labName: ocrLabName.isEmpty ? nil : ocrLabName,
            testDate: ocrTestDate,
            imageUrl: imageUrl,
            ocrConfidence: ocrResponse?.confidence,
            markers: ocrReviewValues
        )

        let panel = try await apiClient.confirmBloodWorkOCR(request)
        panels.insert(panel, at: 0)
        await loadSummary()

        // Clear OCR state
        clearOCRState()

        return panel
    }

    func clearOCRState() {
        ocrResponse = nil
        ocrReviewValues = [:]
        ocrLabName = ""
        ocrTestDate = Date()
    }

    // MARK: - Manual Entry

    func saveManualEntry() async throws -> BloodWorkPanel {
        let panel = try await apiClient.createBloodWorkPanel(manualEntryData)
        panels.insert(panel, at: 0)
        await loadSummary()

        // Clear manual entry state
        manualEntryData = BloodWorkPanelCreate(testDate: Date())

        return panel
    }

    // MARK: - Analysis

    func analyzePanel(_ panel: BloodWorkPanel) async {
        isAnalyzing = true
        error = nil

        do {
            let result = try await apiClient.analyzeBloodWorkPanel(id: panel.id)
            self.analysis = result

            // Update local panel with cached analysis
            if let index = panels.firstIndex(where: { $0.id == panel.id }) {
                panels[index].aiAnalyzedAt = result.analyzedAt
            }
        } catch {
            self.error = error.localizedDescription
            print("[BloodWorkViewModel] Analysis error: \(error)")
        }

        isAnalyzing = false
    }

    func applyRecommendations(panelId: String, supplements: Bool, targets: Bool) async {
        do {
            let response = try await apiClient.applyBloodWorkRecommendations(
                panelId: panelId,
                applySupplements: supplements,
                applyTargets: targets
            )

            // Show feedback
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)

            print("[BloodWorkViewModel] Applied: \(response.appliedActions)")
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Trends

    func loadMarkerTrend(markerKey: String, months: Int = 12) async {
        do {
            self.trend = try await apiClient.getBloodWorkTrend(markerKey: markerKey, months: months)
        } catch {
            print("[BloodWorkViewModel] Trend error: \(error)")
        }
    }

    // MARK: - Helpers

    func getMarkerValue(_ panel: BloodWorkPanel, key: String) -> Double? {
        let mirror = Mirror(reflecting: panel)
        for child in mirror.children {
            if child.label == key, let value = child.value as? Double {
                return value
            }
        }
        return nil
    }

    func formatTestDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
