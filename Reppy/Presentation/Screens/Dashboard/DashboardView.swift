import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    var onSuggestMeal: (() -> Void)?

    @State private var isReady = false
    @State private var showWorkoutLogger = false
    @State private var showMealLogger = false
    @State private var showBarcodeScanner = false
    @State private var showQuickAddCalories = false
    @State private var showCreateFoodFromBarcode = false
    @State private var scannedBarcode: String?
    @State private var createPlanType: PlanType?
    @State private var showCycleLogger = false
    @State private var showCycleDetails = false
    @State private var showMicronutrientDetail = false
    @State private var showSupplements = false
    @State private var showBloodWork = false
    private let impactLight = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    if isReady {
                        content
                            .id("content")
                    } else {
                        skeletonContent
                            .id("skeleton")
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
                await viewModel.quickRefresh()
            }
            .task {
                impactLight.prepare()
                await viewModel.loadData()
                withAnimation(.easeOut(duration: 0.2)) {
                    isReady = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .mealLogged)) { _ in
                Task { await viewModel.quickRefresh() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .workoutLogged)) { _ in
                Task { await viewModel.quickRefresh() }
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
            .sheet(item: $createPlanType) { planType in
                UnifiedPlanCreationSheet(
                    planType: planType,
                    apiClient: DependencyContainer.shared.apiClient,
                    chatRepository: DependencyContainer.shared.chatRepository,
                    appState: appState
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
            .sheet(isPresented: $showMicronutrientDetail) {
                if let profile = appState.userProfile {
                    NavigationStack {
                        MicronutrientProgressView(
                            profile: profile,
                            consumed: viewModel.vitaminMineralTotals,
                            targets: viewModel.vitaminMineralTargets
                        )
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showSupplements) {
                SupplementsView()
            }
            .sheet(isPresented: $showBloodWork) {
                BloodWorkView()
            }
        }
    }

    // MARK: - Main Content

    private var content: some View {
        VStack(spacing: 16) {
            // Compact Header
            compactHeader
                .padding(.horizontal, 20)

            // Hero Calories (Big remaining number)
            CompactCalorieHeader(
                consumed: viewModel.todayCalories,
                burned: viewModel.caloriesBurned,
                target: viewModel.calorieTarget
            )
            .padding(.horizontal, 20)

            // Macro Pills Row
            MacroPillsRow(
                protein: viewModel.todayProtein,
                proteinTarget: viewModel.proteinTarget,
                carbs: viewModel.todayCarbs,
                carbsTarget: viewModel.carbsTarget,
                fat: viewModel.todayFat,
                fatTarget: viewModel.fatTarget
            )
            .padding(.horizontal, 20)

            // Quick Actions Row
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
                }
            )
            .padding(.horizontal, 20)

            // Today Timeline
            TodayTimeline(
                plannedMeals: viewModel.todaysMeals,
                loggedMeals: viewModel.recentMeals.filter { $0.loggedAt.isToday },
                plannedWorkout: viewModel.todaysWorkout,
                loggedWorkouts: viewModel.recentWorkouts.filter { $0.loggedAt.isToday },
                onLogMeal: { meal in
                    Task { await viewModel.logPlannedMeal(meal) }
                },
                onDeleteMeal: { meal in
                    // Handle delete
                },
                onCompleteWorkout: {
                    Task { await viewModel.completeWorkout() }
                }
            )
            .padding(.horizontal, 20)

            // Compact Stats Row
            CompactStatsRow(
                steps: viewModel.todaySteps,
                stepsGoal: viewModel.stepsGoal,
                caloriesBurned: viewModel.caloriesBurned,
                streakDays: viewModel.streakInfo?.currentStreak ?? 0
            )
            .padding(.horizontal, 20)

            // Expandable More Section
            ExpandableMoreSection(
                fiber: viewModel.todayFiber,
                fiberTarget: viewModel.fiberTarget,
                sugar: viewModel.todaySugar,
                sugarLimit: viewModel.sugarTarget,
                sodium: viewModel.todaySodium,
                sodiumLimit: viewModel.sodiumTarget,
                saturatedFat: viewModel.todaySaturatedFat,
                saturatedFatLimit: viewModel.saturatedFatTarget,
                vitaminMineralTotals: viewModel.vitaminMineralTotals,
                vitaminMineralTargets: viewModel.vitaminMineralTargets,
                onSupplementsTap: {
                    impactLight.impactOccurred()
                    showSupplements = true
                },
                onBloodWorkTap: {
                    impactLight.impactOccurred()
                    showBloodWork = true
                },
                onCycleTap: viewModel.isFemaleUser ? {
                    impactLight.impactOccurred()
                    showCycleDetails = true
                } : nil,
                isFemale: viewModel.isFemaleUser
            )
            .padding(.horizontal, 20)

            // Create Plan Cards (only if no active plan)
            if viewModel.todaysMeals.isEmpty || viewModel.todaysWorkout == nil {
                createPlanPrompt
                    .padding(.horizontal, 20)
            }

            Spacer(minLength: 20)
        }
        .padding(.top, 8)
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            // Profile avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(viewModel.greeting.split(separator: ",").last?.trimmingCharacters(in: .whitespaces).prefix(1) ?? "U"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Create Plan Prompt

    private var createPlanPrompt: some View {
        VStack(spacing: 10) {
            if viewModel.todaysMeals.isEmpty {
                Button {
                    impactLight.impactOccurred()
                    createPlanType = .meal
                } label: {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.green)
                        Text("Create Meal Plan")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
            }

            if viewModel.todaysWorkout == nil {
                Button {
                    impactLight.impactOccurred()
                    createPlanType = .workout
                } label: {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.blue)
                        Text("Create Workout Plan")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
            }
        }
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

    // MARK: - Today's Section

    private var hasTodayData: Bool {
        let todayLoggedMeals = viewModel.recentMeals.filter { $0.loggedAt.isToday }
        let todayLoggedWorkouts = viewModel.recentWorkouts.filter { $0.loggedAt.isToday }
        return !viewModel.todaysMeals.isEmpty ||
               !todayLoggedMeals.isEmpty ||
               viewModel.todaysWorkout != nil ||
               !todayLoggedWorkouts.isEmpty
    }

    @ViewBuilder
    private var todaySection: some View {
        if hasTodayData {
            VStack(alignment: .leading, spacing: 14) {
                Text("Today")
                    .font(.headline)
                    .fontWeight(.semibold)

                TodayContentCard(
                    plannedMeals: viewModel.todaysMeals,
                    loggedMeals: viewModel.recentMeals.filter { $0.loggedAt.isToday },
                    plannedWorkout: viewModel.todaysWorkout,
                    loggedWorkouts: viewModel.recentWorkouts.filter { $0.loggedAt.isToday },
                    workoutPlan: viewModel.activeWorkoutPlan,
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
            }
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

// Shimmer effect disabled to prevent scroll issues
struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .opacity(0.6) // Simple opacity instead of shimmer animation
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

// MARK: - Today's Meals Card (Shows Planned + Logged)

struct TodaysMealsCard: View {
    let plannedMeals: [PlannedMeal]
    let loggedMeals: [Meal]
    let hasMealPlan: Bool
    let onLogMeal: (PlannedMeal) -> Void

    @State private var selectedPlannedMeal: PlannedMeal?
    @State private var showAllItems = false

    private let mealTypeOrder = ["breakfast", "lunch", "dinner", "snack"]

    /// Total calories from both planned (not yet logged) and logged meals
    private var totalLoggedCalories: Int {
        loggedMeals.reduce(0) { $0 + ($1.calories ?? 0) }
    }

    /// Get the next unlogged planned meal based on time of day
    private var nextPlannedMeal: PlannedMeal? {
        let hour = Calendar.current.component(.hour, from: Date())
        let currentMealType: String
        switch hour {
        case 0..<11: currentMealType = "breakfast"
        case 11..<15: currentMealType = "lunch"
        case 15..<18: currentMealType = "snack"
        default: currentMealType = "dinner"
        }

        let orderedTypes = mealTypeOrder.drop(while: { $0 != currentMealType }) + mealTypeOrder.prefix(while: { $0 != currentMealType })
        for mealType in orderedTypes {
            if let meal = plannedMeals.first(where: { $0.type.lowercased() == mealType }) {
                return meal
            }
        }
        return plannedMeals.first
    }

    /// Remaining planned meals (excluding next)
    private var remainingPlannedMeals: [PlannedMeal] {
        guard let next = nextPlannedMeal else { return plannedMeals }
        return plannedMeals.filter { $0.id != next.id }
    }

    /// Check if we have any content to show
    private var hasContent: Bool {
        !plannedMeals.isEmpty || !loggedMeals.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "fork.knife")
                    .font(.headline)
                    .foregroundColor(.green)

                Text("Today's Food")
                    .font(.headline)

                Spacer()

                if hasContent {
                    Text("\(totalLoggedCalories) cal logged")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if hasContent {
                VStack(spacing: 10) {
                    // Logged meals section (what you've eaten)
                    if !loggedMeals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LOGGED")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)

                            ForEach(loggedMeals.prefix(showAllItems ? loggedMeals.count : 3)) { meal in
                                LoggedMealRow(meal: meal)
                            }
                        }
                    }

                    // Next planned meal (if any)
                    if let next = nextPlannedMeal {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("UP NEXT")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)

                            NextMealCard(
                                meal: next,
                                onTap: { selectedPlannedMeal = next },
                                onLog: { onLogMeal(next) }
                            )
                        }
                    }

                    // Remaining planned meals
                    if !remainingPlannedMeals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PLANNED")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            ForEach(remainingPlannedMeals.prefix(showAllItems ? remainingPlannedMeals.count : 2)) { meal in
                                CompactMealRow(
                                    meal: meal,
                                    onTap: { selectedPlannedMeal = meal },
                                    onLog: { onLogMeal(meal) }
                                )
                            }
                        }
                    }

                    // Show more/less toggle
                    let totalItems = loggedMeals.count + plannedMeals.count
                    if totalItems > 4 {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showAllItems.toggle()
                            }
                        } label: {
                            HStack {
                                Text(showAllItems ? "Show less" : "Show all \(totalItems) items")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)

                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                                    .rotationEffect(.degrees(showAllItems ? 180 : 0))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else if hasMealPlan {
                // Has plan but nothing for today
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No meals planned today")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Log food via chat or quick add")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
            } else {
                // No meal plan at all
                NavigationLink {
                    MealPlanView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create Meal Plan")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Get personalized daily meals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .sheet(item: $selectedPlannedMeal) { meal in
            MealDetailSheet(meal: meal)
        }
    }
}

// MARK: - Logged Meal Row (for meals already eaten)

struct LoggedMealRow: View {
    let meal: Meal
    @State private var showDetails = false

    private var mealTypeIcon: String {
        switch meal.mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        case .none: return "fork.knife"
        }
    }

    private var mealTypeColor: Color {
        switch meal.mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .green
        case .none: return .gray
        }
    }

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

        if validItems.count == 1 {
            return validItems[0].name
        }

        // Multiple items - show first 2 names
        let names = validItems.prefix(2).map { $0.name }
        let suffix = validItems.count > 2 ? " +\(validItems.count - 2)" : ""
        return names.joined(separator: ", ") + suffix
    }

    private var hasMicronutrients: Bool {
        (meal.fiberGEst ?? 0) > 0 || (meal.sugarGEst ?? 0) > 0 ||
        (meal.vitaminCMgEst ?? 0) > 0 || (meal.ironMgEst ?? 0) > 0
    }

    var body: some View {
        Button {
            showDetails = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Top row: Name, meal type, time
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }

                    Text(displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if meal.mealType != nil {
                        Image(systemName: mealTypeIcon)
                            .font(.caption2)
                            .foregroundColor(mealTypeColor)
                    }

                    Spacer()

                    Text(meal.loggedAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Macro row
                HStack(spacing: 0) {
                    // Calories badge
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(meal.calories ?? 0)")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(6)

                    Spacer().frame(width: 8)

                    // Macros
                    HStack(spacing: 10) {
                        MacroTag(label: "P", value: Int(meal.proteinG ?? 0), color: .blue)
                        MacroTag(label: "C", value: Int(meal.carbsG ?? 0), color: .green)
                        MacroTag(label: "F", value: Int(meal.fatG ?? 0), color: .pink)

                        if let fiber = meal.fiberGEst, fiber > 0 {
                            MacroTag(label: "Fib", value: Int(fiber), color: .mint)
                        }
                    }

                    Spacer()

                    // Expand indicator
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.green.opacity(0.06))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetails) {
            LoggedMealDetailSheet(meal: meal)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Macro Tag (Compact for logged meals)

private struct MacroTag: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .fontWeight(.semibold)
            Text("\(value)g")
        }
        .font(.caption2)
        .foregroundColor(color)
    }
}

// MARK: - Logged Meal Detail Sheet

struct LoggedMealDetailSheet: View {
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
                    // Header with items
                    VStack(alignment: .leading, spacing: 8) {
                        if !meal.items.isEmpty {
                            ForEach(meal.items) { item in
                                HStack {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(item.name)
                                        .font(.body)
                                    if let qty = item.quantity, let unit = item.unit {
                                        Text("(\(Int(qty)) \(unit))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }

                        Text(meal.loggedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // Main Macros
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Macros")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            NutrientStatCell(label: "Calories", value: "\(meal.calories ?? 0)", unit: "", color: .orange, icon: "flame.fill")
                            NutrientStatCell(label: "Protein", value: "\(Int(meal.proteinG ?? 0))", unit: "g", color: .blue, icon: "p.circle.fill")
                            NutrientStatCell(label: "Carbs", value: "\(Int(meal.carbsG ?? 0))", unit: "g", color: .green, icon: "c.circle.fill")
                            NutrientStatCell(label: "Fat", value: "\(Int(meal.fatG ?? 0))", unit: "g", color: .pink, icon: "f.circle.fill")
                        }
                    }

                    // Additional nutrients to watch
                    if (meal.fiberGEst ?? 0) > 0 || (meal.sugarGEst ?? 0) > 0 ||
                       (meal.sodiumMgEst ?? 0) > 0 || (meal.saturatedFatGEst ?? 0) > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                if let fiber = meal.fiberGEst, fiber > 0 {
                                    NutrientStatCell(label: "Fiber", value: "\(Int(fiber))", unit: "g", color: .mint, icon: "leaf.fill")
                                }
                                if let sugar = meal.sugarGEst, sugar > 0 {
                                    NutrientStatCell(label: "Sugar", value: "\(Int(sugar))", unit: "g", color: .purple, icon: "cube.fill")
                                }
                                if let sodium = meal.sodiumMgEst, sodium > 0 {
                                    NutrientStatCell(label: "Sodium", value: "\(Int(sodium))", unit: "mg", color: .gray, icon: "drop.fill")
                                }
                                if let satFat = meal.saturatedFatGEst, satFat > 0 {
                                    NutrientStatCell(label: "Sat Fat", value: "\(Int(satFat))", unit: "g", color: .red, icon: "exclamationmark.triangle.fill")
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
                                    if let vitA = meal.vitaminAMcgEst, vitA > 0 {
                                        MicroBadge(name: "Vitamin A", value: "\(Int(vitA)) mcg")
                                    }
                                    if let vitC = meal.vitaminCMgEst, vitC > 0 {
                                        MicroBadge(name: "Vitamin C", value: "\(Int(vitC)) mg")
                                    }
                                    if let vitD = meal.vitaminDMcgEst, vitD > 0 {
                                        MicroBadge(name: "Vitamin D", value: String(format: "%.1f mcg", vitD))
                                    }
                                    if let vitB12 = meal.vitaminB12McgEst, vitB12 > 0 {
                                        MicroBadge(name: "Vitamin B12", value: String(format: "%.1f mcg", vitB12))
                                    }
                                    if let vitE = meal.vitaminEMgEst, vitE > 0 {
                                        MicroBadge(name: "Vitamin E", value: String(format: "%.1f mg", vitE))
                                    }
                                    if let vitK = meal.vitaminKMcgEst, vitK > 0 {
                                        MicroBadge(name: "Vitamin K", value: "\(Int(vitK)) mcg")
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
                                    if let calcium = meal.calciumMgEst, calcium > 0 {
                                        MicroBadge(name: "Calcium", value: "\(Int(calcium)) mg")
                                    }
                                    if let iron = meal.ironMgEst, iron > 0 {
                                        MicroBadge(name: "Iron", value: String(format: "%.1f mg", iron))
                                    }
                                    if let potassium = meal.potassiumMgEst, potassium > 0 {
                                        MicroBadge(name: "Potassium", value: "\(Int(potassium)) mg")
                                    }
                                    if let magnesium = meal.magnesiumMgEst, magnesium > 0 {
                                        MicroBadge(name: "Magnesium", value: "\(Int(magnesium)) mg")
                                    }
                                    if let zinc = meal.zincMgEst, zinc > 0 {
                                        MicroBadge(name: "Zinc", value: String(format: "%.1f mg", zinc))
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle(meal.mealType?.displayName ?? "Meal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Nutrient Stat Cell

private struct NutrientStatCell: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value + unit)
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

// MARK: - Micro Badge

private struct MicroBadge: View {
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

// MARK: - Next Meal Card (Prominent)

struct NextMealCard: View {
    let meal: PlannedMeal
    let onTap: () -> Void
    let onLog: () -> Void

    private var mealTypeIcon: String {
        switch meal.type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snack": return "carrot.fill"
        default: return "fork.knife"
        }
    }

    private var mealTypeColor: Color {
        switch meal.type.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main content - tappable for details
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Meal image or icon
                    if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            mealIconView
                        }
                        .frame(width: 56, height: 56)
                        .cornerRadius(12)
                    } else {
                        mealIconView
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(meal.type.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(mealTypeColor)

                            Text("• Next up")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(meal.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        // Macro breakdown
                        HStack(spacing: 10) {
                            HStack(spacing: 2) {
                                Image(systemName: "flame")
                                    .font(.caption2)
                                Text("\(meal.calories)")
                            }
                            .foregroundColor(.orange)

                            HStack(spacing: 2) {
                                Text("P")
                                    .fontWeight(.semibold)
                                Text("\(Int(meal.proteinG))g")
                            }
                            .foregroundColor(.blue)

                            HStack(spacing: 2) {
                                Text("C")
                                    .fontWeight(.semibold)
                                Text("\(Int(meal.carbsG))g")
                            }
                            .foregroundColor(.green)

                            HStack(spacing: 2) {
                                Text("F")
                                    .fontWeight(.semibold)
                                Text("\(Int(meal.fatG))g")
                            }
                            .foregroundColor(.pink)
                        }
                        .font(.caption)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.vertical, 10)

            // Log button
            Button(action: onLog) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.subheadline)
                    Text("Log this meal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var mealIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(mealTypeColor.opacity(0.12))
                .frame(width: 52, height: 52)

            Image(systemName: mealTypeIcon)
                .font(.title3)
                .foregroundColor(mealTypeColor)
        }
    }
}

// MARK: - Compact Meal Row (for remaining meals)

struct CompactMealRow: View {
    let meal: PlannedMeal
    let onTap: () -> Void
    let onLog: () -> Void

    private var mealTypeIcon: String {
        switch meal.type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.stars.fill"
        case "snack": return "leaf.fill"
        default: return "fork.knife"
        }
    }

    private var mealTypeColor: Color {
        switch meal.type.lowercased() {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .purple
        case "snack": return .green
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: mealTypeIcon)
                .font(.caption)
                .foregroundColor(mealTypeColor)
                .frame(width: 16)

            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "flame")
                            Text("\(meal.calories)")
                        }
                        .foregroundColor(.orange)

                        Text("P:\(Int(meal.proteinG))g")
                            .foregroundColor(.blue)
                    }
                    .font(.caption2)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onLog) {
                Image(systemName: "plus.circle")
                    .font(.body)
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Dashboard Workout Card (Separate)

struct DashboardWorkoutCard: View {
    let plannedWorkout: WorkoutPlanDay?
    let loggedWorkouts: [Workout]
    let workoutPlan: WorkoutPlan?
    let hasWorkoutPlan: Bool
    let completing: Bool
    let onComplete: () -> Void

    @State private var selectedWorkout: WorkoutPlanDay?
    @State private var showWeekView = false
    @State private var showAllLogged = false

    /// Total calories burned from logged workouts
    private var totalCaloriesBurned: Int {
        loggedWorkouts.reduce(0) { $0 + ($1.caloriesBurnedEst ?? 0) }
    }

    /// Check if we have any content
    private var hasContent: Bool {
        plannedWorkout != nil || !loggedWorkouts.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .font(.headline)
                    .foregroundColor(.orange)

                Text("Today's Activity")
                    .font(.headline)

                Spacer()

                if hasContent {
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .font(.caption2)
                        Text("\(totalCaloriesBurned) cal")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }

            if hasContent {
                VStack(spacing: 10) {
                    // Logged workouts section
                    if !loggedWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COMPLETED")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)

                            ForEach(loggedWorkouts.prefix(showAllLogged ? loggedWorkouts.count : 2)) { workout in
                                LoggedWorkoutRow(workout: workout)
                            }
                        }
                    }

                    // Planned workout
                    if let workout = plannedWorkout {
                        if workout.isCompleted {
                            // Already completed from plan
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FROM PLAN")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)

                                CompletedWorkoutRow(workout: workout) {
                                    selectedWorkout = workout
                                }
                            }
                        } else {
                            // Next planned workout
                            VStack(alignment: .leading, spacing: 8) {
                                Text("UP NEXT")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)

                                PlannedWorkoutCard(
                                    workout: workout,
                                    completing: completing,
                                    onTap: { selectedWorkout = workout },
                                    onComplete: onComplete
                                )
                            }
                        }
                    }

                    // Show more toggle
                    if loggedWorkouts.count > 2 {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showAllLogged.toggle()
                            }
                        } label: {
                            HStack {
                                Text(showAllLogged ? "Show less" : "Show all \(loggedWorkouts.count) workouts")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)

                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                                    .rotationEffect(.degrees(showAllLogged ? 180 : 0))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else if hasWorkoutPlan {
                // Rest day
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "moon.zzz.fill")
                            .font(.body)
                            .foregroundColor(.purple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rest Day")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Recovery is part of the plan")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color.purple.opacity(0.06))
                .cornerRadius(12)
            } else {
                // No workout plan
                NavigationLink {
                    WorkoutPlanView()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 44, height: 44)

                            Image(systemName: "plus")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create Workout Plan")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Get a personalized program")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }

            // Week view button
            if hasWorkoutPlan {
                Button {
                    showWeekView = true
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("View This Week")
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
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

// MARK: - Logged Workout Row

struct LoggedWorkoutRow: View {
    let workout: Workout

    private var workoutIcon: String {
        workout.workoutType?.icon ?? "figure.strengthtraining.traditional"
    }

    private var displayName: String {
        if let type = workout.workoutType {
            return type.displayName
        }
        if let firstExercise = workout.exercises.first {
            return firstExercise.name
        }
        return "Workout"
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let duration = workout.durationMin {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                            Text("\(duration) min")
                        }
                    }
                    if let calories = workout.caloriesBurnedEst, calories > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame")
                            Text("\(calories) cal")
                        }
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            Text(workout.loggedAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.06))
        .cornerRadius(10)
    }
}

// MARK: - Completed Workout Row (from plan)

struct CompletedWorkoutRow: View {
    let workout: WorkoutPlanDay
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("\(workout.exercises.count) exercises")
                        if let duration = workout.estimatedDurationMin {
                            Text("•")
                            Text("\(duration) min")
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.06))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Planned Workout Card

struct PlannedWorkoutCard: View {
    let workout: WorkoutPlanDay
    let completing: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    private var estimatedCalories: Int {
        // Rough estimate: ~7 cal per minute of strength training
        (workout.estimatedDurationMin ?? 45) * 7
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.body)
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(spacing: 8) {
                            HStack(spacing: 3) {
                                Image(systemName: "list.bullet")
                                Text("\(workout.exercises.count)")
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                Text("\(workout.estimatedDurationMin ?? 45) min")
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "flame")
                                Text("~\(estimatedCalories) cal")
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.vertical, 10)

            Button(action: onComplete) {
                HStack(spacing: 6) {
                    if completing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .font(.subheadline)
                        Text("Mark Complete")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(completing)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Legacy TodaysPlanSection (kept for compatibility, now uses new components)

struct TodaysPlanSection: View {
    let plannedMeals: [PlannedMeal]
    let loggedMeals: [Meal]
    let plannedWorkout: WorkoutPlanDay?
    let loggedWorkouts: [Workout]
    let workoutPlan: WorkoutPlan?
    let hasMealPlan: Bool
    let hasWorkoutPlan: Bool
    let completingWorkout: Bool
    let onLogMeal: (PlannedMeal) -> Void
    let onStartWorkout: () -> Void
    let onCompleteWorkout: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Meals Card
            TodaysMealsCard(
                plannedMeals: plannedMeals,
                loggedMeals: loggedMeals,
                hasMealPlan: hasMealPlan,
                onLogMeal: onLogMeal
            )

            // Workout Card
            DashboardWorkoutCard(
                plannedWorkout: plannedWorkout,
                loggedWorkouts: loggedWorkouts,
                workoutPlan: workoutPlan,
                hasWorkoutPlan: hasWorkoutPlan,
                completing: completingWorkout,
                onComplete: onCompleteWorkout
            )
        }
    }
}

// MARK: - Today Content Card (Unified)

struct TodayContentCard: View {
    let plannedMeals: [PlannedMeal]
    let loggedMeals: [Meal]
    let plannedWorkout: WorkoutPlanDay?
    let loggedWorkouts: [Workout]
    let workoutPlan: WorkoutPlan?
    let completingWorkout: Bool
    let onLogMeal: (PlannedMeal) -> Void
    let onStartWorkout: () -> Void
    let onCompleteWorkout: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Meals subsection
            if !plannedMeals.isEmpty || !loggedMeals.isEmpty {
                TodayMealsSubsection(
                    plannedMeals: plannedMeals,
                    loggedMeals: loggedMeals,
                    onLogMeal: onLogMeal
                )
            }

            // Workout subsection
            if plannedWorkout != nil || !loggedWorkouts.isEmpty {
                TodayWorkoutSubsection(
                    plannedWorkout: plannedWorkout,
                    loggedWorkouts: loggedWorkouts,
                    workoutPlan: workoutPlan,
                    completing: completingWorkout,
                    onComplete: onCompleteWorkout
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct TodayMealsSubsection: View {
    let plannedMeals: [PlannedMeal]
    let loggedMeals: [Meal]
    let onLogMeal: (PlannedMeal) -> Void

    private var totalCalories: Int {
        loggedMeals.reduce(0) { $0 + Int($1.calories ?? 0) }
    }

    private var displayMeals: [PlannedMeal] {
        Array(plannedMeals.prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            mealsHeader
            loggedMealsSummary
            plannedMealsList
        }
    }

    private var mealsHeader: some View {
        HStack {
            Image(systemName: "fork.knife")
                .foregroundColor(.orange)
            Text("Meals")
                .font(.subheadline.weight(.semibold))
            Spacer()
            if !loggedMeals.isEmpty {
                Text("\(loggedMeals.count) logged")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var loggedMealsSummary: some View {
        if !loggedMeals.isEmpty {
            HStack(spacing: 8) {
                ForEach(Array(loggedMeals.prefix(3))) { meal in
                    MealTypeCircle(mealType: meal.mealType)
                }
                if loggedMeals.count > 3 {
                    Text("+\(loggedMeals.count - 3)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(totalCalories) cal")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.orange)
            }
        }
    }

    @ViewBuilder
    private var plannedMealsList: some View {
        if !displayMeals.isEmpty {
            ForEach(displayMeals) { meal in
                TodayPlannedMealRow(meal: meal, onLog: { onLogMeal(meal) })
            }
        }
    }
}

struct MealTypeCircle: View {
    let mealType: MealType?

    var body: some View {
        Text(String(mealType?.rawValue.first ?? "M").uppercased())
            .font(.caption2.weight(.bold))
            .frame(width: 24, height: 24)
            .background(Color.orange.opacity(0.2))
            .foregroundColor(.orange)
            .clipShape(Circle())
    }
}

struct TodayPlannedMealRow: View {
    let meal: PlannedMeal
    let onLog: () -> Void
    var onDelete: (() -> Void)?

    @State private var offset: CGFloat = 0
    @State private var showDelete = false

    private let deleteThreshold: CGFloat = -80

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            if offset < 0 {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            onDelete?()
                        }
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .frame(width: 60, height: 44)
                    }
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }

            // Main content
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.type.capitalized)
                        .font(.caption.weight(.medium))
                    Text(meal.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: onLog) {
                    Text("Log")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(10)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < deleteThreshold {
                                offset = -70
                                showDelete = true
                            } else {
                                offset = 0
                                showDelete = false
                            }
                        }
                    }
            )
            .onTapGesture {
                withAnimation(.spring()) {
                    offset = 0
                    showDelete = false
                }
            }
        }
    }
}

struct TodayWorkoutSubsection: View {
    let plannedWorkout: WorkoutPlanDay?
    let loggedWorkouts: [Workout]
    let workoutPlan: WorkoutPlan?
    let completing: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            workoutHeader
            loggedWorkoutsList
            plannedWorkoutRow
        }
    }

    private var workoutHeader: some View {
        HStack {
            Image(systemName: "dumbbell.fill")
                .foregroundColor(.blue)
            Text("Workout")
                .font(.subheadline.weight(.semibold))
            Spacer()
            if !loggedWorkouts.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }

    @ViewBuilder
    private var loggedWorkoutsList: some View {
        if !loggedWorkouts.isEmpty {
            ForEach(Array(loggedWorkouts.prefix(2))) { workout in
                TodayLoggedWorkoutRow(workout: workout)
            }
        }
    }

    @ViewBuilder
    private var plannedWorkoutRow: some View {
        if let workout = plannedWorkout, !workout.isCompleted {
            TodayPlannedWorkoutRow(
                workout: workout,
                completing: completing,
                onComplete: onComplete
            )
        }
    }
}

struct TodayLoggedWorkoutRow: View {
    let workout: Workout

    private var workoutName: String {
        if let type = workout.workoutType {
            return type.rawValue.capitalized
        }
        if let firstExercise = workout.exercises.first {
            return firstExercise.name
        }
        return "Workout"
    }

    var body: some View {
        HStack {
            Text(workoutName)
                .font(.caption.weight(.medium))
            Spacer()
            if let duration = workout.durationMin {
                Text("\(duration) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let cal = workout.caloriesBurnedEst {
                Text("\(cal) cal")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
}

struct TodayPlannedWorkoutRow: View {
    let workout: WorkoutPlanDay
    let completing: Bool
    let onComplete: () -> Void
    var onDeleteExercise: ((String) -> Void)?

    private var musclesText: String {
        guard let muscles = workout.targetMuscles, !muscles.isEmpty else { return "" }
        return Array(muscles.prefix(2)).joined(separator: ", ").capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.displayName)
                        .font(.caption.weight(.semibold))
                    if !musclesText.isEmpty {
                        Text(musclesText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if let duration = workout.estimatedDurationMin {
                    Text("\(duration) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Exercises list with swipe-to-delete
            if !workout.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(workout.exercises.prefix(5)) { exercise in
                        SwipeableExerciseRow(
                            exercise: exercise,
                            onDelete: onDeleteExercise != nil ? {
                                onDeleteExercise?(exercise.name)
                            } : nil
                        )
                    }
                    if workout.exercises.count > 5 {
                        Text("+\(workout.exercises.count - 5) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)
                    }
                }
                .padding(.vertical, 4)
            }

            // Complete button
            HStack {
                Spacer()
                completeButton
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var completeButton: some View {
        Button(action: onComplete) {
            Group {
                if completing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Complete")
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
        .disabled(completing)
    }
}

// MARK: - Swipeable Exercise Row

struct SwipeableExerciseRow: View {
    let exercise: PlannedExercise
    var onDelete: (() -> Void)?

    @State private var offset: CGFloat = 0

    private let deleteThreshold: CGFloat = -60

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            if offset < 0 && onDelete != nil {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            onDelete?()
                        }
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 24)
                    }
                    .background(Color.red)
                    .cornerRadius(6)
                }
            }

            // Main content
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 6, height: 6)
                Text(exercise.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Text(exercise.setsRepsDisplay)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
            .background(Color(.systemBackground))
            .offset(x: offset)
            .gesture(
                onDelete != nil ?
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < deleteThreshold {
                                offset = -50
                            } else {
                                offset = 0
                            }
                        }
                    }
                : nil
            )
            .onTapGesture {
                withAnimation(.spring()) {
                    offset = 0
                }
            }
        }
    }
}

// MARK: - Action Buttons Section

struct ActionButtonsSection: View {
    let onLogMeal: () -> Void
    let onLogWorkout: () -> Void
    let onCreateMealPlan: () -> Void
    let onCreateWorkoutPlan: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Log Actions Row
            HStack(spacing: 12) {
                DashboardActionButton(
                    icon: "fork.knife",
                    title: "Log Meal",
                    color: .orange,
                    action: onLogMeal
                )

                DashboardActionButton(
                    icon: "dumbbell.fill",
                    title: "Log Workout",
                    color: .blue,
                    action: onLogWorkout
                )
            }

            // Create Plan Actions Row
            HStack(spacing: 12) {
                DashboardActionButton(
                    icon: "calendar.badge.plus",
                    title: "Create Meal Plan",
                    color: .green,
                    action: onCreateMealPlan
                )

                DashboardActionButton(
                    icon: "figure.run",
                    title: "Create Workout Plan",
                    color: .purple,
                    action: onCreateWorkoutPlan
                )
            }
        }
    }
}

struct DashboardActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(BounceButtonStyle())
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

// MARK: - Daily Limits Card (things to stay UNDER)

struct DailyLimitsCard: View {
    let sugar: Double
    let sugarLimit: Double
    let sodium: Double
    let sodiumLimit: Double
    let saturatedFat: Double
    let saturatedFatLimit: Double
    let cholesterol: Double
    let cholesterolLimit: Double

    @State private var isExpanded = false

    /// Overall status - how many limits are exceeded
    private var exceededCount: Int {
        var count = 0
        if sugar > sugarLimit { count += 1 }
        if sodium > sodiumLimit { count += 1 }
        if saturatedFat > saturatedFatLimit { count += 1 }
        if cholesterol > cholesterolLimit { count += 1 }
        return count
    }

    private var statusColor: Color {
        if exceededCount > 0 { return .red }
        let avgUsage = (sugar/sugarLimit + sodium/sodiumLimit + saturatedFat/saturatedFatLimit + cholesterol/cholesterolLimit) / 4
        if avgUsage > 0.8 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundColor(statusColor)

                    Text("Daily Limits")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Status badge
                    if exceededCount > 0 {
                        Text("\(exceededCount) over")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.red)
                            .cornerRadius(10)
                    } else {
                        Text("On track")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

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
                    LimitRow(
                        name: "Sugar",
                        value: sugar,
                        limit: sugarLimit,
                        unit: "g",
                        icon: "cube.fill"
                    )

                    LimitRow(
                        name: "Sodium",
                        value: sodium,
                        limit: sodiumLimit,
                        unit: "mg",
                        icon: "drop.fill"
                    )

                    LimitRow(
                        name: "Sat. Fat",
                        value: saturatedFat,
                        limit: saturatedFatLimit,
                        unit: "g",
                        icon: "flame.fill"
                    )

                    LimitRow(
                        name: "Cholesterol",
                        value: cholesterol,
                        limit: cholesterolLimit,
                        unit: "mg",
                        icon: "heart.fill"
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

struct LimitRow: View {
    let name: String
    let value: Double
    let limit: Double
    let unit: String
    let icon: String

    private var usagePercent: Double {
        guard limit > 0 else { return 0 }
        return value / limit
    }

    private var remaining: Double {
        max(limit - value, 0)
    }

    private var isOver: Bool {
        value > limit
    }

    private var statusColor: Color {
        if isOver { return .red }
        if usagePercent > 0.8 { return .orange }
        if usagePercent > 0.5 { return .yellow }
        return .green
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon with status color
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(statusColor)
                )

            // Name and limit bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    if isOver {
                        Text("\(Int(value - limit)) \(unit) over!")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    } else {
                        Text("\(Int(remaining)) \(unit) left")
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                }

                // Inverted progress bar - shows how much of limit is used
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(statusColor)
                            .frame(width: geometry.size.width * min(usagePercent, 1.0))
                    }
                }
                .frame(height: 6)

                // Show actual values in smaller text
                Text("\(Int(value)) of \(Int(limit)) \(unit) limit")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Micronutrient Row (shared component for progress-style display)

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
        return min(value / target, 1.5)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                )

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

// MARK: - Fiber Card (fiber is good - you want MORE)

struct FiberCard: View {
    let fiber: Double
    let fiberTarget: Double

    private var progress: Double {
        guard fiberTarget > 0 else { return 0 }
        return min(fiber / fiberTarget, 1.0)
    }

    private var statusColor: Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.7 { return .yellow }
        return .orange
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Fiber")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(Int(fiber))g of \(Int(fiberTarget))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(statusColor)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 6)

                if fiber >= fiberTarget {
                    Text("Goal reached!")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("\(Int(fiberTarget - fiber))g more to reach goal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 6, y: 3)
    }
}

// MARK: - Preview

#Preview {
    DashboardView(onSuggestMeal: {})
        .environmentObject(AppState())
}
