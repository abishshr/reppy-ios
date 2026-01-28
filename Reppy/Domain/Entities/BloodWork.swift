import Foundation
import SwiftUI

// MARK: - Enums

/// Status classification for a blood marker result
enum MarkerStatus: String, Codable {
    case low
    case suboptimalLow = "suboptimal_low"
    case optimal
    case suboptimalHigh = "suboptimal_high"
    case high

    var color: Color {
        switch self {
        case .low, .high:
            return .red
        case .suboptimalLow, .suboptimalHigh:
            return .orange
        case .optimal:
            return .green
        }
    }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .suboptimalLow: return "Below Optimal"
        case .optimal: return "Optimal"
        case .suboptimalHigh: return "Above Optimal"
        case .high: return "High"
        }
    }
}

/// Source of blood work data entry
enum BloodWorkSource: String, Codable {
    case manual
    case ocr
    case pdfOcr = "pdf_ocr"
}

/// Category of blood markers
enum MarkerCategory: String, CaseIterable {
    case vitamins = "Vitamins & Minerals"
    case metabolic = "Metabolic"
    case lipids = "Lipids"
    case hormones = "Hormones"
    case cbc = "Complete Blood Count"
    case liverKidney = "Liver & Kidney"

    var icon: String {
        switch self {
        case .vitamins: return "pills.fill"
        case .metabolic: return "chart.bar.fill"
        case .lipids: return "heart.fill"
        case .hormones: return "waveform.path.ecg"
        case .cbc: return "drop.fill"
        case .liverKidney: return "staroflife.fill"
        }
    }

    var color: Color {
        switch self {
        case .vitamins: return .orange
        case .metabolic: return .blue
        case .lipids: return .red
        case .hormones: return .purple
        case .cbc: return .pink
        case .liverKidney: return .green
        }
    }
}

// MARK: - Blood Work Panel

/// Blood work panel with all lab results
struct BloodWorkPanel: Identifiable, Codable, Equatable {
    let id: String
    let userId: String

    // Metadata
    var labName: String?
    var testDate: Date
    var reportImageUrl: String?
    var source: BloodWorkSource
    var ocrConfidence: Double?

    // Vitamins & Minerals
    var vitaminDNgMl: Double?
    var vitaminB12PgMl: Double?
    var folateNgMl: Double?
    var ironMcgDl: Double?
    var ferritinNgMl: Double?
    var tibcMcgDl: Double?
    var vitaminAMcgDl: Double?
    var vitaminEMgDl: Double?
    var zincMcgDl: Double?
    var magnesiumMgDl: Double?
    var calciumMgDl: Double?

    // Metabolic
    var fastingGlucoseMgDl: Double?
    var hba1cPercent: Double?
    var insulinMiuMl: Double?
    var homaIr: Double?

    // Lipids
    var totalCholesterolMgDl: Double?
    var ldlMgDl: Double?
    var hdlMgDl: Double?
    var triglyceridesMgDl: Double?
    var vldlMgDl: Double?

    // Hormones
    var testosteroneTotalNgDl: Double?
    var testosteroneFreePgMl: Double?
    var estradiolPgMl: Double?
    var tshMiuL: Double?
    var t3NgDl: Double?
    var t4McgDl: Double?
    var cortisolMcgDl: Double?

    // CBC
    var hemoglobinGDl: Double?
    var hematocritPercent: Double?
    var rbcMillionPerUl: Double?
    var wbcThousandPerUl: Double?
    var plateletsThousandPerUl: Double?
    var mcvFl: Double?
    var mchPg: Double?
    var mchcGDl: Double?

    // Liver & Kidney
    var altUL: Double?
    var astUL: Double?
    var alpUL: Double?
    var bilirubinMgDl: Double?
    var creatinineMgDl: Double?
    var bunMgDl: Double?
    var egfrMlMin: Double?

    // AI Analysis
    var aiAnalysis: [String: AnyCodable]?
    var aiAnalyzedAt: Date?

    // Timestamps
    let createdAt: Date
    var updatedAt: Date

    /// Count of markers with values
    var markerCount: Int {
        var count = 0
        // Count vitamins
        if vitaminDNgMl != nil { count += 1 }
        if vitaminB12PgMl != nil { count += 1 }
        if folateNgMl != nil { count += 1 }
        if ironMcgDl != nil { count += 1 }
        if ferritinNgMl != nil { count += 1 }
        if tibcMcgDl != nil { count += 1 }
        if vitaminAMcgDl != nil { count += 1 }
        if vitaminEMgDl != nil { count += 1 }
        if zincMcgDl != nil { count += 1 }
        if magnesiumMgDl != nil { count += 1 }
        if calciumMgDl != nil { count += 1 }
        // Metabolic
        if fastingGlucoseMgDl != nil { count += 1 }
        if hba1cPercent != nil { count += 1 }
        if insulinMiuMl != nil { count += 1 }
        if homaIr != nil { count += 1 }
        // Lipids
        if totalCholesterolMgDl != nil { count += 1 }
        if ldlMgDl != nil { count += 1 }
        if hdlMgDl != nil { count += 1 }
        if triglyceridesMgDl != nil { count += 1 }
        if vldlMgDl != nil { count += 1 }
        // Hormones
        if testosteroneTotalNgDl != nil { count += 1 }
        if testosteroneFreePgMl != nil { count += 1 }
        if estradiolPgMl != nil { count += 1 }
        if tshMiuL != nil { count += 1 }
        if t3NgDl != nil { count += 1 }
        if t4McgDl != nil { count += 1 }
        if cortisolMcgDl != nil { count += 1 }
        // CBC
        if hemoglobinGDl != nil { count += 1 }
        if hematocritPercent != nil { count += 1 }
        if rbcMillionPerUl != nil { count += 1 }
        if wbcThousandPerUl != nil { count += 1 }
        if plateletsThousandPerUl != nil { count += 1 }
        if mcvFl != nil { count += 1 }
        if mchPg != nil { count += 1 }
        if mchcGDl != nil { count += 1 }
        // Liver & Kidney
        if altUL != nil { count += 1 }
        if astUL != nil { count += 1 }
        if alpUL != nil { count += 1 }
        if bilirubinMgDl != nil { count += 1 }
        if creatinineMgDl != nil { count += 1 }
        if bunMgDl != nil { count += 1 }
        if egfrMlMin != nil { count += 1 }
        return count
    }
}

// MARK: - Marker Result

/// Result for a single blood marker with status classification
struct BloodMarkerResult: Identifiable, Codable, Equatable {
    var id: String { markerKey }
    let markerKey: String
    let name: String
    let value: Double
    let unit: String
    let status: MarkerStatus
    let referenceLow: Double
    let referenceHigh: Double
    let optimalLow: Double?
    let optimalHigh: Double?
}

// MARK: - Category Summary

/// Summary for a category of markers
struct MarkerCategorySummary: Identifiable, Codable, Equatable {
    var id: String { category }
    let category: String
    let totalMarkers: Int
    let optimalCount: Int
    let suboptimalCount: Int
    let outOfRangeCount: Int
    let markers: [BloodMarkerResult]
}

// MARK: - OCR Response

/// Response from OCR extraction
struct BloodWorkOCRResponse: Codable {
    let success: Bool
    let confidence: Double
    let labName: String?
    let testDate: Date?
    let warnings: [String]
    let extractedValues: [String: Double]
    let uncertainValues: [String: UncertainValue]
}

struct UncertainValue: Codable {
    let value: Double
    let confidence: Double
    let rawText: String?
}

// MARK: - Recommendations

struct SupplementRecommendation: Identifiable, Codable, Equatable {
    var id: String { supplementName }
    let supplementName: String
    let reason: String
    let dosageSuggestion: String?
    let priority: String
    let relatedMarkers: [String]
}

struct NutritionRecommendation: Identifiable, Codable, Equatable {
    var id: String { recommendation }
    let recommendation: String
    let foodsToIncrease: [String]
    let foodsToLimit: [String]
    let reason: String
    let relatedMarkers: [String]
}

struct WorkoutRecommendation: Identifiable, Codable, Equatable {
    var id: String { recommendation }
    let recommendation: String
    let intensityModifier: Double
    let reason: String
    let relatedMarkers: [String]
}

struct LifestyleRecommendation: Identifiable, Codable, Equatable {
    var id: String { "\(category)-\(recommendation.prefix(20))" }
    let category: String
    let recommendation: String
    let reason: String
}

struct TargetAdjustment: Identifiable, Codable, Equatable {
    var id: String { nutrient }
    let nutrient: String
    let currentTarget: Double?
    let suggestedTarget: Double
    let unit: String
    let reason: String
}

// MARK: - Analysis Response

/// Full AI analysis of blood work panel
struct BloodWorkAnalysis: Codable {
    let healthScore: Int
    let healthScoreBreakdown: [String: Int]
    let summary: String
    let categories: [MarkerCategorySummary]
    let criticalMarkers: [BloodMarkerResult]
    let supplementRecommendations: [SupplementRecommendation]
    let nutritionRecommendations: [NutritionRecommendation]
    let workoutRecommendations: [WorkoutRecommendation]
    let lifestyleRecommendations: [LifestyleRecommendation]
    let targetAdjustments: [TargetAdjustment]
    let analyzedAt: Date
}

// MARK: - Trend Response

struct TrendDataPoint: Identifiable, Codable, Equatable {
    var id: String { "\(testDate.timeIntervalSince1970)" }
    let testDate: Date
    let value: Double
    let status: MarkerStatus
}

struct BloodWorkTrend: Codable {
    let markerKey: String
    let markerName: String
    let unit: String
    let referenceLow: Double
    let referenceHigh: Double
    let optimalLow: Double?
    let optimalHigh: Double?
    let dataPoints: [TrendDataPoint]
    let trendDirection: String?
    let latestValue: Double?
    let previousValue: Double?
    let changePercent: Double?
    let minValue: Double?
    let maxValue: Double?
    let avgValue: Double?
}

// MARK: - Dashboard Summary

/// Summary of latest blood work for dashboard
struct BloodWorkSummary: Codable {
    let hasData: Bool
    let latestPanelId: String?
    let latestTestDate: Date?
    let daysSinceTest: Int?
    let healthScore: Int?
    let totalMarkersTested: Int
    let optimalCount: Int
    let suboptimalCount: Int
    let outOfRangeCount: Int
    let criticalMarkers: [String]
    let topConcerns: [String]
}

// MARK: - Create Request

struct BloodWorkPanelCreate: Codable {
    var labName: String?
    var testDate: Date
    var reportImageUrl: String?
    var source: BloodWorkSource = .manual
    var ocrConfidence: Double?

    // Vitamins & Minerals
    var vitaminDNgMl: Double?
    var vitaminB12PgMl: Double?
    var folateNgMl: Double?
    var ironMcgDl: Double?
    var ferritinNgMl: Double?
    var tibcMcgDl: Double?
    var vitaminAMcgDl: Double?
    var vitaminEMgDl: Double?
    var zincMcgDl: Double?
    var magnesiumMgDl: Double?
    var calciumMgDl: Double?

    // Metabolic
    var fastingGlucoseMgDl: Double?
    var hba1cPercent: Double?
    var insulinMiuMl: Double?
    var homaIr: Double?

    // Lipids
    var totalCholesterolMgDl: Double?
    var ldlMgDl: Double?
    var hdlMgDl: Double?
    var triglyceridesMgDl: Double?
    var vldlMgDl: Double?

    // Hormones
    var testosteroneTotalNgDl: Double?
    var testosteroneFreePgMl: Double?
    var estradiolPgMl: Double?
    var tshMiuL: Double?
    var t3NgDl: Double?
    var t4McgDl: Double?
    var cortisolMcgDl: Double?

    // CBC
    var hemoglobinGDl: Double?
    var hematocritPercent: Double?
    var rbcMillionPerUl: Double?
    var wbcThousandPerUl: Double?
    var plateletsThousandPerUl: Double?
    var mcvFl: Double?
    var mchPg: Double?
    var mchcGDl: Double?

    // Liver & Kidney
    var altUL: Double?
    var astUL: Double?
    var alpUL: Double?
    var bilirubinMgDl: Double?
    var creatinineMgDl: Double?
    var bunMgDl: Double?
    var egfrMlMin: Double?
}

// MARK: - OCR Request

struct BloodWorkOCRRequest: Codable {
    let imageBase64: String?
    let imageUrl: String?
    let mimeType: String
}

// MARK: - Confirm OCR Request

struct BloodWorkConfirmOCRRequest: Codable {
    var labName: String?
    var testDate: Date
    var imageUrl: String?
    var ocrConfidence: Double?
    var markers: [String: Double]
}

// MARK: - Apply Recommendations

struct ApplyRecommendationsRequest: Codable {
    let applySupplements: Bool
    let applyTargets: Bool
}

struct ApplyRecommendationsResponse: Codable {
    let appliedActions: [String]
    let supplementsCreated: [String]
    let targetsUpdated: [String]
}

// MARK: - Reference Ranges

/// Reference ranges for blood markers
struct MarkerReference {
    let name: String
    let unit: String
    let low: Double
    let high: Double
    let optimalLow: Double?
    let optimalHigh: Double?
}

/// All reference ranges
let bloodMarkerReferences: [String: MarkerReference] = [
    "vitaminDNgMl": MarkerReference(name: "Vitamin D", unit: "ng/mL", low: 30, high: 100, optimalLow: 40, optimalHigh: 60),
    "vitaminB12PgMl": MarkerReference(name: "Vitamin B12", unit: "pg/mL", low: 200, high: 900, optimalLow: 400, optimalHigh: 800),
    "folateNgMl": MarkerReference(name: "Folate", unit: "ng/mL", low: 3, high: 17, optimalLow: 5, optimalHigh: 15),
    "ironMcgDl": MarkerReference(name: "Iron", unit: "mcg/dL", low: 60, high: 170, optimalLow: 80, optimalHigh: 150),
    "ferritinNgMl": MarkerReference(name: "Ferritin", unit: "ng/mL", low: 12, high: 300, optimalLow: 50, optimalHigh: 150),
    "tibcMcgDl": MarkerReference(name: "TIBC", unit: "mcg/dL", low: 250, high: 370, optimalLow: 260, optimalHigh: 350),
    "fastingGlucoseMgDl": MarkerReference(name: "Fasting Glucose", unit: "mg/dL", low: 70, high: 99, optimalLow: 75, optimalHigh: 90),
    "hba1cPercent": MarkerReference(name: "HbA1c", unit: "%", low: 4.0, high: 5.6, optimalLow: 4.5, optimalHigh: 5.3),
    "totalCholesterolMgDl": MarkerReference(name: "Total Cholesterol", unit: "mg/dL", low: 125, high: 200, optimalLow: 150, optimalHigh: 180),
    "ldlMgDl": MarkerReference(name: "LDL", unit: "mg/dL", low: 0, high: 100, optimalLow: 0, optimalHigh: 70),
    "hdlMgDl": MarkerReference(name: "HDL", unit: "mg/dL", low: 40, high: 100, optimalLow: 50, optimalHigh: 90),
    "triglyceridesMgDl": MarkerReference(name: "Triglycerides", unit: "mg/dL", low: 0, high: 150, optimalLow: 0, optimalHigh: 100),
    "hemoglobinGDl": MarkerReference(name: "Hemoglobin", unit: "g/dL", low: 12.0, high: 17.5, optimalLow: 13, optimalHigh: 16),
    "tshMiuL": MarkerReference(name: "TSH", unit: "mIU/L", low: 0.4, high: 4.0, optimalLow: 1.0, optimalHigh: 2.5),
]
