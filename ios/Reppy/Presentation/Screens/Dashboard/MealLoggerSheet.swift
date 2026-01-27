import SwiftUI

// MARK: - Meal Logger Sheet

struct MealLoggerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var selectedMealType: MealType = .lunch
    @State private var animateIn = false

    let onScanBarcode: () -> Void
    let onQuickAdd: () -> Void

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)

    // Would come from ViewModel
    private let caloriesRemaining = 1250
    private let proteinRemaining = 85.0
    private let carbsRemaining = 120.0
    private let fatRemaining = 45.0

    enum MealType: String, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"

        var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.fill"
            case .snack: return "carrot.fill"
            }
        }

        var color: Color {
            switch self {
            case .breakfast: return .orange
            case .lunch: return .yellow
            case .dinner: return .purple
            case .snack: return .green
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Macros Remaining Header
                    macrosHeader
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -10)

                    // Meal Type Selection
                    mealTypeSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)

                    // Logging Options
                    loggingOptionsSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)

                    // AI Chat Button
                    aiChatButton
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                impactLight.prepare()
                impactMedium.prepare()
                selectedMealType = suggestedMealType()

                withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                    animateIn = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Macros Remaining Header

    private var macrosHeader: some View {
        VStack(spacing: 16) {
            // Calories remaining
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories Remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(caloriesRemaining)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text("cal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 6)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: 0.6)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    Text("60%")
                        .font(.caption.weight(.semibold))
                }
            }

            // Macros row
            HStack(spacing: 12) {
                MacroCard(name: "Protein", value: proteinRemaining, unit: "g", color: .blue)
                MacroCard(name: "Carbs", value: carbsRemaining, unit: "g", color: .orange)
                MacroCard(name: "Fat", value: fatRemaining, unit: "g", color: .purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Meal Type Section

    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Type")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(MealType.allCases, id: \.self) { type in
                    MealLoggerTypeButton(
                        type: type,
                        isSelected: selectedMealType == type
                    ) {
                        impactLight.impactOccurred()
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedMealType = type
                        }
                    }
                }
            }
        }
    }

    // MARK: - Logging Options Section

    private var loggingOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Log")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                LogOptionRow(
                    title: "Take Photo",
                    subtitle: "AI identifies your food",
                    icon: "camera.fill",
                    color: .blue
                ) {
                    takePhoto()
                }

                LogOptionRow(
                    title: "Scan Barcode",
                    subtitle: "For packaged foods",
                    icon: "barcode.viewfinder",
                    color: .purple
                ) {
                    impactMedium.impactOccurred()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onScanBarcode()
                    }
                }

                LogOptionRow(
                    title: "Quick Add Calories",
                    subtitle: "Enter calories manually",
                    icon: "plus.circle.fill",
                    color: .orange
                ) {
                    impactMedium.impactOccurred()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onQuickAdd()
                    }
                }

                LogOptionRow(
                    title: "Search Foods",
                    subtitle: "Browse food database",
                    icon: "magnifyingglass",
                    color: .green
                ) {
                    searchFoods()
                }
            }
        }
    }

    // MARK: - AI Chat Button

    private var aiChatButton: some View {
        Button {
            impactMedium.impactOccurred()
            dismiss()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.navigateToChatWith(
                    message: "I want to log my \(selectedMealType.rawValue.lowercased())"
                )
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "message.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Describe Your Meal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Tell Reppy what you ate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                    Text("Voice")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func takePhoto() {
        impactMedium.impactOccurred()
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.navigateToChatWith(
                message: "I want to log my \(selectedMealType.rawValue.lowercased()) using a photo"
            )
        }
    }

    private func searchFoods() {
        impactMedium.impactOccurred()
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.navigateToChatWith(
                message: "Help me search for a food to log for \(selectedMealType.rawValue.lowercased())"
            )
        }
    }

    private func suggestedMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<18: return .snack
        default: return .dinner
        }
    }
}

// MARK: - Macro Card

private struct MacroCard: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value))\(unit)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Meal Type Button

private struct MealLoggerTypeButton: View {
    let type: MealLoggerSheet.MealType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : type.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? type.color : type.color.opacity(0.15))
                    )

                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? type.color : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? type.color.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? type.color.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log Option Row

private struct LogOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MealLoggerSheet(
        onScanBarcode: {},
        onQuickAdd: {}
    )
    .environmentObject(AppState())
}
