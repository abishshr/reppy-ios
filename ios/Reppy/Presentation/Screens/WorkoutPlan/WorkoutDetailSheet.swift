import SwiftUI

struct WorkoutDetailSheet: View {
    let workout: WorkoutPlanDay
    @Environment(\.dismiss) private var dismiss
    @State private var completedExercises: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Quick Info
                    quickInfoSection

                    // Exercises
                    exercisesSection
                }
                .padding()
            }
            .navigationTitle(workout.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Workout type badge
            if let workoutType = workout.workoutType {
                Text(workoutType.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }

            // Target muscles
            if let muscles = workout.targetMuscles, !muscles.isEmpty {
                Text(muscles.joined(separator: " • ").capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Quick Info Section

    private var quickInfoSection: some View {
        HStack(spacing: 16) {
            if let duration = workout.estimatedDurationMin {
                QuickInfoPill(icon: "clock.fill", value: "\(duration)", label: "min", color: .blue)
            }

            QuickInfoPill(icon: "dumbbell.fill", value: "\(workout.exercises.count)", label: "exercises", color: .purple)

            if let calories = workout.estimatedCalories {
                QuickInfoPill(icon: "flame.fill", value: "\(calories)", label: "kcal", color: .orange)
            }
        }
    }

    // MARK: - Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Exercises")
                    .font(.headline)

                Spacer()

                // Progress indicator
                let completed = completedExercises.count
                let total = workout.exercises.count
                Text("\(completed)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(completed == total ? .green : .secondary)
            }

            ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                ExerciseCard(
                    exercise: exercise,
                    number: index + 1,
                    isCompleted: Binding(
                        get: { completedExercises.contains(exercise.id) },
                        set: { newValue in
                            if newValue {
                                completedExercises.insert(exercise.id)
                            } else {
                                completedExercises.remove(exercise.id)
                            }
                        }
                    )
                )
            }
        }
    }
}

// MARK: - Exercise Card (Meal-style)

struct ExerciseCard: View {
    let exercise: PlannedExercise
    let number: Int
    @Binding var isCompleted: Bool
    @State private var showInstructions = false
    @State private var showAICoach = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // GIF at top (like meal image)
            exerciseGIFSection

            // Content below
            VStack(alignment: .leading, spacing: 14) {
                // Header with number and name
                HStack(alignment: .top, spacing: 12) {
                    // Number badge with gradient
                    Text("\(number)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 4, y: 2)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .fontWeight(.bold)

                        if let muscle = exercise.targetMuscle {
                            HStack(spacing: 4) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.caption2)
                                Text(muscle.capitalized)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }

                // Quick stats row (like meal quick info)
                HStack(spacing: 10) {
                    ExerciseStatPill(
                        icon: "arrow.triangle.2.circlepath",
                        value: exercise.setsRepsDisplay,
                        color: .blue
                    )

                    if let rest = exercise.restDisplay {
                        ExerciseStatPill(
                            icon: "timer",
                            value: rest,
                            color: .orange
                        )
                    }

                    if let weight = exercise.weightSuggestion {
                        ExerciseStatPill(
                            icon: "scalemass.fill",
                            value: weight.capitalized,
                            color: .purple
                        )
                    }
                }

                // Notes
                if let notes = exercise.notes, !notes.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(10)
                }

                // Secondary muscles
                if let secondaryMuscles = exercise.secondaryMuscles, !secondaryMuscles.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Also works")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        HStack(spacing: 6) {
                            ForEach(secondaryMuscles, id: \.self) { muscle in
                                Text(muscle.capitalized)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }

                // Instructions (collapsible)
                if let instructions = exercise.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showInstructions.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "text.justify.left")
                                    .foregroundColor(.green)

                                Text("How to perform")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .rotationEffect(.degrees(showInstructions ? 180 : 0))
                            }
                            .foregroundColor(.primary)
                        }

                        if showInstructions {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(instructions.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("\(index + 1)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Circle().fill(Color.green))

                                        Text(step)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)
                }

                // Action Buttons Row
                HStack(spacing: 12) {
                    // Complete Exercise Button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isCompleted.toggle()
                        }
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                            Text(isCompleted ? "Completed" : "Mark Complete")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(isCompleted ? .white : .green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            isCompleted
                                ? AnyShapeStyle(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.green.opacity(0.15))
                        )
                        .cornerRadius(12)
                    }

                    // AI Coach Button - launches directly
                    Button {
                        showAICoach = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.subheadline)
                            Text("AI Coach")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isCompleted ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .fullScreenCover(isPresented: $showAICoach) {
            AICoachingView(exercise: exercise)
        }
    }

    // MARK: - GIF Section (like meal image)

    private var exerciseGIFSection: some View {
        Group {
            if let gifUrl = exercise.gifUrl, let url = URL(string: gifUrl) {
                AnimatedGIFView(url: url)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 20,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 20
                        )
                    )
            } else {
                exercisePlaceholder
            }
        }
    }

    private var exercisePlaceholder: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
            .fill(
                LinearGradient(
                    colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 160)

            VStack(spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text(exercise.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Exercise Stat Pill

struct ExerciseStatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    WorkoutDetailSheet(
        workout: WorkoutPlanDay(
            id: "1",
            weekNumber: 1,
            dayNumber: 1,
            dayName: "Push Day",
            workoutType: "strength",
            exercises: [
                PlannedExercise(
                    name: "Bench Press",
                    sets: 4,
                    reps: .string("8-10"),
                    weightKg: nil,
                    weightSuggestion: "moderate",
                    restSec: 90,
                    tempo: nil,
                    notes: "Control the descent",
                    isSuperset: nil,
                    supersetWith: nil,
                    gifUrl: nil,
                    targetMuscle: "chest",
                    instructions: ["Step 1", "Step 2"],
                    secondaryMuscles: ["triceps", "shoulders"],
                    videoUrl: nil
                )
            ],
            targetMuscles: ["chest", "shoulders", "triceps"],
            estimatedDurationMin: 45,
            estimatedCalories: 300,
            notes: nil,
            isRestDay: false,
            isCompleted: false,
            completedAt: nil
        )
    )
}
