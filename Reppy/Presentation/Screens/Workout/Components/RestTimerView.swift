import SwiftUI
import AVFoundation

/// Rest timer for between-set recovery
struct RestTimerView: View {
    @StateObject private var timer = RestTimerViewModel()
    @Environment(\.dismiss) private var dismiss

    let defaultDuration: Int // in seconds
    let exerciseName: String?
    let onComplete: (() -> Void)?

    init(
        duration: Int = 90,
        exerciseName: String? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.defaultDuration = duration
        self.exerciseName = exerciseName
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                if let exercise = exerciseName {
                    Text("Rest before next set")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(exercise)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Spacer()

                // Timer Circle
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                        .frame(width: 250, height: 250)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: timer.progress)
                        .stroke(
                            timer.isComplete ? Color.green : timer.timerColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: timer.progress)

                    // Time display
                    VStack(spacing: 8) {
                        if timer.isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            Text("Ready!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else {
                            Text(timer.timeString)
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            Text("remaining")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Quick time adjustments
                if !timer.isComplete {
                    HStack(spacing: 16) {
                        TimeAdjustButton(label: "-15s", color: .red) {
                            timer.adjustTime(by: -15)
                        }

                        TimeAdjustButton(label: "-30s", color: .orange) {
                            timer.adjustTime(by: -30)
                        }

                        TimeAdjustButton(label: "+30s", color: .blue) {
                            timer.adjustTime(by: 30)
                        }

                        TimeAdjustButton(label: "+60s", color: .green) {
                            timer.adjustTime(by: 60)
                        }
                    }
                }

                // Preset durations
                VStack(spacing: 12) {
                    Text("Quick Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        PresetButton(label: "30s", seconds: 30, timer: timer)
                        PresetButton(label: "60s", seconds: 60, timer: timer)
                        PresetButton(label: "90s", seconds: 90, timer: timer)
                        PresetButton(label: "2m", seconds: 120, timer: timer)
                        PresetButton(label: "3m", seconds: 180, timer: timer)
                    }
                }

                // Control buttons
                HStack(spacing: 24) {
                    // Skip button
                    Button {
                        timer.skip()
                        onComplete?()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(30)
                    }

                    // Play/Pause button
                    Button {
                        if timer.isComplete {
                            onComplete?()
                            dismiss()
                        } else {
                            timer.togglePause()
                        }
                    } label: {
                        HStack {
                            Image(systemName: timer.isComplete ? "arrow.right" : (timer.isPaused ? "play.fill" : "pause.fill"))
                            Text(timer.isComplete ? "Continue" : (timer.isPaused ? "Resume" : "Pause"))
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(timer.isComplete ? Color.green : Color.blue)
                        .cornerRadius(30)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding()
        }
        .onAppear {
            timer.start(duration: defaultDuration)
        }
        .onChange(of: timer.isComplete) { _, complete in
            if complete {
                onComplete?()
            }
        }
    }
}

// MARK: - Time Adjust Button

struct TimeAdjustButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(color.opacity(0.2))
                .cornerRadius(20)
        }
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let label: String
    let seconds: Int
    @ObservedObject var timer: RestTimerViewModel

    var isSelected: Bool {
        timer.totalDuration == seconds && !timer.isRunning
    }

    var body: some View {
        Button {
            timer.start(duration: seconds)
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.gray.opacity(0.3))
                .cornerRadius(16)
        }
    }
}

// MARK: - Rest Timer ViewModel

@MainActor
class RestTimerViewModel: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var totalDuration: Int = 0
    @Published var isPaused: Bool = false
    @Published var isComplete: Bool = false
    @Published var isRunning: Bool = false

    private var timerTask: Task<Void, Never>?
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    var progress: CGFloat {
        guard totalDuration > 0 else { return 0 }
        return CGFloat(remainingSeconds) / CGFloat(totalDuration)
    }

    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)"
    }

    var timerColor: Color {
        if remainingSeconds <= 5 {
            return .red
        } else if remainingSeconds <= 15 {
            return .orange
        }
        return .blue
    }

    func start(duration: Int) {
        timerTask?.cancel()

        totalDuration = duration
        remainingSeconds = duration
        isPaused = false
        isComplete = false
        isRunning = true

        timerTask = Task {
            while remainingSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                if !isPaused && !Task.isCancelled {
                    remainingSeconds -= 1

                    // Haptic feedback at milestones
                    if remainingSeconds == 10 || remainingSeconds == 5 || remainingSeconds == 3 {
                        hapticFeedback.impactOccurred()
                    }

                    // Countdown beeps for last 3 seconds
                    if remainingSeconds <= 3 && remainingSeconds > 0 {
                        playBeep()
                    }
                }
            }

            if !Task.isCancelled && remainingSeconds == 0 {
                isComplete = true
                isRunning = false
                notificationFeedback.notificationOccurred(.success)
                playCompletionSound()
            }
        }
    }

    func togglePause() {
        isPaused.toggle()
        hapticFeedback.impactOccurred()
    }

    func adjustTime(by seconds: Int) {
        remainingSeconds = max(0, remainingSeconds + seconds)
        if remainingSeconds == 0 {
            isComplete = true
            isRunning = false
        }
        hapticFeedback.impactOccurred()
    }

    func skip() {
        timerTask?.cancel()
        remainingSeconds = 0
        isComplete = true
        isRunning = false
    }

    private func playBeep() {
        AudioServicesPlaySystemSound(1057) // Short beep
    }

    private func playCompletionSound() {
        AudioServicesPlaySystemSound(1025) // Completion sound
    }

    deinit {
        timerTask?.cancel()
    }
}

// MARK: - Compact Rest Timer (for inline use)

struct CompactRestTimer: View {
    @StateObject private var timer = RestTimerViewModel()
    let duration: Int
    let onComplete: (() -> Void)?

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.blue)

                if timer.isComplete {
                    Text("Rest Complete!")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                } else {
                    Text("Rest: \(timer.timeString)")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                Spacer()

                if !timer.isComplete {
                    Button {
                        timer.togglePause()
                    } label: {
                        Image(systemName: timer.isPaused ? "play.fill" : "pause.fill")
                            .foregroundColor(.blue)
                    }

                    Button {
                        timer.skip()
                        onComplete?()
                    } label: {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))

                    Capsule()
                        .fill(timer.isComplete ? Color.green : timer.timerColor)
                        .frame(width: geo.size.width * timer.progress)
                        .animation(.linear(duration: 0.1), value: timer.progress)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            timer.start(duration: duration)
        }
        .onChange(of: timer.isComplete) { _, complete in
            if complete {
                onComplete?()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RestTimerView(
        duration: 90,
        exerciseName: "Bench Press"
    )
}

#Preview("Compact") {
    CompactRestTimer(duration: 60, onComplete: nil)
        .padding()
}
