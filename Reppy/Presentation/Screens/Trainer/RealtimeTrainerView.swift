import SwiftUI
import AVFoundation

struct RealtimeTrainerView: View {
    let exercise: PlannedExercise
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RealtimeTrainerViewModel()

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(previewLayer: viewModel.cameraService.getPreviewLayer())
                .ignoresSafeArea()

            // Pose overlay (green when in frame, yellow when adjusting)
            // Shows guide pose (cyan dashed) when no pose detected
            PoseOverlayView(
                pose: viewModel.currentPose,
                exerciseType: ExerciseType.from(name: exercise.name),
                formStatus: viewModel.formStatus,
                isInFrame: viewModel.currentPose != nil,
                showGuidePose: viewModel.currentPose == nil  // Show guide when no pose detected
            )
            .ignoresSafeArea()

            // UI overlay
            VStack(spacing: 0) {
                // Top bar
                topBar

                Spacer()

                // State-specific content
                stateContent

                Spacer()

                // Bottom controls
                bottomBar
            }
            .padding()

            // Green flash on rep completion
            if viewModel.repJustCompleted {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.green, lineWidth: 20)
                    .ignoresSafeArea()
                    .opacity(0.8)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.3), value: viewModel.repJustCompleted)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.startSession(for: exercise)
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .exerciseComplete = newState {
                // Delay dismiss to let completion message play
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            // Exercise info
            ExerciseInfoPanel(
                name: exercise.name,
                currentSet: viewModel.session?.currentSet ?? 1,
                targetSets: exercise.sets ?? 3,
                targetReps: exercise.reps?.intValue ?? 10
            )

            Spacer()

            // Voice toggle
            Button {
                viewModel.voiceCoachEnabled.toggle()
            } label: {
                Image(systemName: viewModel.voiceCoachEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.voiceCoachEnabled ? .white : .white.opacity(0.5))
            }
        }
    }

    // MARK: - State Content

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            ProgressView()
                .tint(.white)

        case .preparing(let countdown):
            CountdownOverlay(count: countdown)

        case .active:
            activeContent

        case .resting(let timeRemaining):
            RestOverlay(
                timeRemaining: timeRemaining,
                onSkip: { viewModel.skipRest() }
            )

        case .setComplete(let setNumber, let reps):
            SetCompleteOverlay(setNumber: setNumber, reps: reps)

        case .exerciseComplete:
            ExerciseCompleteOverlay(
                exercise: exercise,
                completedSets: viewModel.session?.completedSets ?? []
            )

        case .paused:
            PausedOverlay(onResume: { viewModel.resumeSession() })

        case .error(let message):
            ErrorOverlay(message: message, onDismiss: { dismiss() })
        }
    }

    private var activeContent: some View {
        VStack(spacing: 20) {
            // Rep counter
            RepCounterView(
                count: viewModel.repCount,
                targetReps: viewModel.session?.targetReps ?? 0
            )

            // Form feedback
            if let correction = viewModel.formCorrection {
                FormFeedbackView(
                    status: viewModel.formStatus,
                    correction: correction
                )
            } else {
                FormFeedbackView(
                    status: viewModel.formStatus,
                    correction: nil
                )
            }

            // Debug angle display (can be removed later)
            if let angle = viewModel.currentAngle {
                Text("Angle: \(String(format: "%.0f", angle))°")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        TrainerControlBar(
            state: viewModel.state,
            onPause: { viewModel.pauseSession() },
            onResume: { viewModel.resumeSession() },
            onEnd: { viewModel.endSession() },
            onCompleteSet: { viewModel.completeCurrentSet() }
        )
    }
}

// MARK: - Exercise Info Panel

struct ExerciseInfoPanel: View {
    let name: String
    let currentSet: Int
    let targetSets: Int
    let targetReps: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.headline)
                .foregroundStyle(.white)

            Text("Set \(currentSet) of \(targetSets) • \(targetReps) reps")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Countdown Overlay

struct CountdownOverlay: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 120, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 10)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3), value: count)
    }
}

// MARK: - Rest Overlay

struct RestOverlay: View {
    let timeRemaining: TimeInterval
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("REST")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            Text(formatTime(timeRemaining))
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Button("Skip Rest") {
                onSkip()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.white.opacity(0.2))
            .clipShape(Capsule())
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        return "\(seconds)"
    }
}

// MARK: - Set Complete Overlay

struct SetCompleteOverlay: View {
    let setNumber: Int
    let reps: Int

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Set \(setNumber) Complete!")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            Text("\(reps) reps")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: - Exercise Complete Overlay

struct ExerciseCompleteOverlay: View {
    let exercise: PlannedExercise
    let completedSets: [TrainerSession.CompletedSet]

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("Exercise Complete!")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            Text(exercise.name)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.8))

            if !completedSets.isEmpty {
                VStack(spacing: 8) {
                    ForEach(completedSets.indices, id: \.self) { index in
                        let set = completedSets[index]
                        HStack {
                            Text("Set \(set.setNumber)")
                            Spacer()
                            Text("\(set.reps) reps")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

// MARK: - Paused Overlay

struct PausedOverlay: View {
    let onResume: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white)

            Text("Paused")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            Button("Resume") {
                onResume()
            }
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(.white)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Error Overlay

struct ErrorOverlay: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text(message)
                .font(.body)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Dismiss") {
                onDismiss()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.red)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    RealtimeTrainerView(
        exercise: PlannedExercise(
            name: "Squat",
            sets: 3,
            reps: .int(10),
            weightKg: nil,
            weightSuggestion: nil,
            restSec: 60,
            tempo: nil,
            notes: nil,
            isSuperset: nil,
            supersetWith: nil,
            gifUrl: nil,
            targetMuscle: "Quadriceps",
            instructions: nil,
            secondaryMuscles: nil,
            videoUrl: nil
        )
    )
}
