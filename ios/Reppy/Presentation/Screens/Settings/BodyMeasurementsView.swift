import SwiftUI

struct BodyMeasurementsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = BodyMeasurementsViewModel()
    @State private var showAddMeasurement = false
    @State private var showARMeasurement = false
    @State private var showPremiumPrompt = false

    // Premium check - enabled for all users for now
    private var isPremium: Bool {
        return true // Always enabled for now
        // TODO: Enable premium check when ready to monetize
        // #if DEBUG
        // return true
        // #else
        // return appState.userProfile?.subscriptionTier == "premium"
        // #endif
    }

    var body: some View {
        List {
            // Latest measurement summary
            if let latest = viewModel.latestMeasurement {
                Section {
                    if let bodyFat = latest.bodyFatPercentage {
                        VStack(spacing: 12) {
                            Text("\(String(format: "%.1f", bodyFat))%")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(bodyFatColor(bodyFat))

                            Text(bodyFatCategory(bodyFat))
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Measured \(latest.measuredAt.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }

                    if let waist = latest.waistCm {
                        MeasurementRow(label: "Waist", value: waist, unit: "cm", icon: "circle.dashed", color: .orange)
                    }
                    if let neck = latest.neckCm {
                        MeasurementRow(label: "Neck", value: neck, unit: "cm", icon: "circle", color: .cyan)
                    }
                    if let hips = latest.hipsCm {
                        MeasurementRow(label: "Hips", value: hips, unit: "cm", icon: "circle.bottomhalf.filled", color: .pink)
                    }
                } header: {
                    Text("Current Body Fat")
                }
            }

            // Actions
            Section {
                Button {
                    showAddMeasurement = true
                } label: {
                    Label("Add New Measurement", systemImage: "plus.circle.fill")
                }

                Button {
                    if isPremium {
                        showARMeasurement = true
                    } else {
                        showPremiumPrompt = true
                    }
                } label: {
                    HStack {
                        Label("AR Body Scan", systemImage: "camera.viewfinder")
                        Spacer()
                        if !isPremium {
                            Text("Premium")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            // History
            if !viewModel.measurements.isEmpty {
                Section("History") {
                    ForEach(viewModel.measurements) { measurement in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let bodyFat = measurement.bodyFatPercentage {
                                    Text("\(String(format: "%.1f", bodyFat))%")
                                        .font(.headline)
                                } else {
                                    Text("No body fat")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                Text(measurement.measuredAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if let waist = measurement.waistCm {
                                VStack(alignment: .trailing) {
                                    Text("\(Int(waist)) cm")
                                        .font(.subheadline)
                                    Text("waist")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.deleteMeasurements(at: indexSet)
                        }
                    }
                }
            }

            // Comparison
            if let comparison = viewModel.comparison, !comparison.comparisons.isEmpty {
                Section("Progress") {
                    ForEach(comparison.comparisons, id: \.field) { comp in
                        HStack {
                            Text(comp.fieldDisplayName)
                            Spacer()
                            Text(changeText(comp.change, comp.changePercent))
                                .foregroundColor(comp.isImprovement ? .green : .red)
                        }
                    }
                }
            }

            // Info
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("US Navy Method", systemImage: "info.circle")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Body fat is calculated using the US Navy method, which estimates body fat percentage based on waist, neck, and hip (for women) circumferences combined with your height.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Body Measurements")
        .refreshable {
            await viewModel.loadMeasurements()
        }
        .task {
            await viewModel.loadMeasurements()
        }
        .sheet(isPresented: $showAddMeasurement) {
            AddMeasurementSheet(viewModel: viewModel)
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showARMeasurement) {
            ARBodyScanView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showPremiumPrompt) {
            PremiumPromptView()
        }
    }

    private func bodyFatColor(_ bodyFat: Double) -> Color {
        if bodyFat < 10 { return .yellow }
        else if bodyFat < 20 { return .green }
        else if bodyFat < 25 { return .blue }
        else if bodyFat < 30 { return .orange }
        else { return .red }
    }

    private func bodyFatCategory(_ bodyFat: Double) -> String {
        // This is simplified - the real calculation depends on sex
        if bodyFat < 10 { return "Essential/Athletic" }
        else if bodyFat < 20 { return "Fitness" }
        else if bodyFat < 25 { return "Average" }
        else { return "Above Average" }
    }

    private func changeText(_ change: Double, _ percent: Double) -> String {
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change)) (\(sign)\(String(format: "%.0f", percent))%)"
    }
}

// MARK: - Measurement Row

struct MeasurementRow: View {
    let label: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text("\(Int(value)) \(unit)")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Add Measurement Sheet

struct AddMeasurementSheet: View {
    @ObservedObject var viewModel: BodyMeasurementsViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var waistCm: Double = 80
    @State private var neckCm: Double = 38
    @State private var hipsCm: Double = 95
    @State private var calculatedBodyFat: Double?
    @State private var bodyFatCategory: String?
    @State private var isSaving = false

    private var isFemale: Bool {
        appState.userProfile?.sex == .female
    }

    private var heightCm: Double? {
        appState.userProfile?.heightCm
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Waist")
                            Spacer()
                            Text("\(Int(waistCm)) cm")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $waistCm, in: 50...150, step: 0.5)
                            .tint(.orange)
                        Text("Measure at belly button level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Neck")
                            Spacer()
                            Text("\(Int(neckCm)) cm")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $neckCm, in: 25...60, step: 0.5)
                            .tint(.cyan)
                        Text("Measure below Adam's apple")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if isFemale {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Hips")
                                Spacer()
                                Text("\(Int(hipsCm)) cm")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $hipsCm, in: 60...160, step: 0.5)
                                .tint(.pink)
                            Text("Measure at widest point")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Measurements")
                } footer: {
                    Text("Use a tape measure for best accuracy.")
                }

                Section {
                    Button {
                        calculateBodyFat()
                    } label: {
                        Label("Calculate Body Fat", systemImage: "function")
                    }

                    if let bodyFat = calculatedBodyFat {
                        HStack {
                            Text("Estimated Body Fat")
                            Spacer()
                            Text("\(String(format: "%.1f", bodyFat))%")
                                .fontWeight(.bold)
                        }

                        if let category = bodyFatCategory {
                            HStack {
                                Text("Category")
                                Spacer()
                                Text(category)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveMeasurement()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .onChange(of: waistCm) { _, _ in clearCalculation() }
            .onChange(of: neckCm) { _, _ in clearCalculation() }
            .onChange(of: hipsCm) { _, _ in clearCalculation() }
        }
    }

    private func clearCalculation() {
        calculatedBodyFat = nil
        bodyFatCategory = nil
    }

    private func calculateBodyFat() {
        guard let height = heightCm else { return }
        let isMale = !isFemale

        var bodyFat: Double

        if isMale {
            guard waistCm > neckCm else { return }
            bodyFat = 495 / (1.0324 - 0.19077 * log10(waistCm - neckCm) + 0.15456 * log10(height)) - 450
        } else {
            guard (waistCm + hipsCm) > neckCm else { return }
            bodyFat = 495 / (1.29579 - 0.35004 * log10(waistCm + hipsCm - neckCm) + 0.22100 * log10(height)) - 450
        }

        bodyFat = max(2.0, min(60.0, bodyFat))
        calculatedBodyFat = bodyFat

        // Category
        if isMale {
            if bodyFat < 6 { bodyFatCategory = "Essential Fat" }
            else if bodyFat < 14 { bodyFatCategory = "Athletic" }
            else if bodyFat < 18 { bodyFatCategory = "Fitness" }
            else if bodyFat < 25 { bodyFatCategory = "Average" }
            else { bodyFatCategory = "Above Average" }
        } else {
            if bodyFat < 14 { bodyFatCategory = "Essential Fat" }
            else if bodyFat < 21 { bodyFatCategory = "Athletic" }
            else if bodyFat < 25 { bodyFatCategory = "Fitness" }
            else if bodyFat < 32 { bodyFatCategory = "Average" }
            else { bodyFatCategory = "Above Average" }
        }
    }

    private func saveMeasurement() async {
        isSaving = true

        let measurement = BodyMeasurementCreate(
            neckCm: neckCm,
            waistCm: waistCm,
            hipsCm: isFemale ? hipsCm : nil,
            bodyFatPercentage: calculatedBodyFat
        )

        await viewModel.addMeasurement(measurement)
        dismiss()
    }
}

// MARK: - Premium Prompt View

struct PremiumPromptView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)

                Text("AR Body Scan")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Use your camera to automatically measure your body dimensions without a tape measure.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 12) {
                    PremiumFeatureRow(icon: "camera.fill", text: "Uses back camera for full body scan")
                    PremiumFeatureRow(icon: "person.fill", text: "AI-powered body detection")
                    PremiumFeatureRow(icon: "ruler", text: "Automatic measurement extraction")
                    PremiumFeatureRow(icon: "sparkles", text: "No tape measure needed")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()

                Button {
                    // TODO: Navigate to subscription/paywall
                    dismiss()
                } label: {
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Button("Maybe Later") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom)
            }
            .navigationTitle("Premium Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - ViewModel

@MainActor
class BodyMeasurementsViewModel: ObservableObject {
    @Published var measurements: [BodyMeasurement] = []
    @Published var latestMeasurement: BodyMeasurement?
    @Published var comparison: MeasurementComparison?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let container = DependencyContainer.shared

    func loadMeasurements() async {
        isLoading = true

        do {
            measurements = try await container.apiClient.fetchMeasurements(limit: 50)
            latestMeasurement = measurements.first

            if measurements.count >= 2 {
                comparison = try await container.apiClient.compareMeasurements()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addMeasurement(_ measurement: BodyMeasurementCreate) async {
        do {
            let created = try await container.apiClient.createMeasurement(measurement)
            measurements.insert(created, at: 0)
            latestMeasurement = created

            if measurements.count >= 2 {
                comparison = try await container.apiClient.compareMeasurements()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMeasurements(at offsets: IndexSet) async {
        for index in offsets {
            let measurement = measurements[index]
            do {
                try await container.apiClient.deleteMeasurement(id: measurement.id)
                measurements.remove(at: index)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        latestMeasurement = measurements.first
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BodyMeasurementsView()
            .environmentObject(AppState())
    }
}
