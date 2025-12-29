import Foundation
import Vision
import Combine

// MARK: - Kalman Filter for Smooth Tracking

/// Simple 1D Kalman filter for smoothing noisy angle measurements
final class KalmanFilter {
    private var estimate: Double = 0
    private var errorEstimate: Double = 1
    private let processNoise: Double  // Q - how much we expect the value to change
    private let measurementNoise: Double  // R - how noisy the measurements are
    private var isInitialized = false

    init(processNoise: Double = 0.01, measurementNoise: Double = 0.1) {
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
    }

    func update(_ measurement: Double) -> Double {
        if !isInitialized {
            estimate = measurement
            isInitialized = true
            return estimate
        }

        // Prediction step
        let predictedEstimate = estimate
        let predictedError = errorEstimate + processNoise

        // Update step
        let kalmanGain = predictedError / (predictedError + measurementNoise)
        estimate = predictedEstimate + kalmanGain * (measurement - predictedEstimate)
        errorEstimate = (1 - kalmanGain) * predictedError

        return estimate
    }

    func reset() {
        estimate = 0
        errorEstimate = 1
        isInitialized = false
    }
}

@MainActor
final class ExerciseAnalysisService: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var repCount = 0
    @Published private(set) var currentPhase: ExercisePhase = .start
    @Published private(set) var formStatus: FormStatus = .unknown
    @Published private(set) var lastFormCorrection: String?
    @Published private(set) var currentAngle: Double?
    @Published private(set) var symmetryStatus: SymmetryStatus = .balanced  // NEW: Symmetry feedback
    @Published private(set) var leftKneeAngle: Double?  // NEW: Left knee tracking
    @Published private(set) var rightKneeAngle: Double?  // NEW: Right knee tracking

    // MARK: - Private Properties

    private var currentExercise: ExerciseDefinition?
    private var angleHistory: [Double] = []
    private let angleHistorySize = 5
    private var lastRepTime: Date = .distantPast
    private let minRepInterval: TimeInterval = 0.5 // Minimum time between reps
    private var formCheckResults: [String: Bool] = [:]
    private var consecutiveGoodFrames = 0
    private var consecutiveBadFrames = 0
    private let formThreshold = 3 // Frames needed to change form status

    // MARK: - Kalman Filters (smoother tracking)

    private let rightKneeFilter = KalmanFilter(processNoise: 0.005, measurementNoise: 0.05)
    private let leftKneeFilter = KalmanFilter(processNoise: 0.005, measurementNoise: 0.05)
    private let angleFilter = KalmanFilter(processNoise: 0.01, measurementNoise: 0.08)

    // MARK: - Adaptive Thresholds

    private var calibrationReps: Int = 0
    private var minAngleObserved: Double = 180  // Deepest point observed
    private var maxAngleObserved: Double = 0    // Standing point observed
    private var isCalibrated: Bool = false
    private let calibrationRepsNeeded = 2  // Reps needed before adapting thresholds

    // Adaptive thresholds (updated after calibration)
    private var adaptiveUpThreshold: Double = 160
    private var adaptiveDownThreshold: Double = 100

    // MARK: - Front Camera Tracking

    private var useFrontCamera = true
    private var standingKneeY: CGFloat?  // Right knee standing position
    private var standingLeftKneeY: CGFloat?  // Left knee standing position
    private var standingHipY: CGFloat?  // Legacy
    private var maxKneeDrop: CGFloat = 0

    // MARK: - Active Leg Detection

    private enum ActiveLeg {
        case right
        case left
        case both  // Regular two-leg squat
    }
    private var activeLeg: ActiveLeg = .both

    static let exerciseDefinitions: [ExerciseType: ExerciseDefinition] = [
        .squat: ExerciseDefinition(
            id: "squat",
            name: "Squat",
            type: .squat,
            primaryJoints: [(.rightHip, .rightKnee, .rightAnkle)],
            upPhaseAngleThreshold: 160,
            downPhaseAngleThreshold: 100,
            formCheckpoints: squatFormCheckpoints,
            useSideView: false  // Changed to support front camera
        ),
        .pushup: ExerciseDefinition(
            id: "pushup",
            name: "Push-up",
            type: .pushup,
            primaryJoints: [(.rightShoulder, .rightElbow, .rightWrist)],
            upPhaseAngleThreshold: 160,
            downPhaseAngleThreshold: 90,
            formCheckpoints: pushupFormCheckpoints,
            useSideView: true
        ),
        .lunge: ExerciseDefinition(
            id: "lunge",
            name: "Lunge",
            type: .lunge,
            primaryJoints: [(.rightHip, .rightKnee, .rightAnkle)],
            upPhaseAngleThreshold: 160,
            downPhaseAngleThreshold: 95,
            formCheckpoints: lungeFormCheckpoints,
            useSideView: false  // Changed to support front camera
        ),
        .bicepCurl: ExerciseDefinition(
            id: "bicep_curl",
            name: "Bicep Curl",
            type: .bicepCurl,
            primaryJoints: [(.rightShoulder, .rightElbow, .rightWrist)],
            upPhaseAngleThreshold: 150,
            downPhaseAngleThreshold: 45,
            formCheckpoints: bicepCurlFormCheckpoints,
            useSideView: false  // Works well from front
        ),
        .shoulderPress: ExerciseDefinition(
            id: "shoulder_press",
            name: "Shoulder Press",
            type: .shoulderPress,
            primaryJoints: [(.rightShoulder, .rightElbow, .rightWrist)],
            upPhaseAngleThreshold: 165,
            downPhaseAngleThreshold: 90,
            formCheckpoints: shoulderPressFormCheckpoints,
            useSideView: false
        )
    ]

    // MARK: - Form Checkpoints

    private static let squatFormCheckpoints: [FormCheckpoint] = [
        FormCheckpoint(
            name: "Knee alignment",
            description: "Keep knees tracking over toes",
            validator: { pose in
                guard let knee = pose.joints[.rightKnee],
                      let ankle = pose.joints[.rightAnkle] else { return nil }
                // Knee shouldn't go too far forward
                return knee.x <= ankle.x + 0.15
            },
            correction: "Keep your knees behind your toes"
        ),
        FormCheckpoint(
            name: "Depth check",
            description: "Get low enough for full range",
            validator: { pose in
                guard let hip = pose.joints[.rightHip],
                      let knee = pose.joints[.rightKnee] else { return nil }
                // Hip should get close to or below knee level
                return hip.y >= knee.y - 0.1
            },
            correction: "Try to get a bit lower"
        )
    ]

    private static let pushupFormCheckpoints: [FormCheckpoint] = [
        FormCheckpoint(
            name: "Body alignment",
            description: "Keep body in a straight line",
            validator: { pose in
                guard let shoulder = pose.joints[.rightShoulder],
                      let hip = pose.joints[.rightHip],
                      let ankle = pose.joints[.rightAnkle] else { return nil }
                // Check if shoulder, hip, and ankle are roughly aligned
                let shoulderHipAngle = atan2(hip.y - shoulder.y, hip.x - shoulder.x)
                let hipAnkleAngle = atan2(ankle.y - hip.y, ankle.x - hip.x)
                return abs(shoulderHipAngle - hipAnkleAngle) < 0.3
            },
            correction: "Keep your body straight, don't sag your hips"
        )
    ]

    private static let lungeFormCheckpoints: [FormCheckpoint] = [
        FormCheckpoint(
            name: "Front knee angle",
            description: "Keep front knee at 90 degrees at bottom",
            validator: { pose in
                guard let angle = pose.angle(from: .rightHip, through: .rightKnee, to: .rightAnkle) else {
                    return nil
                }
                // At bottom of lunge, knee should be around 90 degrees
                return angle >= 80 && angle <= 110
            },
            correction: "Bend your front knee to about 90 degrees"
        )
    ]

    private static let bicepCurlFormCheckpoints: [FormCheckpoint] = [
        FormCheckpoint(
            name: "Elbow position",
            description: "Keep elbows close to body",
            validator: { pose in
                guard let elbow = pose.joints[.rightElbow],
                      let hip = pose.joints[.rightHip] else { return nil }
                // Elbow shouldn't drift too far from body
                return abs(elbow.x - hip.x) < 0.2
            },
            correction: "Keep your elbows pinned to your sides"
        )
    ]

    private static let shoulderPressFormCheckpoints: [FormCheckpoint] = [
        FormCheckpoint(
            name: "Full extension",
            description: "Fully extend arms overhead",
            validator: { pose in
                guard let angle = pose.angle(from: .rightShoulder, through: .rightElbow, to: .rightWrist) else {
                    return nil
                }
                // Arms should be nearly straight at top
                return angle > 160
            },
            correction: "Extend your arms fully overhead"
        )
    ]

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    func startAnalysis(for exerciseType: ExerciseType) {
        currentExercise = Self.exerciseDefinitions[exerciseType]
        reset()
    }

    func stopAnalysis() {
        currentExercise = nil
        reset()
    }

    func reset() {
        repCount = 0
        currentPhase = .start
        formStatus = .unknown
        lastFormCorrection = nil
        currentAngle = nil
        symmetryStatus = .balanced
        leftKneeAngle = nil
        rightKneeAngle = nil
        angleHistory.removeAll()
        formCheckResults.removeAll()
        consecutiveGoodFrames = 0
        consecutiveBadFrames = 0

        // Reset Kalman filters
        rightKneeFilter.reset()
        leftKneeFilter.reset()
        angleFilter.reset()

        // Reset adaptive thresholds
        calibrationReps = 0
        minAngleObserved = 180
        maxAngleObserved = 0
        isCalibrated = false
        adaptiveUpThreshold = 160
        adaptiveDownThreshold = 100

        // Reset Y-position tracking for front camera mode
        standingKneeY = nil
        standingLeftKneeY = nil
        standingHipY = nil
        maxKneeDrop = 0

        // Reset frame counters for phase transitions
        framesAtDownThreshold = 0
        framesAtUpThreshold = 0

        // Reset active leg detection
        activeLeg = .both
    }

    func analyzePose(_ pose: DetectedPose) {
        guard let exercise = currentExercise else { return }

        // For front camera with lower body exercises, use Y-position tracking
        if useFrontCamera && (exercise.type == .squat || exercise.type == .lunge) {
            analyzeWithYPosition(pose: pose, exercise: exercise)
        } else {
            analyzeWithAngle(pose: pose, exercise: exercise)
        }

        // Check form
        checkForm(pose: pose, exercise: exercise)
    }

    /// Analyze using traditional angle-based detection (works for side view and upper body)
    private func analyzeWithAngle(pose: DetectedPose, exercise: ExerciseDefinition) {
        let joints = exercise.primaryJoints[0]
        guard let angle = pose.angle(from: joints.from, through: joints.through, to: joints.to) else {
            return
        }

        currentAngle = angle
        updateAngleHistory(angle)

        let smoothedAngle = smoothedCurrentAngle
        detectPhaseAndCountReps(angle: smoothedAngle, exercise: exercise)
    }

    /// Analyze using Y-position tracking (works for front camera with squats/lunges)
    /// Enhanced with Kalman filtering, both knees tracking, and adaptive thresholds
    private func analyzeWithYPosition(pose: DetectedPose, exercise: ExerciseDefinition) {
        // Track BOTH knees for symmetry detection
        guard let rightHip = pose.joints[.rightHip],
              let rightKnee = pose.joints[.rightKnee],
              let rightAnkle = pose.joints[.rightAnkle] else {
            return
        }

        // Get left side (optional - for symmetry)
        let leftKnee = pose.joints[.leftKnee]
        let leftHip = pose.joints[.leftHip]
        let leftAnkle = pose.joints[.leftAnkle]

        // Calibrate standing position on first detection
        if standingKneeY == nil {
            standingKneeY = rightKnee.y
            standingLeftKneeY = leftKnee?.y
            print("[Squat] Initial standing - Right knee Y: \(rightKnee.y), Left knee Y: \(leftKnee?.y ?? 0)")
        }

        // Calculate leg length for normalization
        let upperLegLength = abs(rightHip.y - rightKnee.y)
        let lowerLegLength = abs(rightKnee.y - rightAnkle.y)
        let totalLegLength = upperLegLength + lowerLegLength
        guard totalLegLength > 0.1 else { return }

        // ========== RIGHT KNEE TRACKING ==========
        // NOTE: In Vision framework for front camera, Y=0 is TOP, Y=1 is BOTTOM
        // When squatting DOWN, the knee moves down in frame, so Y INCREASES
        // So kneeDrop = currentY - standingY (positive when squatting)
        let rawRightKneeDrop = (rightKnee.y - (standingKneeY ?? rightKnee.y)) / totalLegLength
        let rightKneeDrop = max(0, rawRightKneeDrop)

        // Debug: Print raw values every ~1 second
        if Int.random(in: 0..<30) == 0 {
            print("[DEBUG] Raw: kneeY=\(String(format: "%.3f", rightKnee.y)) standingY=\(String(format: "%.3f", standingKneeY ?? 0)) legLen=\(String(format: "%.3f", totalLegLength)) rawDrop=\(String(format: "%.3f", rawRightKneeDrop)) drop=\(String(format: "%.3f", rightKneeDrop))")
        }

        // Convert to pseudo-angle (no heavy filtering - needs to be responsive)
        // Use simple exponential smoothing instead of Kalman for faster response
        let rightPseudoAngle = 180.0 - (Double(rightKneeDrop) * 250.0)
        let clampedRightAngle = max(60.0, min(180.0, rightPseudoAngle))
        rightKneeAngle = clampedRightAngle

        // ========== LEFT KNEE TRACKING (for symmetry) ==========
        var clampedLeftAngle: Double = clampedRightAngle  // Default to right if left not visible
        if let leftKnee = leftKnee, let standingLeft = standingLeftKneeY {
            let leftLegLength = abs((leftHip?.y ?? rightHip.y) - leftKnee.y) + abs(leftKnee.y - (leftAnkle?.y ?? rightAnkle.y))
            guard leftLegLength > 0.1 else { return }

            let rawLeftKneeDrop = (leftKnee.y - standingLeft) / leftLegLength
            let leftKneeDrop = max(0, rawLeftKneeDrop)

            let leftPseudoAngle = 180.0 - (Double(leftKneeDrop) * 250.0)
            clampedLeftAngle = max(60.0, min(180.0, leftPseudoAngle))
            leftKneeAngle = clampedLeftAngle
        }

        // ========== SYMMETRY DETECTION ==========
        let angleDifference = abs(clampedRightAngle - clampedLeftAngle)
        if angleDifference > 15 {
            // Significant asymmetry detected
            if clampedLeftAngle < clampedRightAngle {
                symmetryStatus = .favoringLeft  // Left is deeper = favoring left
            } else {
                symmetryStatus = .favoringRight
            }
        } else {
            symmetryStatus = .balanced
        }

        // ========== ACTIVE LEG DETECTION ==========
        // Automatically detect which leg is being used based on which knee is bending more
        // This supports single-leg squats where user switches legs mid-set
        let rightIsActive = clampedRightAngle < 160  // Right leg is bending
        let leftIsActive = clampedLeftAngle < 160    // Left leg is bending

        // Determine which leg to use for rep counting
        let angleForCounting: Double
        if rightIsActive && leftIsActive {
            // Both legs bending - regular squat, use the deeper one
            angleForCounting = min(clampedRightAngle, clampedLeftAngle)
            activeLeg = .both
        } else if leftIsActive && !rightIsActive {
            // Only left leg bending - single leg squat on left
            angleForCounting = clampedLeftAngle
            activeLeg = .left
        } else if rightIsActive && !leftIsActive {
            // Only right leg bending - single leg squat on right
            angleForCounting = clampedRightAngle
            activeLeg = .right
        } else {
            // Neither bending much - use right as default (standing position)
            angleForCounting = clampedRightAngle
            activeLeg = .both
        }

        // Use the active leg's angle for phase detection
        currentAngle = angleForCounting

        // ========== ADAPTIVE THRESHOLD LEARNING ==========
        // Track min/max angles during first few reps to learn user's range
        // Use the active leg's angle for calibration
        if !isCalibrated {
            minAngleObserved = min(minAngleObserved, angleForCounting)
            maxAngleObserved = max(maxAngleObserved, angleForCounting)
        }

        maxKneeDrop = max(maxKneeDrop, rightKneeDrop)

        // Debug logging (less frequent)
        if Int.random(in: 0..<10) == 0 {
            let legStr = activeLeg == .left ? "L" : (activeLeg == .right ? "R" : "B")
            print("[Squat] leg=\(legStr) angle:\(String(format: "%.0f", angleForCounting))° (L:\(String(format: "%.0f", clampedLeftAngle))° R:\(String(format: "%.0f", clampedRightAngle))°) phase=\(currentPhase) reps=\(repCount)")
        }

        updateAngleHistory(angleForCounting)

        // Use adaptive thresholds if calibrated, otherwise use defaults
        let upThreshold = isCalibrated ? adaptiveUpThreshold : exercise.upPhaseAngleThreshold
        let downThreshold = isCalibrated ? adaptiveDownThreshold : exercise.downPhaseAngleThreshold

        detectPhaseAndCountReps(angle: angleForCounting, upThreshold: upThreshold, downThreshold: downThreshold)

        // Only reset standing position when fully standing AND after a rep
        if rightKneeDrop < 0.03 && currentPhase == .rest {
            standingKneeY = rightKnee.y
            standingLeftKneeY = leftKnee?.y
        }
    }

    // MARK: - Private Methods

    private func updateAngleHistory(_ angle: Double) {
        angleHistory.append(angle)
        if angleHistory.count > angleHistorySize {
            angleHistory.removeFirst()
        }
    }

    private var smoothedCurrentAngle: Double {
        guard !angleHistory.isEmpty else { return 0 }
        return angleHistory.reduce(0, +) / Double(angleHistory.count)
    }

    // Track consecutive frames at threshold for stability
    private var framesAtDownThreshold: Int = 0
    private var framesAtUpThreshold: Int = 0
    private let framesNeededForTransition: Int = 3  // Require 3 consecutive frames (~100ms)

    /// Detect exercise phase and count reps using provided thresholds
    private func detectPhaseAndCountReps(angle: Double, upThreshold: Double, downThreshold: Double) {
        let previousPhase = currentPhase

        switch currentPhase {
        case .start, .rest:
            // Wait for eccentric (going down) to start
            // Require a significant drop (20° below up threshold) to prevent false starts
            if angle < upThreshold - 20 {
                currentPhase = .eccentric
                framesAtDownThreshold = 0
            }

        case .eccentric:
            // Check if we've reached the bottom - require consecutive frames
            if angle < downThreshold {
                framesAtDownThreshold += 1
                if framesAtDownThreshold >= framesNeededForTransition {
                    currentPhase = .concentric
                    framesAtUpThreshold = 0
                }
            } else {
                framesAtDownThreshold = 0  // Reset if we bounce back up
            }

        case .concentric:
            // Check if we've returned to the top - require consecutive frames
            if angle > upThreshold {
                framesAtUpThreshold += 1
                if framesAtUpThreshold >= framesNeededForTransition {
                    // Count the rep
                    let now = Date()
                    if now.timeIntervalSince(lastRepTime) >= minRepInterval {
                        repCount += 1
                        lastRepTime = now

                        // Update calibration after rep
                        calibrationReps += 1
                        if calibrationReps >= calibrationRepsNeeded && !isCalibrated {
                            calibrateThresholds()
                        }
                    }
                    currentPhase = .rest
                    framesAtDownThreshold = 0
                }
            } else {
                framesAtUpThreshold = 0  // Reset if we go back down
            }

        case .hold:
            break
        }

        // Log phase transitions for debugging
        if previousPhase != currentPhase {
            print("[ExerciseAnalysis] Phase: \(previousPhase) → \(currentPhase), angle: \(String(format: "%.1f", angle))° (thresholds: up=\(String(format: "%.0f", upThreshold))° down=\(String(format: "%.0f", downThreshold))°)")
        }
    }

    /// Original method for compatibility with angle-based exercises
    private func detectPhaseAndCountReps(angle: Double, exercise: ExerciseDefinition) {
        detectPhaseAndCountReps(
            angle: angle,
            upThreshold: exercise.upPhaseAngleThreshold,
            downThreshold: exercise.downPhaseAngleThreshold
        )
    }

    /// Calibrate adaptive thresholds based on observed range of motion
    private func calibrateThresholds() {
        // Calculate adaptive thresholds based on user's actual range
        // Up threshold: slightly below max observed (when standing)
        // Down threshold: slightly above min observed (at bottom)

        let range = maxAngleObserved - minAngleObserved
        guard range > 20 else {
            // Not enough range detected, keep defaults
            print("[Calibration] Insufficient range detected (\(String(format: "%.0f", range))°), keeping defaults")
            return
        }

        // Set thresholds at 15% from each end of observed range
        adaptiveUpThreshold = maxAngleObserved - (range * 0.15)
        adaptiveDownThreshold = minAngleObserved + (range * 0.15)

        isCalibrated = true
        print("[Calibration] Adapted thresholds - Up: \(String(format: "%.0f", adaptiveUpThreshold))° Down: \(String(format: "%.0f", adaptiveDownThreshold))° (observed range: \(String(format: "%.0f", minAngleObserved))° - \(String(format: "%.0f", maxAngleObserved))°)")
    }

    private func checkForm(pose: DetectedPose, exercise: ExerciseDefinition) {
        var allChecksPassed = true
        var failedCorrection: String?

        for checkpoint in exercise.formCheckpoints {
            let result = checkpoint.validate(pose)

            switch result {
            case .passed:
                formCheckResults[checkpoint.name] = true
            case .failed(let correction):
                formCheckResults[checkpoint.name] = false
                allChecksPassed = false
                failedCorrection = correction
            case .unknown:
                // Can't evaluate - skip
                break
            }
        }

        // Update form status with hysteresis
        if allChecksPassed {
            consecutiveGoodFrames += 1
            consecutiveBadFrames = 0

            if consecutiveGoodFrames >= formThreshold {
                formStatus = .good
                lastFormCorrection = nil
            }
        } else {
            consecutiveBadFrames += 1
            consecutiveGoodFrames = 0

            if consecutiveBadFrames >= formThreshold {
                formStatus = .needsCorrection
                lastFormCorrection = failedCorrection
            }
        }
    }
}
