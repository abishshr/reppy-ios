import SwiftUI

/// Quick add calories sheet for rough calorie tracking
struct QuickAddCaloriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var calories = ""
    @State private var description = ""
    @State private var selectedMealType: MealType = .snack
    @State private var showMacros = false
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loggedAt = Date()
    @State private var showTimePicker = false

    let onAdd: (Int, String, String, Double?, Double?, Double?, Date) async throws -> Void

    private var caloriesInt: Int? {
        Int(calories)
    }

    private var isValid: Bool {
        guard let cal = caloriesInt, cal > 0, cal <= 10000 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Calorie Input
                    VStack(spacing: 8) {
                        Text("How many calories?")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            TextField("0", text: $calories)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 200)

                            Text("cal")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)

                    // Quick presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Presets")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(CaloriePreset.allCases, id: \.rawValue) { preset in
                                Button {
                                    calories = String(preset.rawValue)
                                    description = preset.label
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(preset.rawValue)")
                                            .font(.headline)
                                        Text(preset.label)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("e.g., Coffee with cream", text: $description)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)

                    // Meal Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meal Type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Meal Type", selection: $selectedMealType) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    // Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button {
                            showTimePicker.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.accentColor)
                                Text(loggedAt, style: .time)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(showTimePicker ? 180 : 0))
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        if showTimePicker {
                            DatePicker(
                                "Time",
                                selection: $loggedAt,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal)

                    // Optional Macros
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showMacros.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Add Macros")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(showMacros ? 180 : 0))
                            }
                        }
                        .buttonStyle(.plain)

                        if showMacros {
                            HStack(spacing: 12) {
                                MacroInputField(
                                    label: "Protein",
                                    value: $protein,
                                    color: .blue
                                )
                                MacroInputField(
                                    label: "Carbs",
                                    value: $carbs,
                                    color: .orange
                                )
                                MacroInputField(
                                    label: "Fat",
                                    value: $fat,
                                    color: .purple
                                )
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal)

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await addCalories() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || isLoading)
                }
            }
        }
    }

    private func addCalories() async {
        guard let cal = caloriesInt else { return }
        isLoading = true
        errorMessage = nil

        do {
            let proteinG = Double(protein)
            let carbsG = Double(carbs)
            let fatG = Double(fat)

            try await onAdd(
                cal,
                description.isEmpty ? "Quick Add" : description,
                selectedMealType.rawValue,
                proteinG,
                carbsG,
                fatG,
                loggedAt
            )

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Calorie Presets

enum CaloriePreset: Int, CaseIterable {
    case small = 100
    case medium = 200
    case snack = 300
    case light = 400
    case regular = 500
    case large = 700

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .snack: return "Snack"
        case .light: return "Light"
        case .regular: return "Regular"
        case .large: return "Large"
        }
    }
}

// MARK: - Macro Input Field

private struct MacroInputField: View {
    let label: String
    @Binding var value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            TextField("0", text: $value)
                .font(.headline)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(color.opacity(0.1))
                .cornerRadius(8)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    QuickAddCaloriesSheet { calories, description, mealType, protein, carbs, fat, loggedAt in
        print("Added \(calories) cal: \(description) at \(loggedAt)")
    }
}
