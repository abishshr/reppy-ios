import SwiftUI

/// Diary tab - combines food logging and exercise tracking
struct DiaryView: View {
    @StateObject private var viewModel = DiaryViewModel()
    @State private var selectedTab: DiaryTab = .food
    @State private var showQuickAddCalories = false
    @State private var showCopyMeal = false
    @State private var showMyFoods = false

    enum DiaryTab: String, CaseIterable {
        case food = "Food"
        case exercise = "Exercise"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Control
                Picker("Diary Tab", selection: $selectedTab) {
                    ForEach(DiaryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab Content
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == .food {
                            foodContent
                        } else {
                            exerciseContent
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Diary")
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
        }
    }

    // MARK: - Food Content

    private var foodContent: some View {
        VStack(spacing: 20) {
            // Water Tracking Card
            WaterTrackingSection(
                todayMl: viewModel.todayWaterMl,
                goalMl: viewModel.waterGoalMl,
                isLoading: viewModel.isAddingWater,
                onQuickAdd: { amount in
                    Task { await viewModel.addWater(amountMl: amount) }
                }
            )
            .padding(.horizontal)

            // Diary Tools Row
            DiaryToolsRow(
                onQuickAdd: { showQuickAddCalories = true },
                onCopyMeal: { showCopyMeal = true },
                onMyFoods: { showMyFoods = true }
            )
            .padding(.horizontal)

            // Today's Summary
            TodaySummaryCard(
                calories: viewModel.todayCalories,
                protein: viewModel.todayProtein,
                carbs: viewModel.todayCarbs,
                fat: viewModel.todayFat
            )
            .padding(.horizontal)

            // Meals by Type
            VStack(spacing: 16) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    let meals = viewModel.meals(for: mealType)
                    if !meals.isEmpty {
                        MealSection(type: mealType, meals: meals)
                    }
                }

                // Untyped meals
                let untypedMeals = viewModel.untypedMeals
                if !untypedMeals.isEmpty {
                    MealSection(type: nil, meals: untypedMeals)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Exercise Content

    private var exerciseContent: some View {
        VStack(spacing: 20) {
            // Week Summary Card
            ExerciseWeekSummaryCard(
                workoutCount: viewModel.weekWorkoutCount,
                totalMinutes: viewModel.weekTotalMinutes,
                caloriesBurned: viewModel.weekTotalCalories
            )
            .padding(.horizontal)

            // Recent Workouts
            ExerciseListSection(workouts: viewModel.workouts)
                .padding(.horizontal)
        }
    }
}

// MARK: - Water Tracking Section

struct WaterTrackingSection: View {
    let todayMl: Int
    let goalMl: Int
    let isLoading: Bool
    let onQuickAdd: (Int) -> Void

    private var progress: Double {
        guard goalMl > 0 else { return 0 }
        return min(Double(todayMl) / Double(goalMl), 1.0)
    }

    private var glasses: Int {
        todayMl / 250 // 250ml per glass
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
                WaterButton(label: "250ml", systemImage: "drop", isLoading: isLoading) {
                    onQuickAdd(250)
                }
                WaterButton(label: "500ml", systemImage: "drop.fill", isLoading: isLoading) {
                    onQuickAdd(500)
                }
                WaterButton(label: "750ml", systemImage: "waterbottle", isLoading: isLoading) {
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

struct WaterButton: View {
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

// MARK: - Diary Tools Row

struct DiaryToolsRow: View {
    let onQuickAdd: () -> Void
    let onCopyMeal: () -> Void
    let onMyFoods: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            DiaryToolButton(
                icon: "plus.circle.fill",
                title: "Quick Add",
                color: .orange,
                action: onQuickAdd
            )

            DiaryToolButton(
                icon: "doc.on.doc.fill",
                title: "Copy Meal",
                color: .green,
                action: onCopyMeal
            )

            DiaryToolButton(
                icon: "star.fill",
                title: "My Foods",
                color: .purple,
                action: onMyFoods
            )
        }
    }
}

struct DiaryToolButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

// MARK: - Today's Summary Card

struct TodaySummaryCard: View {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Total")
                    .font(.headline)
                Spacer()
                Text("\(calories) cal")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            HStack(spacing: 20) {
                MacroStat(label: "Protein", value: protein, color: .blue)
                MacroStat(label: "Carbs", value: carbs, color: .orange)
                MacroStat(label: "Fat", value: fat, color: .purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct MacroStat: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value))g")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Meal Section

struct MealSection: View {
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
                    DiaryMealRow(meal: meal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct DiaryMealRow: View {
    let meal: Meal
    @State private var showDetail = false

    private var displayName: String {
        // Filter out empty, whitespace-only, or very short names (likely malformed)
        let validItems = meal.items.filter { item in
            let trimmed = item.name.trimmingCharacters(in: .whitespaces)
            return trimmed.count >= 2  // Names should be at least 2 characters
        }

        if validItems.isEmpty {
            // Try notes first, then meal type, then generic name
            if let notes = meal.notes, !notes.isEmpty, notes != "Quick Add" {
                return notes
            }
            if let mealType = meal.mealType {
                return mealType.displayName
            }
            return "Logged Meal"
        }

        return validItems.map { $0.name }.joined(separator: ", ")
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        Text(meal.loggedAt.timeString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Calories badge
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(meal.calories ?? 0)")
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(6)
                }

                // Macro row
                HStack(spacing: 12) {
                    DiaryMacroTag(label: "Protein", value: Int(meal.proteinG ?? 0), color: .blue)
                    DiaryMacroTag(label: "Carbs", value: Int(meal.carbsG ?? 0), color: .green)
                    DiaryMacroTag(label: "Fat", value: Int(meal.fatG ?? 0), color: .pink)

                    if let fiber = meal.fiberGEst, fiber > 0 {
                        DiaryMacroTag(label: "Fiber", value: Int(fiber), color: .mint)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            DiaryMealDetailSheet(meal: meal)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Diary Macro Tag

private struct DiaryMacroTag: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)g")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Diary Meal Detail Sheet

struct DiaryMealDetailSheet: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss

    private var hasVitamins: Bool {
        (meal.vitaminAMcgEst ?? 0) > 0 || (meal.vitaminCMgEst ?? 0) > 0 ||
        (meal.vitaminDMcgEst ?? 0) > 0 || (meal.vitaminB12McgEst ?? 0) > 0
    }

    private var hasMinerals: Bool {
        (meal.calciumMgEst ?? 0) > 0 || (meal.ironMgEst ?? 0) > 0 ||
        (meal.potassiumMgEst ?? 0) > 0 || (meal.magnesiumMgEst ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Food items
                    if !meal.items.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Items")
                                .font(.headline)

                            ForEach(meal.items) { item in
                                HStack {
                                    Text(item.name)
                                        .font(.body)
                                    Spacer()
                                    if let qty = item.quantity, let unit = item.unit {
                                        Text("\(Int(qty)) \(unit)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }

                    // Macros
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrition")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            DiaryNutrientCell(label: "Calories", value: "\(meal.calories ?? 0)", color: .orange, icon: "flame.fill")
                            DiaryNutrientCell(label: "Protein", value: "\(Int(meal.proteinG ?? 0))g", color: .blue, icon: "p.circle.fill")
                            DiaryNutrientCell(label: "Carbs", value: "\(Int(meal.carbsG ?? 0))g", color: .green, icon: "c.circle.fill")
                            DiaryNutrientCell(label: "Fat", value: "\(Int(meal.fatG ?? 0))g", color: .pink, icon: "f.circle.fill")
                        }
                    }

                    // Additional nutrients
                    if (meal.fiberGEst ?? 0) > 0 || (meal.sugarGEst ?? 0) > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline)

                            HStack(spacing: 16) {
                                if let fiber = meal.fiberGEst, fiber > 0 {
                                    DiaryNutrientCell(label: "Fiber", value: "\(Int(fiber))g", color: .mint, icon: "leaf.fill")
                                }
                                if let sugar = meal.sugarGEst, sugar > 0 {
                                    DiaryNutrientCell(label: "Sugar", value: "\(Int(sugar))g", color: .purple, icon: "cube.fill")
                                }
                            }
                        }
                    }

                    // Vitamins
                    if hasVitamins {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vitamins")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    if let v = meal.vitaminAMcgEst, v > 0 {
                                        DiaryMicroBadge(name: "Vitamin A", value: "\(Int(v)) mcg")
                                    }
                                    if let v = meal.vitaminCMgEst, v > 0 {
                                        DiaryMicroBadge(name: "Vitamin C", value: "\(Int(v)) mg")
                                    }
                                    if let v = meal.vitaminDMcgEst, v > 0 {
                                        DiaryMicroBadge(name: "Vitamin D", value: String(format: "%.1f mcg", v))
                                    }
                                    if let v = meal.vitaminB12McgEst, v > 0 {
                                        DiaryMicroBadge(name: "B12", value: String(format: "%.1f mcg", v))
                                    }
                                }
                            }
                        }
                    }

                    // Minerals
                    if hasMinerals {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Minerals")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    if let v = meal.calciumMgEst, v > 0 {
                                        DiaryMicroBadge(name: "Calcium", value: "\(Int(v)) mg")
                                    }
                                    if let v = meal.ironMgEst, v > 0 {
                                        DiaryMicroBadge(name: "Iron", value: String(format: "%.1f mg", v))
                                    }
                                    if let v = meal.potassiumMgEst, v > 0 {
                                        DiaryMicroBadge(name: "Potassium", value: "\(Int(v)) mg")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(meal.mealType?.displayName ?? "Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DiaryNutrientCell: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct DiaryMicroBadge: View {
    let name: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(8)
    }
}

// MARK: - MealType Extension

extension MealType {
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .green
        }
    }
}

// MARK: - Exercise Week Summary Card

struct ExerciseWeekSummaryCard: View {
    let workoutCount: Int
    let totalMinutes: Int
    let caloriesBurned: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("This Week")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                ExerciseStatColumn(
                    value: "\(workoutCount)",
                    label: "Workouts",
                    icon: "dumbbell.fill",
                    color: .blue
                )

                ExerciseStatColumn(
                    value: "\(totalMinutes)",
                    label: "Minutes",
                    icon: "clock.fill",
                    color: .green
                )

                ExerciseStatColumn(
                    value: "\(caloriesBurned)",
                    label: "Calories",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct ExerciseStatColumn: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise List Section

struct ExerciseListSection: View {
    let workouts: [Workout]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                Text("Recent Workouts")
                    .font(.headline)
                Spacer()
            }

            if workouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No workouts yet")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Tell your coach about your workouts to start logging")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(workouts) { workout in
                        DiaryWorkoutRow(workout: workout)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct DiaryWorkoutRow: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: workout.workoutType?.icon ?? "figure.run")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.workoutType?.displayName ?? "Workout")
                        .fontWeight(.medium)

                    Text(workout.loggedAt.shortDateString + " at " + workout.loggedAt.timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let duration = workout.durationMin {
                        Text("\(duration) min")
                            .fontWeight(.semibold)
                    }

                    if let calories = workout.caloriesBurnedEst, calories > 0 {
                        Text("\(calories) cal")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            // Exercises preview
            if !workout.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(workout.exercises.prefix(2)) { exercise in
                        Text(exercise.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if workout.exercises.count > 2 {
                        Text("+ \(workout.exercises.count - 2) more")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    DiaryView()
}
