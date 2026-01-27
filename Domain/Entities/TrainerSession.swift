import Foundation
import Vision

// MARK: - Detected Pose

struct DetectedPose {
    let timestamp: Date
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let confidence: [VNHumanBodyPoseObservation.JointName: Float]

    /// Calculate angle between three joints (in degrees)
    func angle(from: VNHumanBodyPoseObservation.JointName,
               through: VNHumanBodyPoseObservation.JointName,
               to: VNHumanBodyPoseObservation.JointName) -> Double? {
        guard let pointA = joints[from],
              let pointB = joints[through],
              let pointC = joints[to] else {
            return nil
        }

        let ax = Double(pointA.x - pointB.x)
        let ay = Double(pointA.y - pointB.y)
        let cx = Double(pointC.x - pointB.x)
        let cy = Double(pointC.y - pointB.y)

        let dotProduct = ax * cx + ay * cy
        let magnitudeBA = sqrt(ax * ax + ay * ay)
        let magnitudeBC = sqrt(cx * cx + cy * cy)

        guard magnitudeBA > 0, magnitudeBC > 0 else { return nil }

        let cosAngle = dotProduct / (magnitudeBA * magnitudeBC)
        let clampedCos = max(-1.0, min(1.0, cosAngle))
        return acos(clampedCos) * 180.0 / Double.pi
    }

    /// Check if a specific joint has sufficient confidence
    func hasConfidence(for joint: VNHumanBodyPoseObservation.JointName, threshold: Float = 0.5) -> Bool {
        guard let conf = confidence[joint] else { return false }
        return conf >= threshold
    }
}

// MARK: - Exercise Phase

enum ExercisePhase: String, CaseIterable {
    case start       // Initial position
    case concentric  // Muscle shortening (e.g., lifting up)
    case hold        // Pause at peak
    case eccentric   // Muscle lengthening (e.g., lowering down)
    case rest        // Between reps
}

// MARK: - Form Status

enum FormStatus: String {
    case good
    case needsCorrection
    case unknown

    var displayText: String {
        switch self {
        case .good: return "Good form!"
        case .needsCorrection: return "Check your form"
        case .unknown: return ""
        }
    }

    var color: String {
        switch self {
        case .good: return "green"
        case .needsCorrection: return "orange"
        case .unknown: return "gray"
        }
    }
}

// MARK: - Symmetry Status

enum SymmetryStatus: String {
    case balanced       // Both sides working evenly
    case favoringLeft   // Left side doing more work
    case favoringRight  // Right side doing more work

    var displayText: String {
        switch self {
        case .balanced: return "Balanced"
        case .favoringLeft: return "Favoring left side"
        case .favoringRight: return "Favoring right side"
        }
    }

    var correction: String? {
        switch self {
        case .balanced: return nil
        case .favoringLeft: return "Even it out - you're favoring your left"
        case .favoringRight: return "Even it out - you're favoring your right"
        }
    }
}

// MARK: - Form Checkpoint

struct FormCheckpoint {
    let name: String
    let description: String
    let validator: (DetectedPose) -> Bool?
    let correction: String

    func validate(_ pose: DetectedPose) -> FormCheckResult {
        guard let isValid = validator(pose) else {
            return .unknown
        }
        return isValid ? .passed : .failed(correction: correction)
    }
}

enum FormCheckResult {
    case passed
    case failed(correction: String)
    case unknown
}

// MARK: - Exercise Type

enum ExerciseType: String, CaseIterable {
    case squat
    case pushup
    case lunge
    case bicepCurl
    case shoulderPress
    case plank
    case deadlift
    case row
    case unknown

    var displayName: String {
        switch self {
        case .squat: return "Squat"
        case .pushup: return "Push-up"
        case .lunge: return "Lunge"
        case .bicepCurl: return "Bicep Curl"
        case .shoulderPress: return "Shoulder Press"
        case .plank: return "Plank"
        case .deadlift: return "Deadlift"
        case .row: return "Row"
        case .unknown: return "Exercise"
        }
    }

    /// Attempts to match exercise name to a known type
    static func from(name: String) -> ExerciseType {
        let lowercased = name.lowercased()
        if lowercased.contains("squat") { return .squat }
        if lowercased.contains("push") && lowercased.contains("up") { return .pushup }
        if lowercased.contains("pushup") { return .pushup }
        if lowercased.contains("lunge") { return .lunge }
        if lowercased.contains("curl") { return .bicepCurl }
        if lowercased.contains("bicep") { return .bicepCurl }
        if lowercased.contains("shoulder") && lowercased.contains("press") { return .shoulderPress }
        if lowercased.contains("overhead") && lowercased.contains("press") { return .shoulderPress }
        if lowercased.contains("plank") { return .plank }
        if lowercased.contains("deadlift") { return .deadlift }
        if lowercased.contains("row") { return .row }
        return .unknown
    }
}

// MARK: - Phase Transition

struct PhaseTransition {
    let from: ExercisePhase
    let to: ExercisePhase
    let angleThreshold: Double
    let joints: (from: VNHumanBodyPoseObservation.JointName,
                 through: VNHumanBodyPoseObservation.JointName,
                 to: VNHumanBodyPoseObservation.JointName)
    let comparison: AngleComparison

    enum AngleComparison {
        case greaterThan
        case lessThan
    }
}

// MARK: - Exercise Definition

struct ExerciseDefinition {
    let id: String
    let name: String
    let type: ExerciseType
    let primaryJoints: [(from: VNHumanBodyPoseObservation.JointName,
                         through: VNHumanBodyPoseObservation.JointName,
                         to: VNHumanBodyPoseObservation.JointName)]
    let upPhaseAngleThreshold: Double      // Angle above this = up position
    let downPhaseAngleThreshold: Double    // Angle below this = down position
    let formCheckpoints: [FormCheckpoint]
    let useSideView: Bool                  // true = side view preferred, false = front view

    /// Determine the current phase based on pose
    func detectPhase(from pose: DetectedPose, currentPhase: ExercisePhase) -> ExercisePhase {
        guard let primaryAngle = pose.angle(from: primaryJoints[0].from,
                                            through: primaryJoints[0].through,
                                            to: primaryJoints[0].to) else {
            return currentPhase
        }

        switch currentPhase {
        case .start, .rest:
            // Transition to eccentric when movement starts
            if primaryAngle < upPhaseAngleThreshold {
                return .eccentric
            }
        case .eccentric:
            // Transition to concentric when at bottom
            if primaryAngle < downPhaseAngleThreshold {
                return .concentric
            }
        case .concentric:
            // Transition to rest when back at top
            if primaryAngle > upPhaseAngleThreshold {
                return .rest
            }
        case .hold:
            return currentPhase
        }

        return currentPhase
    }
}

// MARK: - Trainer Session

struct TrainerSession {
    let exercise: PlannedExercise
    let definition: ExerciseDefinition?
    var currentSet: Int
    var currentReps: Int
    var targetReps: Int
    var targetSets: Int
    var formStatus: FormStatus
    var lastFormCorrection: String?
    var isResting: Bool
    var restStartTime: Date?
    var restDuration: TimeInterval
    var currentPhase: ExercisePhase
    var sessionStartTime: Date
    var completedSets: [CompletedSet]

    struct CompletedSet {
        let setNumber: Int
        let reps: Int
        let duration: TimeInterval
        let averageFormScore: Double
    }

    init(exercise: PlannedExercise, definition: ExerciseDefinition?) {
        self.exercise = exercise
        self.definition = definition
        self.currentSet = 1
        self.currentReps = 0
        self.targetReps = exercise.reps?.intValue ?? 10
        self.targetSets = exercise.sets ?? 3
        self.formStatus = .unknown
        self.lastFormCorrection = nil
        self.isResting = false
        self.restStartTime = nil
        self.restDuration = TimeInterval(exercise.restSec ?? 60)
        self.currentPhase = .start
        self.sessionStartTime = Date()
        self.completedSets = []
    }

    var isComplete: Bool {
        currentSet > targetSets
    }

    var progress: Double {
        let setsCompleted = Double(completedSets.count)
        let currentSetProgress = Double(currentReps) / Double(targetReps)
        return (setsCompleted + currentSetProgress) / Double(targetSets)
    }

    var remainingRestTime: TimeInterval? {
        guard isResting, let startTime = restStartTime else { return nil }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, restDuration - elapsed)
    }

    mutating func incrementRep() {
        currentReps += 1
        currentPhase = .rest
    }

    mutating func completeSet(duration: TimeInterval, formScore: Double) {
        let completed = CompletedSet(
            setNumber: currentSet,
            reps: currentReps,
            duration: duration,
            averageFormScore: formScore
        )
        completedSets.append(completed)
        currentSet += 1
        currentReps = 0
        currentPhase = .start

        if currentSet <= targetSets {
            isResting = true
            restStartTime = Date()
        }
    }

    mutating func endRest() {
        isResting = false
        restStartTime = nil
    }
}

// MARK: - Trainer State

enum TrainerState: Equatable {
    case idle
    case preparing(countdown: Int)
    case active
    case resting(timeRemaining: TimeInterval)
    case setComplete(setNumber: Int, reps: Int)
    case exerciseComplete
    case paused
    case error(message: String)

    static func == (lhs: TrainerState, rhs: TrainerState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
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
