import SwiftUI

nonisolated enum ScanPhase: String, Sendable {
    case preScan
    case scanning
    case analyzing
    case results
    case history
    case heatMap
    case progress
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

nonisolated struct SkinAnalysisData: Sendable {
    var brightnessScore: Double = 0
    var rednessScore: Double = 0
    var textureScore: Double = 0
    var hydrationScore: Double = 0
    var overallScore: Double = 0
    var itaAngle: Double = 0
    var aStarMean: Double = 0
    var laplacianVariance: Double = 0
    var saturationVariance: Double = 0
}

struct SkinScanResult: Identifiable {
    let id = UUID()
    let date: Date
    let overallScore: Int
    let regions: [SkinRegionResult]
    let metrics: [SkinMetric]
    let trend: Double
    let analysisData: SkinAnalysisData?

    init(date: Date, overallScore: Int, regions: [SkinRegionResult], metrics: [SkinMetric], trend: Double, analysisData: SkinAnalysisData? = nil) {
        self.date = date
        self.overallScore = overallScore
        self.regions = regions
        self.metrics = metrics
        self.trend = trend
        self.analysisData = analysisData
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
