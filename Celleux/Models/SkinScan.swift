import SwiftUI

nonisolated struct LightingConditions: Sendable {
    var ambientIntensity: Double
    var colorTemperature: Double
    var correctionApplied: Bool

    var isAcceptable: Bool {
        ambientIntensity >= 500 && ambientIntensity <= 2000
    }

    var needsChromaticAdaptation: Bool {
        abs(colorTemperature - 6500) > 1000
    }

    var qualityLevel: LightingQuality {
        if ambientIntensity < 500 || ambientIntensity > 2000 {
            return .poor
        }
        if abs(colorTemperature - 6500) > 1000 {
            return .fair
        }
        return .good
    }
}

nonisolated enum ScanPhase: String, Sendable {
    case preScan
    case scanning
    case analyzing
    case results
    case history
    case heatMap
    case progress
}

nonisolated enum SkinMetricType: String, CaseIterable, Sendable {
    case textureEvenness = "Texture Evenness"
    case apparentHydration = "Apparent Hydration"
    case brightnessRadiance = "Brightness"
    case rednessInflammation = "Redness"
    case poreVisibility = "Pore Visibility"
    case toneUniformity = "Tone Uniformity"
    case underEyeQuality = "Under-Eye Quality"
    case wrinkleDepth = "Wrinkle Depth"
    case elasticityProxy = "Elasticity"
    case overallSkinHealth = "Overall Skin Health"

    var icon: String {
        switch self {
        case .textureEvenness: "square.grid.3x3"
        case .apparentHydration: "drop.fill"
        case .brightnessRadiance: "sun.max.fill"
        case .rednessInflammation: "flame"
        case .poreVisibility: "circle.grid.3x3"
        case .toneUniformity: "paintpalette"
        case .underEyeQuality: "eye"
        case .wrinkleDepth: "line.3.horizontal.decrease"
        case .elasticityProxy: "arrow.up.and.down.and.sparkles"
        case .overallSkinHealth: "heart.text.clipboard"
        }
    }

    var weight: Double {
        switch self {
        case .textureEvenness: 0.20
        case .apparentHydration: 0.15
        case .brightnessRadiance: 0.10
        case .rednessInflammation: 0.15
        case .poreVisibility: 0.10
        case .toneUniformity: 0.10
        case .underEyeQuality: 0.05
        case .wrinkleDepth: 0.10
        case .elasticityProxy: 0.05
        case .overallSkinHealth: 0
        }
    }

    var isImplemented: Bool {
        switch self {
        case .textureEvenness, .apparentHydration, .brightnessRadiance, .rednessInflammation,
             .poreVisibility, .toneUniformity, .underEyeQuality, .wrinkleDepth, .elasticityProxy:
            true
        default:
            false
        }
    }
}

nonisolated enum SkinConcernType: String, CaseIterable, Sendable {
    case redness = "Redness"
    case texture = "Texture"
    case darkSpots = "Dark Spots"
    case dehydration = "Dehydration"

    var color: Color {
        switch self {
        case .redness: Color(hex: "FF4D6A")
        case .texture: Color(hex: "FF9500")
        case .darkSpots: Color(hex: "8B5CF6")
        case .dehydration: Color(hex: "00B4D8")
        }
    }

    var icon: String {
        switch self {
        case .redness: "flame.fill"
        case .texture: "square.grid.3x3.fill"
        case .darkSpots: "circle.dotted"
        case .dehydration: "drop.triangle.fill"
        }
    }
}

nonisolated enum HeatMapMode: String, Sendable {
    case all = "All Concerns"
    case redness = "Redness"
    case texture = "Texture"
    case darkSpots = "Dark Spots"
    case dehydration = "Dehydration"
}

nonisolated enum ProgressTimeframe: String, CaseIterable, Sendable {
    case thirtyDays = "30 Days"
    case sixtyDays = "60 Days"
    case ninetyDays = "90 Days"
}

nonisolated enum FaceDetectionState: Sendable {
    case noFace
    case detected
    case goodLighting
    case tooFar
    case toClose
    case notCentered
}

enum LightingQuality: String {
    case poor = "Find better light"
    case fair = "Fair lighting"
    case good = "Good lighting"

    var color: Color {
        switch self {
        case .poor: Color(hex: "E53935")
        case .fair: Color(hex: "E8A838")
        case .good: Color(hex: "4CAF50")
        }
    }

    var icon: String {
        switch self {
        case .poor: "sun.min"
        case .fair: "sun.haze"
        case .good: "sun.max.fill"
        }
    }
}

nonisolated struct RegionScores: Sendable {
    var textureEvennessScore: Double = 0
    var apparentHydrationScore: Double = 0
    var brightnessRadianceScore: Double = 0
    var rednessScore: Double = 0
    var poreVisibilityScore: Double = 0
    var toneUniformityScore: Double = 0
    var underEyeQualityScore: Double = 0
    var wrinkleDepthScore: Double = 0
    var elasticityProxyScore: Double = 0

    var itaAngle: Double = 0
    var aStarMean: Double = 0
    var bStarMean: Double = 0
    var laplacianVariance: Double = 0
    var saturationVariance: Double = 0

    var brightnessScore: Double { brightnessRadianceScore }
    var textureScore: Double { textureEvennessScore }
    var hydrationScore: Double { apparentHydrationScore }

    func score(for metric: SkinMetricType) -> Double {
        switch metric {
        case .textureEvenness: textureEvennessScore
        case .apparentHydration: apparentHydrationScore
        case .brightnessRadiance: brightnessRadianceScore
        case .rednessInflammation: rednessScore
        case .poreVisibility: poreVisibilityScore
        case .toneUniformity: toneUniformityScore
        case .underEyeQuality: underEyeQualityScore
        case .wrinkleDepth: wrinkleDepthScore
        case .elasticityProxy: elasticityProxyScore
        case .overallSkinHealth: 0
        }
    }
}

nonisolated struct SkinAnalysisData: Sendable {
    var textureEvennessScore: Double = 0
    var apparentHydrationScore: Double = 0
    var brightnessRadianceScore: Double = 0
    var rednessScore: Double = 0
    var poreVisibilityScore: Double = 0
    var toneUniformityScore: Double = 0
    var underEyeQualityScore: Double = 0
    var wrinkleDepthScore: Double = 0
    var elasticityProxyScore: Double = 0
    var overallScore: Double = 0

    var itaAngle: Double = 0
    var aStarMean: Double = 0
    var bStarMean: Double = 0
    var laplacianVariance: Double = 0
    var saturationVariance: Double = 0
    var regionData: [String: RegionScores] = [:]
    var lightingConditions: LightingConditions?

    var brightnessScore: Double { brightnessRadianceScore }
    var textureScore: Double { textureEvennessScore }
    var hydrationScore: Double { apparentHydrationScore }

    func score(for metric: SkinMetricType) -> Double {
        switch metric {
        case .textureEvenness: textureEvennessScore
        case .apparentHydration: apparentHydrationScore
        case .brightnessRadiance: brightnessRadianceScore
        case .rednessInflammation: rednessScore
        case .poreVisibility: poreVisibilityScore
        case .toneUniformity: toneUniformityScore
        case .underEyeQuality: underEyeQualityScore
        case .wrinkleDepth: wrinkleDepthScore
        case .elasticityProxy: elasticityProxyScore
        case .overallSkinHealth: overallScore
        }
    }

    static func computeOverall(from data: SkinAnalysisData) -> Double {
        let implementedMetrics = SkinMetricType.allCases.filter { $0.isImplemented }
        let totalWeight = implementedMetrics.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        let weightedSum = implementedMetrics.reduce(0.0) { $0 + data.score(for: $1) * $1.weight }
        return weightedSum / totalWeight
    }
}

struct SkinScanResult: Identifiable {
    let id = UUID()
    let date: Date
    let overallScore: Int
    let regions: [SkinRegionResult]
    let metrics: [SkinMetric]
    let trend: Double
    let analysisData: SkinAnalysisData?
    let calibration: CalibrationResult?

    init(date: Date, overallScore: Int, regions: [SkinRegionResult], metrics: [SkinMetric], trend: Double, analysisData: SkinAnalysisData? = nil, calibration: CalibrationResult? = nil) {
        self.date = date
        self.overallScore = overallScore
        self.regions = regions
        self.metrics = metrics
        self.trend = trend
        self.analysisData = analysisData
        self.calibration = calibration
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct SkinRegionResult: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let score: Int
    let keyMetric: String
    let keyValue: String
    let trend: RegionTrend
}

enum RegionTrend {
    case improving
    case stable
    case declining

    var icon: String {
        switch self {
        case .improving: "arrow.up.right"
        case .stable: "arrow.right"
        case .declining: "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: Color(hex: "4CAF50")
        case .stable: Color(hex: "E8A838")
        case .declining: Color(hex: "E53935")
        }
    }

    var label: String {
        switch self {
        case .improving: "Improving"
        case .stable: "Stable"
        case .declining: "Declining"
        }
    }
}

struct SkinMetric: Identifiable {
    let id = UUID()
    let name: String
    let score: Int
    let previousScore: Int?
    let icon: String

    var trend: Int? {
        guard let prev = previousScore else { return nil }
        return score - prev
    }
}
