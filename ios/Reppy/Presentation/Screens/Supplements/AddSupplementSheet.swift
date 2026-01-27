import SwiftUI

/// Sheet for adding or editing a supplement
struct AddSupplementSheet: View {
    @ObservedObject var viewModel: SupplementsViewModel
    var editingSupplement: Supplement?

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var brand = ""
    @State private var servingSize = ""
    @State private var notes = ""

    // Vitamins
    @State private var vitaminA = ""
    @State private var vitaminC = ""
    @State private var vitaminD = ""
    @State private var vitaminE = ""
    @State private var vitaminK = ""
    @State private var vitaminB1 = ""
    @State private var vitaminB2 = ""
    @State private var vitaminB3 = ""
    @State private var vitaminB6 = ""
    @State private var vitaminB9 = ""
    @State private var vitaminB12 = ""

    // Minerals
    @State private var calcium = ""
    @State private var iron = ""
    @State private var magnesium = ""
    @State private var zinc = ""
    @State private var selenium = ""
    @State private var iodine = ""

    // Other
    @State private var omega3 = ""
    @State private var biotin = ""

    @State private var isSaving = false
    @State private var showVitamins = false
    @State private var showMinerals = false

    private var isEditing: Bool { editingSupplement != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section {
                    TextField("Name (e.g., Vitamin D3)", text: $name)
                    TextField("Brand (optional)", text: $brand)
                    TextField("Serving Size (e.g., 1 tablet)", text: $servingSize)
                }

                // Vitamins Section
                Section {
                    DisclosureGroup("Vitamins (per serving)", isExpanded: $showVitamins) {
                        NutrientField(label: "Vitamin A", value: $vitaminA, unit: "mcg")
                        NutrientField(label: "Vitamin C", value: $vitaminC, unit: "mg")
                        NutrientField(label: "Vitamin D", value: $vitaminD, unit: "mcg")
                        NutrientField(label: "Vitamin E", value: $vitaminE, unit: "mg")
                        NutrientField(label: "Vitamin K", value: $vitaminK, unit: "mcg")
                        NutrientField(label: "Thiamin (B1)", value: $vitaminB1, unit: "mg")
                        NutrientField(label: "Riboflavin (B2)", value: $vitaminB2, unit: "mg")
                        NutrientField(label: "Niacin (B3)", value: $vitaminB3, unit: "mg")
                        NutrientField(label: "Vitamin B6", value: $vitaminB6, unit: "mg")
                        NutrientField(label: "Folate (B9)", value: $vitaminB9, unit: "mcg")
                        NutrientField(label: "Vitamin B12", value: $vitaminB12, unit: "mcg")
                    }
                }

                // Minerals Section
                Section {
                    DisclosureGroup("Minerals (per serving)", isExpanded: $showMinerals) {
                        NutrientField(label: "Calcium", value: $calcium, unit: "mg")
                        NutrientField(label: "Iron", value: $iron, unit: "mg")
                        NutrientField(label: "Magnesium", value: $magnesium, unit: "mg")
                        NutrientField(label: "Zinc", value: $zinc, unit: "mg")
                        NutrientField(label: "Selenium", value: $selenium, unit: "mcg")
                        NutrientField(label: "Iodine", value: $iodine, unit: "mcg")
                    }
                }

                // Other Section
                Section("Other") {
                    NutrientField(label: "Omega-3", value: $omega3, unit: "mg")
                    NutrientField(label: "Biotin", value: $biotin, unit: "mcg")
                }

                // Notes
                Section("Notes (optional)") {
                    TextField("Any additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Quick Templates
                if !isEditing {
                    Section("Quick Templates") {
                        Button {
                            applyTemplate(.vitaminD)
                        } label: {
                            Label("Vitamin D3 (5000 IU)", systemImage: "sun.max.fill")
                        }

                        Button {
                            applyTemplate(.multivitamin)
                        } label: {
                            Label("Basic Multivitamin", systemImage: "pills.fill")
                        }

                        Button {
                            applyTemplate(.omega3)
                        } label: {
                            Label("Fish Oil / Omega-3", systemImage: "drop.fill")
                        }

                        Button {
                            applyTemplate(.vitaminC)
                        } label: {
                            Label("Vitamin C (1000mg)", systemImage: "leaf.fill")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Supplement" : "Add Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(isEditing ? "Save" : "Add")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .onAppear {
                if let supplement = editingSupplement {
                    loadSupplement(supplement)
                }
            }
        }
    }

    // MARK: - Load Existing Supplement

    private func loadSupplement(_ supplement: Supplement) {
        name = supplement.name
        brand = supplement.brand ?? ""
        servingSize = supplement.servingSize ?? ""
        notes = supplement.notes ?? ""

        // Vitamins
        if let v = supplement.vitaminAMcg { vitaminA = String(format: "%.0f", v) }
        if let v = supplement.vitaminCMg { vitaminC = String(format: "%.0f", v) }
        if let v = supplement.vitaminDMcg { vitaminD = String(format: "%.0f", v) }
        if let v = supplement.vitaminEMg { vitaminE = String(format: "%.0f", v) }
        if let v = supplement.vitaminKMcg { vitaminK = String(format: "%.0f", v) }
        if let v = supplement.vitaminB1Mg { vitaminB1 = String(format: "%.1f", v) }
        if let v = supplement.vitaminB2Mg { vitaminB2 = String(format: "%.1f", v) }
        if let v = supplement.vitaminB3Mg { vitaminB3 = String(format: "%.0f", v) }
        if let v = supplement.vitaminB6Mg { vitaminB6 = String(format: "%.1f", v) }
        if let v = supplement.vitaminB9Mcg { vitaminB9 = String(format: "%.0f", v) }
        if let v = supplement.vitaminB12Mcg { vitaminB12 = String(format: "%.0f", v) }

        // Minerals
        if let v = supplement.calciumMg { calcium = String(format: "%.0f", v) }
        if let v = supplement.ironMg { iron = String(format: "%.0f", v) }
        if let v = supplement.magnesiumMg { magnesium = String(format: "%.0f", v) }
        if let v = supplement.zincMg { zinc = String(format: "%.0f", v) }
        if let v = supplement.seleniumMcg { selenium = String(format: "%.0f", v) }
        if let v = supplement.iodineMcg { iodine = String(format: "%.0f", v) }

        // Other
        if let v = supplement.omega3Mg { omega3 = String(format: "%.0f", v) }
        if let v = supplement.biotinMcg { biotin = String(format: "%.0f", v) }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true

        do {
            if let supplement = editingSupplement {
                // Update existing
                let update = SupplementUpdateRequest(
                    name: name,
                    brand: brand.isEmpty ? nil : brand,
                    servingSize: servingSize.isEmpty ? nil : servingSize,
                    notes: notes.isEmpty ? nil : notes,
                    vitaminAMcg: Double(vitaminA),
                    vitaminCMg: Double(vitaminC),
                    vitaminDMcg: Double(vitaminD),
                    vitaminEMg: Double(vitaminE),
                    vitaminKMcg: Double(vitaminK),
                    vitaminB1Mg: Double(vitaminB1),
                    vitaminB2Mg: Double(vitaminB2),
                    vitaminB3Mg: Double(vitaminB3),
                    vitaminB6Mg: Double(vitaminB6),
                    vitaminB9Mcg: Double(vitaminB9),
                    vitaminB12Mcg: Double(vitaminB12),
                    calciumMg: Double(calcium),
                    ironMg: Double(iron),
                    magnesiumMg: Double(magnesium),
                    zincMg: Double(zinc),
                    seleniumMcg: Double(selenium),
                    iodineMcg: Double(iodine),
                    omega3Mg: Double(omega3),
                    biotinMcg: Double(biotin)
                )
                try await viewModel.updateSupplement(id: supplement.id, update: update)
            } else {
                // Create new
                let request = SupplementCreateRequest(
                    name: name,
                    brand: brand.isEmpty ? nil : brand,
                    servingSize: servingSize.isEmpty ? nil : servingSize,
                    notes: notes.isEmpty ? nil : notes,
                    vitaminAMcg: Double(vitaminA),
                    vitaminCMg: Double(vitaminC),
                    vitaminDMcg: Double(vitaminD),
                    vitaminEMg: Double(vitaminE),
                    vitaminKMcg: Double(vitaminK),
                    vitaminB1Mg: Double(vitaminB1),
                    vitaminB2Mg: Double(vitaminB2),
                    vitaminB3Mg: Double(vitaminB3),
                    vitaminB6Mg: Double(vitaminB6),
                    vitaminB9Mcg: Double(vitaminB9),
                    vitaminB12Mcg: Double(vitaminB12),
                    calciumMg: Double(calcium),
                    ironMg: Double(iron),
                    magnesiumMg: Double(magnesium),
                    phosphorusMg: nil,
                    potassiumMg: nil,
                    zincMg: Double(zinc),
                    seleniumMcg: Double(selenium),
                    copperMcg: nil,
                    manganeseMg: nil,
                    iodineMcg: Double(iodine),
                    omega3Mg: Double(omega3),
                    biotinMcg: Double(biotin),
                    cholineMg: nil
                )
                try await viewModel.createSupplement(request)
            }
            dismiss()
        } catch {
            print("[AddSupplementSheet] Error saving: \(error)")
        }

        isSaving = false
    }

    // MARK: - Templates

    private enum SupplementTemplate {
        case vitaminD
        case multivitamin
        case omega3
        case vitaminC
    }

    private func applyTemplate(_ template: SupplementTemplate) {
        switch template {
        case .vitaminD:
            name = "Vitamin D3"
            servingSize = "1 softgel"
            vitaminD = "125" // 5000 IU
            showVitamins = true

        case .multivitamin:
            name = "Daily Multivitamin"
            servingSize = "1 tablet"
            vitaminA = "900"
            vitaminC = "90"
            vitaminD = "20"
            vitaminE = "15"
            vitaminK = "120"
            vitaminB1 = "1.2"
            vitaminB2 = "1.3"
            vitaminB3 = "16"
            vitaminB6 = "1.7"
            vitaminB9 = "400"
            vitaminB12 = "2.4"
            calcium = "200"
            iron = "8"
            magnesium = "100"
            zinc = "11"
            selenium = "55"
            iodine = "150"
            showVitamins = true

        case .omega3:
            name = "Fish Oil Omega-3"
            servingSize = "1 softgel"
            omega3 = "1000"

        case .vitaminC:
            name = "Vitamin C"
            servingSize = "1 tablet"
            vitaminC = "1000"
            showVitamins = true
        }
    }
}

// MARK: - Nutrient Field

struct NutrientField: View {
    let label: String
    @Binding var value: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)

            Spacer()

            TextField("0", text: $value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)

            Text(unit)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}

#Preview {
    AddSupplementSheet(viewModel: SupplementsViewModel())
}
