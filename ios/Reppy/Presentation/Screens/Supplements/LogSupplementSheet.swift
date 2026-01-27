import SwiftUI

/// Sheet for logging supplement intake
struct LogSupplementSheet: View {
    let supplement: Supplement
    @ObservedObject var viewModel: SupplementsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var servings: Double = 1.0
    @State private var notes = ""
    @State private var isLogging = false
    @State private var showSuccess = false

    private let servingOptions = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Supplement Info
                VStack(spacing: 8) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.purple)

                    Text(supplement.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let brand = supplement.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let servingSize = supplement.servingSize {
                        Text(servingSize)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemFill))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 20)

                // Servings Selector
                VStack(spacing: 12) {
                    Text("How many servings?")
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(servingOptions, id: \.self) { option in
                            ServingButton(
                                value: option,
                                isSelected: servings == option,
                                onTap: { servings = option }
                            )
                        }
                    }
                }

                // Nutrients Preview
                if supplement.hasVitamins || supplement.hasMinerals {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrients from \(formatServings(servings))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                if let d = supplement.vitaminDMcg {
                                    NutrientPreviewPill(
                                        name: "Vit D",
                                        value: d * servings,
                                        unit: "mcg",
                                        color: .orange
                                    )
                                }
                                if let c = supplement.vitaminCMg {
                                    NutrientPreviewPill(
                                        name: "Vit C",
                                        value: c * servings,
                                        unit: "mg",
                                        color: .yellow
                                    )
                                }
                                if let b12 = supplement.vitaminB12Mcg {
                                    NutrientPreviewPill(
                                        name: "B12",
                                        value: b12 * servings,
                                        unit: "mcg",
                                        color: .red
                                    )
                                }
                                if let calcium = supplement.calciumMg {
                                    NutrientPreviewPill(
                                        name: "Calcium",
                                        value: calcium * servings,
                                        unit: "mg",
                                        color: .blue
                                    )
                                }
                                if let iron = supplement.ironMg {
                                    NutrientPreviewPill(
                                        name: "Iron",
                                        value: iron * servings,
                                        unit: "mg",
                                        color: .green
                                    )
                                }
                                if let mag = supplement.magnesiumMg {
                                    NutrientPreviewPill(
                                        name: "Magnesium",
                                        value: mag * servings,
                                        unit: "mg",
                                        color: .purple
                                    )
                                }
                                if let omega = supplement.omega3Mg {
                                    NutrientPreviewPill(
                                        name: "Omega-3",
                                        value: omega * servings,
                                        unit: "mg",
                                        color: .cyan
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }

                // Notes (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Any notes about this intake...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                }

                Spacer()

                // Log Button
                Button {
                    Task { await logSupplement() }
                } label: {
                    if isLogging {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(16)
                    } else if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Logged!")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(16)
                    } else {
                        Text("Log \(formatServings(servings))")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(16)
                    }
                }
                .disabled(isLogging || showSuccess)
            }
            .padding()
            .navigationTitle("Log Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Format Servings

    private func formatServings(_ value: Double) -> String {
        if value == 1.0 {
            return "1 serving"
        } else if value == floor(value) {
            return "\(Int(value)) servings"
        } else {
            return "\(String(format: "%.1f", value)) servings"
        }
    }

    // MARK: - Log Supplement

    private func logSupplement() async {
        isLogging = true

        do {
            try await viewModel.logSupplement(
                supplementId: supplement.id,
                servings: servings,
                notes: notes.isEmpty ? nil : notes
            )

            // Show success
            showSuccess = true
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)

            // Dismiss after delay
            try? await Task.sleep(nanoseconds: 800_000_000)
            dismiss()
        } catch {
            print("[LogSupplementSheet] Error: \(error)")
            isLogging = false
        }
    }
}

// MARK: - Serving Button

struct ServingButton: View {
    let value: Double
    let isSelected: Bool
    let onTap: () -> Void

    private var displayValue: String {
        if value == floor(value) {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(displayValue)
                .font(.headline)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? .white : .purple)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? Color.purple : Color.purple.opacity(0.1))
                )
        }
    }
}

// MARK: - Nutrient Preview Pill

struct NutrientPreviewPill: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("\(Int(value))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 70)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    LogSupplementSheet(
        supplement: Supplement(
            id: "1",
            userId: "user",
            name: "Vitamin D3",
            brand: "NOW Foods",
            servingSize: "1 softgel",
            notes: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            vitaminAMcg: nil,
            vitaminCMg: nil,
            vitaminDMcg: 125,
            vitaminEMg: nil,
            vitaminKMcg: nil,
            vitaminB1Mg: nil,
            vitaminB2Mg: nil,
            vitaminB3Mg: nil,
            vitaminB6Mg: nil,
            vitaminB9Mcg: nil,
            vitaminB12Mcg: nil,
            calciumMg: nil,
            ironMg: nil,
            magnesiumMg: nil,
            phosphorusMg: nil,
            potassiumMg: nil,
            zincMg: nil,
            seleniumMcg: nil,
            copperMcg: nil,
            manganeseMg: nil,
            iodineMcg: nil,
            omega3Mg: nil,
            biotinMcg: nil,
            cholineMg: nil
        ),
        viewModel: SupplementsViewModel()
    )
}
