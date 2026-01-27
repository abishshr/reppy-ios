import Foundation
import Speech
import AVFoundation

/// Service for speech-to-text conversion
@MainActor
final class SpeechService: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private lazy var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    /// Check if speech recognition is available
    var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }

    /// Request authorization for speech recognition
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Start recording and transcribing
    func startRecording() async throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.notAvailable
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create audio engine and recognition request
        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let audioEngine = audioEngine,
              let recognitionRequest = recognitionRequest else {
            throw SpeechError.audioEngineError
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }

        // Configure audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        transcribedText = ""
    }

    /// Stop recording
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        isRecording = false
    }

    /// Get final transcription
    func getTranscription() -> String {
        transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum SpeechError: LocalizedError {
    case notAvailable
    case notAuthorized
    case audioEngineError

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Speech recognition is not available"
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .audioEngineError:
            return "Failed to start audio engine"
        }
    }
}
