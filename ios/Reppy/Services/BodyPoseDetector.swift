import Vision
import CoreImage
import UIKit

/// Service for detecting body pose using Vision framework
final class BodyPoseDetector {

    // MARK: - Types

    struct BodyPoseResult {
        let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
        let confidence: Float

        /// Get a specific joint position
        func joint(_ name: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            joints[name]
        }

        /// Check if all required joints for measurement are detected
        var hasRequiredJoints: Bool {
            let required: [VNHumanBodyPoseObservation.JointName] = [
                .neck,
                .leftShoulder,
                .rightShoulder,
                .leftHip,
                .rightHip
            ]
            return required.allSatisfy { joints[$0] != nil }
        }
    }

    struct BodySegmentationResult {
        let mask: CIImage
        let bounds: CGRect
    }

    enum DetectionError: Error {
        case noBodyDetected
        case insufficientConfidence
        case processingFailed
    }

    // MARK: - Properties

    private let poseRequest: VNDetectHumanBodyPoseRequest
    private let segmentationRequest: VNGeneratePersonSegmentationRequest

    // MARK: - Init

    init() {
        poseRequest = VNDetectHumanBodyPoseRequest()
        segmentationRequest = VNGeneratePersonSegmentationRequest()
        segmentationRequest.qualityLevel = .balanced
    }

    // MARK: - Body Pose Detection

    /// Detect body pose in an image
    func detectBodyPose(in image: CGImage) async throws -> BodyPoseResult {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([poseRequest])

                guard let observation = poseRequest.results?.first else {
                    continuation.resume(throwing: DetectionError.noBodyDetected)
                    return
                }

                var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

                // Extract all available joints
                let jointNames: [VNHumanBodyPoseObservation.JointName] = [
                    .nose, .neck,
                    .leftShoulder, .rightShoulder,
                    .leftElbow, .rightElbow,
                    .leftWrist, .rightWrist,
                    .leftHip, .rightHip,
                    .leftKnee, .rightKnee,
                    .leftAnkle, .rightAnkle,
                    .root
                ]

                for jointName in jointNames {
                    if let point = try? observation.recognizedPoint(jointName),
                       point.confidence > 0.3 {
                        // Vision coordinates are normalized (0-1), with origin at bottom-left
                        joints[jointName] = CGPoint(x: point.x, y: 1 - point.y)
                    }
                }

                let result = BodyPoseResult(
                    joints: joints,
                    confidence: observation.confidence
                )

                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Detect body pose from sample buffer (for real-time camera feed)
    func detectBodyPose(in sampleBuffer: CMSampleBuffer) async throws -> BodyPoseResult {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw DetectionError.processingFailed
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([poseRequest])

                guard let observation = poseRequest.results?.first else {
                    continuation.resume(throwing: DetectionError.noBodyDetected)
                    return
                }

                var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

                let jointNames: [VNHumanBodyPoseObservation.JointName] = [
                    .nose, .neck,
                    .leftShoulder, .rightShoulder,
                    .leftElbow, .rightElbow,
                    .leftWrist, .rightWrist,
                    .leftHip, .rightHip,
                    .leftKnee, .rightKnee,
                    .leftAnkle, .rightAnkle,
                    .root
                ]

                for jointName in jointNames {
                    if let point = try? observation.recognizedPoint(jointName),
                       point.confidence > 0.3 {
                        joints[jointName] = CGPoint(x: point.x, y: 1 - point.y)
                    }
                }

                let result = BodyPoseResult(
                    joints: joints,
                    confidence: observation.confidence
                )

                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Body Segmentation

    /// Segment the person from the background
    func segmentPerson(in image: CGImage) async throws -> BodySegmentationResult {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([segmentationRequest])

                guard let observation = segmentationRequest.results?.first else {
                    continuation.resume(throwing: DetectionError.noBodyDetected)
                    return
                }

                let maskImage = CIImage(cvPixelBuffer: observation.pixelBuffer)

                // Calculate bounding box of the person
                let bounds = calculatePersonBounds(from: observation.pixelBuffer)

                let result = BodySegmentationResult(
                    mask: maskImage,
                    bounds: bounds
                )

                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Measurement Estimation

    /// Estimate body measurements from pose and image
    func estimateMeasurements(
        pose: BodyPoseResult,
        imageSize: CGSize,
        knownHeightCm: Double
    ) -> EstimatedMeasurements? {
        // We need shoulder and hip joints to estimate body width
        guard let leftShoulder = pose.joint(.leftShoulder),
              let rightShoulder = pose.joint(.rightShoulder),
              let leftHip = pose.joint(.leftHip),
              let rightHip = pose.joint(.rightHip) else {
            return nil
        }

        // Calculate pixel distances
        let shoulderWidthPx = abs(rightShoulder.x - leftShoulder.x) * imageSize.width
        let hipWidthPx = abs(rightHip.x - leftHip.x) * imageSize.width

        // Estimate body height in pixels (from top of head to ankles if available)
        var bodyHeightPx: CGFloat = 0

        if let nose = pose.joint(.nose), let leftAnkle = pose.joint(.leftAnkle) {
            bodyHeightPx = abs(nose.y - leftAnkle.y) * imageSize.height
        } else if let neck = pose.joint(.neck), let leftHip = pose.joint(.leftHip) {
            // Fallback: estimate from neck to hip
            let torsoHeight = abs(neck.y - leftHip.y) * imageSize.height
            bodyHeightPx = torsoHeight * 2.5 // Rough estimate of full height
        }

        guard bodyHeightPx > 0 else { return nil }

        // Calculate scale factor (cm per pixel)
        let cmPerPixel = knownHeightCm / Double(bodyHeightPx)

        // Estimate measurements
        // Note: These are front-view widths, not circumferences
        // Circumference requires depth estimation or multiple views
        let shoulderWidthCm = Double(shoulderWidthPx) * cmPerPixel
        let hipWidthCm = Double(hipWidthPx) * cmPerPixel

        // Rough circumference estimation (assuming elliptical cross-section)
        // Circumference ≈ π × (a + b) where a and b are semi-axes
        // For front view, we only see width, so we estimate depth as ~0.6 of width
        let estimatedShoulderCircumference = estimateCircumference(frontWidth: shoulderWidthCm, depthRatio: 0.5)
        let estimatedHipCircumference = estimateCircumference(frontWidth: hipWidthCm, depthRatio: 0.7)

        // Waist estimation (typically about 0.8 of hip width at the hip joint level)
        // This is a very rough approximation
        let waistWidthCm = hipWidthCm * 0.85
        let estimatedWaistCircumference = estimateCircumference(frontWidth: waistWidthCm, depthRatio: 0.65)

        // Neck estimation from shoulder width (very rough)
        let neckWidthCm = shoulderWidthCm * 0.35
        let estimatedNeckCircumference = estimateCircumference(frontWidth: neckWidthCm, depthRatio: 0.9)

        return EstimatedMeasurements(
            neckCm: estimatedNeckCircumference,
            shouldersCm: estimatedShoulderCircumference,
            waistCm: estimatedWaistCircumference,
            hipsCm: estimatedHipCircumference,
            confidence: Double(pose.confidence)
        )
    }

    // MARK: - Private Helpers

    private func calculatePersonBounds(from pixelBuffer: CVPixelBuffer) -> CGRect {
        // Lock the buffer for reading
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return .zero
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x
                if buffer[offset] > 128 { // Person detected
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }

        // Normalize to 0-1 range
        return CGRect(
            x: CGFloat(minX) / CGFloat(width),
            y: CGFloat(minY) / CGFloat(height),
            width: CGFloat(maxX - minX) / CGFloat(width),
            height: CGFloat(maxY - minY) / CGFloat(height)
        )
    }

    private func estimateCircumference(frontWidth: Double, depthRatio: Double) -> Double {
        // Ramanujan's approximation for ellipse perimeter
        // C ≈ π × (3(a + b) - √((3a + b)(a + 3b)))
        let a = frontWidth / 2 // Semi-major axis (half of front width)
        let b = a * depthRatio // Semi-minor axis (estimated depth)

        let h = pow((a - b), 2) / pow((a + b), 2)
        let circumference = Double.pi * (a + b) * (1 + (3 * h) / (10 + sqrt(4 - 3 * h)))

        return circumference
    }
}

// MARK: - Estimated Measurements

struct EstimatedMeasurements {
    let neckCm: Double
    let shouldersCm: Double
    let waistCm: Double
    let hipsCm: Double
    let confidence: Double

    var isReliable: Bool {
        confidence > 0.5
    }

    var disclaimer: String {
        if confidence > 0.7 {
            return "Good detection quality. Measurements may vary ±10% from actual."
        } else if confidence > 0.5 {
            return "Moderate detection quality. Consider retaking in better lighting."
        } else {
            return "Low detection quality. Results may be inaccurate."
        }
    }
}
