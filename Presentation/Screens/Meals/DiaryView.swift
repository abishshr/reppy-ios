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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.items.map { $0.name }.joined(separator: ", "))
                    .fontWeight(.medium)
                    .lineLimit(1)

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
