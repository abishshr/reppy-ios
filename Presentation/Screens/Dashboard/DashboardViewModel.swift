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

    func loadData() async {
        isLoading = true

        async let activityTask: () = loadActivity()
        async let mealsTask: () = loadMeals()
        async let workoutsTask: () = loadWorkouts()
        async let profileTask: () = loadProfile()
        async let todayPlanTask: () = loadTodaysPlan()
        async let waterTask: () = loadWater()
        async let streakTask: () = loadStreak()

        _ = await (activityTask, mealsTask, workoutsTask, profileTask, todayPlanTask, waterTask, streakTask)

        // Load cycle data after profile (need to know if female user)
        await loadCycle()

        isLoading = false
    }

    func refresh() async {
        await loadData()
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

    private func loadTodaysPlan() async {
        // Load active meal plan
        do {
            if let mealPlan = try await container.mealPlanRepository.fetchActiveMealPlan() {
                activeMealPlan = mealPlan
            }
        } catch {
            // No meal plan
        }

        // Load today's meals with enriched images from /today endpoint
        do {
            if let todayPlanDay = try await container.mealPlanRepository.fetchTodaysMeals() {
                todaysMeals = todayPlanDay.meals
            }
        } catch {
            // Fall back to finding from active plan
            if let mealPlan = activeMealPlan {
                let today = Calendar.current.startOfDay(for: Date())
                if let todayPlanDay = mealPlan.days.first(where: {
                    Calendar.current.isDate($0.date, inSameDayAs: today)
                }) {
                    todaysMeals = todayPlanDay.meals
                }
            }
        }

        // Load today's workout with enriched GIFs from /today endpoint
        do {
            if let workoutPlan = try await container.workoutPlanRepository.fetchActiveWorkoutPlan() {
                activeWorkoutPlan = workoutPlan
            }
            todaysWorkout = try await container.workoutPlanRepository.fetchTodaysWorkout()
        } catch {
            // No workout plan
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
