import Foundation
import Combine
import AVFoundation
import PipecatClientIOS
import PipecatClientIOSDaily
import Daily

// MARK: - Pipecat Connection State

enum PipecatConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

// MARK: - Pipecat Service

@MainActor
final class PipecatService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var connectionState: PipecatConnectionState = .disconnected
    @Published private(set) var isAICoachSpeaking = false
    @Published private(set) var currentRoomId: String?

    // NOTE: No video track - camera handled by local CameraService for pose detection

    // MARK: - Private Properties

    private var pipecatClient: PipecatClient?
    private var dailyTransport: DailyTransport?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Session Management

    /// Start an AI coaching session
    func startSession(
        exerciseName: String,
        targetSets: Int,
        targetReps: Int,
        userName: String? = nil
    ) async throws {
        guard connectionState == .disconnected else {
            throw PipecatError.alreadyConnected
        }

        connectionState = .connecting

        do {
            // Create Pipecat client with Daily transport
            // NOTE: Camera is DISABLED - we use local CameraService for pose detection
            // Daily handles audio only (mic + speaker for AI coach voice)
            let transport = DailyTransport()
            dailyTransport = transport

            let options = PipecatClientOptions(
                transport: transport,
                enableMic: true,
                enableCam: false  // Disabled - using local CameraService instead
            )

            pipecatClient = PipecatClient(options: options)
            pipecatClient?.delegate = self

            // Initialize devices
            try await pipecatClient?.initDevices()

            // Build API request - use the backend URL
            let urlString = "\(Constants.Pipecat.baseURL)/connect"
            guard let url = URL(string: urlString) else {
                throw PipecatError.connectionFailed("Invalid URL")
            }

            // Build request body with exercise parameters
            let requestData: Value = .object([
                "exercise_name": .string(exerciseName),
                "target_sets": .number(Double(targetSets)),
                "target_reps": .number(Double(targetReps)),
                "user_name": .string(userName ?? "User")
            ])

            let apiRequest = APIRequest(endpoint: url, requestData: requestData)

            // Start bot and connect
            let _: DailyTransportConnectionParams = try await pipecatClient!.startBotAndConnect(startBotParams: apiRequest)

            // Store room info
            currentRoomId = UUID().uuidString
            connectionState = .connected

        } catch {
            connectionState = .error(error.localizedDescription)
            throw error
        }
    }

    /// End the current coaching session
    func endSession() async {
        guard let client = pipecatClient else { return }

        do {
            try await client.disconnect()
        } catch {
            print("Failed to disconnect: \(error)")
        }

        pipecatClient?.release()
        pipecatClient = nil
        dailyTransport = nil
        currentRoomId = nil
        connectionState = .disconnected
    }

    // MARK: - Pose Data Streaming

    /// Send pose data to the AI coach via raw Daily app message
    func sendPoseData(_ pose: DetectedPose) {
        guard connectionState == .connected,
              let callClient = dailyTransport?.dailyCallClient else { return }

        var jointsDict: [String: [String: CGFloat]] = [:]
        for (key, value) in pose.joints {
            jointsDict[key.rawValue.rawValue] = ["x": value.x, "y": value.y]
        }

        let message: [String: Any] = [
            "type": "pose_update",
            "data": [
                "joints": jointsDict,
                "timestamp": Date().timeIntervalSince1970
            ]
        ]

        sendRawAppMessage(message, using: callClient)
    }

    /// Notify that a rep was completed (detected on-device)
    func sendRepCompleted() {
        guard connectionState == .connected,
              let callClient = dailyTransport?.dailyCallClient else { return }

        let message: [String: Any] = [
            "type": "rep_completed"
        ]

        sendRawAppMessage(message, using: callClient)
    }

    /// Notify that a set was completed
    func sendSetCompleted(setNumber: Int, reps: Int) {
        guard connectionState == .connected,
              let callClient = dailyTransport?.dailyCallClient else { return }

        let message: [String: Any] = [
            "type": "set_completed",
            "set_number": setNumber,
            "reps": reps
        ]

        sendRawAppMessage(message, using: callClient)
    }

    /// Send setup issue for AI voice guidance
    func sendSetupIssue(_ issue: SetupIssue) {
        guard connectionState == .connected,
              let callClient = dailyTransport?.dailyCallClient else { return }

        let message: [String: Any] = [
            "type": "setup_issue",
            "issue_type": issue.type,
            "message": issue.message
        ]

        sendRawAppMessage(message, using: callClient)
    }

    // MARK: - Private Helpers

    /// Send raw JSON app message directly through Daily CallClient
    private func sendRawAppMessage(_ message: [String: Any], using callClient: CallClient) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            callClient.sendAppMessage(json: jsonData, to: .all, completion: nil)
        } catch {
            print("Failed to send app message: \(error)")
        }
    }
}

// MARK: - PipecatClientDelegate

extension PipecatService: PipecatClientDelegate {
    nonisolated func onConnected() {
        Task { @MainActor in
            connectionState = .connected
        }
    }

    nonisolated func onDisconnected() {
        Task { @MainActor in
            connectionState = .disconnected
            currentRoomId = nil
        }
    }

    nonisolated func onBotStartedSpeaking() {
        Task { @MainActor in
            isAICoachSpeaking = true
        }
    }

    nonisolated func onBotStoppedSpeaking() {
        Task { @MainActor in
            isAICoachSpeaking = false
        }
    }

    nonisolated func onError(_ message: String) {
        Task { @MainActor in
            connectionState = .error(message.isEmpty ? "Unknown error" : message)
        }
    }

    nonisolated func onTransportStateChanged(state: TransportState) {
        Task { @MainActor in
            switch state {
            case .connecting:
                connectionState = .connecting
            case .connected:
                connectionState = .connected
            case .disconnected:
                connectionState = .disconnected
            case .error:
                connectionState = .error("Connection error")
            default:
                break
            }
        }
    }

    nonisolated func onBotReady(botReadyData: BotReadyData) {
        Task { @MainActor in
            connectionState = .connected
        }
    }
}

// MARK: - Pipecat Error

enum PipecatError: LocalizedError {
    case alreadyConnected
    case notConnected
    case serverError
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .alreadyConnected:
            return "Already connected to a coaching session"
        case .notConnected:
            return "Not connected to a coaching session"
        case .serverError:
            return "Server error. Please try again."
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        }
    }
}
