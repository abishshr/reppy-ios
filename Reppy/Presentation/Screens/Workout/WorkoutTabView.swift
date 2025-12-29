import SwiftUI

/// Dedicated Workout tab - modern design with today's workout, weekly view, and progression
struct WorkoutTabView: View {
    @StateObject private var viewModel = WorkoutTabViewModel()
    @State private var showLogWorkout = false
    @State private var selectedWorkoutDay: WorkoutPlanDay?
    @State private var showWeeklyView = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Today's Workout Hero Card
                    TodayWorkoutHeroCard(
                        workoutDay: viewModel.todaysWorkoutDay,
                        isRestDay: viewModel.todaysWorkoutDay?.isRestDay ?? false,
                        onTap: {
                            if let workout = viewModel.todaysWorkoutDay {
                                selectedWorkoutDay = workout
                            }
                        },
                        onComplete: {
                            Task { await viewModel.completeTodaysWorkout() }
                        }
                    )
                    .padding(.horizontal)

                    // Week at a Glance
                    WeekAtGlanceSection(
                        weekDays: viewModel.weekWorkouts,
                        onDayTap: { day in
                            selectedWorkoutDay = day
                        },
                        onSeeAll: { showWeeklyView = true }
                    )
                    .padding(.horizontal)

                    // This Week Stats
                    WeekStatsCard(
                        workoutCount: viewModel.weekWorkoutCount,
                        totalMinutes: viewModel.weekTotalMinutes,
                        caloriesBurned: viewModel.weekTotalCalories,
                        completedDays: viewModel.completedDaysThisWeek
                    )
                    .padding(.horizontal)

                    // Weight Progression
                    if !viewModel.progressionData.isEmpty {
                        WeightProgressionSection(progressions: viewModel.progressionData)
                            .padding(.horizontal)
                    }

                    // Personal Records
                    PersonalRecordsSection(
                        recentPRs: viewModel.recentPRs,
                        isLoading: viewModel.isLoadingPRs
                    )
                    .padding(.horizontal)

                    // Workout Tools
                    WorkoutToolsSection()
                        .padding(.horizontal)

                    // Recent Workouts
                    RecentWorkoutsSection(workouts: viewModel.recentWorkouts)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLogWorkout = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showLogWorkout, onDismiss: {
                Task { await viewModel.loadData() }
            }) {
                WorkoutLoggerSheet()
            }
            .sheet(item: $selectedWorkoutDay) { workout in
                WorkoutDayDetailSheet(workout: workout, onComplete: {
                    Task { await viewModel.completeTodaysWorkout() }
                })
            }
            .sheet(isPresented: $showWeeklyView) {
                WeeklyWorkoutsSheet(
                    weekDays: viewModel.weekWorkouts,
                    onDayTap: { day in
                        showWeeklyView = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedWorkoutDay = day
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Today's Workout Hero Card

struct TodayWorkoutHeroCard: View {
    let workoutDay: WorkoutPlanDay?
    let isRestDay: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let workout = workoutDay, !isRestDay {
                // Active workout card
                Button(action: onTap) {
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TODAY'S WORKOUT")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.8))

                                Text(workout.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            if workout.isCompleted {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        // Quick Stats
                        HStack(spacing: 20) {
                            WorkoutQuickStat(
                                icon: "dumbbell.fill",
                                value: "\(workout.exercises.count)",
                                label: "Exercises"
                            )

                            if let duration = workout.estimatedDurationMin {
                                WorkoutQuickStat(
                                    icon: "clock.fill",
                                    value: "\(duration)",
                                    label: "Minutes"
                                )
                            }

                            if let calories = workout.estimatedCalories {
                                WorkoutQuickStat(
                                    icon: "flame.fill",
                                    value: "\(calories)",
                                    label: "Calories"
                                )
                            }

                            if let muscles = workout.targetMuscles, !muscles.isEmpty {
                                WorkoutQuickStat(
                                    icon: "figure.strengthtraining.traditional",
                                    value: muscles.first?.capitalized ?? "",
                                    label: "Focus"
                                )
                            }
                        }

                        // Exercise preview
                        VStack(spacing: 8) {
                            ForEach(workout.exercises.prefix(3)) { exercise in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(.white.opacity(0.2))
                                        .frame(width: 6, height: 6)

                                    Text(exercise.name)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))

                                    Spacer()

                                    Text(exercise.setsRepsDisplay)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }

                            if workout.exercises.count > 3 {
                                Text("+ \(workout.exercises.count - 3) more")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: workout.isCompleted
                                ? [.green.opacity(0.8), .green]
                                : [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)

                // Complete button (outside the tappable area)
                if !workout.isCompleted {
                    Button(action: onComplete) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark Complete")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(14)
                    }
                    .padding(.top, 12)
                }

            } else if isRestDay {
                // Rest day card
                VStack(spacing: 16) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.purple)

                    Text("Rest Day")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Recovery is part of the process. Take it easy today!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(
                    LinearGradient(
                        colors: [.purple.opacity(0.1), .purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)

            } else {
                // No workout plan
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("No Workout Plan")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Create a workout plan to get personalized daily workouts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    NavigationLink {
                        // Navigate to create plan
                        Text("Create Plan View")
                    } label: {
                        Text("Create Plan")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
            }
        }
    }
}

struct WorkoutQuickStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Week at a Glance

struct WeekAtGlanceSection: View {
    let weekDays: [WorkoutPlanDay]
    let onDayTap: (WorkoutPlanDay) -> Void
    let onSeeAll: () -> Void

    private let calendar = Calendar.current
    private let dayNames = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)

                Spacer()

                Button("See All", action: onSeeAll)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = calendar.date(byAdding: .day, value: dayOffset - currentDayOfWeek, to: Date()) ?? Date()
                    let workout = workoutForDate(date)
                    let isToday = calendar.isDateInToday(date)

                    WeekDayCell(
                        dayName: dayNames[dayOffset],
                        dayNumber: calendar.component(.day, from: date),
                        workout: workout,
                        isToday: isToday,
                        onTap: {
                            if let w = workout {
                                onDayTap(w)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var currentDayOfWeek: Int {
        calendar.component(.weekday, from: Date()) - 1
    }

    private func workoutForDate(_ date: Date) -> WorkoutPlanDay? {
        weekDays.first { day in
            // Match by day number in the week
            let dayOfWeek = calendar.component(.weekday, from: date)
            return day.dayNumber == dayOfWeek
        }
    }
}

struct WeekDayCell: View {
    let dayName: String
    let dayNumber: Int
    let workout: WorkoutPlanDay?
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(dayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isToday ? .white : .secondary)

                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 36, height: 36)

                    if let workout = workout {
                        if workout.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        } else if workout.isRestDay {
                            Image(systemName: "moon.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                        } else {
                            Text("\(dayNumber)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(isToday ? .white : .primary)
                        }
                    } else {
                        Text("\(dayNumber)")
                            .font(.caption)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundColor(isToday ? .white : .secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(workout == nil)
    }

    private var backgroundColor: Color {
        if let workout = workout {
            if workout.isCompleted {
                return .green
            } else if workout.isRestDay {
                return .purple.opacity(0.15)
            } else if isToday {
                return .blue
            } else {
                return .blue.opacity(0.15)
            }
        }
        return isToday ? .blue : Color(.tertiarySystemFill)
    }
}

// MARK: - Week Stats Card

struct WeekStatsCard: View {
    let workoutCount: Int
    let totalMinutes: Int
    let caloriesBurned: Int
    let completedDays: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                Text("This Week's Progress")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 0) {
                StatBlock(value: "\(workoutCount)", label: "Workouts", color: .blue)
                Divider().frame(height: 40)
                StatBlock(value: "\(totalMinutes)", label: "Minutes", color: .green)
                Divider().frame(height: 40)
                StatBlock(value: "\(caloriesBurned)", label: "Burned", color: .orange)
                Divider().frame(height: 40)
                StatBlock(value: "\(completedDays)/7", label: "Days", color: .purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct StatBlock: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Weight Progression Section

struct WeightProgressionSection: View {
    let progressions: [ExerciseProgression]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
                Text("Weight Progression")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(progressions.prefix(4)) { progression in
                    ProgressionRow(progression: progression)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct ProgressionRow: View {
    let progression: ExerciseProgression

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(progression.trend == .up ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: progression.trend == .up ? "arrow.up.right" : "arrow.right")
                        .font(.caption)
                        .foregroundColor(progression.trend == .up ? .green : .orange)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(progression.exerciseName)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(progression.lastWeight)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    if progression.trend == .up {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    Text(progression.change)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(progression.trend == .up ? .green : .primary)
                }

                Text("vs last time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Workout Day Detail Sheet

struct WorkoutDayDetailSheet: View {
    let workout: WorkoutPlanDay
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: PlannedExercise?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 12) {
                        Text(workout.displayName)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 24) {
                            if let duration = workout.estimatedDurationMin {
                                Label("\(duration) min", systemImage: "clock")
                            }
                            if let calories = workout.estimatedCalories {
                                Label("\(calories) cal", systemImage: "flame.fill")
                            }
                            Label("\(workout.exercises.count) exercises", systemImage: "dumbbell.fill")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        if let muscles = workout.targetMuscles, !muscles.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(muscles, id: \.self) { muscle in
                                    Text(muscle.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Exercises
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(workout.exercises) { exercise in
                            ExerciseCardRow(exercise: exercise) {
                                selectedExercise = exercise
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Complete Button
                    if !workout.isCompleted {
                        Button(action: {
                            onComplete()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Complete Workout")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                QuickExerciseCard(exercise: exercise)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

struct ExerciseCardRow: View {
    let exercise: PlannedExercise
    let onTap: () -> Void

    private var muscleColor: Color {
        switch exercise.targetMuscle?.lowercased() ?? "" {
        case "chest", "pectorals": return .red
        case "back", "lats": return .blue
        case "shoulders", "delts": return .orange
        case "biceps", "triceps": return .purple
        case "legs", "quadriceps", "hamstrings", "glutes": return .green
        case "core", "abs": return .yellow
        default: return .blue
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Thumbnail
                if let gifUrl = exercise.gifUrl, let url = URL(string: gifUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        muscleColor.opacity(0.2)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(muscleColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(muscleColor)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        if let sets = exercise.sets {
                            Label("\(sets) sets", systemImage: "square.stack.fill")
                        }
                        if let reps = exercise.reps {
                            Label(reps.displayValue, systemImage: "repeat")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weekly Workouts Sheet

struct WeeklyWorkoutsSheet: View {
    let weekDays: [WorkoutPlanDay]
    let onDayTap: (WorkoutPlanDay) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(weekDays) { day in
                    Button {
                        onDayTap(day)
                    } label: {
                        HStack(spacing: 14) {
                            // Day indicator
                            VStack {
                                Text("Day")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(day.dayNumber)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .frame(width: 50)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(day.displayName)
                                    .fontWeight(.medium)

                                if day.isRestDay {
                                    Text("Rest Day")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                } else {
                                    Text("\(day.exercises.count) exercises")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if day.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if day.isRestDay {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Components (kept from original)

struct PersonalRecordsSection: View {
    let recentPRs: [PersonalRecord]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Personal Records")
                    .font(.headline)
                Spacer()

                NavigationLink {
                    AllPRsView()
                } label: {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if recentPRs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    Text("No PRs yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Log your workouts to start tracking!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentPRs.prefix(3)) { pr in
                        PRRow(pr: pr)
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

struct PRRow: View {
    let pr: PersonalRecord

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.yellow.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(pr.exerciseName.capitalized)
                    .fontWeight(.medium)

                if let weight = pr.maxWeightKg {
                    Text("\(String(format: "%.1f", weight)) kg")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            if let date = pr.maxWeightDate {
                Text(date.shortDateString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct RecentWorkoutsSection: View {
    let workouts: [Workout]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
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

                    Text("No workouts logged yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(workouts.prefix(5)) { workout in
                        RecentWorkoutRow(workout: workout)
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

struct RecentWorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.workoutType?.icon ?? "figure.run")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.workoutType?.displayName ?? "Workout")
                    .fontWeight(.medium)

                Text(workout.loggedAt.shortDateString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let duration = workout.durationMin {
                    Text("\(duration) min")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                if let calories = workout.caloriesBurnedEst, calories > 0 {
                    Text("\(calories) cal")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct WorkoutToolsSection: View {
    @State private var showPlateCalculator = false
    @State private var showRestTimer = false
    @State private var showMuscleMap = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.purple)
                Text("Tools")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                ToolButton(icon: "timer", title: "Timer", color: .blue) {
                    showRestTimer = true
                }

                ToolButton(icon: "scalemass.fill", title: "Plates", color: .orange) {
                    showPlateCalculator = true
                }

                ToolButton(icon: "figure.stand", title: "Muscles", color: .green) {
                    showMuscleMap = true
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .sheet(isPresented: $showPlateCalculator) {
            PlateCalculatorView()
        }
        .fullScreenCover(isPresented: $showRestTimer) {
            RestTimerView(duration: 90, exerciseName: nil, onComplete: nil)
        }
        .sheet(isPresented: $showMuscleMap) {
            NavigationStack {
                ScrollView {
                    MuscleHeatMapView(muscleData: [:])
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Muscle Map")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showMuscleMap = false }
                    }
                }
            }
        }
    }
}

struct ToolButton: View {
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
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .cornerRadius(12)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct AllPRsView: View {
    var body: some View {
        Text("All Personal Records")
            .navigationTitle("Personal Records")
    }
}

// MARK: - Preview

#Preview {
    WorkoutTabView()
}
