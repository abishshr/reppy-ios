import Foundation

/// Body measurement record
struct BodyMeasurement: Codable, Identifiable, Equatable {
    let id: String
    let measuredAt: Date

    // Core measurements (in centimeters)
    var neckCm: Double?
    var shouldersCm: Double?
    var chestCm: Double?
    var leftBicepCm: Double?
    var rightBicepCm: Double?
    var leftForearmCm: Double?
    var rightForearmCm: Double?
    var waistCm: Double?
    var hipsCm: Double?
    var leftThighCm: Double?
    var rightThighCm: Double?
    var leftCalfCm: Double?
    var rightCalfCm: Double?

    // Calculated/estimated
    var bodyFatPercentage: Double?

    var notes: String?
    let createdAt: Date
}

/// Request to create body measurements
struct BodyMeasurementCreate: Encodable {
    var neckCm: Double?
    var shouldersCm: Double?
    var chestCm: Double?
    var leftBicepCm: Double?
    var rightBicepCm: Double?
    var leftForearmCm: Double?
    var rightForearmCm: Double?
    var waistCm: Double?
    var hipsCm: Double?
    var leftThighCm: Double?
    var rightThighCm: Double?
    var leftCalfCm: Double?
    var rightCalfCm: Double?
    var bodyFatPercentage: Double?
    var notes: String?
    var measuredAt: Date?

    /// Quick measurement with just essential fields for body fat calculation
    static func forBodyFat(waistCm: Double, neckCm: Double, hipsCm: Double? = nil) -> BodyMeasurementCreate {
        BodyMeasurementCreate(
            neckCm: neckCm,
            waistCm: waistCm,
            hipsCm: hipsCm
        )
    }
}

/// Body fat calculation response
struct BodyFatCalculation: Codable {
    let bodyFatPercentage: Double
    let category: String
    let method: String
    let inputs: BodyFatInputs

    struct BodyFatInputs: Codable {
        let heightCm: Double
        let waistCm: Double
        let neckCm: Double
        let hipsCm: Double?
        let sex: String
    }
}

/// Body fat category with color coding
enum BodyFatCategory: String {
    case essentialFat = "Essential Fat"
    case athletic = "Athletic"
    case fitness = "Fitness"
    case average = "Average"
    case aboveAverage = "Above Average"

    init(from string: String) {
        self = BodyFatCategory(rawValue: string) ?? .average
    }

    var color: String {
        switch self {
        case .essentialFat: return "yellow"
        case .athletic: return "green"
        case .fitness: return "blue"
        case .average: return "gray"
        case .aboveAverage: return "orange"
        }
    }

    var description: String {
        switch self {
        case .essentialFat:
            return "Minimum level needed for basic health. Athletes in weight-class sports may reach this temporarily."
        case .athletic:
            return "Typical for competitive athletes. Very lean with visible muscle definition."
        case .fitness:
            return "Good fitness level with some muscle definition. Healthy and sustainable."
        case .average:
            return "Typical range for general population. Healthy but room for improvement."
        case .aboveAverage:
            return "Higher than average. May want to focus on fat loss for health benefits."
        }
    }
}

/// Comparison between two measurements
struct MeasurementComparison: Codable {
    let currentDate: String
    let previousDate: String
    let comparisons: [FieldComparison]

    struct FieldComparison: Codable {
        let field: String
        let currentValue: Double
        let previousValue: Double
        let change: Double
        let changePercent: Double

        var fieldDisplayName: String {
            switch field {
            case "neck_cm": return "Neck"
            case "shoulders_cm": return "Shoulders"
            case "chest_cm": return "Chest"
            case "left_bicep_cm": return "Left Bicep"
            case "right_bicep_cm": return "Right Bicep"
            case "left_forearm_cm": return "Left Forearm"
            case "right_forearm_cm": return "Right Forearm"
            case "waist_cm": return "Waist"
            case "hips_cm": return "Hips"
            case "left_thigh_cm": return "Left Thigh"
            case "right_thigh_cm": return "Right Thigh"
            case "left_calf_cm": return "Left Calf"
            case "right_calf_cm": return "Right Calf"
            case "body_fat_percentage": return "Body Fat %"
            default: return field.replacingOccurrences(of: "_", with: " ").capitalized
            }
        }

        var isImprovement: Bool {
            // For most measurements, decrease is good (except maybe biceps/chest for muscle gain)
            // For body fat, decrease is always good
            if field == "body_fat_percentage" {
                return change < 0
            }
            // For waist/hips, decrease is typically desired
            if field == "waist_cm" || field == "hips_cm" {
                return change < 0
            }
            // For arms/chest, increase might be desired (muscle gain)
            return change > 0
        }
    }
}
