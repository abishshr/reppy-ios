import SwiftUI

// PlanType and CreationMode are defined in Domain/Entities/PlanTypes.swift

/// Workout schedule type - daily or full plan
enum WorkoutScheduleType: String, CaseIterable {
    case daily = "daily"
    case fullPlan = "full_plan"

    var title: String {
        switch self {
        case .daily: return "Today's Workout"
        case .fullPlan: return "Full Plan"
        }
    }

    var description: String {
        switch self {
        case .daily: return "Single workout for today"
        case .fullPlan: return "Multi-week training program"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "calendar.day.timeline.left"
        case .fullPlan: return "calendar"
        }
    }
}

/// Manual meal entry for building custom meal plans
struct ManualMealEntry: Identifiable {
    let id = UUID()
    var mealType: String  // breakfast, lunch, dinner, snack
    var name: String
    var ingredients: [ManualIngredient]

    var totalEstimatedCalories: Int {
        ingredients.reduce(0) { $0 + $1.estimatedCalories }
    }
}

struct ManualIngredient: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unit: String  // g, oz, cups, pieces, etc.
    var estimatedCalories: Int  // rough estimate, AI will refine

    var displayString: String {
        if unit == "pieces" || unit == "whole" {
            return "\(Int(quantity)) \(name)"
        }
        return "\(Int(quantity))\(unit) \(name)"
    }
}

/// AI analysis result for manual meal plans
struct MealPlanAnalysis: Identifiable {
    let id = UUID()
    var totalCalories: Int
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double

    // Micronutrients
    var fiber: Double?
    var sodium: Double?
    var sugar: Double?
    var vitaminD: Double?
    var iron: Double?
    var calcium: Double?

    // Analysis
    var strengths: [String]
    var improvements: [String]
    var missingNutrients: [String]

    // Special recommendations
    var testosteroneBoostingFoods: [String]?  // For males
    var hormoneBalancingFoods: [String]?  // For females

    // Enhanced meal suggestions
    var suggestedAdditions: [String]
    var suggestedSubstitutions: [(original: String, replacement: String, reason: String)]
}

/// Where meals will come from
enum MealSource: String, CaseIterable {
    case homeCoooked = "home_cooked"
    case fastFood = "fast_food"
    case restaurant = "restaurant"
    case mixed = "mixed"

    var title: String {
        switch self {
        case .homeCoooked: return "Home Cooked"
        case .fastFood: return "Fast Food"
        case .restaurant: return "Restaurant"
        case .mixed: return "Mixed"
        }
    }

    var description: String {
        switch self {
        case .homeCoooked: return "Recipes to cook at home"
        case .fastFood: return "Fast food chain options"
        case .restaurant: return "Restaurant-style dishes"
        case .mixed: return "Combination of all"
        }
    }

    var icon: String {
        switch self {
        case .homeCoooked: return "house.fill"
        case .fastFood: return "car.fill"
        case .restaurant: return "fork.knife"
        case .mixed: return "square.grid.2x2.fill"
        }
    }
}

/// Unified sheet for creating workout or meal plans with multiple modes
struct UnifiedPlanCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlanCreationViewModel

    let planType: PlanType

    init(planType: PlanType, apiClient: APIClient, chatRepository: ChatRepository, appState: AppState?) {
        self.planType = planType
        _viewModel = StateObject(wrappedValue: PlanCreationViewModel(
            planType: planType,
            apiClient: apiClient,
            chatRepository: chatRepository,
            appState: appState
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode selector
                Picker("Mode", selection: $viewModel.selectedMode) {
                    ForEach(CreationMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Content based on selected mode
                ScrollView {
                    switch viewModel.selectedMode {
                    case .quick:
                        QuickCreateTab(viewModel: viewModel, planType: planType)
                    case .customize:
                        CustomizeCreateTab(viewModel: viewModel, planType: planType)
                    case .manual:
                        ManualCreateTab(viewModel: viewModel, planType: planType)
                    }
                }
            }
            .navigationTitle("Create \(planType.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.isCreated) { _, created in
                if created {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class PlanCreationViewModel: ObservableObject {
    let planType: PlanType
    let apiClient: APIClient
    let chatRepository: ChatRepository
    weak var appState: AppState?

    @Published var selectedMode: CreationMode = .quick
    @Published var isLoading = false
    @Published var isCreated = false
    @Published var showError = false
    @Published var errorMessage = ""

    // Quick mode - just uses profile
    @Published var quickGenerating = false

    // Customize mode options - Workout
    @Published var workoutScheduleType: WorkoutScheduleType = .daily
    @Published var selectedGoal: String = "general_fitness"
    @Published var selectedDuration: Int = 4
    @Published var selectedDaysPerWeek: Int = 4
    @Published var selectedDifficulty: String = "intermediate"
    @Published var selectedSplit: String = "push_pull_legs"
    @Published var selectedWorkoutType: String = "strength"  // For daily workouts
    @Published var targetMuscleGroups: [String] = []  // For daily workouts
    @Published var estimatedDuration: Int = 45  // Minutes for daily workout

    // Meal plan customize options
    @Published var selectedDietStyle: String = "balanced"
    @Published var dailyCalories: Int = 2000
    @Published var mealCount: Int = 3
    @Published var selectedMealSource: MealSource = .homeCoooked
    @Published var preferredRestaurant: String = ""  // User can type their preferred restaurant
    @Published var selectedIngredients: [String] = []  // Ingredients user wants to cook with
    @Published var showIngredientPicker = false

    // Meal plan duration and schedule options
    @Published var mealPlanDays: Int = 7  // Number of days for meal plan
    @Published var excludeWeekends: Bool = false  // Exclude Saturday and Sunday
    @Published var excludedDays: Set<Int> = []  // 0 = Sunday, 6 = Saturday

    // Manual meal entry
    @Published var manualMeals: [ManualMealEntry] = []
    @Published var showAddMealSheet = false
    @Published var editingMealIndex: Int?
    @Published var aiAnalysis: MealPlanAnalysis?
    @Published var isAnalyzing = false
    @Published var showAnalysisSheet = false

    // Manual mode
    @Published var manualName: String = ""
    @Published var searchQuery: String = ""
    @Published var searchResults: [Any] = []
    @Published var selectedItems: [Any] = []

    // Exercise search results
    @Published var exerciseSearchResults: [ExerciseSearchResult] = []
    @Published var selectedExercises: [ExerciseSearchResult] = []

    // Food search results
    @Published var foodSearchResults: [FoodSearchResult] = []
    @Published var selectedFoods: [FoodSearchResult] = []

    init(planType: PlanType, apiClient: APIClient, chatRepository: ChatRepository, appState: AppState?) {
        self.planType = planType
        self.apiClient = apiClient
        self.chatRepository = chatRepository
        self.appState = appState
    }

    // MARK: - Quick Create

    func quickCreate() async {
        let prompt: String
        let displayMessage: String

        if planType == .workout {
            if workoutScheduleType == .daily {
                prompt = "Create a workout for today based on my profile and show it to me for approval."
                displayMessage = "Create today's workout"
            } else {
                prompt = "Create a workout plan based on my profile and show it to me for approval."
                displayMessage = "Create workout plan"
            }
        } else {
            // Build excluded days text
            var excludedDaysText = ""
            if excludeWeekends {
                excludedDaysText = " Exclude weekends."
            } else if !excludedDays.isEmpty {
                let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                let excludedNames = excludedDays.sorted().compactMap { $0 < dayNames.count ? dayNames[$0] : nil }
                if !excludedNames.isEmpty {
                    excludedDaysText = " Exclude: \(excludedNames.joined(separator: ", "))."
                }
            }

            prompt = "Create a \(mealPlanDays)-day meal plan based on my profile.\(excludedDaysText) Show it to me for approval."
            displayMessage = "Create \(mealPlanDays)-day meal plan"
        }

        // Navigate to chat with the prompt - the chat will handle the conversation
        appState?.navigateToChatWith(message: prompt, displayMessage: displayMessage)
        isCreated = true
    }

    // MARK: - Customize Create

    func customizeCreate() async {
        let prompt: String
        let displayMessage: String

        if planType == .workout {
            if workoutScheduleType == .daily {
                // Daily workout creation
                let muscleGroupsText = targetMuscleGroups.isEmpty
                    ? "based on what I haven't trained recently"
                    : targetMuscleGroups.joined(separator: ", ")

                prompt = "Create a \(selectedWorkoutType) workout for today targeting \(muscleGroupsText), ~\(estimatedDuration) min, \(selectedDifficulty) difficulty, goal: \(selectedGoal). Show it to me for approval."
                displayMessage = "Create custom \(selectedWorkoutType) workout"
            } else {
                // Full plan creation
                prompt = "Create a workout plan: \(selectedGoal) goal, \(selectedDuration) weeks, \(selectedDaysPerWeek) days/week, \(selectedDifficulty) difficulty, \(selectedSplit) split. Show it to me for approval."
                displayMessage = "Create \(selectedDuration)-week workout plan"
            }
        } else {
            var mealSourceInfo = ""
            var ingredientInfo = ""

            switch selectedMealSource {
            case .homeCoooked:
                if !selectedIngredients.isEmpty {
                    ingredientInfo = " using: \(selectedIngredients.joined(separator: ", "))"
                }
                mealSourceInfo = "home cooked\(ingredientInfo)"
            case .fastFood:
                if !preferredRestaurant.isEmpty {
                    mealSourceInfo = "fast food from \(preferredRestaurant)"
                } else {
                    mealSourceInfo = "fast food"
                }
            case .restaurant:
                if !preferredRestaurant.isEmpty {
                    mealSourceInfo = "restaurant meals from \(preferredRestaurant)"
                } else {
                    mealSourceInfo = "restaurant meals"
                }
            case .mixed:
                if !selectedIngredients.isEmpty {
                    ingredientInfo = " (for home cooking use: \(selectedIngredients.joined(separator: ", ")))"
                }
                mealSourceInfo = "mixed home/restaurant\(ingredientInfo)"
            }

            // Build excluded days text for customize mode
            var excludedDaysText = ""
            if excludeWeekends {
                excludedDaysText = ", weekdays only"
            }

            prompt = "Create a \(mealPlanDays)-day meal plan: \(selectedDietStyle), \(dailyCalories) cal/day, \(mealCount) meals/day, \(mealSourceInfo)\(excludedDaysText). Show it to me for approval."
            displayMessage = "Create custom \(mealPlanDays)-day meal plan"
        }

        // Navigate to chat with the prompt - the chat will handle the conversation
        appState?.navigateToChatWith(message: prompt, displayMessage: displayMessage)
        isCreated = true
    }

    // MARK: - Search

    func searchExercises() async {
        guard !searchQuery.isEmpty else {
            exerciseSearchResults = []
            return
        }

        print("[PlanCreation] Searching exercises for: '\(searchQuery)'")
        do {
            exerciseSearchResults = try await apiClient.searchExercises(query: searchQuery)
            print("[PlanCreation] Found \(exerciseSearchResults.count) exercises")
        } catch {
            print("[PlanCreation] Exercise search error: \(error)")
            exerciseSearchResults = []
        }
    }

    func searchFoods() async {
        guard !searchQuery.isEmpty else {
            foodSearchResults = []
            return
        }

        do {
            foodSearchResults = try await apiClient.searchFoods(query: searchQuery)
        } catch {
            print("Food search error: \(error)")
            foodSearchResults = []
        }
    }

    // MARK: - Manual Meal Entry

    func addManualMeal(_ meal: ManualMealEntry) {
        manualMeals.append(meal)
    }

    func updateManualMeal(at index: Int, with meal: ManualMealEntry) {
        guard index < manualMeals.count else { return }
        manualMeals[index] = meal
    }

    func deleteManualMeal(at index: Int) {
        guard index < manualMeals.count else { return }
        manualMeals.remove(at: index)
    }

    func analyzeManualMeals() async {
        guard !manualMeals.isEmpty else {
            errorMessage = "Please add at least one meal to analyze"
            showError = true
            return
        }

        // Build meal description for AI
        var mealDescription = "Here is my daily meal plan:\n\n"
        for meal in manualMeals {
            mealDescription += "**\(meal.mealType.capitalized): \(meal.name)**\n"
            for ingredient in meal.ingredients {
                mealDescription += "- \(ingredient.displayString)\n"
            }
            mealDescription += "\n"
        }

        let prompt = """
        Analyze this meal plan and provide detailed nutritional feedback:

        \(mealDescription)

        Please provide:
        1. **Estimated Macros**: Calculate total calories, protein (g), carbs (g), and fat (g) for the entire day
        2. **Micronutrient Analysis**: Estimate fiber, sodium, sugar, vitamin D, iron, calcium, zinc, and magnesium levels
        3. **Strengths**: What's good about this meal plan (2-3 points)
        4. **Areas for Improvement**: What could be better (2-3 specific suggestions)
        5. **Missing Nutrients**: Any key nutrients that are lacking
        6. **For MALE users**: Provide a "T-Boost Score" (1-10) rating how testosterone-friendly this meal plan naturally is. Just score the existing meals, don't suggest testosterone-boosting additions.
        7. **For FEMALE users**: ONLY if cycle tracking data exists, provide a "Cycle Sync Score" (1-10) rating how well the meals align with their current cycle phase. If no cycle data, skip this.
        8. **Suggested Additions**: 2-3 foods to add to improve overall nutrition
        9. **Suggested Substitutions**: Any swaps that would improve nutrition (format: "swap X for Y because Z")

        Consider my profile, allergies, medical conditions, and fitness goals when analyzing.
        Be specific with quantities and provide actionable advice.
        """

        // Navigate to chat with the prompt
        appState?.navigateToChatWith(message: prompt, displayMessage: "Analyze my meal plan")
        isCreated = true
    }

    func createMealPlanFromManual() async {
        guard !manualMeals.isEmpty else {
            errorMessage = "Please add at least one meal"
            showError = true
            return
        }

        // Build meal description
        var mealDescription = ""
        for meal in manualMeals {
            mealDescription += "\(meal.mealType.capitalized) - \(meal.name): "
            mealDescription += meal.ingredients.map { $0.displayString }.joined(separator: ", ")
            mealDescription += "\n"
        }

        let prompt = """
        I want to create a \(mealPlanDays)-day meal plan based on this template day I've designed:

        \(mealDescription)

        Please:
        1. Use these meals as the foundation
        2. Create variations for each day while keeping similar macros
        3. Calculate and display accurate nutrition info for each meal including micronutrients (fiber, vitamins, minerals)
        4. Consider my profile, allergies, injuries, and medical conditions
        5. For MALE users: After creating the plan, provide a daily "T-Boost Score" (1-10) rating how testosterone-friendly each day naturally is. Just score, don't modify meals.
        6. For FEMALE users: ONLY if cycle tracking data exists, provide a "Cycle Sync Score" (1-10) for each day. If no cycle data, skip this.
        7. Add any missing micronutrients through strategic food choices

        Show me the complete meal plan and ask for my confirmation before saving it.
        """

        // Navigate to chat with the prompt
        appState?.navigateToChatWith(message: prompt, displayMessage: "Create \(mealPlanDays)-day plan from my template")
        isCreated = true
    }

    // MARK: - Manual Create

    func manualCreateWorkoutPlan() async {
        guard !manualName.isEmpty, !selectedExercises.isEmpty else {
            errorMessage = "Please add a name and at least one exercise"
            showError = true
            return
        }

        isLoading = true

        do {
            let exercises = selectedExercises.map { exercise in
                ExerciseCreateRequest(
                    name: exercise.name,
                    sets: 3,
                    reps: 10,
                    repsRange: nil,
                    weightKg: nil,
                    restSec: 60,
                    notes: nil
                )
            }

            let day = WorkoutDayCreateRequest(
                weekNumber: 1,
                dayNumber: 1,
                dayName: "Day 1",
                workoutType: "strength",
                exercises: exercises,
                isRestDay: false,
                notes: nil
            )

            let request = WorkoutPlanCreateRequest(
                name: manualName,
                description: nil,
                durationWeeks: 1,
                daysPerWeek: 1,
                goal: "general_fitness",
                difficulty: "intermediate",
                splitType: "full_body",
                days: [day]
            )

            _ = try await apiClient.createWorkoutPlan(request)
            isCreated = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func manualCreateMealPlan() async {
        guard !manualName.isEmpty, !selectedFoods.isEmpty else {
            errorMessage = "Please add a name and at least one meal"
            showError = true
            return
        }

        isLoading = true

        do {
            let meals = selectedFoods.map { food in
                MealCreateRequest(
                    type: "lunch",
                    name: food.name,
                    description: nil,
                    calories: food.calories ?? 0,
                    proteinG: food.proteinG ?? 0,
                    carbsG: food.carbsG ?? 0,
                    fatG: food.fatG ?? 0,
                    servings: 1
                )
            }

            let day = MealDayCreateRequest(
                dayNumber: 1,
                meals: meals,
                notes: nil
            )

            let request = MealPlanCreateRequest(
                name: manualName,
                durationDays: 1,
                goal: nil,
                dailyCalorieTarget: nil,
                dailyProteinTarget: nil,
                dailyCarbsTarget: nil,
                dailyFatTarget: nil,
                days: [day]
            )

            _ = try await apiClient.createMealPlan(request)
            isCreated = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

// MARK: - Quick Create Tab

struct QuickCreateTab: View {
    @ObservedObject var viewModel: PlanCreationViewModel
    let planType: PlanType

    var body: some View {
        VStack(spacing: 24) {
            // Schedule type selector for workouts
            if planType == .workout {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What do you want to create?")
                        .font(.subheadline.bold())

                    HStack(spacing: 12) {
                        ForEach(WorkoutScheduleType.allCases, id: \.self) { scheduleType in
                            WorkoutScheduleTypeCard(
                                scheduleType: scheduleType,
                                isSelected: viewModel.workoutScheduleType == scheduleType
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    viewModel.workoutScheduleType = scheduleType
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }

            // Hero illustration
            Image(systemName: planType == .workout
                ? (viewModel.workoutScheduleType == .daily ? "figure.run" : "calendar")
                : planType.icon)
                .font(.system(size: 60))
                .foregroundStyle(.tint)
                .padding(.top, planType == .workout ? 20 : 40)

            VStack(spacing: 8) {
                Text("One-Tap Creation")
                    .font(.title2.bold())

                Text(quickCreateDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Meal plan duration options
            if planType == .meal {
                VStack(alignment: .leading, spacing: 16) {
                    // Number of days
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan Duration")
                            .font(.subheadline.bold())

                        HStack(spacing: 8) {
                            ForEach([3, 5, 7, 14], id: \.self) { days in
                                DayCountChip(
                                    days: days,
                                    isSelected: viewModel.mealPlanDays == days
                                ) {
                                    withAnimation(.spring(response: 0.2)) {
                                        viewModel.mealPlanDays = days
                                    }
                                }
                            }
                        }
                    }

                    // Exclude weekends toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Exclude Weekends")
                                .font(.subheadline.bold())
                            Text("Skip Saturday & Sunday")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $viewModel.excludeWeekends)
                            .labelsHidden()
                            .tint(.green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            // What we'll use
            VStack(alignment: .leading, spacing: 12) {
                Text("Based on your profile:")
                    .font(.subheadline.bold())

                HStack(spacing: 16) {
                    ProfileInfoChip(icon: "person.fill", text: "Age & Sex")
                    ProfileInfoChip(icon: "scalemass.fill", text: "Weight")
                    ProfileInfoChip(icon: "target", text: "Goals")
                }

                HStack(spacing: 16) {
                    ProfileInfoChip(icon: "figure.walk", text: "Activity")
                    if planType == .meal {
                        ProfileInfoChip(icon: "leaf.fill", text: "Diet Style")
                    } else {
                        ProfileInfoChip(icon: "dumbbell.fill", text: "Equipment")
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Spacer()

            // Create button
            Button {
                Task {
                    await viewModel.quickCreate()
                }
            } label: {
                HStack {
                    if viewModel.quickGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(buttonText)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.quickGenerating)
            .padding()
        }
    }

    private var quickCreateDescription: String {
        if planType == .workout {
            if viewModel.workoutScheduleType == .daily {
                return "AI will create a single workout for today based on your profile and what you haven't trained recently."
            } else {
                return "AI will create a personalized multi-week workout plan based on your profile, goals, and preferences."
            }
        } else {
            return "AI will create a personalized meal plan based on your profile, goals, and preferences."
        }
    }

    private var buttonText: String {
        if planType == .workout {
            return viewModel.workoutScheduleType == .daily ? "Generate Today's Workout" : "Generate Workout Plan"
        } else {
            return "Generate Meal Plan"
        }
    }
}

struct ProfileInfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
    }
}

// MARK: - Customize Create Tab

struct CustomizeCreateTab: View {
    @ObservedObject var viewModel: PlanCreationViewModel
    let planType: PlanType

    var body: some View {
        VStack(spacing: 20) {
            if planType == .workout {
                workoutOptions
            } else {
                mealOptions
            }

            Spacer()

            // Create button
            Button {
                Task {
                    await viewModel.customizeCreate()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text("Generate \(planType.title)")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isLoading)
            .padding()
        }
        .padding(.top)
        .sheet(isPresented: $viewModel.showIngredientPicker) {
            IngredientPickerSheet(selectedIngredients: $viewModel.selectedIngredients)
        }
    }

    private var workoutOptions: some View {
        VStack(spacing: 20) {
            // Schedule Type Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("What do you want to create?")
                    .font(.subheadline.bold())

                HStack(spacing: 12) {
                    ForEach(WorkoutScheduleType.allCases, id: \.self) { scheduleType in
                        WorkoutScheduleTypeCard(
                            scheduleType: scheduleType,
                            isSelected: viewModel.workoutScheduleType == scheduleType
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.workoutScheduleType = scheduleType
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            if viewModel.workoutScheduleType == .daily {
                dailyWorkoutOptions
            } else {
                fullPlanOptions
            }
        }
    }

    private var dailyWorkoutOptions: some View {
        VStack(spacing: 16) {
            // Workout Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Workout Type")
                    .font(.subheadline.bold())

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(workoutTypes, id: \.value) { type in
                            WorkoutTypeChip(
                                name: type.name,
                                icon: type.icon,
                                isSelected: viewModel.selectedWorkoutType == type.value
                            ) {
                                viewModel.selectedWorkoutType = type.value
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Target Muscle Groups
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Muscle Groups (optional)")
                    .font(.subheadline.bold())

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(muscleGroups, id: \.self) { muscle in
                            MuscleGroupChip(
                                name: muscle,
                                isSelected: viewModel.targetMuscleGroups.contains(muscle)
                            ) {
                                if viewModel.targetMuscleGroups.contains(muscle) {
                                    viewModel.targetMuscleGroups.removeAll { $0 == muscle }
                                } else {
                                    viewModel.targetMuscleGroups.append(muscle)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if viewModel.targetMuscleGroups.isEmpty {
                    Text("Leave empty to let AI decide based on your recent workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }

            // Duration
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration: \(viewModel.estimatedDuration) minutes")
                    .font(.subheadline.bold())
                Slider(value: Binding(
                    get: { Double(viewModel.estimatedDuration) },
                    set: { viewModel.estimatedDuration = Int($0) }
                ), in: 15...120, step: 5)
            }
            .padding(.horizontal)

            // Difficulty
            VStack(alignment: .leading, spacing: 8) {
                Text("Difficulty")
                    .font(.subheadline.bold())
                Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                    Text("Beginner").tag("beginner")
                    Text("Intermediate").tag("intermediate")
                    Text("Advanced").tag("advanced")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            // Goal
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal")
                    .font(.subheadline.bold())
                Picker("Goal", selection: $viewModel.selectedGoal) {
                    Text("Strength").tag("strength")
                    Text("Muscle").tag("hypertrophy")
                    Text("Fat Loss").tag("fat_loss")
                    Text("Endurance").tag("endurance")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
        }
    }

    private var fullPlanOptions: some View {
        VStack(spacing: 16) {
            // Goal
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal")
                    .font(.subheadline.bold())
                Picker("Goal", selection: $viewModel.selectedGoal) {
                    Text("Strength").tag("strength")
                    Text("Muscle Growth").tag("hypertrophy")
                    Text("Fat Loss").tag("fat_loss")
                    Text("Endurance").tag("endurance")
                    Text("General Fitness").tag("general_fitness")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            // Duration
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration: \(viewModel.selectedDuration) weeks")
                    .font(.subheadline.bold())
                Slider(value: Binding(
                    get: { Double(viewModel.selectedDuration) },
                    set: { viewModel.selectedDuration = Int($0) }
                ), in: 1...12, step: 1)
            }
            .padding(.horizontal)

            // Days per week
            VStack(alignment: .leading, spacing: 8) {
                Text("Days per week: \(viewModel.selectedDaysPerWeek)")
                    .font(.subheadline.bold())
                Picker("Days", selection: $viewModel.selectedDaysPerWeek) {
                    ForEach(2...6, id: \.self) { days in
                        Text("\(days)").tag(days)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            // Difficulty
            VStack(alignment: .leading, spacing: 8) {
                Text("Difficulty")
                    .font(.subheadline.bold())
                Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                    Text("Beginner").tag("beginner")
                    Text("Intermediate").tag("intermediate")
                    Text("Advanced").tag("advanced")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            // Split type
            VStack(alignment: .leading, spacing: 8) {
                Text("Split Type")
                    .font(.subheadline.bold())
                Picker("Split", selection: $viewModel.selectedSplit) {
                    Text("Full Body").tag("full_body")
                    Text("Upper/Lower").tag("upper_lower")
                    Text("Push/Pull/Legs").tag("push_pull_legs")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
        }
    }

    // Data for workout types
    private var workoutTypes: [(name: String, value: String, icon: String)] {
        [
            ("Strength", "strength", "dumbbell.fill"),
            ("Cardio", "cardio", "heart.fill"),
            ("HIIT", "hiit", "flame.fill"),
            ("CrossFit", "crossfit", "figure.cross.training"),
            ("Hyrox", "hyrox", "figure.run"),
            ("Yoga", "yoga", "figure.yoga"),
            ("Pilates", "pilates", "figure.pilates"),
            ("Boxing", "boxing", "figure.boxing"),
            ("Muay Thai", "muay_thai", "figure.kickboxing"),
            ("Swimming", "swimming", "figure.pool.swim"),
            ("Cycling", "cycling", "bicycle"),
            ("Running", "running", "figure.run"),
        ]
    }

    // Data for muscle groups
    private var muscleGroups: [String] {
        ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Glutes", "Core", "Full Body"]
    }

    private var mealOptions: some View {
        VStack(spacing: 20) {
            // Meal Source
            VStack(alignment: .leading, spacing: 12) {
                Text("Where will you eat?")
                    .font(.subheadline.bold())

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(MealSource.allCases, id: \.self) { source in
                        MealSourceCard(
                            source: source,
                            isSelected: viewModel.selectedMealSource == source
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedMealSource = source
                                // Clear restaurant preference when switching to home cooked or mixed
                                if source == .homeCoooked || source == .mixed {
                                    viewModel.preferredRestaurant = ""
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Restaurant preference input (for fast food or restaurant)
            if viewModel.selectedMealSource == .fastFood || viewModel.selectedMealSource == .restaurant {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.selectedMealSource == .fastFood ? "Preferred restaurant (optional)" : "Preferred restaurant type (optional)")
                            .font(.subheadline.bold())
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField(
                            viewModel.selectedMealSource == .fastFood
                                ? "e.g., McDonald's, Chipotle, Chick-fil-A..."
                                : "e.g., Italian, Mexican, Sushi...",
                            text: $viewModel.preferredRestaurant
                        )
                        .textFieldStyle(.plain)

                        if !viewModel.preferredRestaurant.isEmpty {
                            Button {
                                viewModel.preferredRestaurant = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text(viewModel.preferredRestaurant.isEmpty
                        ? "Leave empty for AI to suggest based on your location"
                        : "AI will create meals using \(viewModel.preferredRestaurant) menu items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Ingredient selection (for home cooked or mixed)
            if viewModel.selectedMealSource == .homeCoooked || viewModel.selectedMealSource == .mixed {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("What ingredients do you have?")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("Optional")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Selected ingredients chips
                    if !viewModel.selectedIngredients.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.selectedIngredients, id: \.self) { ingredient in
                                    HStack(spacing: 4) {
                                        Text(ingredient)
                                            .font(.caption.weight(.medium))
                                        Button {
                                            withAnimation(.spring(response: 0.3)) {
                                                viewModel.selectedIngredients.removeAll { $0 == ingredient }
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.green)
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }

                    // Tap to add ingredients button
                    Button {
                        viewModel.showIngredientPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text(viewModel.selectedIngredients.isEmpty ? "Tap to select ingredients" : "Add more ingredients")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                    }

                    if viewModel.selectedIngredients.isEmpty {
                        Text("AI will suggest recipes based on common ingredients")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("AI will create recipes using your \(viewModel.selectedIngredients.count) selected ingredients")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider()
                .padding(.horizontal)

            // Plan Duration
            VStack(alignment: .leading, spacing: 8) {
                Text("Plan Duration")
                    .font(.subheadline.bold())

                HStack(spacing: 8) {
                    ForEach([3, 5, 7, 14], id: \.self) { days in
                        DayCountChip(
                            days: days,
                            isSelected: viewModel.mealPlanDays == days
                        ) {
                            withAnimation(.spring(response: 0.2)) {
                                viewModel.mealPlanDays = days
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Exclude weekends toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Exclude Weekends")
                        .font(.subheadline.bold())
                    Text("Skip Saturday & Sunday")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $viewModel.excludeWeekends)
                    .labelsHidden()
                    .tint(.green)
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)

            // Diet style
            VStack(alignment: .leading, spacing: 8) {
                Text("Diet Style")
                    .font(.subheadline.bold())
                Picker("Diet", selection: $viewModel.selectedDietStyle) {
                    Text("Balanced").tag("balanced")
                    Text("High Protein").tag("high_protein")
                    Text("Low Carb").tag("low_carb")
                    Text("Vegetarian").tag("vegetarian")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            // Daily calories
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Calories: \(viewModel.dailyCalories)")
                    .font(.subheadline.bold())
                Slider(value: Binding(
                    get: { Double(viewModel.dailyCalories) },
                    set: { viewModel.dailyCalories = Int($0) }
                ), in: 1200...4000, step: 100)
            }
            .padding(.horizontal)

            // Meals per day
            VStack(alignment: .leading, spacing: 8) {
                Text("Meals per day: \(viewModel.mealCount)")
                    .font(.subheadline.bold())
                Picker("Meals", selection: $viewModel.mealCount) {
                    Text("3").tag(3)
                    Text("4").tag(4)
                    Text("5").tag(5)
                    Text("6").tag(6)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Manual Create Tab

struct ManualCreateTab: View {
    @ObservedObject var viewModel: PlanCreationViewModel
    let planType: PlanType

    var body: some View {
        if planType == .meal {
            ManualMealEntryView(viewModel: viewModel)
        } else {
            ManualWorkoutEntryView(viewModel: viewModel)
        }
    }
}

// MARK: - Manual Meal Entry View

struct ManualMealEntryView: View {
    @ObservedObject var viewModel: PlanCreationViewModel
    @State private var showAddMealSheet = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)

                Text("Build Your Meal Plan")
                    .font(.headline)

                Text("Add meals with specific ingredients and quantities")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)

            // Added meals list
            if viewModel.manualMeals.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary.opacity(0.5))

                    Text("No meals added yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Tap the button below to add your first meal")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                // Meals list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.manualMeals.enumerated()), id: \.element.id) { index, meal in
                            ManualMealCard(meal: meal) {
                                viewModel.editingMealIndex = index
                                showAddMealSheet = true
                            } onDelete: {
                                withAnimation {
                                    viewModel.deleteManualMeal(at: index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Summary
                HStack(spacing: 20) {
                    VStack {
                        Text("\(viewModel.manualMeals.count)")
                            .font(.title2.bold())
                        Text("Meals")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack {
                        Text("\(totalIngredients)")
                            .font(.title2.bold())
                        Text("Ingredients")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack {
                        Text("~\(estimatedCalories)")
                            .font(.title2.bold())
                        Text("Est. Cal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                // Add meal button
                Button {
                    viewModel.editingMealIndex = nil
                    showAddMealSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Meal")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !viewModel.manualMeals.isEmpty {
                    // Analyze with AI button
                    Button {
                        Task {
                            await viewModel.analyzeManualMeals()
                        }
                    } label: {
                        HStack {
                            if viewModel.isAnalyzing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text("Analyze with AI")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.isAnalyzing)

                    // Create 7-day plan button
                    Button {
                        Task {
                            await viewModel.createMealPlanFromManual()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text("Create 7-Day Plan")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showAddMealSheet) {
            AddMealSheet(viewModel: viewModel)
        }
    }

    private var totalIngredients: Int {
        viewModel.manualMeals.reduce(0) { $0 + $1.ingredients.count }
    }

    private var estimatedCalories: Int {
        viewModel.manualMeals.reduce(0) { $0 + $1.totalEstimatedCalories }
    }
}

// MARK: - Manual Meal Card

struct ManualMealCard: View {
    let meal: ManualMealEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var mealTypeColor: Color {
        switch meal.mealType {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .gray
        }
    }

    private var mealTypeIcon: String {
        switch meal.mealType {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snack": return "leaf.fill"
        default: return "fork.knife"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Meal type badge
                HStack(spacing: 4) {
                    Image(systemName: mealTypeIcon)
                        .font(.caption)
                    Text(meal.mealType.capitalized)
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(mealTypeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(mealTypeColor.opacity(0.15))
                .cornerRadius(8)

                Text(meal.name)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.secondary)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundStyle(.red.opacity(0.7))
                }
            }

            // Ingredients
            IngredientFlowLayout(spacing: 6) {
                ForEach(meal.ingredients) { ingredient in
                    Text(ingredient.displayString)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
            }

            // Estimated calories
            HStack {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("~\(meal.totalEstimatedCalories) cal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout for ingredients

struct IngredientFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Add Meal Sheet

struct AddMealSheet: View {
    @ObservedObject var viewModel: PlanCreationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var mealType = "breakfast"
    @State private var mealName = ""
    @State private var ingredients: [ManualIngredient] = []
    @State private var showAddIngredient = false

    // New ingredient fields
    @State private var newIngredientName = ""
    @State private var newIngredientQuantity: Double = 100
    @State private var newIngredientUnit = "g"

    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]
    private let units = ["g", "oz", "cups", "tbsp", "tsp", "pieces", "ml", "whole"]

    // Common ingredients with estimated calories per 100g
    private let commonIngredients: [(name: String, calPer100g: Int)] = [
        ("Chicken Breast", 165), ("Rice (cooked)", 130), ("Eggs", 155),
        ("Salmon", 208), ("Broccoli", 34), ("Sweet Potato", 86),
        ("Ground Beef", 250), ("Oatmeal", 68), ("Greek Yogurt", 59),
        ("Avocado", 160), ("Spinach", 23), ("Banana", 89),
        ("Almonds", 579), ("Olive Oil", 884), ("Bread", 265)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    mealTypeSection
                    mealNameSection
                    Divider()
                    ingredientsSection
                    totalEstimateSection
                }
                .padding(.vertical)
            }
            .navigationTitle(viewModel.editingMealIndex != nil ? "Edit Meal" : "Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveMeal()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(mealName.isEmpty || ingredients.isEmpty)
                }
            }
            .onAppear { loadExistingMeal() }
        }
    }

    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal Type")
                .font(.subheadline.bold())
            HStack(spacing: 10) {
                ForEach(mealTypes, id: \.self) { type in
                    ManualMealTypeButton(type: type, isSelected: mealType == type) {
                        mealType = type
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var mealNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal Name")
                .font(.subheadline.bold())
            TextField("e.g., Grilled Chicken with Rice", text: $mealName)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ingredientsHeader
            addedIngredientsList
            quickAddSection
            customIngredientSection
        }
        .padding(.horizontal)
    }

    private var ingredientsHeader: some View {
        HStack {
            Text("Ingredients")
                .font(.subheadline.bold())
            Spacer()
            Text("\(ingredients.count) added")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var addedIngredientsList: some View {
        if !ingredients.isEmpty {
            ForEach(ingredients) { ingredient in
                AddedIngredientRow(ingredient: ingredient) {
                    ingredients.removeAll { $0.id == ingredient.id }
                }
            }
        }
    }

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Add")
                .font(.caption)
                .foregroundStyle(.secondary)
            IngredientFlowLayout(spacing: 8) {
                ForEach(commonIngredients, id: \.name) { item in
                    Button {
                        addIngredient(name: item.name, quantity: 100, unit: "g", calPer100g: item.calPer100g)
                    } label: {
                        Text(item.name)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    private var customIngredientSection: some View {
        VStack(spacing: 12) {
            Text("Add Custom Ingredient")
                .font(.caption)
                .foregroundStyle(.secondary)
            customIngredientInputRow
            addIngredientButton
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var customIngredientInputRow: some View {
        HStack(spacing: 8) {
            TextField("Ingredient", text: $newIngredientName)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
            TextField("Qty", value: $newIngredientQuantity, format: .number)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .frame(width: 60)
            Picker("", selection: $newIngredientUnit) {
                ForEach(units, id: \.self) { Text($0).tag($0) }
            }
            .frame(width: 70)
        }
    }

    private var addIngredientButton: some View {
        Button {
            if !newIngredientName.isEmpty {
                addIngredient(name: newIngredientName, quantity: newIngredientQuantity, unit: newIngredientUnit, calPer100g: 100)
                newIngredientName = ""
                newIngredientQuantity = 100
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Ingredient")
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(newIngredientName.isEmpty ? Color.gray.opacity(0.3) : Color.green.opacity(0.2))
            .foregroundColor(newIngredientName.isEmpty ? Color.secondary : Color.green)
            .cornerRadius(8)
        }
        .disabled(newIngredientName.isEmpty)
    }

    @ViewBuilder
    private var totalEstimateSection: some View {
        if !ingredients.isEmpty {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Estimated Total: ~\(totalCalories) calories")
                    .font(.subheadline.weight(.medium))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func loadExistingMeal() {
        if let index = viewModel.editingMealIndex,
           index < viewModel.manualMeals.count {
            let meal = viewModel.manualMeals[index]
            mealType = meal.mealType
            mealName = meal.name
            ingredients = meal.ingredients
        }
    }

    private var totalCalories: Int {
        ingredients.reduce(0) { $0 + $1.estimatedCalories }
    }

    private func addIngredient(name: String, quantity: Double, unit: String, calPer100g: Int) {
        let estimatedCal: Int
        if unit == "g" {
            estimatedCal = Int(Double(calPer100g) * quantity / 100)
        } else if unit == "oz" {
            estimatedCal = Int(Double(calPer100g) * quantity * 28.35 / 100)
        } else {
            estimatedCal = calPer100g // rough estimate for other units
        }

        let ingredient = ManualIngredient(
            name: name,
            quantity: quantity,
            unit: unit,
            estimatedCalories: estimatedCal
        )
        ingredients.append(ingredient)
    }

    private func saveMeal() {
        let meal = ManualMealEntry(
            mealType: mealType,
            name: mealName,
            ingredients: ingredients
        )

        if let index = viewModel.editingMealIndex {
            viewModel.updateManualMeal(at: index, with: meal)
        } else {
            viewModel.addManualMeal(meal)
        }
    }
}

// MARK: - Added Ingredient Row

struct AddedIngredientRow: View {
    let ingredient: ManualIngredient
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(ingredient.displayString)
                .font(.subheadline)
            Spacer()
            Text("~\(ingredient.estimatedCalories) cal")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Manual Meal Type Button

struct ManualMealTypeButton: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch type {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snack": return "leaf.fill"
        default: return "fork.knife"
        }
    }

    private var color: Color {
        switch type {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .gray
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(type.capitalized)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Manual Workout Entry View (keeping existing behavior)

struct ManualWorkoutEntryView: View {
    @ObservedObject var viewModel: PlanCreationViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Plan name
            TextField("Plan Name", text: $viewModel.manualName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search exercises...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await viewModel.searchExercises()
                        }
                    }

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                        viewModel.exerciseSearchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            // Search results
            if !viewModel.exerciseSearchResults.isEmpty {
                exerciseSearchResults
            }

            // Selected items
            if !viewModel.selectedExercises.isEmpty {
                selectedExercisesSection
            }

            Spacer()

            // Create button
            Button {
                Task {
                    await viewModel.manualCreateWorkoutPlan()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Create Workout Plan")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCreate ? Color.accentColor : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canCreate || viewModel.isLoading)
            .padding()
        }
        .padding(.top)
    }

    private var canCreate: Bool {
        !viewModel.manualName.isEmpty && !viewModel.selectedExercises.isEmpty
    }

    private var exerciseSearchResults: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Results")
                .font(.subheadline.bold())
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.exerciseSearchResults) { exercise in
                        ExerciseSearchCard(exercise: exercise) {
                            if !viewModel.selectedExercises.contains(where: { $0.id == exercise.id }) {
                                viewModel.selectedExercises.append(exercise)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var foodSearchResults: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Results")
                .font(.subheadline.bold())
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.foodSearchResults) { food in
                        FoodSearchCard(food: food) {
                            if !viewModel.selectedFoods.contains(where: { $0.id == food.id }) {
                                viewModel.selectedFoods.append(food)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var selectedExercisesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Exercises (\(viewModel.selectedExercises.count))")
                .font(.subheadline.bold())
                .padding(.horizontal)

            ForEach(viewModel.selectedExercises) { exercise in
                HStack {
                    Text(exercise.name)
                    Spacer()
                    Button {
                        viewModel.selectedExercises.removeAll { $0.id == exercise.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
            }
        }
    }

    private var selectedFoodsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Foods (\(viewModel.selectedFoods.count))")
                .font(.subheadline.bold())
                .padding(.horizontal)

            ForEach(viewModel.selectedFoods) { food in
                HStack {
                    VStack(alignment: .leading) {
                        Text(food.name)
                        Text("\(Int(food.calories ?? 0)) cal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        viewModel.selectedFoods.removeAll { $0.id == food.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Search Result Cards

struct ExerciseSearchCard: View {
    let exercise: ExerciseSearchResult
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Media
            if let gifUrl = exercise.gifUrl {
                AsyncImage(url: URL(string: gifUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(width: 120, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 80)
                    .overlay {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(.secondary)
                    }
            }

            Text(exercise.name)
                .font(.caption.bold())
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            if let muscle = exercise.targetMuscle {
                Text(muscle.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button("Add", action: onAdd)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(width: 120)
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

struct FoodSearchCard: View {
    let food: FoodSearchResult
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let imageUrl = food.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(width: 120, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 80)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    }
            }

            Text(food.name)
                .font(.caption.bold())
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            Text("\(food.calories ?? 0) cal")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button("Add", action: onAdd)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(width: 120)
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Meal Source Card

struct MealSourceCard: View {
    let source: MealSource
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: source.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(source.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(source.description)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workout Schedule Type Card

struct WorkoutScheduleTypeCard: View {
    let scheduleType: WorkoutScheduleType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: scheduleType.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(scheduleType.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(scheduleType.description)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workout Type Chip

struct WorkoutTypeChip: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Muscle Group Chip

struct MuscleGroupChip: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                }
                Text(name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ingredient Picker Sheet (Engaging Game-like Experience)

struct IngredientPickerSheet: View {
    @Binding var selectedIngredients: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var currentCategory = 0
    @State private var customIngredient = ""
    @State private var showCustomInput = false

    private let categories: [(name: String, icon: String, color: Color, items: [String])] = [
        ("Proteins", "flame.fill", .red, [
            "Chicken Breast", "Ground Beef", "Salmon", "Eggs", "Tofu",
            "Shrimp", "Turkey", "Pork", "Tuna", "Greek Yogurt"
        ]),
        ("Vegetables", "leaf.fill", .green, [
            "Broccoli", "Spinach", "Bell Peppers", "Onions", "Tomatoes",
            "Carrots", "Zucchini", "Mushrooms", "Asparagus", "Kale"
        ]),
        ("Carbs", "bolt.fill", .orange, [
            "Rice", "Pasta", "Potatoes", "Bread", "Oats",
            "Quinoa", "Sweet Potato", "Tortillas", "Couscous", "Noodles"
        ]),
        ("Dairy & More", "drop.fill", .blue, [
            "Cheese", "Milk", "Butter", "Cream", "Avocado",
            "Olive Oil", "Coconut Oil", "Almond Milk", "Sour Cream", "Feta"
        ]),
        ("Pantry", "archivebox.fill", .purple, [
            "Garlic", "Ginger", "Lemon", "Soy Sauce", "Honey",
            "Beans", "Chickpeas", "Lentils", "Nuts", "Seeds"
        ])
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category tabs (horizontally scrollable)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<categories.count, id: \.self) { index in
                            CategoryTab(
                                name: categories[index].name,
                                icon: categories[index].icon,
                                color: categories[index].color,
                                isSelected: currentCategory == index
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    currentCategory = index
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemGroupedBackground))

                // Ingredient grid - tappable
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(categories[currentCategory].items, id: \.self) { item in
                            IngredientChipButton(
                                name: item,
                                isSelected: selectedIngredients.contains(item),
                                color: categories[currentCategory].color
                            ) {
                                withAnimation(.spring(response: 0.2)) {
                                    if selectedIngredients.contains(item) {
                                        selectedIngredients.removeAll { $0 == item }
                                    } else {
                                        selectedIngredients.append(item)
                                    }
                                }
                            }
                        }

                        // Add custom ingredient button
                        Button {
                            showCustomInput = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle")
                                Text("Add Custom")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }

                // Selected count and done button
                VStack(spacing: 12) {
                    if !selectedIngredients.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedIngredients, id: \.self) { ingredient in
                                    HStack(spacing: 4) {
                                        Text(ingredient)
                                            .font(.caption.weight(.medium))
                                        Button {
                                            withAnimation(.spring(response: 0.2)) {
                                                selectedIngredients.removeAll { $0 == ingredient }
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.green)
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(selectedIngredients.isEmpty ? "Skip Ingredients" : "Done (\(selectedIngredients.count) selected)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedIngredients.isEmpty ? Color.secondary : Color.green)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Select Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if !selectedIngredients.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            withAnimation {
                                selectedIngredients.removeAll()
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Add Custom Ingredient", isPresented: $showCustomInput) {
                TextField("Ingredient name", text: $customIngredient)
                Button("Cancel", role: .cancel) {
                    customIngredient = ""
                }
                Button("Add") {
                    if !customIngredient.isEmpty && !selectedIngredients.contains(customIngredient) {
                        selectedIngredients.append(customIngredient)
                    }
                    customIngredient = ""
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? color : color.opacity(0.15))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ingredient Chip Button

struct IngredientChipButton: View {
    let name: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? color : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(IngredientButtonStyle())
    }
}

// MARK: - Ingredient Button Style (with bounce)

struct IngredientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Day Count Chip

struct DayCountChip: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(days)")
                    .font(.headline.bold())
                Text(days == 1 ? "day" : "days")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.green : Color(.systemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.green : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
