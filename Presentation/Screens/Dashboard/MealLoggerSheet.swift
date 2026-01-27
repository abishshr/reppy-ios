import SwiftUI

// MARK: - Meal Logger Sheet

struct MealLoggerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var selectedMealType: MealType = .lunch
    @State private var animateIn = false
    @State private var showPhotoOptions = false
    @State private var showBarcodeScanner = false
    @State private var showQuickAdd = false

    let onScanBarcode: () -> Void
    let onQuickAdd: () -> Void

    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
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

        var gradient: [Color] {
            switch self {
            case .breakfast: return [.orange, .yellow]
            case .lunch: return [.yellow, .orange]
            case .dinner: return [.purple, .pink]
            case .snack: return [.green, .mint]
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        selectedMealType.color.opacity(0.1),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: selectedMealType)

                ScrollView {
                    VStack(spacing: 24) {
                        // Macros Remaining Header
                        macrosHeader
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)

                        // Meal Type Selection
                        mealTypeSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)

                        // Logging Options
                        loggingOptionsSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 30)

                        // Describe with AI Button
                        describeWithAIButton
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 40)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        impactMedium.impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Log Meal")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                impactMedium.prepare()
                impactHeavy.prepare()

                // Set default meal type based on time of day
                selectedMealType = suggestedMealType()

                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    animateIn = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Macros Remaining Header

    private var macrosHeader: some View {
        VStack(spacing: 12) {
            // Calories remaining
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(caloriesRemaining)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 6)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: 0.6) // Would be calculated
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("60%")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )

            // Macros row
            HStack(spacing: 12) {
                MacroRemainingCard(name: "Protein", value: proteinRemaining, unit: "g", color: .blue)
                MacroRemainingCard(name: "Carbs", value: carbsRemaining, unit: "g", color: .orange)
                MacroRemainingCard(name: "Fat", value: fatRemaining, unit: "g", color: .purple)
            }
        }
    }

    // MARK: - Meal Type Section

    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What meal?")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 10) {
                ForEach(MealType.allCases, id: \.self) { type in
                    MealTypeButton(
                        type: type,
                        isSelected: selectedMealType == type
                    ) {
                        impactMedium.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
            Text("How to log?")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 10) {
                // Photo option
                LoggingOptionRow(
                    title: "Take Photo",
                    subtitle: "AI identifies your food",
                    icon: "camera.fill",
                    color: .blue,
                    badge: "AI"
                ) {
                    takePhoto()
                }

                // Barcode scan
                LoggingOptionRow(
                    title: "Scan Barcode",
                    subtitle: "For packaged foods",
                    icon: "barcode.viewfinder",
                    color: .purple,
                    badge: nil
                ) {
                    impactMedium.impactOccurred()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onScanBarcode()
                    }
                }

                // Quick add
                LoggingOptionRow(
                    title: "Quick Add Calories",
                    subtitle: "Enter calories manually",
                    icon: "plus.circle.fill",
                    color: .orange,
                    badge: nil
                ) {
                    impactMedium.impactOccurred()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onQuickAdd()
                    }
                }

                // Search food database
                LoggingOptionRow(
                    title: "Search Foods",
                    subtitle: "Browse food database",
                    icon: "magnifyingglass",
                    color: .green,
                    badge: nil
                ) {
                    searchFoods()
                }
            }
        }
    }

    // MARK: - Describe with AI Button

    private var describeWithAIButton: some View {
        Button {
            impactHeavy.impactOccurred()
            dismiss()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.navigateToChatWith(
                    message: "I want to log my \(selectedMealType.rawValue.lowercased())"
                )
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "message.fill")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Describe Your Meal")
                        .font(.headline)

                    Text("Tell the AI what you ate")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                    Text("Voice")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: selectedMealType.gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: selectedMealType.color.opacity(0.4), radius: 10, y: 5)
        }
        .buttonStyle(BounceButtonStyle())
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

// MARK: - Macro Remaining Card

struct MacroRemainingCard: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value))\(unit)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Meal Type Button

struct MealTypeButton: View {
    let type: MealLoggerSheet.MealType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(colors: type.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [type.color.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .white : type.color)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(type.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? type.color : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? type.color.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Logging Option Row

struct LoggingOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        }
        .buttonStyle(BounceButtonStyle())
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
