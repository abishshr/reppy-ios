import SwiftUI
import Vision

struct PoseOverlayView: View {
    let pose: DetectedPose?
    let exerciseType: ExerciseType
    let formStatus: FormStatus
    let isInFrame: Bool  // True when all required joints are visible
    var showGuidePose: Bool = true  // Show reference pose when calibrating
    var currentPhase: ExercisePhase = .start

    private let jointRadius: CGFloat = 8
    private let lineWidth: CGFloat = 3

    /// Color for the skeleton based on in-frame status
    private var skeletonColor: Color {
        if isInFrame {
            return .green  // Green = you're good!
        } else {
            return .yellow  // Yellow = adjust position
        }
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw guide pose first (underneath user's skeleton)
                if showGuidePose && !isInFrame {
                    drawGuidePose(context: context, size: size)
                }

                guard let pose = pose else { return }

                // Draw skeleton connections
                drawConnections(context: context, pose: pose, size: size)

                // Draw joints
                drawJoints(context: context, pose: pose, size: size)
            }
        }
    }

    private func drawConnections(context: GraphicsContext, pose: DetectedPose, size: CGSize) {
        let connections = PoseDetectionService.skeletonConnections
        let keyJoints = Set(PoseDetectionService.keyJoints(for: exerciseType))

        for (start, end) in connections {
            guard let startPoint = pose.joints[start],
                  let endPoint = pose.joints[end] else {
                continue
            }

            let screenStart = normalizedToScreen(startPoint, size: size)
            let screenEnd = normalizedToScreen(endPoint, size: size)

            // Highlight key joints for the current exercise
            let isKeyConnection = keyJoints.contains(start) || keyJoints.contains(end)
            let color = connectionColor(isKey: isKeyConnection)

            var path = Path()
            path.move(to: screenStart)
            path.addLine(to: screenEnd)

            context.stroke(
                path,
                with: .color(color),
                lineWidth: isKeyConnection ? lineWidth + 1 : lineWidth
            )
        }
    }

    private func drawJoints(context: GraphicsContext, pose: DetectedPose, size: CGSize) {
        let keyJoints = Set(PoseDetectionService.keyJoints(for: exerciseType))

        for (jointName, point) in pose.joints {
            let screenPoint = normalizedToScreen(point, size: size)
            let confidence = pose.confidence[jointName] ?? 0

            // Skip low confidence joints
            guard confidence > 0.3 else { continue }

            let isKeyJoint = keyJoints.contains(jointName)
            let radius = isKeyJoint ? jointRadius + 2 : jointRadius
            let color = jointColor(isKey: isKeyJoint, confidence: confidence)

            let rect = CGRect(
                x: screenPoint.x - radius,
                y: screenPoint.y - radius,
                width: radius * 2,
                height: radius * 2
            )

            // Draw outer ring for key joints
            if isKeyJoint {
                let outerRect = rect.insetBy(dx: -2, dy: -2)
                context.stroke(
                    Path(ellipseIn: outerRect),
                    with: .color(formStatusColor),
                    lineWidth: 2
                )
            }

            // Draw joint circle
            context.fill(
                Path(ellipseIn: rect),
                with: .color(color)
            )
        }
    }

    private func normalizedToScreen(_ point: CGPoint, size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x * size.width,
            y: point.y * size.height
        )
    }

    private func connectionColor(isKey: Bool) -> Color {
        if !isInFrame {
            // Not in frame - show yellow to indicate adjustment needed
            return isKey ? .yellow.opacity(0.9) : .yellow.opacity(0.4)
        }
        if isKey {
            return formStatus == .good ? .green.opacity(0.9) : .white.opacity(0.9)
        }
        return .green.opacity(0.5)  // In frame = green skeleton
    }

    private func jointColor(isKey: Bool, confidence: Float) -> Color {
        let opacity = Double(confidence)
        if !isInFrame {
            // Not in frame - yellow joints
            return .yellow.opacity(opacity)
        }
        if isKey {
            return formStatus == .good ? .green.opacity(opacity) : .orange.opacity(opacity)
        }
        return .green.opacity(opacity * 0.8)  // In frame = green
    }

    private var formStatusColor: Color {
        if !isInFrame {
            return .yellow
        }
        switch formStatus {
        case .good:
            return .green
        case .needsCorrection:
            return .orange
        case .unknown:
            return .green  // In frame but unknown form = still green (ready)
        }
    }

    // MARK: - Guide Pose Drawing

    private func drawGuidePose(context: GraphicsContext, size: CGSize) {
        let guidePoints = GuidePose.points(for: exerciseType, phase: .start)
        let guideColor = Color.cyan.opacity(0.4)
        let guideLineWidth: CGFloat = 4

        // Draw guide connections
        let connections: [(String, String)] = [
            // Torso
            ("leftShoulder", "rightShoulder"),
            ("leftShoulder", "leftHip"),
            ("rightShoulder", "rightHip"),
            ("leftHip", "rightHip"),
            // Left arm
            ("leftShoulder", "leftElbow"),
            ("leftElbow", "leftWrist"),
            // Right arm
            ("rightShoulder", "rightElbow"),
            ("rightElbow", "rightWrist"),
            // Left leg
            ("leftHip", "leftKnee"),
            ("leftKnee", "leftAnkle"),
            // Right leg
            ("rightHip", "rightKnee"),
            ("rightKnee", "rightAnkle"),
            // Head
            ("leftShoulder", "neck"),
            ("rightShoulder", "neck"),
            ("neck", "head")
        ]

        for (startName, endName) in connections {
            guard let startPoint = guidePoints[startName],
                  let endPoint = guidePoints[endName] else {
                continue
            }

            let screenStart = CGPoint(x: startPoint.x * size.width, y: startPoint.y * size.height)
            let screenEnd = CGPoint(x: endPoint.x * size.width, y: endPoint.y * size.height)

            var path = Path()
            path.move(to: screenStart)
            path.addLine(to: screenEnd)

            // Draw dashed line for guide
            context.stroke(
                path,
                with: .color(guideColor),
                style: StrokeStyle(lineWidth: guideLineWidth, dash: [10, 5])
            )
        }

        // Draw guide joints
        for (_, point) in guidePoints {
            let screenPoint = CGPoint(x: point.x * size.width, y: point.y * size.height)
            let rect = CGRect(
                x: screenPoint.x - 6,
                y: screenPoint.y - 6,
                width: 12,
                height: 12
            )

            context.stroke(
                Path(ellipseIn: rect),
                with: .color(guideColor),
                lineWidth: 2
            )
        }

        // Draw "Match this pose" text
        let textPoint = CGPoint(x: size.width / 2, y: size.height * 0.15)
        context.draw(
            Text("Match this pose")
                .font(.headline)
                .foregroundColor(.cyan),
            at: textPoint
        )
    }
}

// MARK: - Guide Pose Data

/// Pre-defined reference poses for each exercise
struct GuidePose {
    /// Get normalized joint positions for a guide pose
    /// Coordinates are normalized (0-1) for both x and y
    /// Y=0 is top, Y=1 is bottom (matches Vision framework)
    static func points(for exercise: ExerciseType, phase: ExercisePhase) -> [String: CGPoint] {
        switch exercise {
        case .squat:
            return squatStandingPose

        case .lunge:
            return lungeStandingPose

        case .pushup:
            return pushupStartPose

        case .bicepCurl:
            return curlStandingPose

        case .shoulderPress:
            return pressStartPose

        default:
            return squatStandingPose  // Default to squat
        }
    }

    // MARK: - Squat Poses (Front View)

    /// Standing position for squat - centered in frame
    static let squatStandingPose: [String: CGPoint] = [
        "head": CGPoint(x: 0.5, y: 0.12),
        "neck": CGPoint(x: 0.5, y: 0.18),
        "leftShoulder": CGPoint(x: 0.38, y: 0.22),
        "rightShoulder": CGPoint(x: 0.62, y: 0.22),
        "leftElbow": CGPoint(x: 0.32, y: 0.35),
        "rightElbow": CGPoint(x: 0.68, y: 0.35),
        "leftWrist": CGPoint(x: 0.30, y: 0.48),
        "rightWrist": CGPoint(x: 0.70, y: 0.48),
        "leftHip": CGPoint(x: 0.42, y: 0.45),
        "rightHip": CGPoint(x: 0.58, y: 0.45),
        "leftKnee": CGPoint(x: 0.40, y: 0.65),
        "rightKnee": CGPoint(x: 0.60, y: 0.65),
        "leftAnkle": CGPoint(x: 0.40, y: 0.88),
        "rightAnkle": CGPoint(x: 0.60, y: 0.88)
    ]

    /// Bottom of squat position
    static let squatBottomPose: [String: CGPoint] = [
        "head": CGPoint(x: 0.5, y: 0.25),
        "neck": CGPoint(x: 0.5, y: 0.32),
        "leftShoulder": CGPoint(x: 0.38, y: 0.36),
        "rightShoulder": CGPoint(x: 0.62, y: 0.36),
        "leftElbow": CGPoint(x: 0.30, y: 0.42),
        "rightElbow": CGPoint(x: 0.70, y: 0.42),
        "leftWrist": CGPoint(x: 0.35, y: 0.52),
        "rightWrist": CGPoint(x: 0.65, y: 0.52),
        "leftHip": CGPoint(x: 0.40, y: 0.55),
        "rightHip": CGPoint(x: 0.60, y: 0.55),
        "leftKnee": CGPoint(x: 0.35, y: 0.70),
        "rightKnee": CGPoint(x: 0.65, y: 0.70),
        "leftAnkle": CGPoint(x: 0.40, y: 0.88),
        "rightAnkle": CGPoint(x: 0.60, y: 0.88)
    ]

    // MARK: - Lunge Pose

    static let lungeStandingPose: [String: CGPoint] = squatStandingPose

    // MARK: - Push-up Pose (Side View)

    static let pushupStartPose: [String: CGPoint] = [
        "head": CGPoint(x: 0.75, y: 0.35),
        "neck": CGPoint(x: 0.70, y: 0.38),
        "leftShoulder": CGPoint(x: 0.65, y: 0.40),
        "rightShoulder": CGPoint(x: 0.65, y: 0.40),
        "leftElbow": CGPoint(x: 0.65, y: 0.55),
        "rightElbow": CGPoint(x: 0.65, y: 0.55),
        "leftWrist": CGPoint(x: 0.65, y: 0.70),
        "rightWrist": CGPoint(x: 0.65, y: 0.70),
        "leftHip": CGPoint(x: 0.40, y: 0.42),
        "rightHip": CGPoint(x: 0.40, y: 0.42),
        "leftKnee": CGPoint(x: 0.25, y: 0.55),
        "rightKnee": CGPoint(x: 0.25, y: 0.55),
        "leftAnkle": CGPoint(x: 0.15, y: 0.70),
        "rightAnkle": CGPoint(x: 0.15, y: 0.70)
    ]

    // MARK: - Bicep Curl Pose

    static let curlStandingPose: [String: CGPoint] = [
        "head": CGPoint(x: 0.5, y: 0.10),
        "neck": CGPoint(x: 0.5, y: 0.16),
        "leftShoulder": CGPoint(x: 0.38, y: 0.20),
        "rightShoulder": CGPoint(x: 0.62, y: 0.20),
        "leftElbow": CGPoint(x: 0.35, y: 0.38),
        "rightElbow": CGPoint(x: 0.65, y: 0.38),
        "leftWrist": CGPoint(x: 0.35, y: 0.55),
        "rightWrist": CGPoint(x: 0.65, y: 0.55),
        "leftHip": CGPoint(x: 0.42, y: 0.45),
        "rightHip": CGPoint(x: 0.58, y: 0.45),
        "leftKnee": CGPoint(x: 0.42, y: 0.68),
        "rightKnee": CGPoint(x: 0.58, y: 0.68),
        "leftAnkle": CGPoint(x: 0.42, y: 0.90),
        "rightAnkle": CGPoint(x: 0.58, y: 0.90)
    ]

    // MARK: - Shoulder Press Pose

    static let pressStartPose: [String: CGPoint] = [
        "head": CGPoint(x: 0.5, y: 0.10),
        "neck": CGPoint(x: 0.5, y: 0.16),
        "leftShoulder": CGPoint(x: 0.38, y: 0.20),
        "rightShoulder": CGPoint(x: 0.62, y: 0.20),
        "leftElbow": CGPoint(x: 0.30, y: 0.28),
        "rightElbow": CGPoint(x: 0.70, y: 0.28),
        "leftWrist": CGPoint(x: 0.32, y: 0.18),
        "rightWrist": CGPoint(x: 0.68, y: 0.18),
        "leftHip": CGPoint(x: 0.42, y: 0.45),
        "rightHip": CGPoint(x: 0.58, y: 0.45),
        "leftKnee": CGPoint(x: 0.42, y: 0.68),
        "rightKnee": CGPoint(x: 0.58, y: 0.68),
        "leftAnkle": CGPoint(x: 0.42, y: 0.90),
        "rightAnkle": CGPoint(x: 0.58, y: 0.90)
    ]
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black

        PoseOverlayView(
            pose: nil,
            exerciseType: .squat,
            formStatus: .good,
            isInFrame: true
        )
    }
}
