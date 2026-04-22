import Foundation
import SwiftData

nonisolated struct SkinForecastPoint: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let score: Double
    let isProjected: Bool
}

nonisolated struct SkinForecast: Sendable {
    let history: [SkinForecastPoint]
    let projection: [SkinForecastPoint]
    let currentScore: Double
    let projectedScore30: Double
    let projectedScore60: Double
    let projectedScore90: Double
    let targetReachDate: Date?
    let targetScore: Double
    let confidenceLabel: String
    let weeklyGain: Double
    let summary: String

    var combined: [SkinForecastPoint] {
        history + projection
    }

    var minY: Double {
        let values = combined.map(\.score)
        return max(0, (values.min() ?? 40) - 8)
    }

    var maxY: Double {
        let values = combined.map(\.score)
        return min(100, (values.max() ?? 90) + 8)
    }
}

@Observable
final class ForecastEngine {
    static let shared = ForecastEngine()

    private init() {}

    func computeForecast(scans: [SkinScanRecord], longevityScores: [DailyLongevityScore]) -> SkinForecast? {
        let sortedScans = scans.sorted { $0.date < $1.date }
        guard let latest = sortedScans.last else { return nil }

        let currentScore = Double(latest.overallScore)
        let today = Calendar.current.startOfDay(for: Date())

        let history: [SkinForecastPoint] = sortedScans.suffix(14).map { scan in
            SkinForecastPoint(date: scan.date, score: Double(scan.overallScore), isProjected: false)
        }

        let weeklyGain = estimateWeeklyGain(scans: sortedScans, longevityScores: longevityScores)
        let adherenceBoost = adherenceMultiplier(longevityScores: longevityScores)
        let effectiveWeekly = weeklyGain * adherenceBoost

        let targetScore: Double = min(95, max(currentScore + 12, 85))

        var projection: [SkinForecastPoint] = []
        var projectedScore30: Double = currentScore
        var projectedScore60: Double = currentScore
        var projectedScore90: Double = currentScore
        var targetReachDate: Date?

        for week in 1...13 {
            guard let date = Calendar.current.date(byAdding: .day, value: week * 7, to: today) else { continue }
            let rawScore = currentScore + effectiveWeekly * Double(week)
            let decayedScore = applyDiminishingReturns(base: currentScore, projected: rawScore)
            let clamped = min(98, max(0, decayedScore))
            projection.append(SkinForecastPoint(date: date, score: clamped, isProjected: true))

            if week == 4 { projectedScore30 = clamped }
            if week == 8 { projectedScore60 = clamped }
            if week == 13 { projectedScore90 = clamped }

            if targetReachDate == nil && clamped >= targetScore {
                targetReachDate = date
            }
        }

        let confidenceLabel: String
        if sortedScans.count >= 10 { confidenceLabel = "High confidence" }
        else if sortedScans.count >= 5 { confidenceLabel = "Moderate confidence" }
        else { confidenceLabel = "Early projection" }

        let summary = buildSummary(
            currentScore: currentScore,
            projectedScore90: projectedScore90,
            targetReachDate: targetReachDate,
            targetScore: targetScore,
            weeklyGain: effectiveWeekly
        )

        return SkinForecast(
            history: history,
            projection: projection,
            currentScore: currentScore,
            projectedScore30: projectedScore30,
            projectedScore60: projectedScore60,
            projectedScore90: projectedScore90,
            targetReachDate: targetReachDate,
            targetScore: targetScore,
            confidenceLabel: confidenceLabel,
            weeklyGain: effectiveWeekly,
            summary: summary
        )
    }

    private func estimateWeeklyGain(scans: [SkinScanRecord], longevityScores: [DailyLongevityScore]) -> Double {
        guard scans.count >= 2, let first = scans.first, let last = scans.last else {
            return 0.6
        }
        let days = max(1.0, last.date.timeIntervalSince(first.date) / 86400.0)
        let scoreDelta = Double(last.overallScore - first.overallScore)
        let dailyRate = scoreDelta / days
        let weeklyRate = dailyRate * 7.0
        if scans.count < 4 {
            return max(0.3, min(2.5, (weeklyRate + 0.8) / 2))
        }
        return max(-0.5, min(3.0, weeklyRate))
    }

    private func adherenceMultiplier(longevityScores: [DailyLongevityScore]) -> Double {
        let streak = UserDefaults.standard.integer(forKey: "adherenceStreak")
        let streakBoost: Double
        if streak >= 30 { streakBoost = 1.35 }
        else if streak >= 14 { streakBoost = 1.2 }
        else if streak >= 7 { streakBoost = 1.1 }
        else { streakBoost = 0.85 }

        guard !longevityScores.isEmpty else { return streakBoost }
        let recent = longevityScores.prefix(7)
        let avgComposite = recent.map(\.compositeScore).reduce(0, +) / Double(recent.count)
        let compositeBoost = 0.8 + (avgComposite / 100.0) * 0.5
        return streakBoost * compositeBoost
    }

    private func applyDiminishingReturns(base: Double, projected: Double) -> Double {
        let ceiling: Double = 96
        let gap = projected - base
        guard gap > 0 else { return projected }
        let headroom = ceiling - base
        guard headroom > 0 else { return base }
        let ratio = gap / max(10, headroom)
        let decayFactor = 1.0 - pow(ratio, 1.5) * 0.25
        return base + gap * max(0.5, decayFactor)
    }

    private func buildSummary(currentScore: Double, projectedScore90: Double, targetReachDate: Date?, targetScore: Double, weeklyGain: Double) -> String {
        let gainPoints = projectedScore90 - currentScore
        if weeklyGain < 0.1 {
            return "Consistency is slipping. Re-commit to your daily protocol to unlock progress."
        }
        if let reachDate = targetReachDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "At this pace you'll reach \(Int(targetScore)) by \(formatter.string(from: reachDate))."
        }
        if gainPoints >= 5 {
            return String(format: "Projected +%.0f points over 90 days. Stay consistent.", gainPoints)
        }
        return "Build a longer streak to accelerate your trajectory."
    }
}
