import SwiftUI

/// Dedicated Food tab - food logging, water tracking, and meal management
struct FoodTabView: View {
    @StateObject private var viewModel = FoodTabViewModel()
    @State private var showQuickAddCalories = false
    @State private var showCopyMeal = false
    @State private var showMyFoods = false
    @State private var showFoodSearch = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Water Tracking Card
                    WaterTrackingCard(
                        todayMl: viewModel.todayWaterMl,
                        goalMl: viewModel.waterGoalMl,
                        isLoading: viewModel.isAddingWater,
                        onQuickAdd: { amount in
                            Task { await viewModel.addWater(amountMl: amount) }
                        }
                    )
                    .padding(.horizontal)

                    // Food Tools Row
                    FoodToolsRow(
                        onQuickAdd: { showQuickAddCalories = true },
                        onCopyMeal: { showCopyMeal = true },
                        onMyFoods: { showMyFoods = true },
                        onSearch: { showFoodSearch = true }
                    )
                    .padding(.horizontal)

                    // Today's Summary
                    FoodSummaryCard(
                        calories: viewModel.todayCalories,
                        calorieTarget: viewModel.calorieTarget,
                        protein: viewModel.todayProtein,
                        proteinTarget: viewModel.proteinTarget,
                        carbs: viewModel.todayCarbs,
                        carbsTarget: viewModel.carbsTarget,
                        fat: viewModel.todayFat,
                        fatTarget: viewModel.fatTarget
                    )
                    .padding(.horizontal)

                    // Testosterone Summary (male users only)
                    if viewModel.isMaleUser {
                        DailyTestosteroneSummary(
                            boostingCount: viewModel.testosteroneBoostingCount,
                            reducingCount: viewModel.testosteroneReducingCount,
                            neutralCount: viewModel.testosteroneNeutralCount
                        )
                        .padding(.horizontal)
                    }

                    // Meals by Type
                    VStack(spacing: 16) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            let meals = viewModel.meals(for: mealType)
                            if !meals.isEmpty {
                                FoodMealSection(type: mealType, meals: meals)
                            }
                        }

                        // Untyped meals
                        let untypedMeals = viewModel.untypedMeals
                        if !untypedMeals.isEmpty {
                            FoodMealSection(type: nil, meals: untypedMeals)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Food")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .mealLogged)) { _ in
                Task { await viewModel.loadData() }
            }
            .sheet(isPresented: $showQuickAddCalories) {
                QuickAddCaloriesSheet { calories, description, mealType, protein, carbs, fat, loggedAt in
                    try await viewModel.quickAddCalories(
                        calories: calories,
                        description: description,
                        mealType: mealType,
                        proteinG: protein,
                        carbsG: carbs,
                        fatG: fat,
                        loggedAt: loggedAt
                    )
                }
            }
            .sheet(isPresented: $showCopyMeal) {
                CopyMealSheet(apiClient: DependencyContainer.shared.apiClient) { _ in
                    Task { await viewModel.loadData() }
                }
            }
            .sheet(isPresented: $showMyFoods) {
                MyFoodsSheet(apiClient: DependencyContainer.shared.apiClient)
            }
            .sheet(isPresented: $showFoodSearch) {
                FoodSearchSheet()
            }
        }
    }
}

// MARK: - Water Tracking Card

struct WaterTrackingCard: View {
    let todayMl: Int
    let goalMl: Int
    let isLoading: Bool
    let onQuickAdd: (Int) -> Void

    private var progress: Double {
        guard goalMl > 0 else { return 0 }
        return min(Double(todayMl) / Double(goalMl), 1.0)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                Text("Water")
                    .font(.headline)
                Spacer()
                Text("\(todayMl) / \(goalMl) ml")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 12)

            // Quick add buttons
            HStack(spacing: 12) {
                WaterAddButton(label: "250ml", systemImage: "drop", isLoading: isLoading) {
                    onQuickAdd(250)
                }
                WaterAddButton(label: "500ml", systemImage: "drop.fill", isLoading: isLoading) {
                    onQuickAdd(500)
                }
                WaterAddButton(label: "750ml", systemImage: "waterbottle", isLoading: isLoading) {
                    onQuickAdd(750)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct WaterAddButton: View {
    let label: String
    let systemImage: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.5 : 1.0)
    }
}

// MARK: - Food Tools Row

struct FoodToolsRow: View {
    let onQuickAdd: () -> Void
    let onCopyMeal: () -> Void
    let onMyFoods: () -> Void
    let onSearch: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            FoodToolButton(
                icon: "plus.circle.fill",
                title: "Quick Add",
                color: .orange,
                action: onQuickAdd
            )

            FoodToolButton(
                icon: "doc.on.doc.fill",
                title: "Copy Meal",
                color: .green,
                action: onCopyMeal
            )

            FoodToolButton(
                icon: "star.fill",
                title: "My Foods",
                color: .purple,
                action: onMyFoods
            )

            FoodToolButton(
                icon: "magnifyingglass",
                title: "Search",
                color: .blue,
                action: onSearch
            )
        }
    }
}

struct FoodToolButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

// MARK: - Food Summary Card

struct FoodSummaryCard: View {
    let calories: Int
    let calorieTarget: Int
    let protein: Double
    let proteinTarget: Double
    let carbs: Double
    let carbsTarget: Double
    let fat: Double
    let fatTarget: Double

    private var caloriesRemaining: Int {
        max(0, calorieTarget - calories)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Calories Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Intake")
                        .font(.headline)
                    Text("\(caloriesRemaining) cal remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(calories)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("of \(calorieTarget) cal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar for calories
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange)
                        .frame(width: min(geometry.size.width * (Double(calories) / Double(max(calorieTarget, 1))), geometry.size.width))
                }
            }
            .frame(height: 8)

            Divider()

            // Macros Row
            HStack(spacing: 16) {
                MacroProgressColumn(
                    label: "Protein",
                    value: protein,
                    target: proteinTarget,
                    color: .blue
                )
                MacroProgressColumn(
                    label: "Carbs",
                    value: carbs,
                    target: carbsTarget,
                    color: .orange
                )
                MacroProgressColumn(
                    label: "Fat",
                    value: fat,
                    target: fatTarget,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct MacroProgressColumn: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(value))g")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.2))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 4)

            Text("\(Int(target))g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Food Meal Section

struct FoodMealSection: View {
    let type: MealType?
    let meals: [Meal]

    private var totalCalories: Int {
        meals.reduce(0) { $0 + ($1.calories ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if let type = type {
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)
                    Text(type.displayName)
                        .font(.headline)
                } else {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.gray)
                    Text("Other")
                        .font(.headline)
                }
                Spacer()
                Text("\(totalCalories) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Meals
            VStack(spacing: 8) {
                ForEach(meals) { meal in
                    FoodMealRow(meal: meal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct FoodMealRow: View {
    let meal: Meal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(meal.items.map { $0.name }.joined(separator: ", "))
                        .fontWeight(.medium)
                        .lineLimit(1)

                    // Testosterone impact badge
                    if let impact = meal.testosteroneImpact {
                        TestosteroneImpactBadge(impact: impact)
                    }
                }

                Text(meal.loggedAt.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(meal.calories ?? 0) cal")
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    Text("P:\(Int(meal.proteinG ?? 0))")
                    Text("C:\(Int(meal.carbsG ?? 0))")
                    Text("F:\(Int(meal.fatG ?? 0))")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - MealType Extension

extension MealType {
    var foodColor: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .green
        }
    }
}

// MARK: - Placeholder Views

struct FoodSearchSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Food Search")
                .navigationTitle("Search Foods")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    FoodTabView()
}
