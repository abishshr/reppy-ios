import Foundation
import Combine
import AVFoundation

@MainActor
final class RealtimeTrainerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var state: TrainerState = .idle
    @Published private(set) var session: TrainerSession?
    @Published private(set) var currentPose: DetectedPose?
    @Published private(set) var repCount = 0
    @Published private(set) var formStatus: FormStatus = .unknown
    @Published private(set) var formCorrection: String?
    @Published private(set) var currentAngle: Double?
    @Published private(set) var countdownValue = 3
    @Published private(set) var repJustCompleted = false  // Triggers green flash
    @Published var voiceCoachEnabled = true

    // MARK: - Services

    let cameraService: CameraService
    private let poseDetectionService: PoseDetectionService
    private let exerciseAnalysisService: ExerciseAnalysisService
    let voiceCoachService: VoiceCoachService

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?
    private var restTimer: Timer?
    private var setStartTime: Date?
    private var formScores: [Double] = []

    // MARK: - Initialization

    init() {
        self.cameraService = CameraService()
        self.poseDetectionService = PoseDetectionService()
        self.exerciseAnalysisService = ExerciseAnalysisService()
        self.voiceCoachService = VoiceCoachService()

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Bind pose detection to analysis
        poseDetectionService.$currentPose
            .compactMap { $0 }
            .sink { [weak self] pose in
                self?.currentPose = pose
                self?.exerciseAnalysisService.analyzePose(pose)
            }
            .store(in: &cancellables)

        // Bind analysis results
        exerciseAnalysisService.$repCount
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] count in
                guard let self = self, count > self.repCount else { return }
                self.repCount = count
                self.onRepCompleted(count)
            }
            .store(in: &cancellables)

        exerciseAnalysisService.$formStatus
            .assign(to: &$formStatus)

        exerciseAnalysisService.$lastFormCorrection
            .sink { [weak self] correction in
                self?.formCorrection = correction
                if let correction = correction {
                    self?.voiceCoachService.announceFormCorrection(correction)
                }
            }
            .store(in: &cancellables)

        exerciseAnalysisService.$currentAngle
            .assign(to: &$currentAngle)

        // Bind voice coach enabled state
        $voiceCoachEnabled
            .sink { [weak self] enabled in
                self?.voiceCoachService.setEnabled(enabled)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func startSession(for exercise: PlannedExercise) async {
        // Request camera permission
        guard await cameraService.checkAuthorization() else {
            state = .error(message: "Camera access required for the realtime trainer")
            return
        }

        // Setup camera
        do {
            try cameraService.setupSession()
        } catch {
            state = .error(message: error.localizedDescription)
            return
        }

        // Determine exercise type
        let exerciseType = ExerciseType.from(name: exercise.name)
        let definition = ExerciseAnalysisService.exerciseDefinitions[exerciseType]

        // Create session
        session = TrainerSession(exercise: exercise, definition: definition)

        // Start services
        cameraService.startSession()
        poseDetectionService.subscribeToFrames(cameraService.framePublisher)
        exerciseAnalysisService.startAnalysis(for: exerciseType)

        // Start countdown
        startCountdown()
    }

    func pauseSession() {
        guard state == .active else { return }
        state = .paused
        cameraService.pauseSession()
    }

    func resumeSession() {
        guard state == .paused else { return }
        cameraService.resumeSession()
        state = .active
    }

    func endSession() {
        stopAllServices()
        state = .exerciseComplete
    }

    func completeCurrentSet() {
        guard var session = session else { return }

        let duration = setStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let avgFormScore = formScores.isEmpty ? 0.5 : formScores.reduce(0, +) / Double(formScores.count)

        session.completeSet(duration: duration, formScore: avgFormScore)
        self.session = session

        voiceCoachService.announceSetComplete(session.currentSet - 1, reps: repCount)

        if session.isComplete {
            endSession()
        } else {
            startRest()
        }

        // Reset for next set
        repCount = 0
        formScores.removeAll()
        exerciseAnalysisService.reset()
    }

    func skipRest() {
        endRest()
    }

    // MARK: - Private Methods

    private func startCountdown() {
        countdownValue = 3
        state = .preparing(countdown: countdownValue)

        voiceCoachService.announceCountdown(3)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                self.countdownValue -= 1
                self.voiceCoachService.announceCountdown(self.countdownValue)

                if self.countdownValue <= 0 {
                    timer.invalidate()
                    self.countdownTimer = nil
                    self.startActive()
                } else {
                    self.state = .preparing(countdown: self.countdownValue)
                }
            }
        }
    }

    private func startActive() {
        state = .active
        setStartTime = Date()

        if let exerciseType = session?.definition?.type {
            exerciseAnalysisService.startAnalysis(for: exerciseType)
        }
    }

    private func startRest() {
        guard var session = session else { return }

        session.isResting = true
        session.restStartTime = Date()
        self.session = session

        let restDuration = Int(session.restDuration)
        state = .resting(timeRemaining: session.restDuration)
        voiceCoachService.announceRest(seconds: restDuration)

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self, let session = self.session else {
                    timer.invalidate()
                    return
                }

                if let remaining = session.remainingRestTime, remaining > 0 {
                    self.state = .resting(timeRemaining: remaining)
                } else {
                    timer.invalidate()
                    self.restTimer = nil
                    self.endRest()
                }
            }
        }
    }

    private func endRest() {
        restTimer?.invalidate()
        restTimer = nil

        guard var session = session else { return }
        session.endRest()
        self.session = session

        voiceCoachService.announceRestComplete()
        startCountdown()
    }

    private func onRepCompleted(_ count: Int) {
        voiceCoachService.announceRep(count)

        // Trigger green flash
        repJustCompleted = true
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            repJustCompleted = false
        }

        // Record form score for this rep
        if formStatus == .good {
            formScores.append(1.0)
        } else if formStatus == .needsCorrection {
            formScores.append(0.5)
        }

        // Check if set is complete
        if let session = session, count >= session.targetReps {
            // Short delay before completing set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.completeCurrentSet()
            }
        }
    }

    private func stopAllServices() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        restTimer?.invalidate()
        restTimer = nil

        cameraService.stopSession()
        cameraService.cleanup()
        poseDetectionService.stopDetection()
        exerciseAnalysisService.stopAnalysis()
        voiceCoachService.stopSpeaking()
    }

    deinit {
        // Note: Can't call stopAllServices() here since it's @MainActor
        // Services will clean up when deallocated
    }
}
