import SwiftUI
import AVFoundation

/// AI-powered coaching view with Pipecat + Gemini Live
struct AICoachingView: View {
    let exercise: PlannedExercise
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AICoachingViewModel()

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()

            // Dimmed camera preview (30% opacity for reference)
            CameraPreviewView(previewLayer: viewModel.cameraService.getPreviewLayer())
                .ignoresSafeArea()
                .opacity(0.3)

            // Bright skeleton overlay from local pose detection
            // Green = in frame, Yellow = needs adjustment
            // Shows guide pose (cyan dashed) when user needs to get in position
            PoseOverlayView(
                pose: viewModel.currentPose,
                exerciseType: ExerciseType.from(name: exercise.name),
                formStatus: viewModel.formStatus,
                isInFrame: viewModel.positioningGuidance == nil,
                showGuidePose: viewModel.calibrationState != .ready,
                currentPhase: viewModel.currentPhase
            )
            .ignoresSafeArea()

            // In-frame guidance overlay
            if let guidance = viewModel.positioningGuidance {
                InFrameGuidanceView(guidance: guidance)
            }

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

            // AI Coach speaking indicator
            if viewModel.isAICoachSpeaking {
                aiSpeakingIndicator
            }

            // Green flash on rep completion
            if viewModel.repJustCompleted {
                repCompletedFlash
            }

            // Debug panel (bottom left)
            if showDebugLog {
                VStack {
                    Spacer()
                    HStack {
                        debugLogPanel
                        Spacer()
                    }
                    .padding()
                    .padding(.bottom, 60)
                }
            }

            // Debug button (bottom left corner)
            VStack {
                Spacer()
                HStack {
                    debugLogButton
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.startSession(for: exercise)
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .exerciseComplete = newState {
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
                viewModel.endSession()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            // Exercise info with AI badge
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)

                ExerciseInfoPanel(
                    name: exercise.name,
                    currentSet: viewModel.session?.currentSet ?? 1,
                    targetSets: exercise.sets ?? 3,
                    targetReps: exercise.reps?.intValue ?? 10
                )
            }

            Spacer()

            // Connection indicator
            connectionIndicator
        }
    }

    private var connectionIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)

            Text(connectionText)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var connectionColor: Color {
        switch viewModel.state {
        case .connecting:
            return .orange
        case .active, .resting, .preparing:
            return .green
        case .error:
            return .red
        default:
            return .gray
        }
    }

    private var connectionText: String {
        switch viewModel.state {
        case .connecting:
            return "Connecting..."
        case .active, .resting, .preparing:
            return "AI Coach Active"
        case .error:
            return "Disconnected"
        default:
            return "Offline"
        }
    }

    // MARK: - State Content

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle, .connecting:
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)

                Text("Connecting to AI Coach...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

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
            // Calibration status indicator
            if viewModel.calibrationState != .ready {
                calibrationIndicator
            }

            // Rep counter (local detection - instant)
            RepCounterView(
                count: viewModel.repCount,
                targetReps: viewModel.session?.targetReps ?? 0
            )

            // Form feedback from local analysis
            FormFeedbackView(
                status: viewModel.formStatus,
                correction: nil
            )

            // Debug angle display
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
            state: trainerState,
            onPause: { viewModel.pauseSession() },
            onResume: { viewModel.resumeSession() },
            onEnd: { viewModel.endSession() },
            onCompleteSet: { viewModel.completeCurrentSet() }
        )
    }

    /// Convert AICoachingState to TrainerState for control bar
    private var trainerState: TrainerState {
        switch viewModel.state {
        case .idle:
            return .idle
        case .connecting:
            return .idle
        case .preparing(let countdown):
            return .preparing(countdown: countdown)
        case .active:
            return .active
        case .resting(let timeRemaining):
            return .resting(timeRemaining: timeRemaining)
        case .setComplete(let setNumber, let reps):
            return .setComplete(setNumber: setNumber, reps: reps)
        case .exerciseComplete:
            return .exerciseComplete
        case .paused:
            return .paused
        case .error(let message):
            return .error(message: message)
        }
    }

    // MARK: - Calibration Indicator

    private var calibrationIndicator: some View {
        VStack(spacing: 12) {
            // Icon with animation
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)

                Image(systemName: viewModel.calibrationState.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(calibrationColor)
                    .symbolEffect(.pulse, options: .repeating, value: viewModel.calibrationState != .ready)
            }

            // Status text
            Text(viewModel.calibrationState.displayText)
                .font(.headline)
                .foregroundStyle(.white)

            // Progress bar for calibrating state
            if case .calibrating(let progress) = viewModel.calibrationState {
                ProgressView(value: Double(progress), total: 100)
                    .progressViewStyle(.linear)
                    .tint(calibrationColor)
                    .frame(width: 150)
            }

            // Hint text
            Text(calibrationHint)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var calibrationColor: Color {
        switch viewModel.calibrationState {
        case .initializing, .detectingPose:
            return .orange
        case .calibrating:
            return .yellow
        case .ready:
            return .green
        }
    }

    private var calibrationHint: String {
        switch viewModel.calibrationState {
        case .initializing:
            return "Setting up camera and AI coach"
        case .detectingPose:
            return "Make sure your full body is visible"
        case .calibrating(let progress):
            if progress < 50 {
                return "Hold still for a moment..."
            } else {
                return "Do 2 practice reps to calibrate"
            }
        case .ready:
            return "Let's go!"
        }
    }

    // MARK: - Debug Log Panel

    @State private var showDebugLog = false

    private var debugLogButton: some View {
        Button {
            showDebugLog.toggle()
        } label: {
            Image(systemName: "ladybug.fill")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var debugLogPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("DEBUG")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
                Spacer()
                Button {
                    showDebugLog = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Group {
                Text("Angle: \(viewModel.currentAngle.map { String(format: "%.0f°", $0) } ?? "N/A")")
                Text("Phase: \(viewModel.currentPhase.rawValue)")
                Text("Calibration: \(viewModel.calibrationState.displayText)")
                Text("Symmetry: \(viewModel.symmetryStatus.rawValue)")
                if let left = viewModel.leftKneeAngle,
                   let right = viewModel.rightKneeAngle {
                    Text("L: \(String(format: "%.0f°", left)) R: \(String(format: "%.0f°", right))")
                }
                Text("Reps: \(viewModel.repCount)")
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.green.opacity(0.8))
        }
        .padding(8)
        .frame(width: 160)
        .background(.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Rep Completed Flash

    private var repCompletedFlash: some View {
        RoundedRectangle(cornerRadius: 0)
            .stroke(Color.green, lineWidth: 20)
            .ignoresSafeArea()
            .opacity(0.8)
            .transition(.opacity)
            .animation(.easeOut(duration: 0.3), value: viewModel.repJustCompleted)
    }

    // MARK: - AI Speaking Indicator

    private var aiSpeakingIndicator: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.title3)
                        .symbolEffect(.variableColor.iterative)

                    Text("AI Coach speaking")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.5), radius: 10)
                .padding(.trailing)
                .padding(.bottom, 100)
            }
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: viewModel.isAICoachSpeaking)
    }
}

// MARK: - Preview

#Preview {
    AICoachingView(
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
