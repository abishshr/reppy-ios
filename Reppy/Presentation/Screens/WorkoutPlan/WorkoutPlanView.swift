import SwiftUI

struct WorkoutPlanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var showingAllPlans = false
    @State private var showingTodaysWorkout = false
    @State private var showingCreateSheet = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading workout plan...")
                        .padding(.top, 50)
                } else if let plan = viewModel.activePlan {
                    activePlanContent(plan)
                } else {
                    emptyPlanView
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Workout Plan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if viewModel.activePlan != nil {
                        Button {
                            smartCreateWorkoutPlan()
                        } label: {
                            Label("Smart Create", systemImage: "brain.head.profile")
                        }

                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("Customize New Plan", systemImage: "slider.horizontal.3")
                        }

                        Divider()
                    }

                    Button {
                        showingAllPlans = true
                    } label: {
                        Label("All Plans", systemImage: "list.bullet")
                    }

                    if viewModel.todaysWorkout != nil {
                        Button {
                            showingTodaysWorkout = true
                        } label: {
                            Label("Today's Workout", systemImage: "figure.strengthtraining.traditional")
                        }
                    }

                    if viewModel.activePlan != nil {
                        Divider()

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Plan", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Delete Workout Plan?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let plan = viewModel.activePlan {
                    Task {
                        await viewModel.deletePlan(id: plan.id)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(viewModel.activePlan?.name ?? "this plan")\" and all its workouts. This cannot be undone.")
        }
        .refreshable {
            await viewModel.loadAll()
        }
        .task {
            await viewModel.loadAll()
        }
        .sheet(isPresented: $showingAllPlans) {
            AllWorkoutPlansSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingTodaysWorkout) {
            if let workout = viewModel.todaysWorkout, let plan = viewModel.activePlan {
                TodaysWorkoutSheet(workout: workout, planId: plan.id, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            UnifiedPlanCreationSheet(
                planType: .workout,
                apiClient: DependencyContainer.shared.apiClient,
                chatRepository: DependencyContainer.shared.chatRepository,
                appState: appState
            )
        }
    }

    // MARK: - Active Plan Content

    @ViewBuilder
    private func activePlanContent(_ plan: WorkoutPlan) -> some View {
        VStack(spacing: 16) {
            // Plan Header
            planHeader(plan)

            // Today's Workout Card (if available)
            if let todaysWorkout = viewModel.todaysWorkout {
                TodaysWorkoutCard(workout: todaysWorkout) {
                    showingTodaysWorkout = true
                }
                .padding(.horizontal)
            }

            // Progress Card
            ProgressCard(plan: plan)
                .padding(.horizontal)

            // Week Selector
            WeekSelector(
                weeks: viewModel.weeksArray,
                selectedWeek: viewModel.selectedWeek
            ) { week in
                viewModel.selectWeek(week)
            }

            // Week Schedule
            VStack(spacing: 12) {
                ForEach(viewModel.currentWeekDays) { day in
                    WorkoutDayCard(day: day, planId: plan.id, viewModel: viewModel)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func planHeader(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        if let difficulty = plan.difficulty {
                            DifficultyBadge(difficulty: difficulty)
                        }

                        Text("\(plan.durationWeeks) week\(plan.durationWeeks > 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let goal = plan.goal {
                    GoalBadge(goal: goal)
                }
            }

            if let description = plan.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Empty State

    private var emptyPlanView: some View {
        VStack(spacing: 28) {
            Spacer()
                .frame(height: 20)

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No Workout Plan Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create a personalized program based on your goals and equipment")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Two Options
            VStack(spacing: 12) {
                // Smart Create - AI decides everything
                Button {
                    smartCreateWorkoutPlan()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 20))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Smart Create")
                                .font(.headline)

                            Text("AI builds the perfect program for you")
                                .font(.caption)
                                .opacity(0.9)
                        }

                        Spacer()

                        Image(systemName: "sparkles")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(BounceButtonStyle())

                // Customize - User chooses
                Button {
                    showingCreateSheet = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 44, height: 44)

                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Customize")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Choose duration, split, and more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .buttonStyle(BounceButtonStyle())
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func smartCreateWorkoutPlan() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.navigateToChatWith(
                message: "Create a 4-week workout plan for me based on my profile. Use my goals and equipment preferences. Do NOT ask questions - just generate the complete plan now."
            )
        }
    }

    // MARK: - Actions

    private func createNewPlan() {
        showingCreateSheet = true
    }
}

// MARK: - Today's Workout Card

struct TodaysWorkoutCard: View {
    let workout: WorkoutPlanDay
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Workout")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(workout.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Card

struct ProgressCard: View {
    let plan: WorkoutPlan

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(plan.completedWorkouts)/\(plan.totalWorkouts) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(plan.progressPercent / 100))
                }
            }
            .frame(height: 8)

            HStack {
                Label("Week \(plan.currentWeek)", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(plan.progressPercent))% complete")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Week Selector

struct WeekSelector: View {
    let weeks: [Int]
    let selectedWeek: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(weeks, id: \.self) { week in
                    Button {
                        onSelect(week)
                    } label: {
                        Text("Week \(week)")
                            .font(.subheadline)
                            .fontWeight(selectedWeek == week ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedWeek == week
                                    ? Color.accentColor
                                    : Color(.secondarySystemBackground)
                            )
                            .foregroundColor(selectedWeek == week ? .white : .primary)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Workout Day Card

struct WorkoutDayCard: View {
    let day: WorkoutPlanDay
    let planId: String
    @ObservedObject var viewModel: WorkoutPlanViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Status Icon
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: statusIcon)
                            .foregroundColor(statusColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(dayLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(day.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                if day.isRestDay {
                    Text("Rest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(day.exercises.count) exercises")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let duration = day.estimatedDurationMin {
                            Text("\(duration) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if !day.isRestDay {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Expanded Content
            if isExpanded && !day.isRestDay {
                Divider()

                // Target Muscles
                if let muscles = day.targetMuscles, !muscles.isEmpty {
                    HStack {
                        Image(systemName: "figure.arms.open")
                            .foregroundColor(.secondary)
                            .font(.caption)

                        Text(muscles.joined(separator: ", ").capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Exercises
                VStack(spacing: 8) {
                    ForEach(day.exercises) { exercise in
                        ExerciseRow(exercise: exercise)
                    }
                }

                // Complete Button (if not completed)
                if !day.isCompleted {
                    Button {
                        Task {
                            await viewModel.completeWorkout(planId: planId, dayId: day.id)
                        }
                    } label: {
                        HStack {
                            if viewModel.completingWorkout {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark Complete")
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.completingWorkout)
                }

                // Notes
                if let notes = day.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(day.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private var dayLabel: String {
        let days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let index = min(day.dayNumber, days.count - 1)
        return days[index]
    }

    private var statusColor: Color {
        if day.isCompleted {
            return .green
        } else if day.isRestDay {
            return .gray
        } else {
            return .blue
        }
    }

    private var statusIcon: String {
        if day.isCompleted {
            return "checkmark"
        } else if day.isRestDay {
            return "bed.double.fill"
        } else {
            return "dumbbell.fill"
        }
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: PlannedExercise
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack {
                // Show indicator if has demo
                if exercise.hasMedia {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    if let notes = exercise.notes {
                        Text(notes)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(exercise.setsRepsDisplay)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let weight = exercise.weightSuggestion {
                        Text(weight)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            ExerciseDetailSheet(exercise: exercise)
        }
    }
}

// MARK: - Badges

struct GoalBadge: View {
    let goal: String

    var body: some View {
        Text(goal.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
    }
}

struct DifficultyBadge: View {
    let difficulty: String

    var body: some View {
        Text(difficulty.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficultyColor.opacity(0.15))
            .foregroundColor(difficultyColor)
            .clipShape(Capsule())
    }

    private var difficultyColor: Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}

// MARK: - All Plans Sheet

struct AllWorkoutPlansSheet: View {
    @ObservedObject var viewModel: WorkoutPlanViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if viewModel.allPlans.isEmpty {
                    ContentUnavailableView(
                        "No Workout Plans",
                        systemImage: "dumbbell",
                        description: Text("Your workout plans will appear here")
                    )
                } else {
                    ForEach(viewModel.allPlans) { plan in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.name)
                                    .fontWeight(.medium)

                                HStack(spacing: 8) {
                                    Text("\(plan.durationWeeks) weeks")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text("\(Int(plan.progressPercent))%")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }

                            Spacer()

                            if plan.isActive {
                                Text("Active")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deletePlan(id: plan.id)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadAllPlans()
            }
        }
    }
}

// MARK: - Today's Workout Sheet

struct TodaysWorkoutSheet: View {
    let workout: WorkoutPlanDay
    let planId: String
    @ObservedObject var viewModel: WorkoutPlanViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(workout.displayName)
                            .font(.title)
                            .fontWeight(.bold)

                        if let muscles = workout.targetMuscles, !muscles.isEmpty {
                            Text(muscles.joined(separator: " - ").capitalized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 20) {
                            if let duration = workout.estimatedDurationMin {
                                Label("\(duration) min", systemImage: "clock")
                            }

                            Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()

                    // Exercises
                    VStack(spacing: 12) {
                        ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseDetailCard(exercise: exercise, index: index + 1)
                        }
                    }
                    .padding(.horizontal)

                    // Notes
                    if let notes = workout.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)

                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Complete Button
                    if !workout.isCompleted {
                        Button {
                            Task {
                                await viewModel.completeWorkout(planId: planId, dayId: workout.id)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                if viewModel.completingWorkout {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Complete Workout")
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.completingWorkout)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
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

// MARK: - Exercise Detail Card

struct ExerciseDetailCard: View {
    let exercise: PlannedExercise
    let index: Int
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Exercise Number
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("\(index)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )

                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Demo indicator
                    if exercise.hasMedia {
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.caption)
                            Text("Demo")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                HStack(spacing: 20) {
                    StatPill(label: "Sets", value: exercise.sets.map { "\($0)" } ?? "-")
                    StatPill(label: "Reps", value: exercise.repsDisplay)
                    if let rest = exercise.restDisplay {
                        StatPill(label: "Rest", value: rest)
                    }
                }

                if let weight = exercise.weightSuggestion {
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(.secondary)
                        Text(weight)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if let notes = exercise.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            ExerciseDetailSheet(exercise: exercise)
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 50)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Create Workout Plan Sheet

struct CreateWorkoutPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (String) -> Void

    @State private var selectedWeeks = 4
    @State private var selectedDays = 4
    @State private var selectedSplit = "upper_lower"
    @State private var selectedGoal = "build_muscle"

    private let weekOptions = [4, 6, 8, 12]
    private let dayOptions = [3, 4, 5, 6]
    private let splitOptions = [
        ("full_body", "Full Body", "figure.stand"),
        ("upper_lower", "Upper/Lower", "arrow.up.arrow.down"),
        ("push_pull_legs", "Push/Pull/Legs", "arrow.left.arrow.right"),
    ]
    private let goalOptions = [
        ("strength", "Strength", "bolt.fill"),
        ("build_muscle", "Build Muscle", "figure.strengthtraining.traditional"),
        ("fat_loss", "Fat Loss", "flame.fill"),
        ("endurance", "Endurance", "heart.fill"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Customize Your Plan")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("We'll create a personalized program based on your profile")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Goal Selection
                    OptionSection(title: "Goal") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(goalOptions, id: \.0) { goal in
                                SelectableCard(
                                    title: goal.1,
                                    icon: goal.2,
                                    isSelected: selectedGoal == goal.0,
                                    color: .blue
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedGoal = goal.0
                                    }
                                }
                            }
                        }
                    }

                    // Split Selection
                    OptionSection(title: "Workout Split") {
                        HStack(spacing: 10) {
                            ForEach(splitOptions, id: \.0) { split in
                                SelectablePill(
                                    title: split.1,
                                    isSelected: selectedSplit == split.0,
                                    color: .blue
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedSplit = split.0
                                    }
                                }
                            }
                        }
                    }

                    // Duration
                    HStack(spacing: 16) {
                        OptionSection(title: "Weeks") {
                            HStack(spacing: 8) {
                                ForEach(weekOptions, id: \.self) { week in
                                    SelectableChip(
                                        title: "\(week)",
                                        isSelected: selectedWeeks == week,
                                        color: .blue
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedWeeks = week
                                        }
                                    }
                                }
                            }
                        }

                        OptionSection(title: "Days/Week") {
                            HStack(spacing: 8) {
                                ForEach(dayOptions, id: \.self) { day in
                                    SelectableChip(
                                        title: "\(day)",
                                        isSelected: selectedDays == day,
                                        color: .blue
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedDays = day
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    // Create Button
                    Button {
                        let prompt = buildPrompt()
                        dismiss()
                        onCreate(prompt)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Create Plan")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func buildPrompt() -> String {
        let goalText = goalOptions.first { $0.0 == selectedGoal }?.1 ?? "general fitness"
        let splitText = splitOptions.first { $0.0 == selectedSplit }?.1 ?? "upper/lower"

        return "Create a \(selectedWeeks)-week \(splitText.lowercased()) workout plan for \(goalText.lowercased()), training \(selectedDays) days per week"
    }
}

// MARK: - Reusable Option Components

struct OptionSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            content
        }
    }
}

struct SelectableCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color(.secondarySystemBackground))
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SelectablePill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color(.secondarySystemBackground))
                )
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color(.secondarySystemBackground))
                )
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    WorkoutPlanView()
}
