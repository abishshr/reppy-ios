import SwiftUI

struct WorkoutLogView: View {
    @StateObject private var viewModel = WorkoutLogViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Week Summary
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("This Week")
                                .font(.headline)
                            Text("\(viewModel.weekWorkoutCount) workouts")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(viewModel.weekTotalMinutes) min")
                                .fontWeight(.medium)
                            Text("\(viewModel.weekTotalCalories) cal burned")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Recent Workouts
                Section("Recent Workouts") {
                    if viewModel.workouts.isEmpty {
                        ContentUnavailableView(
                            "No workouts yet",
                            systemImage: "dumbbell",
                            description: Text("Tell your coach about your workouts to start logging")
                        )
                    } else {
                        ForEach(viewModel.workouts) { workout in
                            WorkoutRow(workout: workout)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Workouts")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadWorkouts()
            }
        }
    }
}

// MARK: - Workout Row

struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: workout.workoutType?.icon ?? "figure.run")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading) {
                    Text(workout.workoutType?.displayName ?? "Workout")
                        .fontWeight(.medium)

                    Text(workout.loggedAt.shortDateString + " at " + workout.loggedAt.timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    if let duration = workout.durationMin {
                        Text("\(duration) min")
                            .fontWeight(.semibold)
                    }

                    if let confidence = workout.confidence {
                        ConfidenceBadge(confidence: confidence)
                    }
                }
            }

            // Exercises list
            VStack(alignment: .leading, spacing: 4) {
                ForEach(workout.exercises.prefix(3)) { exercise in
                    Text(exercise.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if workout.exercises.count > 3 {
                    Text("+ \(workout.exercises.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    WorkoutLogView()
}
