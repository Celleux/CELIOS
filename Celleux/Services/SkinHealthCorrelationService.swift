import Foundation

@Observable
final class SkinHealthCorrelationService {
    static let shared = SkinHealthCorrelationService()

    private let healthService = HealthKitService.shared

    var sleepScore: Double = 0
    var stressScore: Double = 0
    var hydrationScore: Double = 0
    var uvScore: Double = 0
    var activityScore: Double = 0

    var overallCorrelationScore: Double = 0

    var skinMoodCorrelation: Double?
    var skinSleepCorrelation: Double?

    var stressRiskLevel: StressRiskLevel = .unknown

    private init() {}

    func computeCorrelation() {
        sleepScore = computeSleepContribution()
        stressScore = computeStressContribution()
        hydrationScore = computeHydrationContribution()
        uvScore = computeUVContribution()
        activityScore = computeActivityContribution()

        overallCorrelationScore = sleepScore * SkinHealthFactor.sleep.weight
            + stressScore * SkinHealthFactor.stress.weight
            + hydrationScore * SkinHealthFactor.hydration.weight
            + uvScore * SkinHealthFactor.uvExposure.weight
            + activityScore * SkinHealthFactor.activity.weight

        overallCorrelationScore = min(100, max(0, overallCorrelationScore))

        computeStressRisk()
    }

    private func computeSleepContribution() -> Double {
        guard let hours = healthService.sleepData.totalHours else { return 50 }
        let totalMin = healthService.sleepData.totalMinutes ?? 0
        let deepMin = healthService.sleepData.deepMinutes ?? 0
        let remMin = healthService.sleepData.remMinutes ?? 0

        let durationScore: Double
        if hours >= 7 && hours <= 9 {
            durationScore = 90 + min(10, (hours - 7) * 5)
        } else if hours >= 6 {
            durationScore = 60 + (hours - 6) * 30
        } else {
            durationScore = max(20, hours * 10)
        }

        let deepPercent = totalMin > 0 ? (deepMin / totalMin) * 100 : 0
        let deepScore = min(100, deepPercent * 5)

        let remPercent = totalMin > 0 ? (remMin / totalMin) * 100 : 0
        let remScore = min(100, remPercent * 4)

        return durationScore * 0.4 + deepScore * 0.35 + remScore * 0.25
    }

    private func computeStressContribution() -> Double {
        var score: Double = 50

        if let hrv = healthService.latestHRV {
            if hrv >= 60 { score = 85 + min(15, (hrv - 60) * 0.5) }
            else if hrv >= 40 { score = 55 + (hrv - 40) * 1.5 }
            else if hrv >= 20 { score = 25 + (hrv - 20) * 1.5 }
            else { score = max(10, hrv * 1.25) }
        }

        if let rhr = healthService.latestRestingHR {
            let rhrComponent: Double
            if rhr <= 55 { rhrComponent = 95 }
            else if rhr <= 65 { rhrComponent = 80 }
            else if rhr <= 75 { rhrComponent = 60 }
            else { rhrComponent = max(20, 60 - (rhr - 75) * 2) }
            score = score * 0.6 + rhrComponent * 0.4
        }

        if let valence = healthService.averageMoodValence {
            let moodScore = (valence + 1.0) / 2.0 * 100
            score = score * 0.7 + moodScore * 0.3
        }

        return min(100, max(0, score))
    }

    private func computeHydrationContribution() -> Double {
        guard let waterMl = healthService.todayWaterIntake else { return 50 }
        let targetMl: Double = 2500
        let ratio = waterMl / targetMl
        if ratio >= 1.0 { return min(100, 90 + (ratio - 1.0) * 20) }
        if ratio >= 0.7 { return 60 + (ratio - 0.7) / 0.3 * 30 }
        return max(10, ratio / 0.7 * 60)
    }

    private func computeUVContribution() -> Double {
        guard let uvDose = healthService.todayUVExposure else { return 70 }
        if uvDose <= 2 { return 90 }
        if uvDose <= 5 { return 90 - (uvDose - 2) * 8 }
        if uvDose <= 8 { return 66 - (uvDose - 5) * 8 }
        return max(10, 42 - (uvDose - 8) * 5)
    }

    private func computeActivityContribution() -> Double {
        var score: Double = 50

        if let cal = healthService.todayActiveCalories {
            if cal >= 300 && cal <= 600 { score = 85 + min(15, (cal - 300) / 300 * 15) }
            else if cal >= 100 { score = 55 + (cal - 100) / 200 * 30 }
            else if cal > 0 { score = 30 + cal / 100 * 25 }
            else { score = 30 }
        }

        if let exercise = healthService.todayExerciseMinutes {
            let exerciseScore: Double
            if exercise >= 30 && exercise <= 60 { exerciseScore = 90 }
            else if exercise >= 15 { exerciseScore = 60 + (exercise - 15) / 15 * 30 }
            else if exercise > 0 { exerciseScore = 30 + exercise / 15 * 30 }
            else { exerciseScore = 25 }
            score = score * 0.6 + exerciseScore * 0.4
        }

        return min(100, max(0, score))
    }

    private func computeStressRisk() {
        if let hrv = healthService.latestHRV,
           let valence = healthService.averageMoodValence {
            if hrv < 30 && valence < -0.3 {
                stressRiskLevel = .high
            } else if hrv < 45 && valence < 0 {
                stressRiskLevel = .moderate
            } else if hrv >= 50 && valence > 0.2 {
                stressRiskLevel = .low
            } else {
                stressRiskLevel = .moderate
            }
        } else if let hrv = healthService.latestHRV {
            stressRiskLevel = hrv < 35 ? .moderate : .low
        } else {
            stressRiskLevel = .unknown
        }
    }

    func generateNarrativeInsight(latestSkinScore: Int, hasScanData: Bool) -> NarrativeInsight {
        var candidates: [NarrativeInsight] = []

        if !hasScanData {
            return NarrativeInsight(text: "Complete your first scan to get insights", icon: "viewfinder", priority: 0)
        }

        if stressRiskLevel == .high {
            candidates.append(NarrativeInsight(text: "Elevated stress may be affecting your skin", icon: "brain.head.profile", priority: 10))
        }

        if sleepScore >= 80 {
            candidates.append(NarrativeInsight(text: "Great sleep is boosting your skin recovery", icon: "moon.fill", priority: 7))
        } else if sleepScore > 0 && sleepScore < 50 {
            candidates.append(NarrativeInsight(text: "Poor sleep may slow collagen repair tonight", icon: "moon.zzz.fill", priority: 8))
        }

        if hydrationScore < 50 && hydrationScore > 0 {
            candidates.append(NarrativeInsight(text: "Hydration could use some attention today", icon: "drop.fill", priority: 7))
        } else if hydrationScore >= 80 {
            candidates.append(NarrativeInsight(text: "Your hydration is on point today", icon: "drop.fill", priority: 5))
        }

        if uvScore < 50 && uvScore > 0 {
            candidates.append(NarrativeInsight(text: "High UV exposure detected — reapply SPF", icon: "sun.max.trianglebadge.exclamationmark.fill", priority: 9))
        }

        if activityScore >= 75 {
            candidates.append(NarrativeInsight(text: "Activity is boosting circulation to your skin", icon: "figure.run", priority: 5))
        }

        if latestSkinScore >= 80 {
            candidates.append(NarrativeInsight(text: "Your skin is glowing today", icon: "sparkles", priority: 6))
        } else if latestSkinScore >= 60 {
            candidates.append(NarrativeInsight(text: "Your skin is looking steady", icon: "face.smiling", priority: 4))
        } else if latestSkinScore > 0 {
            candidates.append(NarrativeInsight(text: "Your skin needs a little extra care today", icon: "heart.fill", priority: 6))
        }

        if overallCorrelationScore >= 80 {
            candidates.append(NarrativeInsight(text: "Your lifestyle is strongly supporting your skin", icon: "leaf.fill", priority: 5))
        }

        guard let best = candidates.max(by: { $0.priority < $1.priority }) else {
            return NarrativeInsight(text: "Keep tracking for personalized insights", icon: "sparkles", priority: 0)
        }
        return best
    }

    func generateInsights() -> [SkinCorrelationInsight] {
        var insights: [SkinCorrelationInsight] = []

        if sleepScore < 50 {
            insights.append(SkinCorrelationInsight(
                title: "Sleep Impacting Skin",
                detail: "Poor sleep reduces collagen synthesis. Aim for 7-9 hours with deep sleep cycles.",
                icon: "moon.zzz.fill",
                severity: .warning,
                factor: .sleep
            ))
        } else if sleepScore >= 80 {
            insights.append(SkinCorrelationInsight(
                title: "Great Sleep Quality",
                detail: "Your sleep is supporting growth hormone release and tissue repair.",
                icon: "moon.fill",
                severity: .positive,
                factor: .sleep
            ))
        }

        if stressScore < 45 {
            insights.append(SkinCorrelationInsight(
                title: "Stress Alert",
                detail: "Elevated stress markers detected. Cortisol may increase sebum production and break down collagen.",
                icon: "brain.head.profile",
                severity: .warning,
                factor: .stress
            ))
        }

        if hydrationScore < 50 {
            insights.append(SkinCorrelationInsight(
                title: "Hydration Needed",
                detail: "Low water intake impairs skin barrier function. Try to reach 2.5L today.",
                icon: "drop.fill",
                severity: .warning,
                factor: .hydration
            ))
        }

        if uvScore < 50 {
            insights.append(SkinCorrelationInsight(
                title: "UV Overexposure",
                detail: "High UV exposure accelerates photoaging. Consider SPF reapplication.",
                icon: "sun.max.trianglebadge.exclamationmark.fill",
                severity: .warning,
                factor: .uvExposure
            ))
        }

        if activityScore >= 75 {
            insights.append(SkinCorrelationInsight(
                title: "Activity Boost",
                detail: "Good activity level boosts circulation and oxygen delivery to skin.",
                icon: "figure.run",
                severity: .positive,
                factor: .activity
            ))
        }

        if stressRiskLevel == .high {
            insights.insert(SkinCorrelationInsight(
                title: "Skin Flare-Up Risk",
                detail: "Low HRV combined with negative mood increases risk of stress-related skin issues.",
                icon: "exclamationmark.triangle.fill",
                severity: .critical,
                factor: .stress
            ), at: 0)
        }

        return insights
    }
}

nonisolated enum SkinHealthFactor: String, Identifiable, CaseIterable, Sendable {
    case sleep
    case stress
    case hydration
    case uvExposure
    case activity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep: "Sleep Quality"
        case .stress: "Stress Level"
        case .hydration: "Hydration"
        case .uvExposure: "UV Exposure"
        case .activity: "Activity"
        }
    }

    var weight: Double {
        switch self {
        case .sleep: 0.35
        case .stress: 0.25
        case .hydration: 0.15
        case .uvExposure: 0.15
        case .activity: 0.10
        }
    }

    var icon: String {
        switch self {
        case .sleep: "moon.fill"
        case .stress: "brain.head.profile"
        case .hydration: "drop.fill"
        case .uvExposure: "sun.max.fill"
        case .activity: "figure.run"
        }
    }

    var skinImpact: String {
        switch self {
        case .sleep: "Deep sleep drives growth hormone release for collagen synthesis and tissue repair."
        case .stress: "Chronic stress activates cortisol, causing sebum overproduction and collagen breakdown."
        case .hydration: "Dehydration impairs skin barrier leading to dryness and sensitivity."
        case .uvExposure: "Overexposure accelerates photoaging and hyperpigmentation."
        case .activity: "Exercise boosts circulation for oxygen and nutrient delivery to skin."
        }
    }
}

nonisolated enum StressRiskLevel: String, Sendable {
    case low
    case moderate
    case high
    case unknown

    var label: String {
        switch self {
        case .low: "Low Risk"
        case .moderate: "Moderate"
        case .high: "High Risk"
        case .unknown: "Unknown"
        }
    }

    var color: String {
        switch self {
        case .low: "4CAF50"
        case .moderate: "FF9800"
        case .high: "E53935"
        case .unknown: "9E9E9E"
        }
    }
}

nonisolated struct SkinCorrelationInsight: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let severity: InsightSeverity
    let factor: SkinHealthFactor
}

nonisolated enum InsightSeverity: String, Sendable {
    case positive
    case neutral
    case warning
    case critical
}

nonisolated struct NarrativeInsight: Sendable {
    let text: String
    let icon: String
    let priority: Int
}
