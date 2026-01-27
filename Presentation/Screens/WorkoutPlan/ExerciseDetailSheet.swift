import SwiftUI

struct ExerciseDetailSheet: View {
    let exercise: PlannedExercise
    @Environment(\.dismiss) private var dismiss
    @State private var showTrainer = false
    @State private var showAICoach = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise GIF
                    if let gifUrl = exercise.gifUrl, let url = URL(string: gifUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                        .frame(height: 280)

                                    ProgressView()
                                        .scaleEffect(1.5)
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 320)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                            case .failure:
                                placeholderImage
                            @unknown default:
                                placeholderImage
                            }
                        }
                    } else {
                        placeholderImage
                    }

                    // Exercise Info
                    VStack(spacing: 16) {
                        // Sets & Reps Card
                        HStack(spacing: 16) {
                            InfoCard(
                                icon: "number.square.fill",
                                title: "Sets",
                                value: exercise.sets.map { "\($0)" } ?? "-",
                                color: .blue
                            )

                            InfoCard(
                                icon: "repeat",
                                title: "Reps",
                                value: exercise.repsDisplay,
                                color: .green
                            )

                            if let rest = exercise.restDisplay {
                                InfoCard(
                                    icon: "timer",
                                    title: "Rest",
                                    value: rest,
                                    color: .orange
                                )
                            }
                        }

                        // Target Muscle
                        if let targetMuscle = exercise.targetMuscle {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .foregroundColor(.purple)
                                Text("Target: ")
                                    .foregroundColor(.secondary)
                                Text(targetMuscle.capitalized)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Secondary Muscles
                        if let secondaryMuscles = exercise.secondaryMuscles, !secondaryMuscles.isEmpty {
                            HStack {
                                Image(systemName: "figure.mixed.cardio")
                                    .foregroundColor(.blue)
                                Text("Also works: ")
                                    .foregroundColor(.secondary)
                                Text(secondaryMuscles.map { $0.capitalized }.joined(separator: ", "))
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Weight Suggestion
                        if let weight = exercise.weightSuggestion {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(.orange)
                                Text("Weight: ")
                                    .foregroundColor(.secondary)
                                Text(weight)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Tempo
                        if let tempo = exercise.tempo {
                            HStack {
                                Image(systemName: "metronome.fill")
                                    .foregroundColor(.cyan)
                                Text("Tempo: ")
                                    .foregroundColor(.secondary)
                                Text(tempo)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Instructions
                        if let instructions = exercise.instructions, !instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "list.bullet.clipboard.fill")
                                        .foregroundColor(.green)
                                    Text("How to perform")
                                        .font(.headline)
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .frame(width: 24, height: 24)
                                                .background(
                                                    Circle()
                                                        .fill(Color.green)
                                                )

                                            Text(instruction)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Notes
                        if let notes = exercise.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text("Tips")
                                        .font(.headline)
                                }

                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Trainer Buttons
                        if isTrainerSupported {
                            VStack(spacing: 12) {
                                // AI Coach Button (Primary)
                                Button {
                                    showAICoach = true
                                } label: {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Start AI Coach")
                                                .font(.headline)
                                            Text("Real-time voice coaching with Gemini")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }

                                // Basic Trainer Button (Secondary)
                                Button {
                                    showTrainer = true
                                } label: {
                                    HStack {
                                        Image(systemName: "figure.run.circle.fill")
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Basic Rep Counter")
                                                .font(.headline)
                                            Text("Offline mode with pose tracking")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundStyle(.primary)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(exercise.name.capitalized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .fullScreenCover(isPresented: $showTrainer) {
                RealtimeTrainerView(exercise: exercise)
            }
            .fullScreenCover(isPresented: $showAICoach) {
                AICoachingView(exercise: exercise)
            }
        }
    }

    /// Check if this exercise type supports the realtime trainer
    private var isTrainerSupported: Bool {
        let exerciseType = ExerciseType.from(name: exercise.name)
        return exerciseType != .unknown
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)

            VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))

                Text("Demo not available")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ExerciseDetailSheet(
        exercise: PlannedExercise(
            name: "Barbell Bench Press",
            sets: 4,
            reps: .string("8-10"),
            weightKg: nil,
            weightSuggestion: "Moderate weight",
            restSec: 90,
            tempo: "3-1-2-0",
            notes: "Keep your feet flat on the floor and maintain a slight arch in your lower back.",
            isSuperset: false,
            supersetWith: nil,
            gifUrl: "https://v2.exercisedb.io/image/nU5SzKiQAIbMVe",
            targetMuscle: "chest",
            instructions: [
                "Lie flat on a bench with your feet flat on the ground.",
                "Grip the barbell slightly wider than shoulder-width apart.",
                "Lower the bar slowly to your mid-chest.",
                "Press the bar back up to the starting position."
            ],
            secondaryMuscles: ["triceps", "shoulders"],
            videoUrl: nil
        )
    )
}
