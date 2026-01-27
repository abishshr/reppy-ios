import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published var isReachable = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Send Messages to Phone

    func sendWaterLog(amount: Int) {
        guard WCSession.default.isReachable else {
            // Queue for later if phone not reachable
            queueMessage(["type": "waterLog", "amount": amount])
            return
        }

        WCSession.default.sendMessage(
            ["type": "waterLog", "amount": amount],
            replyHandler: nil
        ) { error in
            print("Error sending water log: \(error.localizedDescription)")
        }
    }

    func requestDataSync() {
        guard WCSession.default.isReachable else { return }

        WCSession.default.sendMessage(
            ["type": "requestSync"],
            replyHandler: { response in
                if let data = response["widgetData"] as? Data {
                    self.updateLocalData(from: data)
                }
            }
        ) { error in
            print("Error requesting sync: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private func queueMessage(_ message: [String: Any]) {
        // Store in UserDefaults to send later
        var queue = UserDefaults.standard.array(forKey: "pendingMessages") as? [[String: Any]] ?? []
        queue.append(message)
        UserDefaults.standard.set(queue, forKey: "pendingMessages")
    }

    private func sendQueuedMessages() {
        guard WCSession.default.isReachable else { return }

        let queue = UserDefaults.standard.array(forKey: "pendingMessages") as? [[String: Any]] ?? []

        for message in queue {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending queued message: \(error.localizedDescription)")
            }
        }

        UserDefaults.standard.removeObject(forKey: "pendingMessages")
    }

    private func updateLocalData(from data: Data) {
        guard let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return
        }
        WidgetDataManager.shared.save(widgetData)
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        if activationState == .activated {
            requestDataSync()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        if session.isReachable {
            sendQueuedMessages()
            requestDataSync()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleReceivedMessage(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleReceivedMessage(message)
        replyHandler([:])
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["widgetData"] as? Data {
            updateLocalData(from: data)
        }
    }

    private func handleReceivedMessage(_ message: [String: Any]) {
        if let type = message["type"] as? String {
            switch type {
            case "dataUpdate":
                if let data = message["widgetData"] as? Data {
                    updateLocalData(from: data)
                }
            default:
                break
            }
        }
    }
}
