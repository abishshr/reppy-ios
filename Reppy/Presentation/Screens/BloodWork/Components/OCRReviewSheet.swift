import SwiftUI

/// Sheet for reviewing and correcting OCR-extracted blood work values
struct OCRReviewSheet: View {
    @ObservedObject var viewModel: BloodWorkViewModel
    @Binding var isPresented: Bool

    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Confidence indicator
                if let response = viewModel.ocrResponse {
                    ConfidenceHeader(confidence: response.confidence, warnings: response.warnings)
                }

                Form {
                    // Test Info
                    Section("Test Information") {
                        TextField("Lab Name", text: $viewModel.ocrLabName)
                        DatePicker("Test Date", selection: $viewModel.ocrTestDate, displayedComponents: .date)
                    }

                    // Extracted Values
                    Section {
                        ForEach(Array(viewModel.ocrReviewValues.keys.sorted()), id: \.self) { key in
                            if let ref = bloodMarkerReferences[key] {
                                OCRMarkerRow(
                                    name: ref.name,
                                    value: Binding(
                                        get: { viewModel.ocrReviewValues[key] ?? 0 },
                                        set: { viewModel.ocrReviewValues[key] = $0 }
                                    ),
                                    unit: ref.unit,
                                    referenceLow: ref.low,
                                    referenceHigh: ref.high,
                                    isUncertain: viewModel.ocrResponse?.uncertainValues[key] != nil
                                )
                            }
                        }
                    } header: {
                        Text("Extracted Values")
                    } footer: {
                        Text("Review values and correct any errors before saving.")
                            .font(.caption)
                    }

                    // Uncertain values warning
                    if let uncertain = viewModel.ocrResponse?.uncertainValues, !uncertain.isEmpty {
                        Section {
                            ForEach(Array(uncertain.keys), id: \.self) { key in
                                if let val = uncertain[key], let ref = bloodMarkerReferences[key] {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(ref.name)
                                                .font(.subheadline)

                                            if let rawText = val.rawText {
                                                Text("OCR read: \"\(rawText)\"")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()

                                        Text(String(format: "%.0f%%", val.confidence * 100))
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        } header: {
                            Text("Needs Review")
                        }
                    }
                }
            }
            .navigationTitle("Review Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.clearOCRState()
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || viewModel.ocrReviewValues.isEmpty)
                }
            }
        }
    }

    private func save() async {
        isSaving = true

        do {
            _ = try await viewModel.confirmOCRResults()
            isPresented = false
        } catch {
            print("[OCRReviewSheet] Error: \(error)")
        }

        isSaving = false
    }
}

// MARK: - Confidence Header

struct ConfidenceHeader: View {
    let confidence: Double
    let warnings: [String]

    var confidenceColor: Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: confidence >= 0.8 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(confidenceColor)

                Text("OCR Confidence: \(Int(confidence * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()
            }

            if !warnings.isEmpty {
                ForEach(warnings, id: \.self) { warning in
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                            .font(.caption)

                        Text(warning)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(confidenceColor.opacity(0.1))
    }
}

// MARK: - OCR Marker Row

struct OCRMarkerRow: View {
    let name: String
    @Binding var value: Double
    let unit: String
    let referenceLow: Double
    let referenceHigh: Double
    let isUncertain: Bool

    @State private var valueText: String = ""

    var status: MarkerStatus {
        if value < referenceLow { return .low }
        if value > referenceHigh { return .high }
        return .optimal
    }

    var body: some View {
        HStack {
            if isUncertain {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)

                Text("\(String(format: "%.0f", referenceLow))-\(String(format: "%.0f", referenceHigh)) \(unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            TextField("", text: $valueText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .onChange(of: valueText) { _, newValue in
                    if let parsed = Double(newValue) {
                        value = parsed
                    }
                }
                .onAppear {
                    valueText = value > 0 ? String(format: "%.1f", value) : ""
                }

            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            Circle()
                .fill(status.color)
                .frame(width: 10, height: 10)
        }
    }
}

#Preview {
    OCRReviewSheet(viewModel: BloodWorkViewModel(), isPresented: .constant(true))
}
