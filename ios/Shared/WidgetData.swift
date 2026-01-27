import Foundation
import WidgetKit

/// Shared data structure for widget display
struct WidgetData: Codable {
    // Nutrition
    var caloriesConsumed: Int
    var caloriesTarget: Int
    var proteinConsumed: Double
    var proteinTarget: Double
    var carbsConsumed: Double
    var carbsTarget: Double
    var fatConsumed: Double
    var fatTarget: Double

    // Water
    var waterConsumedMl: Int
    var waterTargetMl: Int

    // Streak
    var currentStreak: Int

    // Steps
    var stepsToday: Int
    var stepsGoal: Int

    // Fasting
    var isFasting: Bool
    var fastingProtocol: String?
    var fastingStartedAt: Date?
    var fastingTargetEndAt: Date?

    // Metadata
    var lastUpdated: Date

    // MARK: - Computed Properties

    var caloriesRemaining: Int {
        max(0, caloriesTarget - caloriesConsumed)
    }

    var caloriesProgress: Double {
        guard caloriesTarget > 0 else { return 0 }
        return min(1.0, Double(caloriesConsumed) / Double(caloriesTarget))
    }

    var proteinProgress: Double {
        guard proteinTarget > 0 else { return 0 }
        return min(1.0, proteinConsumed / proteinTarget)
    }

    var carbsProgress: Double {
        guard carbsTarget > 0 else { return 0 }
        return min(1.0, carbsConsumed / carbsTarget)
    }

    var fatProgress: Double {
        guard fatTarget > 0 else { return 0 }
        return min(1.0, fatConsumed / fatTarget)
    }

    var waterProgress: Double {
        guard waterTargetMl > 0 else { return 0 }
        return min(1.0, Double(waterConsumedMl) / Double(waterTargetMl))
    }

    var stepsProgress: Double {
        guard stepsGoal > 0 else { return 0 }
        return min(1.0, Double(stepsToday) / Double(stepsGoal))
    }

    var fastingProgress: Double {
        guard isFasting,
              let started = fastingStartedAt,
              let targetEnd = fastingTargetEndAt else { return 0 }

        let total = targetEnd.timeIntervalSince(started)
        let elapsed = Date().timeIntervalSince(started)
        return min(1.0, elapsed / total)
    }

    var fastingTimeRemaining: TimeInterval? {
        guard isFasting, let targetEnd = fastingTargetEndAt else { return nil }
        return max(0, targetEnd.timeIntervalSince(Date()))
    }

    // MARK: - Placeholder

    static var placeholder: WidgetData {
        WidgetData(
            caloriesConsumed: 1200,
            caloriesTarget: 2000,
            proteinConsumed: 80,
            proteinTarget: 150,
            carbsConsumed: 120,
            carbsTarget: 200,
            fatConsumed: 40,
            fatTarget: 65,
            waterConsumedMl: 1500,
            waterTargetMl: 2500,
            currentStreak: 7,
            stepsToday: 6500,
            stepsGoal: 10000,
            isFasting: false,
            fastingProtocol: nil,
            fastingStartedAt: nil,
            fastingTargetEndAt: nil,
            lastUpdated: Date()
        )
    }
}

// MARK: - Widget Data Manager

final class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let suiteName = "group.com.abish.reppy"
    private let dataKey = "widgetData"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private init() {}

    // MARK: - Save & Load

    func save(_ data: WidgetData) {
        guard let defaults = userDefaults else {
            print("WidgetDataManager: Failed to access App Group UserDefaults")
            return
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let encoded = try encoder.encode(data)
            defaults.set(encoded, forKey: dataKey)
            defaults.synchronize()

            // Reload widgets
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("WidgetDataManager: Failed to encode data - \(error)")
        }
    }

    func load() -> WidgetData? {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: dataKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(WidgetData.self, from: data)
        } catch {
            print("WidgetDataManager: Failed to decode data - \(error)")
            return nil
        }
    }

    // MARK: - Update Helpers

    func updateNutrition(
        calories: Int,
        caloriesTarget: Int,
        protein: Double,
        proteinTarget: Double,
        carbs: Double,
        carbsTarget: Double,
        fat: Double,
        fatTarget: Double
    ) {
        var data = load() ?? .placeholder
        data.caloriesConsumed = calories
        data.caloriesTarget = caloriesTarget
        data.proteinConsumed = protein
        data.proteinTarget = proteinTarget
        data.carbsConsumed = carbs
        data.carbsTarget = carbsTarget
        data.fatConsumed = fat
        data.fatTarget = fatTarget
        data.lastUpdated = Date()
        save(data)
    }

    func updateWater(consumed: Int, target: Int) {
        var data = load() ?? .placeholder
        data.waterConsumedMl = consumed
        data.waterTargetMl = target
        data.lastUpdated = Date()
        save(data)
    }

    func updateStreak(_ streak: Int) {
        var data = load() ?? .placeholder
        data.currentStreak = streak
        data.lastUpdated = Date()
        save(data)
    }

    func updateSteps(today: Int, goal: Int) {
        var data = load() ?? .placeholder
        data.stepsToday = today
        data.stepsGoal = goal
        data.lastUpdated = Date()
        save(data)
    }

    func updateFasting(
        isFasting: Bool,
        protocol fastingProtocol: String? = nil,
        startedAt: Date? = nil,
        targetEndAt: Date? = nil
    ) {
        var data = load() ?? .placeholder
        data.isFasting = isFasting
        data.fastingProtocol = fastingProtocol
        data.fastingStartedAt = startedAt
        data.fastingTargetEndAt = targetEndAt
        data.lastUpdated = Date()
        save(data)
    }
}
