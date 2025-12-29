import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    var onSuggestMeal: (() -> Void)?

    @State private var isReady = false
    @State private var showWorkoutLogger = false
    @State private var showMealLogger = false
    @State private var showCreatePlanSheet = false
    @State private var showBarcodeScanner = false
    @State private var showQuickAddCalories = false
    @State private var showCreateFoodFromBarcode = false
    @State private var scannedBarcode: String?
    @State private var createPlanType: PlanType = .workout
    @State private var showCycleLogger = false
    @State private var showCycleDetails = false
    private let impactLight = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    if isReady {
                        content
                    } else {
                        skeletonContent
                    }
                }
                .background(Color(.systemGroupedBackground))

                // Celebration overlay
                if viewModel.showCelebration {
                    CelebrationOverlay(
                        isShowing: $viewModel.showCelebration,
                        type: viewModel.celebrationType,
                        value: viewModel.celebrationValue,
                        label: viewModel.celebrationLabel
                    )
                    .zIndex(100)
                }

                // Milestone celebration overlay
                if viewModel.showMilestoneCelebration, let milestone = viewModel.achievedMilestone {
                    MilestoneCelebrationView(milestone: milestone) {
                        viewModel.dismissMilestoneCelebration()
                    }
                    .zIndex(101)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                impactLight.prepare()
                await viewModel.loadData()
                withAnimation(.easeOut(duration: 0.2)) {
                    isReady = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .mealLogged)) { _ in
                Task { await viewModel.loadData() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .workoutLogged)) { _ in
                Task { await viewModel.loadData() }
            }
            .sheet(isPresented: $showWorkoutLogger) {
                WorkoutLoggerSheet()
            }
            .sheet(isPresented: $showMealLogger) {
                MealLoggerSheet(
                    onScanBarcode: {
                        showBarcodeScanner = true
                    },
                    onQuickAdd: {
                        showQuickAddCalories = true
                    }
                )
            }
            .sheet(isPresented: $showQuickAddCalories) {
                QuickAddCaloriesSheet { calories, description, mealType, protein, carbs, fat, loggedAt in
                    _ = try await DependencyContainer.shared.apiClient.quickAddCalories(
                        calories: calories,
                        description: description,
                        mealType: mealType,
                        proteinG: protein,
                        carbsG: carbs,
                        fatG: fat,
                        loggedAt: loggedAt
                    )
                    NotificationCenter.default.post(name: .mealLogged, object: nil)
                }
            }
            .sheet(isPresented: $showCreatePlanSheet) {
                UnifiedPlanCreationSheet(
                    planType: createPlanType,
                    apiClient: DependencyContainer.shared.apiClient,
                    chatRepository: DependencyContainer.shared.chatRepository
                )
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(
                    foodRepository: DependencyContainer.shared.foodRepository,
                    onFoodFound: { food in
                        // Navigate to chat to log the scanned food
                        appState.navigateToChatWith(
                            message: "Log \(food.name) - \(Int(food.calories ?? 0)) calories"
                        )
                    },
                    onCreateFood: { barcode in
                        // Store barcode and show create food sheet
                        scannedBarcode = barcode
                        showCreateFoodFromBarcode = true
                    }
                )
            }
            .sheet(isPresented: $showCreateFoodFromBarcode) {
                CreateCustomFoodSheet(
                    apiClient: DependencyContainer.shared.apiClient,
                    prefillBarcode: scannedBarcode
                )
            }
            .sheet(isPresented: $showCycleLogger) {
                CycleLoggerSheet(
                    apiClient: DependencyContainer.shared.apiClient,
                    date: Date(),
                    existingLog: nil,
                    onSaved: { _ in
                        Task { await viewModel.loadData() }
                    }
                )
            }
            .sheet(isPresented: $showCycleDetails) {
                CycleDetailSheet(
                    apiClient: DependencyContainer.shared.apiClient,
                    status: viewModel.cycleStatus,
                    recommendations: viewModel.cycleRecommendations,
                    onLogTap: {
                        showCycleDetails = false
                        showCycleLogger = true
                    }
                )
            }
        }
    }

    // MARK: - Main Content

    private var content: some View {
        VStack(spacing: 20) {
            // Header
            headerSection
                .padding(.horizontal, 20)

            // Hero Calorie Ring
            CalorieRingCard(
                consumed: viewModel.todayCalories,
                burned: viewModel.caloriesBurned,
                target: viewModel.calorieTarget,
                protein: viewModel.todayProtein,
                proteinTarget: viewModel.proteinTarget,
                carbs: viewModel.todayCarbs,
                carbsTarget: viewModel.carbsTarget,
                fat: viewModel.todayFat,
                fatTarget: viewModel.fatTarget
            )
            .padding(.horizontal, 20)

            // Micronutrients Card
            MicronutrientsCard(
                sugar: viewModel.todaySugar,
                sugarTarget: viewModel.sugarTarget,
                fiber: viewModel.todayFiber,
                fiberTarget: viewModel.fiberTarget,
                sodium: viewModel.todaySodium,
                sodiumTarget: viewModel.sodiumTarget,
                saturatedFat: viewModel.todaySaturatedFat,
                saturatedFatTarget: viewModel.saturatedFatTarget,
                cholesterol: viewModel.todayCholesterol,
                cholesterolTarget: viewModel.cholesterolTarget
            )
            .padding(.horizontal, 20)

            // Stats Row (Steps + Calories Burned)
            StatsRow(
                steps: viewModel.todaySteps,
                stepsGoal: viewModel.stepsGoal,
                caloriesBurned: viewModel.caloriesBurned,
                workoutsThisWeek: viewModel.recentWorkouts.count
            )
            .padding(.horizontal, 20)

            // Streak Tracking
            StreakCard(
                streakInfo: viewModel.streakInfo,
                isLoading: viewModel.isLoadingStreak,
                onTap: {
                    // Could navigate to streak history in the future
                }
            )
            .padding(.horizontal, 20)

            // Menstrual Cycle Tracking (Female Users Only)
            if viewModel.isFemaleUser, let cycleStatus = viewModel.cycleStatus {
                CycleStatusCardCompact(
                    status: cycleStatus,
                    onTap: {
                        impactLight.impactOccurred()
                        showCycleDetails = true
                    }
                )
                .padding(.horizontal, 20)
            }

            // Today's Plan
            TodaysPlanSection(
                meals: viewModel.todaysMeals,
                workout: viewModel.todaysWorkout,
                workoutPlan: viewModel.activeWorkoutPlan,
                hasMealPlan: viewModel.activeMealPlan != nil,
                hasWorkoutPlan: viewModel.activeWorkoutPlan != nil,
                completingWorkout: viewModel.completingWorkout,
                onLogMeal: { meal in
                    Task { await viewModel.logPlannedMeal(meal) }
                },
                onStartWorkout: {
                    if let workout = viewModel.todaysWorkout {
                        appState.navigateToChatWith(
                            message: "I'm starting my workout: \(workout.displayName)"
                        )
                    }
                },
                onCompleteWorkout: {
                    Task { await viewModel.completeWorkout() }
                }
            )
            .padding(.horizontal, 20)

            // Plan Creation Section (always visible, compact when plans exist)
            PlanCreationSection(
                hasWorkoutPlan: viewModel.activeWorkoutPlan != nil,
                hasMealPlan: viewModel.activeMealPlan != nil,
                onCreateWorkoutPlan: {
                    impactLight.impactOccurred()
                    createPlanType = .workout
                    showCreatePlanSheet = true
                },
                onCreateMealPlan: {
                    impactLight.impactOccurred()
                    createPlanType = .meal
                    showCreatePlanSheet = true
                }
            )
            .padding(.horizontal, 20)

            // Quick Actions (4 most-used)
            QuickActionsRow(
                onLogMeal: {
                    impactLight.impactOccurred()
                    showMealLogger = true
                },
                onLogWorkout: {
                    impactLight.impactOccurred()
                    showWorkoutLogger = true
                },
                onScanBarcode: {
                    impactLight.impactOccurred()
                    showBarcodeScanner = true
                },
                onAskCoach: {
                    impactLight.impactOccurred()
                    appState.selectedTab = 1
                }
            )
            .padding(.horizontal, 20)

            // Recent Activity
            if !viewModel.recentMeals.isEmpty || !viewModel.recentWorkouts.isEmpty {
                RecentActivitySection(
                    meals: Array(viewModel.recentMeals.prefix(3)),
                    workouts: Array(viewModel.recentWorkouts.prefix(2))
                )
            }

            Spacer(minLength: 20)
        }
        .padding(.top, 8)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.title)
                    .fontWeight(.bold)

                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Profile avatar placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(viewModel.greeting.split(separator: ",").last?.trimmingCharacters(in: .whitespaces).prefix(1) ?? "U"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
    }

    // MARK: - Skeleton Loading

    private var skeletonContent: some View {
        VStack(spacing: 20) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonView(width: 180, height: 28)
                    SkeletonView(width: 140, height: 16)
                }
                Spacer()
                SkeletonView(width: 44, height: 44)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 20)

            // Calorie ring skeleton
            SkeletonView(height: 200)
                .padding(.horizontal, 20)

            // Stats row skeleton
            HStack(spacing: 12) {
                SkeletonView(height: 80)
                SkeletonView(height: 80)
            }
            .padding(.horizontal, 20)

            // Quick actions skeleton
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonView(height: 80)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
    }
}

// MARK: - Skeleton View

struct SkeletonView: View {
    var width: CGFloat?
    var height: CGFloat = 20

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .shimmering()
    }
}

// Shimmer effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Calorie Ring Card (Gamified)

struct CalorieRingCard: View {
    let consumed: Int
    let burned: Int
    let target: Int
    let protein: Double
    let proteinTarget: Double
    let carbs: Double
    let carbsTarget: Double
    let fat: Double
    let fatTarget: Double

    private var netCalories: Int {
        consumed - burned
    }

    private var ringColor: Color {
        let progress = Double(netCalories) / Double(target)
        if netCalories > target {
            return .red
        } else if progress > 0.8 {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Main Calorie Meter
            CalorieMeter(consumed: consumed, burned: burned, target: target)

            // Net calories breakdown - animated stats
            HStack(spacing: 0) {
                Spacer()

                // Eaten
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "fork.knife")
                            .font(.caption2)
                            .foregroundColor(.primary.opacity(0.6))
                        PulsingCounter(
                            value: consumed,
                            font: .subheadline.bold(),
                            color: .primary
                        )
                    }
                    Text("eaten")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Divider
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1, height: 30)

                Spacer()

                // Burned
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        PulsingCounter(
                            value: burned,
                            font: .subheadline.bold(),
                            color: .orange
                        )
                    }
                    Text("burned")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Divider
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1, height: 30)

                Spacer()

                // Net
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "equal.circle.fill")
                            .font(.caption2)
                            .foregroundColor(ringColor)
                        PulsingCounter(
                            value: netCalories,
                            font: .subheadline.bold(),
                            color: ringColor
                        )
                    }
                    Text("net")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )

            // Macro Progress Bars - XP style
            VStack(spacing: 12) {
                LevelProgressBar(
                    current: protein,
                    target: proteinTarget,
                    label: "Protein",
                    color: .blue,
                    icon: "p.circle.fill"
                )

                LevelProgressBar(
                    current: carbs,
                    target: carbsTarget,
                    label: "Carbs",
                    color: .orange,
                    icon: "c.circle.fill"
                )

                LevelProgressBar(
                    current: fat,
                    target: fatTarget,
                    label: "Fat",
                    color: .purple,
                    icon: "f.circle.fill"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
        )
    }
}

// MARK: - Macro Progress Bar

struct MacroProgressBar: View {
    let name: String
    let current: Double
    let target: Double
    let color: Color
    let icon: String

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)

                Text("\(Int(current))g")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)

            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stats Row (Gamified)

struct StatsRow: View {
    let steps: Int
    let stepsGoal: Int
    let caloriesBurned: Int
    let workoutsThisWeek: Int

    @State private var stepsAnimatedProgress: Double = 0

    private var stepsProgress: Double {
        guard stepsGoal > 0 else { return 0 }
        return min(Double(steps) / Double(stepsGoal), 1.0)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Steps Card
            HStack(spacing: 12) {
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 4)
                        .frame(width: 44, height: 44)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: stepsAnimatedProgress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "figure.walk")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    PulsingCounter(
                        value: steps,
                        font: .headline,
                        color: .primary
                    )

                    Text("/ \(stepsGoal.formatted()) steps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )

            // Calories Burned Card
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    PulsingCounter(
                        value: caloriesBurned,
                        font: .headline,
                        color: .primary
                    )

                    Text("cal burned")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                stepsAnimatedProgress = stepsProgress
            }
        }
        .onChange(of: stepsProgress) { _, newProgress in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                stepsAnimatedProgress = newProgress
            }
        }
    }
}

// MARK: - Today's Plan Section

struct TodaysPlanSection: View {
    let meals: [PlannedMeal]
    let workout: WorkoutPlanDay?
    let workoutPlan: WorkoutPlan?
    let hasMealPlan: Bool
    let hasWorkoutPlan: Bool
    let completingWorkout: Bool
    let onLogMeal: (PlannedMeal) -> Void
    let onStartWorkout: () -> Void
    let onCompleteWorkout: () -> Void

    @State private var selectedMeal: PlannedMeal?
    @State private var selectedWorkout: WorkoutPlanDay?
    @State private var showWeekView = false

    private let mealTypeOrder = ["breakfast", "lunch", "dinner", "snack"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("Today's Plan")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if hasWorkoutPlan {
                    Button {
                        showWeekView = true
                    } label: {
                        Label("This Week", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
            }

            VStack(spacing: 10) {
                // Today's Meals - grouped by type
                if !meals.isEmpty {
                    ForEach(mealTypeOrder, id: \.self) { mealType in
                        let mealsOfType = meals.filter { $0.type.lowercased() == mealType }
                        if !mealsOfType.isEmpty {
                            MealTypeGroup(
                                mealType: mealType,
                                meals: mealsOfType,
                                onTap: { meal in selectedMeal = meal },
                                onLog: { meal in onLogMeal(meal) }
                            )
                        }
                    }
                } else if hasMealPlan {
                    EmptyMealRow()
                } else {
                    // No meal plan - show create option
                    CreatePlanRow(
                        icon: "fork.knife",
                        title: "Meal Plan",
                        subtitle: "Create a personalized meal plan",
                        gradient: [.green, .mint]
                    )
                }

                // Today's Workout
                if let workout = workout {
                    CollapsibleWorkoutSection(
                        workout: workout,
                        completing: completingWorkout,
                        onTap: { selectedWorkout = workout },
                        onComplete: onCompleteWorkout
                    )
                } else if hasWorkoutPlan {
                    RestDayRow()
                } else {
                    // No workout plan - show create option
                    CreatePlanRow(
                        icon: "dumbbell.fill",
                        title: "Workout Plan",
                        subtitle: "Create a personalized program",
                        gradient: [.blue, .cyan]
                    )
                }
            }
        }
        .sheet(item: $selectedMeal) { meal in
            MealDetailSheet(meal: meal)
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailSheet(workout: workout)
        }
        .sheet(isPresented: $showWeekView) {
            if let plan = workoutPlan {
                WeekWorkoutSheet(plan: plan, onSelectWorkout: { day in
                    showWeekView = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedWorkout = day
                    }
                })
            }
        }
    }
}

// MARK: - Week Workout Sheet

struct WeekWorkoutSheet: View {
    let plan: WorkoutPlan
    let onSelectWorkout: (WorkoutPlanDay) -> Void
    @Environment(\.dismiss) private var dismiss

    private var currentWeekDays: [WorkoutPlanDay] {
        plan.days.filter { $0.weekNumber == plan.currentWeek }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Week Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week \(plan.currentWeek)")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(plan.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Progress
                        let completed = currentWeekDays.filter { $0.isCompleted }.count
                        let total = currentWeekDays.filter { !$0.isRestDay }.count
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(completed)/\(total)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Days List
                    VStack(spacing: 12) {
                        ForEach(currentWeekDays) { day in
                            WeekDayRow(day: day) {
                                if !day.isRestDay {
                                    onSelectWorkout(day)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WeekDayRow: View {
    let day: WorkoutPlanDay
    let onTap: () -> Void

    private var dayOfWeek: String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let index = (day.dayNumber - 1) % 7
        return days[index]
    }

    private var isToday: Bool {
        // Simple check - could be improved with actual date comparison
        let calendar = Calendar.current
        let todayDayOfWeek = calendar.component(.weekday, from: Date())
        // Convert Sunday=1 to Monday=1 format
        let adjustedToday = todayDayOfWeek == 1 ? 7 : todayDayOfWeek - 1
        return day.dayNumber == adjustedToday
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Day indicator
                VStack(spacing: 2) {
                    Text(dayOfWeek)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isToday ? .white : .secondary)

                    Text("\(day.dayNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isToday ? .white : .primary)
                }
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isToday ? Color.blue : Color(.systemGray6))
                )

                // Workout info
                VStack(alignment: .leading, spacing: 4) {
                    if day.isRestDay {
                        Text("Rest Day")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    } else {
                        Text(day.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        if let muscles = day.targetMuscles, !muscles.isEmpty {
                            Text(muscles.prefix(3).joined(separator: ", ").capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Status & Info
                if day.isRestDay {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.purple)
                } else {
                    HStack(spacing: 8) {
                        if let duration = day.estimatedDurationMin {
                            Text("\(duration) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if day.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(day.isCompleted ? Color.green.opacity(0.3) : (isToday ? Color.blue.opacity(0.3) : Color.clear), lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(day.isRestDay)
    }
}

// MARK: - No Plan Card

struct NoPlanCard: View {
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                MealPlanView()
            } label: {
                CreatePlanMiniCard(
                    icon: "fork.knife",
                    title: "Meal Plan",
                    gradient: [.green, .mint]
                )
            }
            .buttonStyle(BounceButtonStyle())

            NavigationLink {
                WorkoutPlanView()
            } label: {
                CreatePlanMiniCard(
                    icon: "dumbbell.fill",
                    title: "Workout",
                    gradient: [.blue, .cyan]
                )
            }
            .buttonStyle(BounceButtonStyle())
        }
    }
}

struct CreatePlanMiniCard: View {
    let icon: String
    let title: String
    let gradient: [Color]

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("Create")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Meal Type Group

struct MealTypeGroup: View {
    let mealType: String
    let meals: [PlannedMeal]
    let onTap: (PlannedMeal) -> Void
    let onLog: (PlannedMeal) -> Void

    @State private var isExpanded = true

    private var mealTypeIcon: String {
        switch mealType.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snack": return "carrot.fill"
        default: return "fork.knife"
        }
    }

    private var mealTypeColor: Color {
        switch mealType.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .gray
        }
    }

    private var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Group Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(mealTypeColor.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: mealTypeIcon)
                            .font(.system(size: 16))
                            .foregroundColor(mealTypeColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(mealType.capitalized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("\(meals.count) meal\(meals.count == 1 ? "" : "s") • \(totalCalories) cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
            }
            .buttonStyle(.plain)

            // Expanded meals
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(meals) { meal in
                        CollapsibleMealRow(
                            meal: meal,
                            onTap: { onTap(meal) },
                            onLog: { onLog(meal) }
                        )
                    }
                }
                .padding(.top, 8)
                .padding(.leading, 48)
            }
        }
    }
}

// MARK: - Collapsible Meal Row (within group)

struct CollapsibleMealRow: View {
    let meal: PlannedMeal
    let onTap: () -> Void
    let onLog: () -> Void

    @State private var showLogConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Meal image or placeholder
            if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("\(meal.calories) cal • P:\(Int(meal.proteinG))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Log button
            Button {
                showLogConfirmation = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)

            // Info button
            Button {
                onTap()
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
        .confirmationDialog("Log \(meal.name)?", isPresented: $showLogConfirmation, titleVisibility: .visible) {
            Button("Log Meal") {
                onLog()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(meal.calories) calories • \(Int(meal.proteinG))g protein")
        }
    }
}

// MARK: - Collapsible Meal Section

struct CollapsibleMealSection: View {
    let meal: PlannedMeal
    let onTap: () -> Void
    let onLog: () -> Void

    @State private var isExpanded = false
    @State private var showLogConfirmation = false

    private var mealIcon: String {
        switch meal.type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snack": return "carrot.fill"
        default: return "fork.knife"
        }
    }

    private var mealColor: Color {
        switch meal.type.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .gray
        }
    }

    private var hasIngredients: Bool {
        meal.ingredients != nil && !meal.ingredients!.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Row (always visible)
            HStack(spacing: 12) {
                // Icon - same style as workout
                Circle()
                    .fill(mealColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: mealIcon)
                            .font(.system(size: 18))
                            .foregroundColor(mealColor)
                    )

                // Details
                VStack(alignment: .leading, spacing: 3) {
                    Text(meal.type.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(meal.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }

                Spacer()

                // Calories (like exercise count for workout)
                Text("\(meal.calories) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Log Button - same as workout
                Button {
                    showLogConfirmation = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            mealColor,
                            mealColor.opacity(0.2)
                        )
                }

                // Expand/Collapse chevron (always visible)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            // Expanded ingredients
            if isExpanded {
                Divider()
                    .padding(.horizontal, 12)

                if let ingredients = meal.ingredients, !ingredients.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(ingredients) { ingredient in
                            CollapsibleIngredientRow(ingredient: ingredient)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                } else {
                    // No ingredients message
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Ingredients not available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        .confirmationDialog(
            "Log \(meal.name)?",
            isPresented: $showLogConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log This Meal") {
                onLog()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(meal.calories) cal • \(Int(meal.proteinG))g protein")
        }
    }
}

// MARK: - Collapsible Ingredient Row

struct CollapsibleIngredientRow: View {
    let ingredient: RecipeIngredient

    var body: some View {
        HStack(spacing: 10) {
            // Small icon
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                )

            // Name
            Text(ingredient.item)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            // Amount
            Text(ingredient.amount)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(6)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Planned Meal Row (Legacy)

struct PlannedMealRow: View {
    let meal: PlannedMeal
    let onTap: () -> Void
    let onLog: () -> Void

    var body: some View {
        CollapsibleMealSection(meal: meal, onTap: onTap, onLog: onLog)
    }
}

// MARK: - Empty Meal Row

struct EmptyMealRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                )

            Text("No meals scheduled for today")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Planned Workout Row

struct PlannedWorkoutRow: View {
    let workout: WorkoutPlanDay
    let completing: Bool
    let onTap: () -> Void
    let onStart: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        workout.isCompleted
                            ? AnyShapeStyle(Color.green.opacity(0.15))
                            : AnyShapeStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .frame(width: 44, height: 44)

                if workout.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }

            // Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Workout")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if workout.isCompleted {
                        Text("Done")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Text(workout.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            Spacer()

            // Tap indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)

            // Duration & Exercises
            VStack(alignment: .trailing, spacing: 2) {
                if let duration = workout.estimatedDurationMin {
                    Text("\(duration) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("\(workout.exercises.count) exercises")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Action Buttons
            if !workout.isCompleted {
                HStack(spacing: 8) {
                    // Complete Button
                    Button {
                        onComplete()
                    } label: {
                        if completing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 70)
                        } else {
                            Text("Complete")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .buttonStyle(BounceButtonStyle())
                    .disabled(completing)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(workout.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Collapsible Workout Section

struct CollapsibleWorkoutSection: View {
    let workout: WorkoutPlanDay
    let completing: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var isExpanded = true
    @State private var selectedExercise: PlannedExercise?

    var body: some View {
        VStack(spacing: 0) {
            // Header Row (always visible) - matches PlannedMealRow style
            HStack(spacing: 12) {
                // Icon - same style as meals
                Circle()
                    .fill(workout.isCompleted ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: workout.isCompleted ? "checkmark" : "dumbbell.fill")
                            .font(.system(size: 18, weight: workout.isCompleted ? .bold : .regular))
                            .foregroundColor(workout.isCompleted ? .green : .blue)
                    )

                // Details - same layout as meals
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Workout")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if workout.isCompleted {
                            Text("Done")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    Text(workout.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }

                Spacer()

                // Exercise count (like calories for meals)
                Text("\(workout.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Log/Complete Button - same as meal's plus button
                Button {
                    onComplete()
                } label: {
                    if completing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: workout.isCompleted ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                workout.isCompleted ? Color.green : Color.blue,
                                workout.isCompleted ? Color.green.opacity(0.2) : Color.blue.opacity(0.2)
                            )
                    }
                }
                .disabled(workout.isCompleted)

                // Expand/Collapse chevron
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }

            // Expanded exercises
            if isExpanded && !workout.exercises.isEmpty {
                Divider()
                    .padding(.horizontal, 12)

                VStack(spacing: 6) {
                    ForEach(workout.exercises) { exercise in
                        CollapsibleExerciseRow(
                            exercise: exercise,
                            isWorkoutCompleted: workout.isCompleted,
                            onTap: { selectedExercise = exercise },
                            onComplete: {
                                // Haptic feedback when exercise is completed
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            }
                        )
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        .sheet(item: $selectedExercise) { exercise in
            QuickExerciseCard(exercise: exercise)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Collapsible Exercise Row

struct CollapsibleExerciseRow: View {
    let exercise: PlannedExercise
    let isWorkoutCompleted: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var isExerciseCompleted = false
    @State private var showCompleteConfirmation = false

    private var isCompleted: Bool {
        isWorkoutCompleted || isExerciseCompleted
    }

    private var exerciseColor: Color {
        if isCompleted { return .green }
        switch exercise.targetMuscle?.lowercased() ?? "" {
        case "chest", "pectorals": return .red
        case "back", "lats", "upper back", "lower back": return .blue
        case "shoulders", "delts": return .orange
        case "arms", "biceps", "triceps", "forearms": return .purple
        case "legs", "quadriceps", "hamstrings", "glutes", "calves": return .green
        case "core", "abs", "abdominals", "waist": return .yellow
        default: return .blue
        }
    }

    private var exerciseIcon: String {
        switch exercise.targetMuscle?.lowercased() ?? "" {
        case "chest", "pectorals": return "figure.strengthtraining.traditional"
        case "back", "lats", "upper back", "lower back": return "figure.rowing"
        case "shoulders", "delts": return "figure.arms.open"
        case "arms", "biceps", "triceps", "forearms": return "figure.boxing"
        case "legs", "quadriceps", "hamstrings", "glutes", "calves": return "figure.walk"
        case "core", "abs", "abdominals", "waist": return "figure.core.training"
        default: return "dumbbell.fill"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Small icon
            Circle()
                .fill(exerciseColor.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: isCompleted ? "checkmark" : exerciseIcon)
                        .font(.system(size: 12, weight: isCompleted ? .bold : .regular))
                        .foregroundColor(exerciseColor)
                )

            // Name
            Text(exercise.name)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundColor(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted, color: .secondary)

            Spacer()

            // Sets x Reps
            if let sets = exercise.sets {
                Text("\(sets) x \(exercise.reps?.displayValue ?? "-")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(6)
            }

            // Complete Button
            Button {
                if !isCompleted {
                    showCompleteConfirmation = true
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(
                        exerciseColor,
                        exerciseColor.opacity(0.2)
                    )
            }
            .disabled(isCompleted)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .confirmationDialog(
            "Complete \(exercise.name)?",
            isPresented: $showCompleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Mark as Done") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExerciseCompleted = true
                }
                onComplete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let sets = exercise.sets {
                Text("\(sets) sets × \(exercise.reps?.displayValue ?? "-") reps")
            }
        }
    }
}

// MARK: - Quick Exercise Card

struct QuickExerciseCard: View {
    let exercise: PlannedExercise
    @Environment(\.dismiss) private var dismiss

    private var muscleColor: Color {
        switch exercise.targetMuscle?.lowercased() ?? "" {
        case "chest", "pectorals": return .red
        case "back", "lats", "upper back", "lower back": return .blue
        case "shoulders", "delts": return .orange
        case "arms", "biceps", "triceps", "forearms": return .purple
        case "legs", "quadriceps", "hamstrings", "glutes", "calves": return .green
        case "core", "abs", "abdominals", "waist": return .yellow
        default: return .blue
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Video/GIF Header (video preferred)
                ZStack(alignment: .topTrailing) {
                    if exercise.hasMedia {
                        ExerciseMediaView(exercise: exercise, height: 280)
                    } else {
                        exercisePlaceholder
                    }

                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .padding(12)
                }
                .background(Color(.systemGray6))

                VStack(spacing: 20) {
                    // Exercise Name & Muscle
                    VStack(spacing: 8) {
                        Text(exercise.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        if let muscle = exercise.targetMuscle {
                            Text(muscle.capitalized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(muscleColor)
                                .cornerRadius(20)
                        }
                    }

                    // Quick Stats Row
                    HStack(spacing: 24) {
                        if let sets = exercise.sets {
                            QuickStat(value: "\(sets)", label: "Sets")
                        }

                        if let reps = exercise.reps {
                            QuickStat(value: reps.displayValue, label: "Reps")
                        }

                        if let rest = exercise.restSec {
                            QuickStat(value: "\(rest)s", label: "Rest")
                        }

                        if let weight = exercise.weightSuggestion {
                            QuickStat(value: weight, label: "Weight")
                        }
                    }
                    .padding(.horizontal)

                    // Notes
                    if let notes = exercise.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Tips", systemImage: "lightbulb.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)

                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Instructions
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("How to do it", systemImage: "list.number")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 22, height: 22)
                                            .background(muscleColor)
                                            .clipShape(Circle())

                                        Text(instruction)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Secondary muscles
                    if let secondary = exercise.secondaryMuscles, !secondary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Also works")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(secondary, id: \.self) { muscle in
                                    Text(muscle.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(.tertiarySystemFill))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }

                    // Watch on YouTube button
                    Button {
                        openYouTubeSearch()
                    } label: {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(.red)
                            Text("Watch Tutorial on YouTube")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
        }
        .background(Color(.systemBackground))
    }

    private func openYouTubeSearch() {
        let query = "\(exercise.name) exercise tutorial how to"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://www.youtube.com/results?search_query=\(query)") {
            UIApplication.shared.open(url)
        }
    }

    private var exercisePlaceholder: some View {
        Rectangle()
            .fill(muscleColor.opacity(0.1))
            .frame(height: 200)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 50))
                        .foregroundColor(muscleColor.opacity(0.5))
                    Text(exercise.targetMuscle?.capitalized ?? "Exercise")
                        .font(.headline)
                        .foregroundColor(muscleColor)
                }
            )
    }
}

// MARK: - Quick Stat

struct QuickStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Workout Header Row (Legacy)

struct WorkoutHeaderRow: View {
    let workout: WorkoutPlanDay
    let completing: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    var body: some View {
        CollapsibleWorkoutSection(
            workout: workout,
            completing: completing,
            onTap: onTap,
            onComplete: onComplete
        )
    }
}

// MARK: - Planned Exercise Row (matches PlannedMealRow style)

struct PlannedExerciseRow: View {
    let exercise: PlannedExercise
    let isCompleted: Bool
    let onTap: () -> Void

    private var exerciseColor: Color {
        if isCompleted {
            return .green
        }
        // Color based on muscle group
        switch exercise.targetMuscle?.lowercased() ?? "" {
        case "chest", "pectorals": return .red
        case "back", "lats", "upper back", "lower back": return .blue
        case "shoulders", "delts": return .orange
        case "arms", "biceps", "triceps", "forearms": return .purple
        case "legs", "quadriceps", "hamstrings", "glutes", "calves": return .green
        case "core", "abs", "abdominals", "waist": return .yellow
        default: return .blue
        }
    }

    private var exerciseIcon: String {
        switch exercise.targetMuscle?.lowercased() ?? "" {
        case "chest", "pectorals": return "figure.strengthtraining.traditional"
        case "back", "lats", "upper back", "lower back": return "figure.rowing"
        case "shoulders", "delts": return "figure.arms.open"
        case "arms", "biceps", "triceps", "forearms": return "figure.boxing"
        case "legs", "quadriceps", "hamstrings", "glutes", "calves": return "figure.walk"
        case "core", "abs", "abdominals", "waist": return "figure.core.training"
        default: return "dumbbell.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon - same size as meal rows (44x44)
            Circle()
                .fill(exerciseColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Group {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: exerciseIcon)
                                .font(.system(size: 18))
                                .foregroundColor(exerciseColor)
                        }
                    }
                )

            // Details - matches meal row layout
            VStack(alignment: .leading, spacing: 3) {
                // Muscle group label (like meal type)
                if let muscle = exercise.targetMuscle {
                    Text(muscle.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Exercise name (like meal name)
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(isCompleted ? .secondary : .primary)
            }

            Spacer()

            // Sets x Reps info (like calories)
            if let sets = exercise.sets {
                Text("\(sets) x \(exercise.reps?.displayValue ?? "-")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            // Tap indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Rest Day Row

struct RestDayRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Rest Day")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            Text("Recover & recharge")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Create Plan Row

struct CreatePlanRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]

    var body: some View {
        NavigationLink {
            if title.contains("Meal") {
                MealPlanView()
            } else {
                WorkoutPlanView()
            }
        } label: {
            HStack(spacing: 12) {
                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Arrow
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

// MARK: - Quick Actions Row (Simplified 4 actions)

struct QuickActionsRow: View {
    let onLogMeal: () -> Void
    let onLogWorkout: () -> Void
    let onScanBarcode: () -> Void
    let onAskCoach: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "fork.knife",
                    title: "Log Meal",
                    color: .orange,
                    action: onLogMeal
                )

                QuickActionButton(
                    icon: "dumbbell.fill",
                    title: "Workout",
                    color: .blue,
                    action: onLogWorkout
                )

                QuickActionButton(
                    icon: "barcode.viewfinder",
                    title: "Scan",
                    color: .purple,
                    action: onScanBarcode
                )

                QuickActionButton(
                    icon: "bubble.left.fill",
                    title: "Coach",
                    color: .teal,
                    action: onAskCoach
                )
            }
        }
    }
}

/// Compact quick action button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(color)
                    )

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BounceButtonStyle())
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let gradient: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    // Icon circle - clean without glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Recent Activity Section

struct RecentActivitySection: View {
    let meals: [Meal]
    let workouts: [Workout]
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Recent Activity")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
            }
            .padding(.horizontal, 20)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(meals) { meal in
                        ActivityRow(
                            icon: meal.mealType?.icon ?? "fork.knife",
                            iconColor: .orange,
                            title: meal.items.first?.name ?? "Meal",
                            subtitle: meal.loggedAt.relativeTime,
                            trailing: "\(meal.calories ?? 0) cal"
                        )
                    }

                    ForEach(workouts) { workout in
                        ActivityRow(
                            icon: workout.workoutType?.icon ?? "figure.run",
                            iconColor: .blue,
                            title: workout.exercises.first?.name ?? "Workout",
                            subtitle: workout.loggedAt.relativeTime,
                            trailing: workout.durationMin.map { "\($0) min" } ?? ""
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let trailing: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(trailing)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Micronutrients Card

struct MicronutrientsCard: View {
    let sugar: Double
    let sugarTarget: Double
    let fiber: Double
    let fiberTarget: Double
    let sodium: Double
    let sodiumTarget: Double
    let saturatedFat: Double
    let saturatedFatTarget: Double
    let cholesterol: Double
    let cholesterolTarget: Double

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.headline)
                        .foregroundColor(.green)

                    Text("Micronutrients")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 12) {
                    MicronutrientRow(
                        name: "Sugar",
                        value: sugar,
                        target: sugarTarget,
                        unit: "g",
                        color: .pink,
                        icon: "cube.fill",
                        isWarning: sugar > sugarTarget
                    )

                    MicronutrientRow(
                        name: "Fiber",
                        value: fiber,
                        target: fiberTarget,
                        unit: "g",
                        color: .green,
                        icon: "leaf.fill",
                        isWarning: false
                    )

                    MicronutrientRow(
                        name: "Sodium",
                        value: sodium,
                        target: sodiumTarget,
                        unit: "mg",
                        color: .blue,
                        icon: "drop.fill",
                        isWarning: sodium > sodiumTarget
                    )

                    MicronutrientRow(
                        name: "Sat. Fat",
                        value: saturatedFat,
                        target: saturatedFatTarget,
                        unit: "g",
                        color: .orange,
                        icon: "flame.fill",
                        isWarning: saturatedFat > saturatedFatTarget
                    )

                    MicronutrientRow(
                        name: "Cholesterol",
                        value: cholesterol,
                        target: cholesterolTarget,
                        unit: "mg",
                        color: .red,
                        icon: "heart.fill",
                        isWarning: cholesterol > cholesterolTarget
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }
}

struct MicronutrientRow: View {
    let name: String
    let value: Double
    let target: Double
    let unit: String
    let color: Color
    let icon: String
    let isWarning: Bool

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.5) // Cap at 150% for visual
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                )

            // Name and progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(Int(value))/\(Int(target)) \(unit)")
                        .font(.caption)
                        .foregroundColor(isWarning ? .red : .secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(isWarning ? Color.red : color)
                            .frame(width: geometry.size.width * min(progress, 1.0))
                    }
                }
                .frame(height: 6)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView(onSuggestMeal: {})
        .environmentObject(AppState())
}
