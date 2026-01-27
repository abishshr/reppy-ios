import AVFoundation
import Foundation

@MainActor
final class VoiceCoachService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isSpeaking = false
    @Published var isEnabled = true

    // MARK: - Private Properties

    private let synthesizer = AVSpeechSynthesizer()
    private var announcementQueue: [QueuedAnnouncement] = []
    private var lastFormCorrectionTime: Date = .distantPast
    private let formCorrectionCooldown: TimeInterval = 5.0 // Don't repeat form corrections too often

    // MARK: - Types

    enum AnnouncementPriority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3

        static func < (lhs: AnnouncementPriority, rhs: AnnouncementPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private struct QueuedAnnouncement {
        let message: String
        let priority: AnnouncementPriority
        let timestamp: Date
    }

    // MARK: - Configuration

    private var voiceRate: Float = 0.52 // Slightly faster than default
    private var voicePitch: Float = 1.0
    private var voiceVolume: Float = 1.0

    // MARK: - Initialization

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        } catch {
            print("[VoiceCoach] Audio session error: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Methods

    func announce(_ message: String, priority: AnnouncementPriority = .normal) {
        guard isEnabled else { return }

        let announcement = QueuedAnnouncement(message: message, priority: priority, timestamp: Date())
        announcementQueue.append(announcement)

        // Sort by priority (higher first)
        announcementQueue.sort { $0.priority > $1.priority }

        processQueue()
    }

    func announceRep(_ count: Int) {
        announce("\(count)", priority: .high)
    }

    func announceSetComplete(_ setNumber: Int, reps: Int) {
        announce("Set \(setNumber) complete. \(reps) reps. Great work!", priority: .high)
    }

    func announceExerciseComplete(_ exerciseName: String) {
        announce("\(exerciseName) complete!", priority: .high)
    }

    func announceFormCorrection(_ correction: String) {
        // Rate limit form corrections
        let now = Date()
        guard now.timeIntervalSince(lastFormCorrectionTime) >= formCorrectionCooldown else { return }
        lastFormCorrectionTime = now

        announce(correction, priority: .normal)
    }

    func announceCountdown(_ seconds: Int) {
        switch seconds {
        case 3:
            announce("Get ready", priority: .high)
        case 2:
            announce("Two", priority: .high)
        case 1:
            announce("One", priority: .high)
        case 0:
            announce("Go!", priority: .critical)
        default:
            announce("\(seconds)", priority: .high)
        }
    }

    func announceRest(seconds: Int) {
        announce("Rest for \(seconds) seconds", priority: .normal)
    }

    func announceRestComplete() {
        announce("Let's go! Next set!", priority: .high)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        announcementQueue.removeAll()
        isSpeaking = false
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopSpeaking()
        }
    }

    // MARK: - Private Methods

    private func processQueue() {
        guard !isSpeaking, !announcementQueue.isEmpty else { return }

        let announcement = announcementQueue.removeFirst()

        // Skip old announcements
        let maxAge: TimeInterval = 2.0
        if Date().timeIntervalSince(announcement.timestamp) > maxAge {
            processQueue()
            return
        }

        speak(announcement.message)
    }

    private func speak(_ message: String) {
        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = voiceRate
        utterance.pitchMultiplier = voicePitch
        utterance.volume = voiceVolume

        // Use a natural-sounding voice
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceCoachService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.processQueue()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
