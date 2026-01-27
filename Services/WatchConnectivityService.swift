import Foundation
import WatchConnectivity
import WidgetKit

@MainActor
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published var isWatchAppInstalled = false
    @Published var isReachable = false

    private var onWaterLogged: ((Int) async -> Void)?

    private override init() {
        super.init()
        Task { @MainActor in
            setupSession()
        }
    }

    private func setupSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Public Methods

    func setWaterLogHandler(_ handler: @escaping (Int) async -> Void) {
        onWaterLogged = handler
    }

    func syncDataToWatch() {
        guard WCSession.default.activationState == .activated else { return }

        guard let widgetData = WidgetDataManager.shared.load(),
              let data = try? JSONEncoder().encode(widgetData) else {
            return
        }

        // Use application context for background updates
        do {
            try WCSession.default.updateApplicationContext(["widgetData": data])
        } catch {
            print("Error updating application context: \(error.localizedDescription)")
        }

        // Also send immediate message if reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                ["type": "dataUpdate", "widgetData": data],
                replyHandler: nil
            ) { error in
                print("Error sending data to watch: \(error.localizedDescription)")
            }
        }
    }

    func sendFastingUpdate(isFasting: Bool, fastingProtocol: String?, startedAt: Date?, targetEndAt: Date?) {
        WidgetDataManager.shared.updateFasting(
            isFasting: isFasting,
            protocol: fastingProtocol,
            startedAt: startedAt,
            targetEndAt: targetEndAt
        )
        syncDataToWatch()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func sendNutritionUpdate(calories: Int, caloriesTarget: Int, protein: Double, proteinTarget: Double, carbs: Double, carbsTarget: Double, fat: Double, fatTarget: Double) {
        WidgetDataManager.shared.updateNutrition(
            calories: calories,
            caloriesTarget: caloriesTarget,
            protein: protein,
            proteinTarget: proteinTarget,
            carbs: carbs,
            carbsTarget: carbsTarget,
            fat: fat,
            fatTarget: fatTarget
        )
        syncDataToWatch()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func sendWaterUpdate(consumed: Int, target: Int) {
        WidgetDataManager.shared.updateWater(consumed: consumed, target: target)
        syncDataToWatch()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func sendStreakUpdate(streak: Int) {
        WidgetDataManager.shared.updateStreak(streak)
        syncDataToWatch()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable

            if activationState == .activated {
                self.syncDataToWatch()
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        WCSession.default.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            if session.isReachable {
                self.syncDataToWatch()
            }
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            await handleReceivedMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            await handleReceivedMessage(message)

            // If watch requested sync, send current data
            if message["type"] as? String == "requestSync" {
                if let widgetData = WidgetDataManager.shared.load(),
                   let data = try? JSONEncoder().encode(widgetData) {
                    replyHandler(["widgetData": data])
                } else {
                    replyHandler([:])
                }
            } else {
                replyHandler([:])
            }
        }
    }

    @MainActor
    private func handleReceivedMessage(_ message: [String: Any]) async {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "waterLog":
            if let amount = message["amount"] as? Int {
                // Update local data
                let data = WidgetDataManager.shared.load() ?? .placeholder
                let newTotal = data.waterConsumedMl + amount
                WidgetDataManager.shared.updateWater(consumed: newTotal, target: data.waterTargetMl)

                // Notify handler to sync with backend
                await onWaterLogged?(amount)

                // Sync back to watch
                syncDataToWatch()
                WidgetCenter.shared.reloadAllTimelines()
            }

        case "requestSync":
            syncDataToWatch()

        default:
            break
        }
    }
}
