import SwiftData
import Foundation

nonisolated enum ConfidenceLevel: String, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

nonisolated struct CalibrationResult: Sendable {
    let isCalibrating: Bool
    let calibrationScanCount: Int
    let calibrationScansRemaining: Int
    let deltaFromBaseline: Double?
    let baselineScore: Double?
    let perMetricDeltas: [SkinMetricType: Double]
    let perMetricConfidence: [SkinMetricType: ConfidenceLevel]
    let overallConfidence: ConfidenceLevel
}

final class CalibrationService {

    private static let minimumDetectableChange: Double = 3.0
    private static let calibrationScanThreshold = 3
    private static let regionNames = ["Forehead", "Left Cheek", "Right Cheek", "Chin", "Under-Eyes", "Nose"]

    func processCalibration(
        analysis: SkinAnalysisData,
        modelContext: ModelContext
    ) -> CalibrationResult {
        let baseline = fetchOrCreateBaseline(modelContext: modelContext)
        let totalScans = totalScanCount(modelContext: modelContext)
        let isCalibrating = totalScans < Self.calibrationScanThreshold

        if isCalibrating {
            accumulateBaseline(baseline: baseline, analysis: analysis, scanIndex: totalScans)
            try? modelContext.save()
        }

        let perMetricConfidence = computeConfidence(totalScans: totalScans, analysis: analysis, modelContext: modelContext)

        let overallConfidence: ConfidenceLevel
        if totalScans < Self.calibrationScanThreshold {
            overallConfidence = .low
        } else if totalScans < 10 {
            overallConfidence = .medium
        } else {
            overallConfidence = .high
        }

        var perMetricDeltas: [SkinMetricType: Double] = [:]
        var deltaFromBaseline: Double? = nil
        var baselineScore: Double? = nil

        if !isCalibrating {
            baselineScore = baseline.baselineOverall

            for metric in SkinMetricType.allCases where metric != .overallSkinHealth && metric.isImplemented {
                let current = analysis.score(for: metric)
                let base = baseline.baselineScore(for: metric)
                let raw = current - base
                if abs(raw) >= Self.minimumDetectableChange {
                    perMetricDeltas[metric] = raw
                } else {
                    perMetricDeltas[metric] = 0
                }
            }

            let rawDelta = analysis.overallScore - baseline.baselineOverall
            if abs(rawDelta) >= Self.minimumDetectableChange {
                deltaFromBaseline = rawDelta
            } else {
                deltaFromBaseline = 0
            }
        }

        return CalibrationResult(
            isCalibrating: isCalibrating,
            calibrationScanCount: min(totalScans, Self.calibrationScanThreshold),
            calibrationScansRemaining: max(0, Self.calibrationScanThreshold - totalScans),
            deltaFromBaseline: deltaFromBaseline,
            baselineScore: baselineScore,
            perMetricDeltas: perMetricDeltas,
            perMetricConfidence: perMetricConfidence,
            overallConfidence: overallConfidence
        )
    }

    func computeTrend(for metric: SkinMetricType, modelContext: ModelContext) -> RegionTrend? {
        let descriptor = FetchDescriptor<SkinScanRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let records = try? modelContext.fetch(descriptor), records.count >= 3 else {
            return nil
        }

        let recentThree = Array(records.prefix(3))
        let scores = recentThree.map { scoreFromRecord($0, metric: metric) }

        let allIncreasing = scores[0] > scores[1] && scores[1] > scores[2]
        let allDecreasing = scores[0] < scores[1] && scores[1] < scores[2]

        if allIncreasing { return .improving }
        if allDecreasing { return .declining }
        return .stable
    }

    private func fetchOrCreateBaseline(modelContext: ModelContext) -> CalibrationBaseline {
        let descriptor = FetchDescriptor<CalibrationBaseline>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let baseline = CalibrationBaseline()
        modelContext.insert(baseline)
        return baseline
    }

    private func totalScanCount(modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<SkinScanRecord>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func accumulateBaseline(baseline: CalibrationBaseline, analysis: SkinAnalysisData, scanIndex: Int) {
        let n = Double(scanIndex)
        let newN = n + 1.0

        baseline.baselineTextureEvenness = runningAverage(old: baseline.baselineTextureEvenness, newVal: analysis.textureEvennessScore, n: n, newN: newN)
        baseline.baselineApparentHydration = runningAverage(old: baseline.baselineApparentHydration, newVal: analysis.apparentHydrationScore, n: n, newN: newN)
        baseline.baselineBrightnessRadiance = runningAverage(old: baseline.baselineBrightnessRadiance, newVal: analysis.brightnessRadianceScore, n: n, newN: newN)
        baseline.baselineRedness = runningAverage(old: baseline.baselineRedness, newVal: analysis.rednessScore, n: n, newN: newN)
        baseline.baselinePoreVisibility = runningAverage(old: baseline.baselinePoreVisibility, newVal: analysis.poreVisibilityScore, n: n, newN: newN)
        baseline.baselineToneUniformity = runningAverage(old: baseline.baselineToneUniformity, newVal: analysis.toneUniformityScore, n: n, newN: newN)
        baseline.baselineUnderEyeQuality = runningAverage(old: baseline.baselineUnderEyeQuality, newVal: analysis.underEyeQualityScore, n: n, newN: newN)
        baseline.baselineWrinkleDepth = runningAverage(old: baseline.baselineWrinkleDepth, newVal: analysis.wrinkleDepthScore, n: n, newN: newN)
        baseline.baselineElasticity = runningAverage(old: baseline.baselineElasticity, newVal: analysis.elasticityProxyScore, n: n, newN: newN)
        baseline.baselineOverall = runningAverage(old: baseline.baselineOverall, newVal: analysis.overallScore, n: n, newN: newN)

        for regionName in Self.regionNames {
            guard let regionScores = analysis.regionData[regionName] else { continue }
            let existing = baseline.regionMeans(for: regionName)
            baseline.setRegionMeans(
                for: regionName,
                meanL: runningAverage(old: existing.meanL, newVal: regionScores.itaAngle != 0 ? regionScores.itaAngle : existing.meanL, n: n, newN: newN),
                meanA: runningAverage(old: existing.meanA, newVal: regionScores.aStarMean, n: n, newN: newN),
                meanB: runningAverage(old: existing.meanB, newVal: regionScores.bStarMean, n: n, newN: newN),
                textureVar: runningAverage(old: existing.textureVar, newVal: regionScores.laplacianVariance, n: n, newN: newN),
                satVar: runningAverage(old: existing.satVar, newVal: regionScores.saturationVariance, n: n, newN: newN)
            )
        }

        baseline.scanCount = Int(newN)
        baseline.updatedAt = Date()
    }

    private func runningAverage(old: Double, newVal: Double, n: Double, newN: Double) -> Double {
        guard newN > 0 else { return newVal }
        return (old * n + newVal) / newN
    }

    private func computeConfidence(totalScans: Int, analysis: SkinAnalysisData, modelContext: ModelContext) -> [SkinMetricType: ConfidenceLevel] {
        var result: [SkinMetricType: ConfidenceLevel] = [:]
        let lightingConsistent = isLightingConsistent(modelContext: modelContext)

        for metric in SkinMetricType.allCases where metric != .overallSkinHealth && metric.isImplemented {
            if totalScans < Self.calibrationScanThreshold {
                result[metric] = .low
            } else if totalScans >= 10 && lightingConsistent {
                result[metric] = .high
            } else {
                result[metric] = .medium
            }
        }
        return result
    }

    private func isLightingConsistent(modelContext: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<SkinScanRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 5
        guard let records = try? modelContext.fetch(descriptor), records.count >= 3 else {
            return false
        }

        let intensities = records.map(\.lightingAmbientIntensity).filter { $0 > 0 }
        guard intensities.count >= 3 else { return false }

        let mean = intensities.reduce(0, +) / Double(intensities.count)
        guard mean > 0 else { return false }
        let coefficientOfVariation = sqrt(intensities.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(intensities.count)) / mean

        return coefficientOfVariation < 0.3
    }

    private func scoreFromRecord(_ record: SkinScanRecord, metric: SkinMetricType) -> Double {
        switch metric {
        case .textureEvenness: record.textureEvennessScore
        case .apparentHydration: record.apparentHydrationScore
        case .brightnessRadiance: record.brightnessRadianceScore
        case .rednessInflammation: record.rednessScore
        case .poreVisibility: record.poreVisibilityScore
        case .toneUniformity: record.toneUniformityScore
        case .underEyeQuality: record.underEyeQualityScore
        case .wrinkleDepth: record.wrinkleDepthScore
        case .elasticityProxy: record.elasticityProxyScore
        case .overallSkinHealth: Double(record.overallScore)
        }
    }
}
