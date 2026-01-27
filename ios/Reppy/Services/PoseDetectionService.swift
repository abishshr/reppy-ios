import Vision
import CoreMedia
import Combine
import UIKit

@MainActor
final class PoseDetectionService: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var currentPose: DetectedPose?
    @Published private(set) var isDetecting = false
    @Published private(set) var detectionConfidence: Float = 0

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let processingQueue = DispatchQueue(label: "com.reppy.pose.processing", qos: .userInteractive)
    private var lastProcessedTime: Date = .distantPast
    private let minProcessingInterval: TimeInterval = 1.0 / 30.0 // 30 fps max

    // MARK: - Initialization

    init() {}

    // MARK: - Frame Subscription

    func subscribeToFrames(_ publisher: AnyPublisher<CMSampleBuffer, Never>) {
        publisher
            .receive(on: processingQueue)
            .sink { [weak self] buffer in
                self?.processFrame(buffer)
            }
            .store(in: &cancellables)
    }

    func stopDetection() {
        cancellables.removeAll()
        Task { @MainActor in
            currentPose = nil
            isDetecting = false
        }
    }

    // MARK: - Frame Processing

    private func processFrame(_ buffer: CMSampleBuffer) {
        // Throttle processing
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= minProcessingInterval else { return }
        lastProcessedTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }

        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            if let error = error {
                print("[PoseDetection] Error: \(error.localizedDescription)")
                return
            }

            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                Task { @MainActor [weak self] in
                    self?.currentPose = nil
                    self?.detectionConfidence = 0
                }
                return
            }

            self?.processObservation(observation)
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([request])
            Task { @MainActor [weak self] in
                self?.isDetecting = true
            }
        } catch {
            print("[PoseDetection] Handler error: \(error.localizedDescription)")
        }
    }

    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        var confidences: [VNHumanBodyPoseObservation.JointName: Float] = [:]

        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist, .leftHip, .rightHip,
            .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
            .neck, .root
        ]

        var totalConfidence: Float = 0
        var jointCount: Float = 0

        for jointName in allJoints {
            if let point = try? observation.recognizedPoint(jointName),
               point.confidence > 0.1 {
                // Vision coordinates are normalized (0-1), origin at bottom-left
                // Convert to UIKit coordinates (origin at top-left)
                joints[jointName] = CGPoint(x: point.location.x, y: 1 - point.location.y)
                confidences[jointName] = point.confidence
                totalConfidence += point.confidence
                jointCount += 1
            }
        }

        let averageConfidence = jointCount > 0 ? totalConfidence / jointCount : 0

        let pose = DetectedPose(
            timestamp: Date(),
            joints: joints,
            confidence: confidences
        )

        Task { @MainActor [weak self] in
            self?.currentPose = pose
            self?.detectionConfidence = averageConfidence
        }
    }
}

// MARK: - Pose Drawing Helper

extension PoseDetectionService {
    /// Returns the connections between joints for drawing a skeleton
    static var skeletonConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        [
            // Head
            (.nose, .neck),
            (.leftEye, .nose),
            (.rightEye, .nose),
            (.leftEar, .leftEye),
            (.rightEar, .rightEye),

            // Torso
            (.neck, .leftShoulder),
            (.neck, .rightShoulder),
            (.leftShoulder, .leftHip),
            (.rightShoulder, .rightHip),
            (.leftHip, .rightHip),
            (.leftShoulder, .rightShoulder),

            // Left arm
            (.leftShoulder, .leftElbow),
            (.leftElbow, .leftWrist),

            // Right arm
            (.rightShoulder, .rightElbow),
            (.rightElbow, .rightWrist),

            // Left leg
            (.leftHip, .leftKnee),
            (.leftKnee, .leftAnkle),

            // Right leg
            (.rightHip, .rightKnee),
            (.rightKnee, .rightAnkle)
        ]
    }

    /// Key joints for specific exercises
    static func keyJoints(for exerciseType: ExerciseType) -> [VNHumanBodyPoseObservation.JointName] {
        switch exerciseType {
        case .squat:
            return [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle]
        case .pushup:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist]
        case .lunge:
            return [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle]
        case .bicepCurl:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist]
        case .shoulderPress:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist]
        case .plank:
            return [.leftShoulder, .rightShoulder, .leftHip, .rightHip, .leftAnkle, .rightAnkle]
        case .deadlift:
            return [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftShoulder, .rightShoulder]
        case .row:
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist]
        case .unknown:
            return []
        }
    }
}
