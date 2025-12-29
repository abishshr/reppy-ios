@preconcurrency import AVFoundation
import Combine
import UIKit

@MainActor
final class CameraService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isRunning = false
    @Published private(set) var isAuthorized = false
    @Published private(set) var error: CameraError?

    // MARK: - Private Properties

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.reppy.camera.session")
    private let videoOutputQueue = DispatchQueue(label: "com.reppy.camera.videoOutput")

    // nonisolated(unsafe) because PassthroughSubject is thread-safe and accessed from delegate
    nonisolated(unsafe) private let frameSubject = PassthroughSubject<CMSampleBuffer, Never>()

    // MARK: - Public Properties

    var framePublisher: AnyPublisher<CMSampleBuffer, Never> {
        frameSubject.eraseToAnyPublisher()
    }

    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Authorization

    func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            return granted
        case .denied, .restricted:
            isAuthorized = false
            return false
        @unknown default:
            isAuthorized = false
            return false
        }
    }

    // MARK: - Session Setup

    func setupSession() throws {
        guard isAuthorized else {
            throw CameraError.notAuthorized
        }

        let session = AVCaptureSession()
        session.sessionPreset = .high

        // Configure front camera input
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw CameraError.deviceNotFound
        }

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: frontCamera)
        } catch {
            throw CameraError.inputError(error)
        }

        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        // Configure video output
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoOutputQueue)

        guard session.canAddOutput(output) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(output)

        // Configure video orientation
        if let connection = output.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        self.captureSession = session
        self.videoOutput = output

        // Create preview layer
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.previewLayer = layer
    }

    // MARK: - Session Control

    func startSession() {
        guard let session = captureSession else { return }
        sessionQueue.async { [weak self] in
            if !session.isRunning {
                session.startRunning()
                DispatchQueue.main.async {
                    self?.isRunning = true
                }
            }
        }
    }

    func stopSession() {
        guard let session = captureSession else { return }
        sessionQueue.async { [weak self] in
            if session.isRunning {
                session.stopRunning()
                DispatchQueue.main.async {
                    self?.isRunning = false
                }
            }
        }
    }

    func pauseSession() {
        stopSession()
    }

    func resumeSession() {
        startSession()
    }

    // MARK: - Preview Layer

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }

    // MARK: - Cleanup

    func cleanup() {
        stopSession()
        captureSession = nil
        videoOutput = nil
        previewLayer = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        frameSubject.send(sampleBuffer)
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didDrop sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        // Frames dropped - this is expected under heavy load
    }
}

// MARK: - Camera Error

enum CameraError: LocalizedError {
    case notAuthorized
    case deviceNotFound
    case inputError(Error)
    case cannotAddInput
    case cannotAddOutput
    case sessionNotConfigured

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized. Please enable in Settings."
        case .deviceNotFound:
            return "Front camera not found on this device."
        case .inputError(let error):
            return "Camera input error: \(error.localizedDescription)"
        case .cannotAddInput:
            return "Cannot add camera input to session."
        case .cannotAddOutput:
            return "Cannot add video output to session."
        case .sessionNotConfigured:
            return "Camera session not configured."
        }
    }
}
