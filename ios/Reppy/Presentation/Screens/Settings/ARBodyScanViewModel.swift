import SwiftUI
import AVFoundation
import Vision
import ARKit
import Combine

// MARK: - Audio Guidance

class AudioGuidance {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenMode: String?

    init() {
        // Configure audio session to work even in silent mode
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func speak(_ text: String, force: Bool = false) {
        // Avoid repeating the same instruction
        if !force && lastSpokenMode == text {
            return
        }

        // Ensure audio session is active
        configureAudioSession()

        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52 // Faster pace
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.1

        synthesizer.speak(utterance)
        lastSpokenMode = text
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        lastSpokenMode = nil
    }
}

// MARK: - Scan Measurements Result

struct ScanMeasurements {
    let neckCm: Double
    let shouldersCm: Double
    let chestCm: Double
    let waistCm: Double
    let hipsCm: Double
    let confidence: Double
    let method: String // "ARKit Body Tracking", "Vision", etc.
}

// MARK: - AR Body Scan ViewModel

@MainActor
final class ARBodyScanViewModel: NSObject, ObservableObject {

    // MARK: - Scan Mode

    enum ScanMode: Equatable {
        case tutorial
        case detecting
        case tooClose
        case tooFar
        case positioningFront
        case countdown(Int)
        case capturingFront
        case turningSide
        case positioningSide
        case capturingSide
        case processing
        case complete
        case error(String)

        static func == (lhs: ScanMode, rhs: ScanMode) -> Bool {
            switch (lhs, rhs) {
            case (.tutorial, .tutorial),
                 (.detecting, .detecting),
                 (.tooClose, .tooClose),
                 (.tooFar, .tooFar),
                 (.positioningFront, .positioningFront),
                 (.capturingFront, .capturingFront),
                 (.turningSide, .turningSide),
                 (.positioningSide, .positioningSide),
                 (.capturingSide, .capturingSide),
                 (.processing, .processing),
                 (.complete, .complete):
                return true
            case (.countdown(let a), .countdown(let b)):
                return a == b
            case (.error(let a), .error(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    // MARK: - Device Capability

    enum DeviceCapability {
        case bodyTrackingSupported  // ARKit body tracking (A12+)
        case visionOnly             // Vision framework only

        var shortName: String {
            switch self {
            case .bodyTrackingSupported: return "AR Body"
            case .visionOnly: return "Vision"
            }
        }

        var color: Color {
            switch self {
            case .bodyTrackingSupported: return .green
            case .visionOnly: return .orange
            }
        }

        var description: String {
            switch self {
            case .bodyTrackingSupported:
                return "Using AR body tracking for accurate 3D measurements"
            case .visionOnly:
                return "Using camera-based estimation"
            }
        }
    }

    // MARK: - Detected Pose

    struct DetectedPose {
        let joints: [String: CGPoint]

        var connections: [(String, String)] {
            [
                ("neck", "leftShoulder"),
                ("neck", "rightShoulder"),
                ("leftShoulder", "leftElbow"),
                ("rightShoulder", "rightElbow"),
                ("leftElbow", "leftWrist"),
                ("rightElbow", "rightWrist"),
                ("neck", "root"),
                ("root", "leftHip"),
                ("root", "rightHip"),
                ("leftHip", "leftKnee"),
                ("rightHip", "rightKnee"),
                ("leftKnee", "leftAnkle"),
                ("rightKnee", "rightAnkle")
            ]
        }
    }

    // MARK: - 3D Skeleton (for ARKit)

    struct Skeleton3D {
        let joints: [String: simd_float4x4]
        let confidence: Float

        func position(for joint: String) -> simd_float3? {
            guard let transform = joints[joint] else { return nil }
            return simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        }

        func distance(from joint1: String, to joint2: String) -> Float? {
            guard let p1 = position(for: joint1),
                  let p2 = position(for: joint2) else { return nil }
            return simd_distance(p1, p2)
        }
    }

    // MARK: - Published Properties

    @Published var currentMode: ScanMode = .tutorial {
        didSet {
            provideAudioGuidance(for: currentMode)
        }
    }
    @Published var isCameraReady = false
    @Published var detectedPose: DetectedPose?
    @Published var showSkeleton = false // Disabled for better performance
    @Published var isBodyAligned = false {
        didSet {
            if isBodyAligned && !oldValue {
                // Body just became aligned
                provideAlignmentFeedback()
            }
        }
    }
    @Published var currentStep = 1
    @Published var finalMeasurements: ScanMeasurements?

    // MARK: - User Properties

    var userHeightCm: Double = 170
    var userSex: Sex = .male

    // MARK: - Computed Properties

    var showCaptureButton: Bool {
        switch currentMode {
        case .positioningFront, .positioningSide:
            return true
        default:
            return false
        }
    }

    var deviceCapability: DeviceCapability {
        if ARBodyTrackingConfiguration.isSupported {
            return .bodyTrackingSupported
        } else {
            return .visionOnly
        }
    }

    private var useARKit: Bool {
        deviceCapability == .bodyTrackingSupported
    }

    // MARK: - ARKit Properties

    private(set) var arSession: ARSession?
    private var currentSkeleton3D: Skeleton3D?
    private var frontSkeleton3D: Skeleton3D?
    private var sideSkeleton3D: Skeleton3D?

    // MARK: - Camera Properties (for Vision fallback)
    // These are nonisolated because they're accessed from videoQueue

    nonisolated(unsafe) let captureSession = AVCaptureSession()
    nonisolated(unsafe) private var videoOutput: AVCaptureVideoDataOutput?
    nonisolated(unsafe) private var photoOutput: AVCapturePhotoOutput?
    private let videoQueue = DispatchQueue(label: "com.reppy.bodyscan.video")

    // MARK: - Vision Properties

    private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    private var lastPoseDetectionTime = Date.distantPast
    private let poseDetectionInterval: TimeInterval = 0.25 // Reduced frequency for better performance

    // MARK: - Capture State

    private var frontImage: CGImage?
    private var sideImage: CGImage?
    private var frontPose: VNHumanBodyPoseObservation?
    private var sidePose: VNHumanBodyPoseObservation?

    // MARK: - Timers

    private var countdownTimer: Timer?

    // MARK: - Audio Guidance

    private let audioGuidance = AudioGuidance()
    private var lastAudioTime = Date.distantPast
    private let audioThrottleInterval: TimeInterval = 2.0 // Minimum 2 seconds between audio updates

    // MARK: - Init

    override init() {
        super.init()
    }

    // MARK: - Public Methods

    func startScanning() {
        currentMode = .detecting

        if useARKit {
            setupARSession()
        } else {
            requestCameraPermission()
        }
    }

    func capture() {
        guard isBodyAligned else { return }

        switch currentMode {
        case .positioningFront:
            startCountdown(for: .capturingFront)
        case .positioningSide:
            startCountdown(for: .capturingSide)
        default:
            break
        }
    }

    func reset() {
        frontImage = nil
        sideImage = nil
        frontPose = nil
        sidePose = nil
        frontSkeleton3D = nil
        sideSkeleton3D = nil
        currentSkeleton3D = nil
        currentStep = 1
        finalMeasurements = nil
        isBodyAligned = false
        detectedPose = nil
        currentMode = .tutorial

        countdownTimer?.invalidate()
    }

    func stopSession() {
        if useARKit {
            arSession?.pause()
        } else {
            captureSession.stopRunning()
        }
        countdownTimer?.invalidate()
        audioGuidance.stop()
    }

    // MARK: - Audio Guidance

    private func provideAlignmentFeedback() {
        // Simplified - only speak if not recently spoken
        let now = Date()
        guard now.timeIntervalSince(lastAudioTime) >= 3.0 else { return }
        lastAudioTime = now

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            switch self.currentMode {
            case .positioningFront:
                self.audioGuidance.speak("Ready. Tap to capture", force: true)
            case .positioningSide:
                self.audioGuidance.speak("Ready. Tap to capture", force: true)
            default:
                break
            }
        }
    }

    private func provideAudioGuidance(for mode: ScanMode) {
        // Skip audio for positioning states to avoid spam
        let shouldThrottle: Bool
        switch mode {
        case .positioningFront, .positioningSide, .detecting, .tooClose, .tooFar:
            shouldThrottle = true
        default:
            shouldThrottle = false
        }

        // Throttle non-critical audio
        if shouldThrottle {
            let now = Date()
            guard now.timeIntervalSince(lastAudioTime) >= audioThrottleInterval else {
                return
            }
            lastAudioTime = now
        }

        // Run audio on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            switch mode {
            case .tutorial:
                // No audio during tutorial (user is reading)
                break

            case .detecting:
                self.audioGuidance.speak("Looking for you")

            case .tooClose:
                self.audioGuidance.speak("Step back")

            case .tooFar:
                self.audioGuidance.speak("Step closer")

            case .positioningFront:
                if self.isBodyAligned {
                    self.audioGuidance.speak("Perfect. Tap to capture")
                } else {
                    self.audioGuidance.speak("Face the camera")
                }

            case .countdown(let count):
                self.audioGuidance.speak("\(count)", force: true)

            case .capturingFront:
                self.audioGuidance.speak("Hold still")

            case .turningSide:
                self.audioGuidance.speak("Great! Now turn sideways")

            case .positioningSide:
                if self.isBodyAligned {
                    self.audioGuidance.speak("Perfect. Tap to capture")
                } else {
                    self.audioGuidance.speak("Show your side")
                }

            case .capturingSide:
                self.audioGuidance.speak("Hold still")

            case .processing:
                self.audioGuidance.speak("Processing")

            case .complete:
                self.audioGuidance.speak("Scan complete")

            case .error(let message):
                self.audioGuidance.speak("Error: \(message)")
            }
        }
    }

    // MARK: - ARKit Setup

    private func setupARSession() {
        guard ARBodyTrackingConfiguration.isSupported else {
            // Fallback to Vision
            requestCameraPermission()
            return
        }

        let configuration = ARBodyTrackingConfiguration()
        configuration.automaticSkeletonScaleEstimationEnabled = true

        arSession = ARSession()
        arSession?.delegate = self

        arSession?.run(configuration)
        isCameraReady = true
    }

    // MARK: - Camera Setup (Vision fallback)

    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.currentMode = .error("Camera access is required for body scanning.")
                    }
                }
            }
        default:
            currentMode = .error("Camera access denied. Please enable in Settings.")
        }
    }

    private func setupCamera() {
        videoQueue.async { [weak self] in
            guard let self = self else { return }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .hd1280x720 // Use 720p for better performance

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                DispatchQueue.main.async {
                    self.currentMode = .error("Failed to access camera.")
                }
                return
            }

            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: self.videoQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true

            if self.captureSession.canAddOutput(videoOutput) {
                self.captureSession.addOutput(videoOutput)
                self.videoOutput = videoOutput
            }

            let photoOutput = AVCapturePhotoOutput()
            if self.captureSession.canAddOutput(photoOutput) {
                self.captureSession.addOutput(photoOutput)
                self.photoOutput = photoOutput
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()

            DispatchQueue.main.async {
                self.isCameraReady = true
            }
        }
    }

    // MARK: - Countdown

    private func startCountdown(for captureMode: ScanMode) {
        var count = 3
        currentMode = .countdown(count)

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            count -= 1

            if count > 0 {
                Task { @MainActor in
                    self.currentMode = .countdown(count)
                }
            } else {
                timer.invalidate()
                Task { @MainActor in
                    self.performCapture(mode: captureMode)
                }
            }
        }
    }

    // MARK: - Capture

    private func performCapture(mode: ScanMode) {
        currentMode = mode

        if useARKit {
            // Capture current skeleton
            captureARKitSkeleton(for: mode)
        } else {
            // Capture photo for Vision
            let settings = AVCapturePhotoSettings()
            photoOutput?.capturePhoto(with: settings, delegate: self)
        }
    }

    private func captureARKitSkeleton(for mode: ScanMode) {
        guard let skeleton = currentSkeleton3D else {
            currentMode = .error("No body detected. Please try again.")
            return
        }

        switch mode {
        case .capturingFront:
            frontSkeleton3D = skeleton
            currentStep = 2

            // Transition to side capture
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.currentMode = .turningSide

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.currentMode = .positioningSide
                }
            }

        case .capturingSide:
            sideSkeleton3D = skeleton

            // Calculate measurements from 3D skeletons
            calculateARKitMeasurements()

        default:
            break
        }
    }

    // MARK: - ARKit Measurement Calculation

    private func calculateARKitMeasurements() {
        currentMode = .processing

        Task {
            guard let frontSkeleton = frontSkeleton3D else {
                await MainActor.run {
                    self.currentMode = .error("Missing body data. Please try again.")
                }
                return
            }

            // Calculate measurements from 3D skeleton
            let measurements = calculateFromSkeleton3D(front: frontSkeleton, side: sideSkeleton3D)

            await MainActor.run {
                self.finalMeasurements = measurements
                self.currentMode = .complete
            }
        }
    }

    private func calculateFromSkeleton3D(front: Skeleton3D, side: Skeleton3D?) -> ScanMeasurements {
        // Get key measurements from 3D skeleton
        // ARKit skeleton joint names differ from Vision

        // Shoulder width (3D distance)
        let shoulderWidth = front.distance(from: "left_shoulder_1_joint", to: "right_shoulder_1_joint") ?? 0.4

        // Hip width
        let hipWidth = front.distance(from: "left_upLeg_joint", to: "right_upLeg_joint") ?? 0.3

        // Torso height (for scale reference)
        let torsoHeight = front.distance(from: "neck_1_joint", to: "hips_joint") ?? 0.5

        // Convert to cm using known height
        let heightScale = userHeightCm / Double(torsoHeight * 3.0) // Torso is roughly 1/3 of height

        let shoulderWidthCm = Double(shoulderWidth) * heightScale
        let hipWidthCm = Double(hipWidth) * heightScale

        // With 3D data, we can estimate depth more accurately
        var depthRatio: Double = 0.65

        // If we have side skeleton, calculate actual front-to-side ratio
        if let side = side {
            if let frontShoulderWidth = front.distance(from: "left_shoulder_1_joint", to: "right_shoulder_1_joint"),
               let sideShoulderDepth = side.distance(from: "left_shoulder_1_joint", to: "right_shoulder_1_joint") {
                depthRatio = Double(sideShoulderDepth / frontShoulderWidth)
            }
        }

        // Calculate circumferences
        let shoulderCircumference = calculateCircumference(frontWidth: shoulderWidthCm, depthRatio: depthRatio * 0.85)
        let hipCircumference = calculateCircumference(frontWidth: hipWidthCm, depthRatio: depthRatio * 1.1)

        let waistWidthCm = hipWidthCm * 0.85
        let waistCircumference = calculateCircumference(frontWidth: waistWidthCm, depthRatio: depthRatio)

        let chestWidthCm = (shoulderWidthCm + waistWidthCm) / 2 * 1.05
        let chestCircumference = calculateCircumference(frontWidth: chestWidthCm, depthRatio: depthRatio * 0.95)

        let neckWidthCm = shoulderWidthCm * 0.35
        let neckCircumference = calculateCircumference(frontWidth: neckWidthCm, depthRatio: 0.9)

        // Higher confidence with ARKit 3D tracking
        var confidence = Double(front.confidence)
        if side != nil {
            confidence = min(1.0, confidence + 0.15)
        }
        // ARKit body tracking is more accurate
        confidence = min(1.0, confidence + 0.1)

        return ScanMeasurements(
            neckCm: max(30, min(55, neckCircumference)),
            shouldersCm: max(80, min(150, shoulderCircumference)),
            chestCm: max(70, min(150, chestCircumference)),
            waistCm: max(55, min(150, waistCircumference)),
            hipsCm: max(70, min(160, hipCircumference)),
            confidence: confidence,
            method: "ARKit Body Tracking"
        )
    }

    // MARK: - Vision Pose Detection

    private func detectPose(in sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let now = Date()
        guard now.timeIntervalSince(lastPoseDetectionTime) >= poseDetectionInterval else { return }
        lastPoseDetectionTime = now

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([bodyPoseRequest])

            guard let observation = bodyPoseRequest.results?.first else {
                DispatchQueue.main.async { [weak self] in
                    self?.detectedPose = nil
                    self?.updateModeForNoBody()
                }
                return
            }

            var joints: [String: CGPoint] = [:]
            let jointNames: [(VNHumanBodyPoseObservation.JointName, String)] = [
                (.nose, "nose"),
                (.neck, "neck"),
                (.leftShoulder, "leftShoulder"),
                (.rightShoulder, "rightShoulder"),
                (.leftElbow, "leftElbow"),
                (.rightElbow, "rightElbow"),
                (.leftWrist, "leftWrist"),
                (.rightWrist, "rightWrist"),
                (.root, "root"),
                (.leftHip, "leftHip"),
                (.rightHip, "rightHip"),
                (.leftKnee, "leftKnee"),
                (.rightKnee, "rightKnee"),
                (.leftAnkle, "leftAnkle"),
                (.rightAnkle, "rightAnkle")
            ]

            for (visionName, stringName) in jointNames {
                if let point = try? observation.recognizedPoint(visionName),
                   point.confidence > 0.3 {
                    joints[stringName] = CGPoint(x: point.x, y: 1 - point.y)
                }
            }

            let pose = DetectedPose(joints: joints)
            let isAligned = checkBodyAlignment(pose: pose)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.detectedPose = pose
                self.isBodyAligned = isAligned
                self.updateModeForDetectedBody(pose: pose)

                if self.currentMode == .capturingFront {
                    self.frontPose = observation
                } else if self.currentMode == .capturingSide {
                    self.sidePose = observation
                }
            }

        } catch {
            // Pose detection failed silently
        }
    }

    private func checkBodyAlignment(pose: DetectedPose) -> Bool {
        let requiredJoints = ["neck", "leftShoulder", "rightShoulder", "leftHip", "rightHip"]
        let hasAllJoints = requiredJoints.allSatisfy { pose.joints[$0] != nil }

        guard hasAllJoints else { return false }

        if let neck = pose.joints["neck"], let root = pose.joints["root"] {
            let verticalDistance = abs(neck.y - root.y)
            if verticalDistance < 0.15 { return false }
        }

        if let leftShoulder = pose.joints["leftShoulder"],
           let rightShoulder = pose.joints["rightShoulder"] {
            let centerX = (leftShoulder.x + rightShoulder.x) / 2
            if centerX < 0.3 || centerX > 0.7 { return false }
        }

        if let nose = pose.joints["nose"], let leftAnkle = pose.joints["leftAnkle"] {
            let bodyHeight = abs(nose.y - leftAnkle.y)
            if bodyHeight < 0.4 { return false }
            if bodyHeight > 0.95 { return false }
        }

        return true
    }

    private func updateModeForNoBody() {
        switch currentMode {
        case .detecting, .positioningFront, .positioningSide:
            if currentMode != .detecting {
                currentMode = .detecting
            }
        default:
            break
        }
    }

    private func updateModeForDetectedBody(pose: DetectedPose) {
        switch currentMode {
        case .detecting:
            if let nose = pose.joints["nose"], let ankle = pose.joints["leftAnkle"] ?? pose.joints["rightAnkle"] {
                let bodyHeight = abs(nose.y - ankle.y)

                if bodyHeight > 0.95 {
                    currentMode = .tooClose
                } else if bodyHeight < 0.4 {
                    currentMode = .tooFar
                } else {
                    currentMode = .positioningFront
                }
            } else {
                currentMode = .positioningFront
            }

        case .tooClose:
            if let nose = pose.joints["nose"], let ankle = pose.joints["leftAnkle"] ?? pose.joints["rightAnkle"] {
                let bodyHeight = abs(nose.y - ankle.y)
                if bodyHeight <= 0.95 {
                    currentMode = bodyHeight < 0.4 ? .tooFar : .positioningFront
                }
            }

        case .tooFar:
            if let nose = pose.joints["nose"], let ankle = pose.joints["leftAnkle"] ?? pose.joints["rightAnkle"] {
                let bodyHeight = abs(nose.y - ankle.y)
                if bodyHeight >= 0.4 {
                    currentMode = bodyHeight > 0.95 ? .tooClose : .positioningFront
                }
            }

        default:
            break
        }
    }

    // MARK: - Vision Measurement Calculation

    private func calculateVisionMeasurements() {
        currentMode = .processing

        Task {
            do {
                guard let frontPose = frontPose else {
                    throw MeasurementError.insufficientData
                }

                let measurements = try calculateFromPoses(front: frontPose, side: sidePose)

                await MainActor.run {
                    self.finalMeasurements = measurements
                    self.currentMode = .complete
                }

            } catch {
                await MainActor.run {
                    self.currentMode = .error("Could not calculate measurements. Please try again with better lighting.")
                }
            }
        }
    }

    private func calculateFromPoses(front: VNHumanBodyPoseObservation, side: VNHumanBodyPoseObservation?) throws -> ScanMeasurements {
        guard let leftShoulder = try? front.recognizedPoint(.leftShoulder),
              let rightShoulder = try? front.recognizedPoint(.rightShoulder),
              let leftHip = try? front.recognizedPoint(.leftHip),
              let rightHip = try? front.recognizedPoint(.rightHip),
              let _ = try? front.recognizedPoint(.neck) else {
            throw MeasurementError.insufficientData
        }

        var bodyHeightNormalized: CGFloat = 0.7

        if let nose = try? front.recognizedPoint(.nose),
           let ankle = try? front.recognizedPoint(.leftAnkle) {
            bodyHeightNormalized = abs(nose.y - ankle.y)
        } else if let ankle = try? front.recognizedPoint(.rightAnkle),
                  let nose = try? front.recognizedPoint(.nose) {
            bodyHeightNormalized = abs(nose.y - ankle.y)
        }

        let cmPerUnit = userHeightCm / Double(bodyHeightNormalized)

        let shoulderWidthNorm = abs(rightShoulder.x - leftShoulder.x)
        let hipWidthNorm = abs(rightHip.x - leftHip.x)

        let shoulderWidthCm = Double(shoulderWidthNorm) * cmPerUnit
        let hipWidthCm = Double(hipWidthNorm) * cmPerUnit

        var depthRatio: Double = 0.6

        if let side = side,
           let sideLeftShoulder = try? side.recognizedPoint(.leftShoulder),
           let sideRightShoulder = try? side.recognizedPoint(.rightShoulder) {
            let sideShoulderWidth = abs(sideRightShoulder.x - sideLeftShoulder.x)
            if shoulderWidthNorm > 0 {
                depthRatio = Double(sideShoulderWidth / shoulderWidthNorm)
            }
        }

        let shoulderCircumference = calculateCircumference(frontWidth: shoulderWidthCm, depthRatio: depthRatio * 0.8)
        let hipCircumference = calculateCircumference(frontWidth: hipWidthCm, depthRatio: depthRatio * 1.1)

        let waistWidthCm = hipWidthCm * 0.85
        let waistCircumference = calculateCircumference(frontWidth: waistWidthCm, depthRatio: depthRatio)

        let chestWidthCm = (shoulderWidthCm + waistWidthCm) / 2 * 1.05
        let chestCircumference = calculateCircumference(frontWidth: chestWidthCm, depthRatio: depthRatio * 0.95)

        let neckWidthCm = shoulderWidthCm * 0.35
        let neckCircumference = calculateCircumference(frontWidth: neckWidthCm, depthRatio: 0.9)

        var confidence = Double(front.confidence)
        if side != nil {
            confidence = min(1.0, confidence + 0.2)
        }

        return ScanMeasurements(
            neckCm: max(30, min(55, neckCircumference)),
            shouldersCm: max(80, min(150, shoulderCircumference)),
            chestCm: max(70, min(150, chestCircumference)),
            waistCm: max(55, min(150, waistCircumference)),
            hipsCm: max(70, min(160, hipCircumference)),
            confidence: confidence,
            method: "Vision Framework"
        )
    }

    private func calculateCircumference(frontWidth: Double, depthRatio: Double) -> Double {
        let a = frontWidth / 2
        let b = a * depthRatio

        let h = pow((a - b), 2) / pow((a + b), 2)
        let circumference = Double.pi * (a + b) * (1 + (3 * h) / (10 + sqrt(4 - 3 * h)))

        return circumference
    }

    enum MeasurementError: Error {
        case insufficientData
        case calculationFailed
    }
}

// MARK: - ARSessionDelegate

extension ARBodyScanViewModel: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

            let skeleton = bodyAnchor.skeleton

            // Extract joint transforms
            var joints: [String: simd_float4x4] = [:]

            // Map ARKit skeleton joints
            let jointNames = [
                "head_joint",
                "neck_1_joint",
                "left_shoulder_1_joint",
                "right_shoulder_1_joint",
                "left_arm_joint",
                "right_arm_joint",
                "left_forearm_joint",
                "right_forearm_joint",
                "left_hand_joint",
                "right_hand_joint",
                "hips_joint",
                "left_upLeg_joint",
                "right_upLeg_joint",
                "left_leg_joint",
                "right_leg_joint",
                "left_foot_joint",
                "right_foot_joint",
                "spine_1_joint",
                "spine_4_joint",
                "spine_7_joint"
            ]

            for name in jointNames {
                if let transform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: name)) {
                    joints[name] = transform
                }
            }

            let skeleton3D = Skeleton3D(
                joints: joints,
                confidence: bodyAnchor.isTracked ? 0.9 : 0.5
            )

            // Convert to 2D pose for UI display
            let pose2D = convert3DSkeletonTo2D(skeleton3D, in: session)

            Task { @MainActor in
                self.currentSkeleton3D = skeleton3D
                self.detectedPose = pose2D
                self.isBodyAligned = skeleton3D.joints.count >= 10 && bodyAnchor.isTracked

                // Update mode based on body detection
                if self.currentMode == .detecting && self.isBodyAligned {
                    self.currentMode = .positioningFront
                }
            }
        }
    }

    nonisolated private func convert3DSkeletonTo2D(_ skeleton: Skeleton3D, in session: ARSession) -> DetectedPose {
        // Simplified 2D projection for UI overlay
        var joints2D: [String: CGPoint] = [:]

        let mapping: [(String, String)] = [
            ("head_joint", "nose"),
            ("neck_1_joint", "neck"),
            ("left_shoulder_1_joint", "leftShoulder"),
            ("right_shoulder_1_joint", "rightShoulder"),
            ("left_forearm_joint", "leftElbow"),
            ("right_forearm_joint", "rightElbow"),
            ("left_hand_joint", "leftWrist"),
            ("right_hand_joint", "rightWrist"),
            ("hips_joint", "root"),
            ("left_upLeg_joint", "leftHip"),
            ("right_upLeg_joint", "rightHip"),
            ("left_leg_joint", "leftKnee"),
            ("right_leg_joint", "rightKnee"),
            ("left_foot_joint", "leftAnkle"),
            ("right_foot_joint", "rightAnkle")
        ]

        for (arkit, vision) in mapping {
            if let pos = skeleton.position(for: arkit) {
                // Simple projection (normalized 0-1)
                let x = CGFloat((pos.x + 1) / 2)
                let y = CGFloat(1 - (pos.y + 1) / 2)
                joints2D[vision] = CGPoint(x: x.clamped(to: 0...1), y: y.clamped(to: 0...1))
            }
        }

        return DetectedPose(joints: joints2D)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ARBodyScanViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        Task { @MainActor in
            // Only use Vision if not using ARKit
            guard !self.useARKit else { return }

            switch self.currentMode {
            case .detecting, .positioningFront, .positioningSide, .tooClose, .tooFar:
                self.detectPose(in: sampleBuffer)
            default:
                break
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension ARBodyScanViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)?.cgImage else {
            Task { @MainActor in
                self.currentMode = .error("Failed to capture photo. Please try again.")
            }
            return
        }

        Task { @MainActor in
            switch self.currentMode {
            case .capturingFront:
                self.frontImage = image
                self.currentStep = 2

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.currentMode = .turningSide

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.currentMode = .positioningSide
                    }
                }

            case .capturingSide:
                self.sideImage = image
                self.calculateVisionMeasurements()

            default:
                break
            }
        }
    }
}

// MARK: - CGFloat Extension

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
