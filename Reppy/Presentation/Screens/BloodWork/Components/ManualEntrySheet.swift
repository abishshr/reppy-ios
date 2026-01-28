import SwiftUI

/// Sheet for manually entering blood work results
struct ManualEntrySheet: View {
    @ObservedObject var viewModel: BloodWorkViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var labName = ""
    @State private var testDate = Date()
    @State private var isSaving = false

    // Category expansion states
    @State private var showVitamins = true
    @State private var showMetabolic = false
    @State private var showLipids = false
    @State private var showHormones = false
    @State private var showCBC = false
    @State private var showLiverKidney = false

    // Marker values (as strings for text fields)
    @State private var vitaminD = ""
    @State private var vitaminB12 = ""
    @State private var folate = ""
    @State private var iron = ""
    @State private var ferritin = ""
    @State private var fastingGlucose = ""
    @State private var hba1c = ""
    @State private var insulin = ""
    @State private var totalCholesterol = ""
    @State private var ldl = ""
    @State private var hdl = ""
    @State private var triglycerides = ""
    @State private var testosterone = ""
    @State private var tsh = ""
    @State private var cortisol = ""
    @State private var hemoglobin = ""
    @State private var hematocrit = ""
    @State private var alt = ""
    @State private var ast = ""
    @State private var creatinine = ""

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Test Information") {
                    TextField("Lab Name (optional)", text: $labName)
                    DatePicker("Test Date", selection: $testDate, displayedComponents: .date)
                }

                // Vitamins & Minerals
                Section {
                    DisclosureGroup("Vitamins & Minerals", isExpanded: $showVitamins) {
                        MarkerField(label: "Vitamin D", value: $vitaminD, unit: "ng/mL", reference: "30-100")
                        MarkerField(label: "Vitamin B12", value: $vitaminB12, unit: "pg/mL", reference: "200-900")
                        MarkerField(label: "Folate", value: $folate, unit: "ng/mL", reference: "3-17")
                        MarkerField(label: "Iron", value: $iron, unit: "mcg/dL", reference: "60-170")
                        MarkerField(label: "Ferritin", value: $ferritin, unit: "ng/mL", reference: "12-300")
                    }
                }

                // Metabolic
                Section {
                    DisclosureGroup("Metabolic Panel", isExpanded: $showMetabolic) {
                        MarkerField(label: "Fasting Glucose", value: $fastingGlucose, unit: "mg/dL", reference: "70-99")
                        MarkerField(label: "HbA1c", value: $hba1c, unit: "%", reference: "4.0-5.6")
                        MarkerField(label: "Insulin", value: $insulin, unit: "mIU/mL", reference: "2.6-24.9")
                    }
                }

                // Lipids
                Section {
                    DisclosureGroup("Lipid Panel", isExpanded: $showLipids) {
                        MarkerField(label: "Total Cholesterol", value: $totalCholesterol, unit: "mg/dL", reference: "125-200")
                        MarkerField(label: "LDL", value: $ldl, unit: "mg/dL", reference: "<100")
                        MarkerField(label: "HDL", value: $hdl, unit: "mg/dL", reference: ">40")
                        MarkerField(label: "Triglycerides", value: $triglycerides, unit: "mg/dL", reference: "<150")
                    }
                }

                // Hormones
                Section {
                    DisclosureGroup("Hormones", isExpanded: $showHormones) {
                        MarkerField(label: "Testosterone", value: $testosterone, unit: "ng/dL", reference: "300-1000")
                        MarkerField(label: "TSH", value: $tsh, unit: "mIU/L", reference: "0.4-4.0")
                        MarkerField(label: "Cortisol", value: $cortisol, unit: "mcg/dL", reference: "6-23")
                    }
                }

                // CBC
                Section {
                    DisclosureGroup("Complete Blood Count", isExpanded: $showCBC) {
                        MarkerField(label: "Hemoglobin", value: $hemoglobin, unit: "g/dL", reference: "12-17.5")
                        MarkerField(label: "Hematocrit", value: $hematocrit, unit: "%", reference: "36-50")
                    }
                }

                // Liver & Kidney
                Section {
                    DisclosureGroup("Liver & Kidney", isExpanded: $showLiverKidney) {
                        MarkerField(label: "ALT", value: $alt, unit: "U/L", reference: "7-56")
                        MarkerField(label: "AST", value: $ast, unit: "U/L", reference: "10-40")
                        MarkerField(label: "Creatinine", value: $creatinine, unit: "mg/dL", reference: "0.7-1.3")
                    }
                }
            }
            .navigationTitle("Manual Entry")
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
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true

        // Build request with all entered values
        var data = BloodWorkPanelCreate(testDate: testDate)
        data.labName = labName.isEmpty ? nil : labName
        data.source = .manual

        // Parse and set marker values
        data.vitaminDNgMl = Double(vitaminD)
        data.vitaminB12PgMl = Double(vitaminB12)
        data.folateNgMl = Double(folate)
        data.ironMcgDl = Double(iron)
        data.ferritinNgMl = Double(ferritin)
        data.fastingGlucoseMgDl = Double(fastingGlucose)
        data.hba1cPercent = Double(hba1c)
        data.insulinMiuMl = Double(insulin)
        data.totalCholesterolMgDl = Double(totalCholesterol)
        data.ldlMgDl = Double(ldl)
        data.hdlMgDl = Double(hdl)
        data.triglyceridesMgDl = Double(triglycerides)
        data.testosteroneTotalNgDl = Double(testosterone)
        data.tshMiuL = Double(tsh)
        data.cortisolMcgDl = Double(cortisol)
        data.hemoglobinGDl = Double(hemoglobin)
        data.hematocritPercent = Double(hematocrit)
        data.altUL = Double(alt)
        data.astUL = Double(ast)
        data.creatinineMgDl = Double(creatinine)

        do {
            _ = try await viewModel.createPanel(data)
            dismiss()
        } catch {
            print("[ManualEntrySheet] Error: \(error)")
        }

        isSaving = false
    }
}

// MARK: - Marker Field

struct MarkerField: View {
    let label: String
    @Binding var value: String
    let unit: String
    let reference: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)

                Text("Ref: \(reference)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            TextField("Value", text: $value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)

            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
        }
    }
}

#Preview {
    ManualEntrySheet(viewModel: BloodWorkViewModel())
}
