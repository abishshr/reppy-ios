import SwiftUI
import Combine
import Vision

/// ViewModel for AI-powered coaching with Pipecat + Gemini Live
@MainActor
final class AICoachingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var state: AICoachingState = .idle
    @Published private(set) var currentPose: DetectedPose?
    @Published private(set) var repCount: Int = 0
    @Published private(set) var currentSet: Int = 1
    @Published private(set) var formStatus: FormStatus = .unknown
    @Published private(set) var isAICoachSpeaking = false
    @Published private(set) var currentAngle: Double?
    @Published private(set) var positioningGuidance: PositioningGuidance?
    @Published private(set) var repJustCompleted = false  // Triggers green flash
    @Published private(set) var calibrationState: CalibrationState = .initializing
    @Published private(set) var currentPhase: ExercisePhase = .start
    @Published private(set) var symmetryStatus: SymmetryStatus = .balanced
    @Published private(set) var leftKneeAngle: Double?
    @Published private(set) var rightKneeAngle: Double?

    @Published var session: TrainerSession?

    // MARK: - Services

    // CameraService handles local video for pose detection
    // Daily SDK handles audio only (mic + speaker for AI coach)
    let cameraService = CameraService()
    private let poseDetectionService = PoseDetectionService()
    private let exerciseAnalysisService = ExerciseAnalysisService()
    let pipecatService = PipecatService()

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var exercise: PlannedExercise?
    private var lastPoseSentTime: Date = .distantPast
    private let poseSendInterval: TimeInterval = 0.25 // Send pose data at 4Hz

    // Setup issue tracking (debounce to avoid spamming AI)
    private var lastSetupIssue: SetupIssue?
    private var lastSetupIssueSentTime: Date = .distantPast
    private let setupIssueInterval: TimeInterval = 15.0 // Only send same issue every 15 seconds (give time to adjust)
    private var consecutiveIssueFrames: Int = 0
    private let issueFrameThreshold: Int = 60 // ~2 sec of consistent issue before alerting AI (30fps)

    // Calibration tracking
    private var consecutivePoseFrames: Int = 0

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    // MARK: - Session Management

    /// Start an AI coaching session for the given exercise
    func startSession(for exercise: PlannedExercise) async {
        self.exercise = exercise
        state = .connecting

        // Initialize trainer session
        let exerciseType = ExerciseType.from(name: exercise.name)
        let definition = ExerciseAnalysisService.exerciseDefinitions[exerciseType]
        session = TrainerSession(exercise: exercise, definition: definition)

        // Start exercise analysis
        exerciseAnalysisService.startAnalysis(for: exerciseType)

        do {
            // Setup local camera for pose detection
            // (Daily SDK uses audio only - no camera conflict)
            let authorized = await cameraService.checkAuthorization()
            guard authorized else {
                state = .error(message: "Camera access required for pose detection")
                return
            }

            try cameraService.setupSession()
            cameraService.startSession()

            // Connect to AI coach (audio only via Daily)
            try await pipecatService.startSession(
                exerciseName: exercise.name,
                targetSets: exercise.sets ?? 3,
                targetReps: exercise.reps?.intValue ?? 10
            )

            // Start countdown
            await startCountdown()

        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    /// End the current session
    func endSession() {
        Task {
            await pipecatService.endSession()
        }
        cameraService.stopSession()
        state = .idle
    }

    /// Pause the session
    func pauseSession() {
        cameraService.pauseSession()
        state = .paused
    }

    /// Resume the session
    func resumeSession() {
        cameraService.resumeSession()
        state = .active
    }

    /// Skip rest period
    func skipRest() {
        session?.endRest()
        state = .active
    }

    /// Manually complete current set
    func completeCurrentSet() {
        guard var currentSession = session else { return }

        let reps = currentSession.currentReps > 0 ? currentSession.currentReps : currentSession.targetReps
        currentSession.completeSet(duration: 0, formScore: 1.0)
        session = currentSession

        // Notify Pipecat
        pipecatService.sendSetCompleted(setNumber: currentSession.currentSet - 1, reps: reps)

        if currentSession.isComplete {
            state = .exerciseComplete
        } else {
            state = .resting(timeRemaining: currentSession.restDuration)
            startRestTimer()
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Subscribe pose detection to camera frames
        poseDetectionService.subscribeToFrames(cameraService.framePublisher)

        // Observe pose detection results
        poseDetectionService.$currentPose
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pose in
                self?.handlePoseUpdate(pose)
            }
            .store(in: &cancellables)

        // Observe Pipecat connection state
        pipecatService.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionState in
                self?.handleConnectionStateChange(connectionState)
            }
            .store(in: &cancellables)

        // Observe AI speaking state
        pipecatService.$isAICoachSpeaking
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAICoachSpeaking)

        // Observe rep counting from exercise analysis
        exerciseAnalysisService.$repCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                if count > (self?.repCount ?? 0) {
                    self?.handleRepCompleted()
                }
                self?.repCount = count
            }
            .store(in: &cancellables)

        // Observe form status
        exerciseAnalysisService.$formStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$formStatus)

        // Observe phase for debug display
        exerciseAnalysisService.$currentPhase
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentPhase)

        // Observe symmetry status
        exerciseAnalysisService.$symmetryStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$symmetryStatus)

        // Observe knee angles for debug display
        exerciseAnalysisService.$leftKneeAngle
            .receive(on: DispatchQueue.main)
            .assign(to: &$leftKneeAngle)

        exerciseAnalysisService.$rightKneeAngle
            .receive(on: DispatchQueue.main)
            .assign(to: &$rightKneeAngle)
    }

    private func handlePoseUpdate(_ pose: DetectedPose?) {
        currentPose = pose

        guard let pose = pose else {
            // No pose detected - user might not be in frame
            positioningGuidance = PositioningGuidance(
                message: "Step into frame",
                icon: "person.fill.questionmark",
                isFullBody: false
            )
            // Update calibration state
            if calibrationState != .initializing {
                calibrationState = .detectingPose
            }
            consecutivePoseFrames = 0
            // Notify AI coach
            sendSetupIssueToAI(.notInFrame)
            return
        }

        // Check if key joints are visible for the exercise
        let exerciseType = ExerciseType.from(name: exercise?.name ?? "")
        positioningGuidance = checkPositioning(pose: pose, exerciseType: exerciseType)

        // Update exercise analysis (local rep counting)
        exerciseAnalysisService.analyzePose(pose)
        currentAngle = exerciseAnalysisService.currentAngle

        // Update calibration state based on pose detection
        updateCalibrationState(positioningOK: positioningGuidance == nil)

        // Send pose to AI coach at 4Hz (every 250ms)
        let now = Date()
        if now.timeIntervalSince(lastPoseSentTime) >= poseSendInterval {
            pipecatService.sendPoseData(pose)
            lastPoseSentTime = now
        }
    }

    /// Track calibration progress based on pose detection and rep counting
    private func updateCalibrationState(positioningOK: Bool) {
        if !positioningOK {
            calibrationState = .detectingPose
            consecutivePoseFrames = 0
            return
        }

        // User is in frame with good positioning
        consecutivePoseFrames += 1

        // Need ~1 second of stable pose detection before calibrating
        let framesNeeded = 30  // ~1 second at 30fps

        if consecutivePoseFrames < framesNeeded {
            // Still detecting, show progress
            let progress = Int((Double(consecutivePoseFrames) / Double(framesNeeded)) * 50)
            calibrationState = .calibrating(progress: progress)
        } else if repCount < 2 {
            // Have stable pose, waiting for first reps to calibrate thresholds
            let progress = 50 + (repCount * 25)  // 50%, 75%
            calibrationState = .calibrating(progress: min(progress, 99))
        } else {
            // Fully calibrated after 2 reps
            if calibrationState != .ready {
                calibrationState = .ready
            }
        }
    }

    private func checkPositioning(pose: DetectedPose, exerciseType: ExerciseType) -> PositioningGuidance? {
        // Define required joints for different exercise types
        let requiredJoints: [VNHumanBodyPoseObservation.JointName]

        switch exerciseType {
        case .squat, .lunge, .deadlift:
            // Lower body exercises - only need lower body visible (hip, knee, ankle)
            // Upper body is optional for form checks but not required
            requiredJoints = [.rightHip, .rightKnee, .rightAnkle]
        case .pushup, .plank:
            // Need side view with full body
            requiredJoints = [.rightShoulder, .rightElbow, .rightWrist, .rightHip, .rightAnkle]
        case .bicepCurl, .shoulderPress, .row:
            // Upper body exercises - just need arms visible
            requiredJoints = [.rightShoulder, .rightElbow, .rightWrist]
        case .unknown:
            requiredJoints = [.rightHip, .rightKnee]
        }

        // Check visibility with confidence threshold
        var missingJoints: [String] = []
        for joint in requiredJoints {
            let confidence = pose.confidence[joint] ?? 0
            if confidence < 0.3 {
                missingJoints.append(jointDisplayName(joint))
            }
        }

        if missingJoints.isEmpty {
            // User is properly in frame - reset issue tracking
            consecutiveIssueFrames = 0
            lastSetupIssue = nil
            return nil // All good!
        }

        // Determine guidance based on what's missing
        let hasLowerBody = (pose.confidence[.rightKnee] ?? 0) > 0.3
        let hasUpperBody = (pose.confidence[.rightShoulder] ?? 0) > 0.3

        var guidance: PositioningGuidance?
        var issue: SetupIssue?

        if !hasUpperBody && !hasLowerBody {
            guidance = PositioningGuidance(
                message: "Step back so your whole body is visible",
                icon: "arrow.backward.circle.fill",
                isFullBody: false
            )
            issue = .tooClose
        } else if !hasLowerBody {
            guidance = PositioningGuidance(
                message: "Step back - legs not visible",
                icon: "arrow.backward.circle.fill",
                isFullBody: false
            )
            issue = .legsNotVisible
        } else if !hasUpperBody {
            guidance = PositioningGuidance(
                message: "Step forward - head/shoulders not visible",
                icon: "arrow.forward.circle.fill",
                isFullBody: false
            )
            issue = .upperBodyNotVisible
        }

        // Send issue to AI coach with debouncing
        if let issue = issue {
            sendSetupIssueToAI(issue)
        }

        return guidance
    }

    /// Send setup issue to AI coach with debouncing
    private func sendSetupIssueToAI(_ issue: SetupIssue) {
        consecutiveIssueFrames += 1

        // Only alert AI after consistent issue detection
        guard consecutiveIssueFrames >= issueFrameThreshold else { return }

        // Don't spam the same issue
        let now = Date()
        if issue == lastSetupIssue && now.timeIntervalSince(lastSetupIssueSentTime) < setupIssueInterval {
            return
        }

        // Send to AI coach
        pipecatService.sendSetupIssue(issue)
        lastSetupIssue = issue
        lastSetupIssueSentTime = now
    }

    private func jointDisplayName(_ joint: VNHumanBodyPoseObservation.JointName) -> String {
        switch joint {
        case .rightKnee, .leftKnee: return "knee"
        case .rightAnkle, .leftAnkle: return "ankle"
        case .rightHip, .leftHip: return "hip"
        case .rightShoulder, .leftShoulder: return "shoulder"
        case .rightElbow, .leftElbow: return "elbow"
        case .rightWrist, .leftWrist: return "wrist"
        default: return "joint"
        }
    }

    private func handleRepCompleted() {
        guard var currentSession = session else { return }

        currentSession.incrementRep()
        session = currentSession

        // Trigger green flash
        repJustCompleted = true
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            repJustCompleted = false
        }

        // Notify AI coach of rep completion
        pipecatService.sendRepCompleted()

        // Check if set is complete
        if currentSession.currentReps >= currentSession.targetReps {
            completeCurrentSet()
        }
    }

    private func handleConnectionStateChange(_ connectionState: PipecatConnectionState) {
        switch connectionState {
        case .connected:
            // Connection established, will transition to active after countdown
            break
        case .disconnected:
            if case .active = state {
                state = .error(message: "Connection lost to AI coach")
            }
        case .connecting:
            state = .connecting
        case .error(let message):
            state = .error(message: message)
        }
    }

    private func startCountdown() async {
        for i in (1...3).reversed() {
            state = .preparing(countdown: i)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        state = .active
    }

    private func startRestTimer() {
        guard let restDuration = session?.restDuration else { return }

        Task {
            var remaining = restDuration
            while remaining > 0, case .resting = state {
                state = .resting(timeRemaining: remaining)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                remaining -= 1
            }

            if case .resting = state {
                session?.endRest()
                state = .active
            }
        }
    }
}

// MARK: - AI Coaching State

enum AICoachingState: Equatable {
    case idle
    case connecting
    case preparing(countdown: Int)
    case active
    case resting(timeRemaining: TimeInterval)
    case setComplete(setNumber: Int, reps: Int)
    case exerciseComplete
    case paused
    case error(message: String)

    static func == (lhs: AICoachingState, rhs: AICoachingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.connecting, .connecting): return true
        case (.preparing(let l), .preparing(let r)): return l == r
        case (.active, .active): return true
        case (.resting(let l), .resting(let r)): return abs(l - r) < 0.5
        case (.setComplete(let ls, let lr), .setComplete(let rs, let rr)): return ls == rs && lr == rr
        case (.exerciseComplete, .exerciseComplete): return true
        case (.paused, .paused): return true
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }
}

// MARK: - Calibration State

enum CalibrationState: Equatable {
    case initializing           // Starting up camera, AI coach
    case detectingPose          // Looking for user in frame
    case calibrating(progress: Int)  // Calibrating thresholds (0-100%)
    case ready                  // Ready to count reps!

    var displayText: String {
        switch self {
        case .initializing:
            return "Starting up..."
        case .detectingPose:
            return "Step into frame"
        case .calibrating(let progress):
            return "Calibrating... \(progress)%"
        case .ready:
            return "Ready!"
        }
    }

    var icon: String {
        switch self {
        case .initializing:
            return "gear"
        case .detectingPose:
            return "person.fill.questionmark"
        case .calibrating:
            return "waveform"
        case .ready:
            return "checkmark.circle.fill"
        }
    }
}
