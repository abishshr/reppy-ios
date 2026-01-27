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

    init(planType: PlanType, apiClient: APIClient, chatRepository: ChatRepository) {
        self.planType = planType
        _viewModel = StateObject(wrappedValue: PlanCreationViewModel(
            planType: planType,
            apiClient: apiClient,
            chatRepository: chatRepository
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

    init(planType: PlanType, apiClient: APIClient, chatRepository: ChatRepository) {
        self.planType = planType
        self.apiClient = apiClient
        self.chatRepository = chatRepository
    }

    // MARK: - Quick Create

    func quickCreate() async {
        quickGenerating = true
        isLoading = true

        do {
            let prompt: String
            if planType == .workout {
                if workoutScheduleType == .daily {
                    prompt = "Create a single workout for me to do today based on my profile and goals. Just create it without asking questions."
                } else {
                    prompt = "Create a workout plan for me based on my profile. Just create it without asking questions."
                }
            } else {
                prompt = "Create a meal plan for me based on my profile. Just create it without asking questions."
            }

            _ = try await chatRepository.sendMessage(prompt, sessionId: nil, imageBase64: nil)
            isCreated = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        quickGenerating = false
        isLoading = false
    }

    // MARK: - Customize Create

    func customizeCreate() async {
        isLoading = true

        do {
            let prompt: String
            if planType == .workout {
                if workoutScheduleType == .daily {
                    // Daily workout creation
                    let muscleGroupsText = targetMuscleGroups.isEmpty
                        ? "based on what I haven't trained recently"
                        : targetMuscleGroups.joined(separator: ", ")

                    prompt = """
                    Create a single workout for me to do today with these specifications:
                    - Workout type: \(selectedWorkoutType)
                    - Target muscle groups: \(muscleGroupsText)
                    - Duration: approximately \(estimatedDuration) minutes
                    - Difficulty: \(selectedDifficulty)
                    - Goal: \(selectedGoal)
                    Create it without asking questions. Include specific exercises with sets, reps, and rest times.
                    """
                } else {
                    // Full plan creation
                    prompt = """
                    Create a workout plan with these specifications:
                    - Goal: \(selectedGoal)
                    - Duration: \(selectedDuration) weeks
                    - Days per week: \(selectedDaysPerWeek)
                    - Difficulty: \(selectedDifficulty)
                    - Split type: \(selectedSplit)
                    Create it without asking questions.
                    """
                }
            } else {
                var mealSourceInfo = ""
                switch selectedMealSource {
                case .homeCoooked:
                    mealSourceInfo = "Home cooked meals only - provide recipes I can make at home"
                case .fastFood:
                    if !preferredRestaurant.isEmpty {
                        mealSourceInfo = "Fast food meals from \(preferredRestaurant) ONLY - tell me exactly what to order that fits my goals. Use real menu items from this restaurant."
                    } else {
                        mealSourceInfo = "Fast food meals from popular chains near the user - tell me what to order that fits my goals. Suggest restaurants based on my location and preferences."
                    }
                case .restaurant:
                    if !preferredRestaurant.isEmpty {
                        mealSourceInfo = "Restaurant meals from \(preferredRestaurant) or similar restaurants - suggest specific dishes I could order"
                    } else {
                        mealSourceInfo = "Restaurant-style dishes I could order when eating out - suggest specific restaurants based on my location"
                    }
                case .mixed:
                    mealSourceInfo = "Mix of home cooked and eating out options"
                }

                prompt = """
                Create a meal plan with these specifications:
                - Diet style: \(selectedDietStyle)
                - Daily calories: \(dailyCalories)
                - Meals per day: \(mealCount)
                - Duration: 7 days
                - Meal source: \(mealSourceInfo)
                Create it without asking questions. For fast food/restaurant options, include the specific restaurant name and exact menu item to order.
                """
            }

            _ = try await chatRepository.sendMessage(prompt, sessionId: nil, imageBase64: nil)
            isCreated = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
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
        VStack(spacing: 16) {
            // Plan name
            TextField("Plan Name", text: $viewModel.manualName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(
                    planType == .workout ? "Search exercises..." : "Search foods...",
                    text: $viewModel.searchQuery
                )
                .textFieldStyle(.plain)
                .onSubmit {
                    Task {
                        if planType == .workout {
                            await viewModel.searchExercises()
                        } else {
                            await viewModel.searchFoods()
                        }
                    }
                }

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                        viewModel.exerciseSearchResults = []
                        viewModel.foodSearchResults = []
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
            if planType == .workout && !viewModel.exerciseSearchResults.isEmpty {
                exerciseSearchResults
            } else if planType == .meal && !viewModel.foodSearchResults.isEmpty {
                foodSearchResults
            }

            // Selected items
            if planType == .workout && !viewModel.selectedExercises.isEmpty {
                selectedExercisesSection
            } else if planType == .meal && !viewModel.selectedFoods.isEmpty {
                selectedFoodsSection
            }

            Spacer()

            // Create button
            Button {
                Task {
                    if planType == .workout {
                        await viewModel.manualCreateWorkoutPlan()
                    } else {
                        await viewModel.manualCreateMealPlan()
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Create \(planType.title)")
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
        !viewModel.manualName.isEmpty && (
            (planType == .workout && !viewModel.selectedExercises.isEmpty) ||
            (planType == .meal && !viewModel.selectedFoods.isEmpty)
        )
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
