import SwiftUI

struct MealLogView: View {
    @StateObject private var viewModel = MealLogViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Today's Summary
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today's Total")
                                .font(.headline)
                            Text("\(viewModel.todayCalories) calories")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack {
                                Text("P:")
                                Text("\(Int(viewModel.todayProtein))g")
                                    .fontWeight(.medium)
                            }
                            .font(.caption)

                            HStack {
                                Text("C:")
                                Text("\(Int(viewModel.todayCarbs))g")
                                    .fontWeight(.medium)
                            }
                            .font(.caption)

                            HStack {
                                Text("F:")
                                Text("\(Int(viewModel.todayFat))g")
                                    .fontWeight(.medium)
                            }
                            .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                // Meals by type
                ForEach(MealType.allCases, id: \.self) { mealType in
                    let meals = viewModel.meals(for: mealType)
                    if !meals.isEmpty {
                        Section(header: MealTypeHeader(type: mealType, meals: meals)) {
                            ForEach(meals) { meal in
                                MealRow(meal: meal)
                            }
                        }
                    }
                }

                // Untyped meals
                let untypedMeals = viewModel.untypedMeals
                if !untypedMeals.isEmpty {
                    Section("Other") {
                        ForEach(untypedMeals) { meal in
                            MealRow(meal: meal)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Meals")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadMeals()
            }
            .onReceive(NotificationCenter.default.publisher(for: .mealLogged)) { _ in
                print("[MealLogView] Received .mealLogged notification")
                Task {
                    await viewModel.loadMeals()
                }
            }
        }
    }
}

// MARK: - Meal Type Header

struct MealTypeHeader: View {
    let type: MealType
    let meals: [Meal]

    private var totalCalories: Int {
        meals.reduce(0) { $0 + ($1.calories ?? 0) }
    }

    var body: some View {
        HStack {
            Image(systemName: type.icon)
            Text(type.displayName)
            Spacer()
            Text("\(totalCalories) cal")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Meal Row

struct MealRow: View {
    let meal: Meal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(meal.items.map { $0.name }.joined(separator: ", "))
                        .fontWeight(.medium)
                        .lineLimit(2)

                    Text(meal.loggedAt.timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(meal.calories ?? 0) cal")
                        .fontWeight(.semibold)

                    if let confidence = meal.confidence {
                        ConfidenceBadge(confidence: confidence)
                    }
                }
            }

            // Macro breakdown
            HStack(spacing: 16) {
                MacroLabel(name: "P", value: meal.proteinG ?? 0)
                MacroLabel(name: "C", value: meal.carbsG ?? 0)
                MacroLabel(name: "F", value: meal.fatG ?? 0)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct MacroLabel: View {
    let name: String
    let value: Double

    var body: some View {
        HStack(spacing: 2) {
            Text(name)
            Text("\(Int(value))g")
                .fontWeight(.medium)
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: Double

    private var color: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// MARK: - Preview

#Preview {
    MealLogView()
}
