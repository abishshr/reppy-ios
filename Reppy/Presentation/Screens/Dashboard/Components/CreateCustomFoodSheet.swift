import SwiftUI

/// Sheet to create a custom food item
struct CreateCustomFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var brand = ""
    @State private var servingSize = "1 serving"
    @State private var servingSizeG = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var sugar = ""
    @State private var barcode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    let apiClient: APIClient
    var prefillBarcode: String?
    var onCreated: ((CustomFood) -> Void)?

    private var isValid: Bool {
        !name.isEmpty &&
        !servingSize.isEmpty &&
        (Double(calories) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section {
                    TextField("Food Name", text: $name)
                    TextField("Brand (optional)", text: $brand)
                } header: {
                    Text("Basic Info")
                }

                // Serving
                Section {
                    TextField("Serving Size (e.g., 1 cup)", text: $servingSize)
                    TextField("Grams per serving (optional)", text: $servingSizeG)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Serving")
                }

                // Nutrition
                Section {
                    NutritionInputRow(label: "Calories", value: $calories, unit: "cal", color: .orange)
                    NutritionInputRow(label: "Protein", value: $protein, unit: "g", color: .blue)
                    NutritionInputRow(label: "Carbs", value: $carbs, unit: "g", color: .yellow)
                    NutritionInputRow(label: "Fat", value: $fat, unit: "g", color: .purple)
                } header: {
                    Text("Main Nutrients")
                } footer: {
                    Text("Calories is required. Macros are optional but recommended.")
                }

                // Optional Nutrients
                Section {
                    NutritionInputRow(label: "Fiber", value: $fiber, unit: "g", color: .green)
                    NutritionInputRow(label: "Sugar", value: $sugar, unit: "g", color: .pink)
                } header: {
                    Text("Optional")
                }

                // Barcode
                Section {
                    TextField("Barcode (optional)", text: $barcode)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Barcode")
                } footer: {
                    Text("Add a barcode to find this food when scanning.")
                }

                // Error
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Food")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let prefillBarcode = prefillBarcode {
                    barcode = prefillBarcode
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await createFood() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || isLoading)
                }
            }
        }
    }

    private func createFood() async {
        isLoading = true
        errorMessage = nil

        let food = CustomFoodCreate(
            name: name,
            brand: brand.isEmpty ? nil : brand,
            servingSize: servingSize,
            servingSizeG: Double(servingSizeG),
            calories: Double(calories) ?? 0,
            proteinG: Double(protein),
            carbsG: Double(carbs),
            fatG: Double(fat),
            fiberG: Double(fiber),
            sugarG: Double(sugar),
            barcode: barcode.isEmpty ? nil : barcode
        )

        do {
            let created = try await apiClient.createCustomFood(food)

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            onCreated?(created)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Nutrition Input Row

private struct NutritionInputRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(label.prefix(1))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                )

            Text(label)

            Spacer()

            HStack(spacing: 4) {
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)

                Text(unit)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    CreateCustomFoodSheet(apiClient: DependencyContainer.shared.apiClient)
}
