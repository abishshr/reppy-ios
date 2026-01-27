import SwiftUI

// CelebrationType is defined in CelebrationOverlay.swift and is accessible in same module

@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Steps
    @Published var todaySteps = 0
    @Published var stepsGoal = 10000

    // Macros
    @Published var todayCalories = 0
    @Published var calorieTarget = 2000
    @Published var todayProtein = 0.0
    @Published var proteinTarget = 150.0
    @Published var todayCarbs = 0.0
    @Published var carbsTarget = 250.0
    @Published var todayFat = 0.0
    @Published var fatTarget = 65.0

    // Micronutrients
    @Published var todaySugar = 0.0
    @Published var sugarTarget = 50.0  // ~10% of 2000 cal diet
    @Published var todayFiber = 0.0
    @Published var fiberTarget = 28.0  // FDA daily value
    @Published var todaySodium = 0.0
    @Published var sodiumTarget = 2300.0  // mg, FDA daily value
    @Published var todaySaturatedFat = 0.0
    @Published var saturatedFatTarget = 20.0  // g, ~10% of 2000 cal
    @Published var todayCholesterol = 0.0
    @Published var cholesterolTarget = 300.0  // mg, FDA daily value

    // Vitamin/Mineral tracking (daily totals from meals + supplements)
    @Published var vitaminMineralTotals: VitaminMineralTotals = VitaminMineralTotals()
    @Published var vitaminMineralTargets: MicronutrientTargets?

    // Supplement tracking
    @Published var supplementSummary: TodaySupplementSummary?

    // Blood work tracking
    @Published var bloodWorkSummary: BloodWorkSummary?

    // Exercise calories
    @Published var caloriesBurned = 0

    // Water tracking
    @Published var todayWaterMl = 0
    @Published var waterGoalMl = 2500
    @Published var isAddingWater = false

    // Streak tracking
    @Published var streakInfo: StreakInfo?
    @Published var isLoadingStreak = false
    @Published var showMilestoneCelebration = false
    @Published var achievedMilestone: StreakMilestone?

    // Menstrual Cycle (Female users only)
    @Published var isFemaleUser = false
    @Published var cycleStatus: CycleStatus?
    @Published var cycleRecommendations: CycleRecommendations?
    @Published var isLoadingCycle = false

    // Celebration state
    @Published var showCelebration = false
    @Published var celebrationType: CelebrationType = .meal
    @Published var celebrationValue = 0
    @Published var celebrationLabel = ""

    // Previous values for detecting changes
    private var previousCalories = 0
    private var previousCaloriesBurned = 0

    // Recent activity
    @Published var recentMeals: [Meal] = []
    @Published var recentWorkouts: [Workout] = []

    // Today's Plan
    @Published var todaysMeals: [PlannedMeal] = []
    @Published var todaysWorkout: WorkoutPlanDay?
    @Published var activeMealPlan: MealPlan?
    @Published var activeWorkoutPlan: WorkoutPlan?
    @Published var loggingMealId: String?
    @Published var completingWorkout = false

    // MARK: - Dependencies

    private let container = DependencyContainer.shared

    // MARK: - Computed Properties

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning!"
        case 12..<17:
            return "Good afternoon!"
        case 17..<22:
            return "Good evening!"
        default:
            return "Hello!"
        }
    }

    /// Whether user has both workout and meal plans active
    var hasActivePlans: Bool {
        activeMealPlan != nil && activeWorkoutPlan != nil
    }

    // MARK: - Data Loading

    /// Load data in two phases: critical first (fast UI), then secondary in background
    func loadData() async {
        isLoading = true

        // Phase 1: Critical data - load in parallel (required for main UI)
        async let profileTask: () = loadProfile()
        async let mealsTask: () = loadMeals()
        async let workoutsTask: () = loadWorkouts()
        async let todayPlanTask: () = loadTodaysPlan()
        async let waterTask: () = loadWater()

        _ = await (profileTask, mealsTask, workoutsTask, todayPlanTask, waterTask)

        // UI is now usable - hide loading indicator
        isLoading = false

        // Phase 2: Secondary data - load in background (doesn't block UI)
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }

            async let activityTask: () = await self.loadActivity()
            async let streakTask: () = await self.loadStreak()
            async let supplementTask: () = await self.loadSupplements()
            async let bloodWorkTask: () = await self.loadBloodWork()

            _ = await (activityTask, streakTask, supplementTask, bloodWorkTask)

            // Load cycle data (depends on profile being loaded)
            await self.loadCycle()

            // Combine vitamin/mineral totals on main actor
            await MainActor.run {
                self.combineVitaminMineralTotals()
            }
        }
    }

    func refresh() async {
        // On refresh, load everything but prioritize critical data
        await loadData()
    }

    /// Quick refresh - only reload today's data (for pull-to-refresh)
    func quickRefresh() async {
        async let mealsTask: () = loadMeals()
        async let workoutsTask: () = loadWorkouts()
        async let todayPlanTask: () = loadTodaysPlan()
        async let waterTask: () = loadWater()

        _ = await (mealsTask, workoutsTask, todayPlanTask, waterTask)
    }

    private func loadActivity() async {
        do {
            let summary = try await container.activityRepository.getActivitySummary()
            todaySteps = summary.todaySteps
            stepsGoal = summary.todayGoal
        } catch {
            // Activity might not be synced yet
        }
    }

    private func loadMeals() async {
        do {
            recentMeals = try await container.mealRepository.fetchMeals(days: 1)

            // Calculate today's totals
            let today = recentMeals.filter { $0.loggedAt.isToday }
            let newCalories = today.reduce(0) { $0 + ($1.calories ?? 0) }
            let newProtein = today.reduce(0) { $0 + ($1.proteinG ?? 0) }
            let newCarbs = today.reduce(0) { $0 + ($1.carbsG ?? 0) }
            let newFat = today.reduce(0) { $0 + ($1.fatG ?? 0) }

            // Calculate micronutrients
            let newSugar = today.reduce(0.0) { $0 + ($1.sugarGEst ?? 0) }
            let newFiber = today.reduce(0.0) { $0 + ($1.fiberGEst ?? 0) }
            let newSodium = today.reduce(0.0) { $0 + ($1.sodiumMgEst ?? 0) }
            let newSaturatedFat = today.reduce(0.0) { $0 + ($1.saturatedFatGEst ?? 0) }
            let newCholesterol = today.reduce(0.0) { $0 + ($1.cholesterolMgEst ?? 0) }

            // Calculate vitamin/mineral totals
            vitaminMineralTotals = VitaminMineralTotals(
                vitaminA: today.reduce(0.0) { $0 + ($1.vitaminAMcgEst ?? 0) },
                vitaminC: today.reduce(0.0) { $0 + ($1.vitaminCMgEst ?? 0) },
                vitaminD: today.reduce(0.0) { $0 + ($1.vitaminDMcgEst ?? 0) },
                vitaminE: today.reduce(0.0) { $0 + ($1.vitaminEMgEst ?? 0) },
                vitaminK: today.reduce(0.0) { $0 + ($1.vitaminKMcgEst ?? 0) },
                thiamin: today.reduce(0.0) { $0 + ($1.vitaminB1MgEst ?? 0) },
                riboflavin: today.reduce(0.0) { $0 + ($1.vitaminB2MgEst ?? 0) },
                niacin: today.reduce(0.0) { $0 + ($1.vitaminB3MgEst ?? 0) },
                vitaminB6: today.reduce(0.0) { $0 + ($1.vitaminB6MgEst ?? 0) },
                folate: today.reduce(0.0) { $0 + ($1.vitaminB9McgEst ?? 0) },
                vitaminB12: today.reduce(0.0) { $0 + ($1.vitaminB12McgEst ?? 0) },
                calcium: today.reduce(0.0) { $0 + ($1.calciumMgEst ?? 0) },
                iron: today.reduce(0.0) { $0 + ($1.ironMgEst ?? 0) },
                magnesium: today.reduce(0.0) { $0 + ($1.magnesiumMgEst ?? 0) },
                phosphorus: today.reduce(0.0) { $0 + ($1.phosphorusMgEst ?? 0) },
                potassium: today.reduce(0.0) { $0 + ($1.potassiumMgEst ?? 0) },
                zinc: today.reduce(0.0) { $0 + ($1.zincMgEst ?? 0) },
                selenium: today.reduce(0.0) { $0 + ($1.seleniumMcgEst ?? 0) },
                copper: today.reduce(0.0) { $0 + ($1.copperMcgEst ?? 0) },
                manganese: today.reduce(0.0) { $0 + ($1.manganeseMgEst ?? 0) }
            )

            // Check if calories increased (meal was logged)
            if newCalories > previousCalories && previousCalories > 0 {
                let addedCalories = newCalories - previousCalories
                celebrationType = .meal
                celebrationValue = addedCalories
                celebrationLabel = recentMeals.first?.items.first?.name ?? "Meal Logged"
                showCelebration = true
            }

            previousCalories = newCalories
            todayCalories = newCalories
            todayProtein = newProtein
            todayCarbs = newCarbs
            todayFat = newFat
            todaySugar = newSugar
            todayFiber = newFiber
            todaySodium = newSodium
            todaySaturatedFat = newSaturatedFat
            todayCholesterol = newCholesterol
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadWorkouts() async {
        do {
            recentWorkouts = try await container.workoutRepository.fetchWorkouts(days: 7)

            // Calculate calories burned from today's workouts
            let todayWorkouts = recentWorkouts.filter { $0.loggedAt.isToday }
            let newBurned = todayWorkouts.reduce(0) { $0 + ($1.caloriesBurnedEst ?? 0) }

            // Check if calories burned increased (workout was logged)
            if newBurned > previousCaloriesBurned && previousCaloriesBurned > 0 {
                let addedBurned = newBurned - previousCaloriesBurned
                celebrationType = .workout
                celebrationValue = addedBurned
                celebrationLabel = todayWorkouts.first?.exercises.first?.name ?? "Workout Complete"
                showCelebration = true
            }

            previousCaloriesBurned = newBurned
            caloriesBurned = newBurned
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProfile() async {
        do {
            let profile = try await container.profileRepository.fetchProfile()
            if let target = profile.dailyCalorieTarget {
                calorieTarget = target
            }
            if let target = profile.dailyProteinTarget {
                proteinTarget = target
            }
            if let target = profile.dailyCarbsTarget {
                carbsTarget = target
            }
            if let target = profile.dailyFatTarget {
                fatTarget = target
            }
            // Micronutrient targets
            if let target = profile.dailySugarTargetG {
                sugarTarget = target
            }
            if let target = profile.dailyFiberTargetG {
                fiberTarget = target
            }
            if let target = profile.dailySodiumTargetMg {
                sodiumTarget = target
            }
            if let target = profile.dailySaturatedFatTargetG {
                saturatedFatTarget = target
            }
            if let goal = profile.dailyStepsGoal {
                stepsGoal = goal
            }
            if let goal = profile.dailyWaterGoalMl {
                waterGoalMl = goal
            }

            // Check if user is female for cycle tracking
            isFemaleUser = profile.sex == .female

            // Calculate vitamin/mineral targets from profile
            vitaminMineralTargets = MicronutrientCalculatorService.shared.calculateTargets(from: profile)
        } catch {
            // Use defaults
        }
    }

    private func loadCycle() async {
        // Only load for female users
        guard isFemaleUser else { return }

        isLoadingCycle = true
        do {
            async let statusTask = container.apiClient.getCycleStatus()
            async let recsTask = container.apiClient.getCycleRecommendations()

            cycleStatus = try await statusTask
            cycleRecommendations = try await recsTask
        } catch {
            // Cycle tracking not set up yet - that's OK
            print("[Dashboard] Failed to load cycle data: \(error)")
        }
        isLoadingCycle = false
    }

    private func loadWater() async {
        do {
            let summary = try await container.apiClient.getTodayWater()
            todayWaterMl = summary.totalMl
            waterGoalMl = summary.goalMl
        } catch {
            // Water tracking might not be set up yet
        }
    }

    private func loadStreak() async {
        isLoadingStreak = true
        do {
            streakInfo = try await container.apiClient.getStreak()
        } catch {
            // Streak might not be available yet
            print("[Dashboard] Failed to load streak: \(error)")
        }
        isLoadingStreak = false
    }

    private func loadSupplements() async {
        do {
            supplementSummary = try await container.apiClient.getTodaySupplementSummary()
        } catch {
            // Supplement tracking might not be set up yet
            print("[Dashboard] Failed to load supplements: \(error)")
        }
    }

    private func loadBloodWork() async {
        do {
            bloodWorkSummary = try await container.apiClient.getBloodWorkSummary()
        } catch {
            // Blood work might not be set up yet
            print("[Dashboard] Failed to load blood work: \(error)")
        }
    }

    /// Combine vitamin/mineral totals from both meals and supplements
    private func combineVitaminMineralTotals() {
        guard let supplements = supplementSummary else { return }

        // Add supplement nutrients to the meal-based totals
        vitaminMineralTotals.vitaminA += supplements.totalVitaminAMcg
        vitaminMineralTotals.vitaminC += supplements.totalVitaminCMg
        vitaminMineralTotals.vitaminD += supplements.totalVitaminDMcg
        vitaminMineralTotals.vitaminE += supplements.totalVitaminEMg
        vitaminMineralTotals.vitaminK += supplements.totalVitaminKMcg
        vitaminMineralTotals.thiamin += supplements.totalVitaminB1Mg
        vitaminMineralTotals.riboflavin += supplements.totalVitaminB2Mg
        vitaminMineralTotals.niacin += supplements.totalVitaminB3Mg
        vitaminMineralTotals.vitaminB6 += supplements.totalVitaminB6Mg
        vitaminMineralTotals.folate += supplements.totalVitaminB9Mcg
        vitaminMineralTotals.vitaminB12 += supplements.totalVitaminB12Mcg
        vitaminMineralTotals.calcium += supplements.totalCalciumMg
        vitaminMineralTotals.iron += supplements.totalIronMg
        vitaminMineralTotals.magnesium += supplements.totalMagnesiumMg
        vitaminMineralTotals.phosphorus += supplements.totalPhosphorusMg
        vitaminMineralTotals.potassium += supplements.totalPotassiumMg
        vitaminMineralTotals.zinc += supplements.totalZincMg
        vitaminMineralTotals.selenium += supplements.totalSeleniumMcg
        vitaminMineralTotals.copper += supplements.totalCopperMcg
        vitaminMineralTotals.manganese += supplements.totalManganeseMg
    }

    private func loadTodaysPlan() async {
        // Load all plan data in parallel for faster loading
        async let mealPlanTask: MealPlan? = {
            try? await container.mealPlanRepository.fetchActiveMealPlan()
        }()
        async let todayMealsTask: MealPlanDay? = {
            try? await container.mealPlanRepository.fetchTodaysMeals()
        }()
        async let workoutPlanTask: WorkoutPlan? = {
            try? await container.workoutPlanRepository.fetchActiveWorkoutPlan()
        }()
        async let todayWorkoutTask: WorkoutPlanDay? = {
            try? await container.workoutPlanRepository.fetchTodaysWorkout()
        }()

        // Await all results
        let (mealPlan, todayMealsResult, workoutPlan, todayWorkout) = await (mealPlanTask, todayMealsTask, workoutPlanTask, todayWorkoutTask)

        activeMealPlan = mealPlan
        activeWorkoutPlan = workoutPlan
        todaysWorkout = todayWorkout

        // Use today's meals from API, or fall back to plan
        if let todayPlanDay = todayMealsResult {
            todaysMeals = todayPlanDay.meals
        } else if let mealPlan = mealPlan {
            let today = Calendar.current.startOfDay(for: Date())
            if let todayPlanDay = mealPlan.days.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: today)
            }) {
                todaysMeals = todayPlanDay.meals
            }
        }
    }

    // MARK: - Actions

    func syncSteps() async {
        do {
            let activity = try await container.activityRepository.syncTodaySteps()
            todaySteps = activity.steps
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func quickLogMeal(_ meal: PlannedMeal) async {
        loggingMealId = meal.id
        // Navigate to chat to confirm the log
        // The chat will handle the actual logging
        loggingMealId = nil
    }

    func completeWorkout() async {
        guard let workout = todaysWorkout, let plan = activeWorkoutPlan else { return }
        completingWorkout = true
        do {
            try await container.workoutPlanRepository.completeWorkoutDay(planId: plan.id, dayId: workout.id)

            // Add estimated calories burned from workout
            let burnedCalories = workout.estimatedCalories ?? 0
            if burnedCalories > 0 {
                caloriesBurned += burnedCalories

                // Show celebration
                celebrationType = .workout
                celebrationValue = burnedCalories
                celebrationLabel = workout.displayName
                showCelebration = true
            }

            // Reload today's workout to get updated isCompleted status
            todaysWorkout = try await container.workoutPlanRepository.fetchTodaysWorkout()
            NotificationCenter.default.post(name: .workoutLogged, object: nil)

            // Check for streak milestone
            await checkStreakMilestone()
        } catch {
            errorMessage = error.localizedDescription
        }
        completingWorkout = false
    }

    func addWater(amountMl: Int) async {
        isAddingWater = true
        do {
            _ = try await container.apiClient.logWater(amountMl: amountMl)
            todayWaterMl += amountMl

            // Show celebration if goal just met
            if todayWaterMl >= waterGoalMl && (todayWaterMl - amountMl) < waterGoalMl {
                celebrationType = .water
                celebrationValue = waterGoalMl
                celebrationLabel = "Water Goal!"
                showCelebration = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isAddingWater = false
    }

    func quickAddCalories(
        calories: Int,
        description: String,
        mealType: String,
        proteinG: Double?,
        carbsG: Double?,
        fatG: Double?,
        loggedAt: Date
    ) async throws {
        let _ = try await container.apiClient.quickAddCalories(
            calories: calories,
            description: description,
            mealType: mealType,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            loggedAt: loggedAt
        )

        // Update local state
        todayCalories += calories
        if let protein = proteinG { todayProtein += protein }
        if let carbs = carbsG { todayCarbs += carbs }
        if let fat = fatG { todayFat += fat }

        // Show celebration
        celebrationType = .meal
        celebrationValue = calories
        celebrationLabel = description
        showCelebration = true

        // Notify other views
        NotificationCenter.default.post(name: .mealLogged, object: nil)
    }

    func dismissMilestoneCelebration() {
        showMilestoneCelebration = false
        achievedMilestone = nil
    }

    /// Log a planned meal directly without going to chat
    @MainActor
    func logPlannedMeal(_ meal: PlannedMeal) async {
        do {
            _ = try await container.apiClient.quickAddCalories(
                calories: meal.calories,
                description: meal.name,
                mealType: meal.type.lowercased(),
                proteinG: meal.proteinG,
                carbsG: meal.carbsG,
                fatG: meal.fatG,
                loggedAt: Date()
            )

            // Update local state
            todayCalories += meal.calories
            todayProtein += meal.proteinG
            todayCarbs += meal.carbsG
            todayFat += meal.fatG

            // Show celebration
            celebrationType = .meal
            celebrationValue = meal.calories
            celebrationLabel = meal.name
            showCelebration = true

            // Remove logged meal from today's plan
            todaysMeals.removeAll { $0.id == meal.id }

            // Notify other views
            NotificationCenter.default.post(name: .mealLogged, object: nil)

            // Check for streak milestone
            await checkStreakMilestone()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called after any activity is logged to check for new milestones
    func checkStreakMilestone() async {
        do {
            let response = try await container.apiClient.recordActivity()
            streakInfo = response.streak
            if let milestone = response.newMilestone {
                achievedMilestone = milestone
                showMilestoneCelebration = true
            }
        } catch {
            print("[Dashboard] Failed to record activity: \(error)")
        }
    }
}

// MARK: - Vitamin/Mineral Daily Totals

struct VitaminMineralTotals {
    // Vitamins
    var vitaminA: Double = 0  // mcg
    var vitaminC: Double = 0  // mg
    var vitaminD: Double = 0  // mcg
    var vitaminE: Double = 0  // mg
    var vitaminK: Double = 0  // mcg
    var thiamin: Double = 0   // mg (B1)
    var riboflavin: Double = 0 // mg (B2)
    var niacin: Double = 0    // mg (B3)
    var vitaminB6: Double = 0 // mg
    var folate: Double = 0    // mcg (B9)
    var vitaminB12: Double = 0 // mcg

    // Minerals
    var calcium: Double = 0   // mg
    var iron: Double = 0      // mg
    var magnesium: Double = 0 // mg
    var phosphorus: Double = 0 // mg
    var potassium: Double = 0 // mg
    var zinc: Double = 0      // mg
    var selenium: Double = 0  // mcg
    var copper: Double = 0    // mcg
    var manganese: Double = 0 // mg

    /// Check if any vitamin/mineral data exists
    var hasData: Bool {
        vitaminA > 0 || vitaminC > 0 || vitaminD > 0 || iron > 0 || calcium > 0
    }

    /// Get key nutrients with actual vs target comparison
    func keyNutrients(targets: MicronutrientTargets?) -> [KeyNutrientProgress] {
        guard let targets = targets else { return [] }
        return [
            KeyNutrientProgress(name: "Vitamin D", actual: vitaminD, target: targets.vitaminD, unit: "mcg", icon: "sun.max.fill", color: .yellow),
            KeyNutrientProgress(name: "Vitamin C", actual: vitaminC, target: targets.vitaminC, unit: "mg", icon: "leaf.fill", color: .orange),
            KeyNutrientProgress(name: "Iron", actual: iron, target: targets.iron, unit: "mg", icon: "drop.fill", color: .red),
            KeyNutrientProgress(name: "Calcium", actual: calcium, target: targets.calcium, unit: "mg", icon: "bone.fill", color: .gray),
            KeyNutrientProgress(name: "Magnesium", actual: magnesium, target: targets.magnesium, unit: "mg", icon: "sparkles", color: .purple),
            KeyNutrientProgress(name: "Potassium", actual: potassium, target: targets.potassium, unit: "mg", icon: "bolt.fill", color: .blue),
        ]
    }
}

struct KeyNutrientProgress: Identifiable {
    let id = UUID()
    let name: String
    let actual: Double
    let target: Double
    let unit: String
    let icon: String
    let color: Color

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(actual / target, 1.0)
    }

    var percentComplete: Int {
        Int(progress * 100)
    }

    var formattedActual: String {
        if actual >= 1000 {
            return String(format: "%.0f", actual)
        } else if actual >= 10 {
            return String(format: "%.0f", actual)
        } else {
            return String(format: "%.1f", actual)
        }
    }

    var formattedTarget: String {
        if target >= 1000 {
            return String(format: "%.0f", target)
        } else if target >= 10 {
            return String(format: "%.0f", target)
        } else {
            return String(format: "%.1f", target)
        }
    }
}
