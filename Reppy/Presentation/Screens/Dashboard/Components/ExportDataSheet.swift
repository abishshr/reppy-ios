import SwiftUI

/// Sheet to export data to CSV
struct ExportDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExportType: ExportType = .all
    @State private var selectedDays = 30
    @State private var isExporting = false
    @State private var errorMessage: String?
    @State private var exportedURL: URL?
    @State private var showShareSheet = false

    let apiClient: APIClient

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Export Type", selection: $selectedExportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("What to Export")
                } footer: {
                    Text(selectedExportType.description)
                }

                Section {
                    Picker("Time Period", selection: $selectedDays) {
                        Text("Last 7 days").tag(7)
                        Text("Last 30 days").tag(30)
                        Text("Last 90 days").tag(90)
                        Text("Last 365 days").tag(365)
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Time Period")
                }

                Section {
                    Button {
                        Task { await exportData() }
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Exporting...")
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export to CSV")
                            }
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .background(isExporting ? Color.gray : Color.accentColor)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(isExporting)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportData() async {
        isExporting = true
        errorMessage = nil

        do {
            let data: Data
            let filename: String

            switch selectedExportType {
            case .all:
                data = try await apiClient.exportAllCSV(days: selectedDays)
                filename = "reppy_summary.csv"
            case .meals:
                data = try await apiClient.exportMealsCSV(days: selectedDays)
                filename = "reppy_meals.csv"
            case .workouts:
                data = try await apiClient.exportWorkoutsCSV(days: selectedDays)
                filename = "reppy_workouts.csv"
            case .water:
                data = try await apiClient.exportWaterCSV(days: selectedDays)
                filename = "reppy_water.csv"
            }

            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tempURL)

            exportedURL = tempURL
            showShareSheet = true

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

        } catch {
            errorMessage = error.localizedDescription
        }

        isExporting = false
    }
}

// MARK: - Export Type

enum ExportType: String, CaseIterable {
    case all
    case meals
    case workouts
    case water

    var displayName: String {
        switch self {
        case .all: return "Daily Summary"
        case .meals: return "Meals Only"
        case .workouts: return "Workouts Only"
        case .water: return "Water Only"
        }
    }

    var icon: String {
        switch self {
        case .all: return "doc.text"
        case .meals: return "fork.knife"
        case .workouts: return "figure.run"
        case .water: return "drop.fill"
        }
    }

    var description: String {
        switch self {
        case .all: return "Aggregated daily totals for calories, macros, workouts, and water."
        case .meals: return "Detailed meal logs with food items, macros, and timestamps."
        case .workouts: return "Workout logs with exercises, sets, reps, and calories burned."
        case .water: return "Water intake logs with amounts and timestamps."
        }
    }
}

// ShareSheet is defined in Reppy/Presentation/Screens/Sharing/ShareSheet.swift

#Preview {
    ExportDataSheet(apiClient: DependencyContainer.shared.apiClient)
}
