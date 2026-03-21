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

    func generateActionableInsights() -> [ActionableInsight] {
        var insights: [ActionableInsight] = []

        if let hours = healthService.sleepData.totalHours, hours < 6 {
            insights.append(ActionableInsight(
                title: "Poor Sleep Last Night",
                detail: String(format: "You slept %.1f hours — below the 7-9h optimal range. This may reduce collagen synthesis and slow skin repair.", hours),
                icon: "moon.zzz.fill",
                severity: .warning,
                actionLabel: "Improve Sleep",
                actionDestination: .tip("Try setting a consistent bedtime. Avoid screens 1 hour before sleep and keep your room cool (65-68°F)."),
                priority: 8
            ))
        } else if let hours = healthService.sleepData.totalHours, hours >= 8 {
            insights.append(ActionableInsight(
                title: "Restorative Sleep",
                detail: String(format: "%.1f hours of quality sleep is fueling your skin's overnight repair cycle.", hours),
                icon: "moon.fill",
                severity: .positive,
                actionLabel: "Keep It Up",
                actionDestination: .tip("Maintaining this sleep schedule consistently will compound benefits for your skin longevity."),
                priority: 4
            ))
        }

        if let hrv = healthService.latestHRV {
            if hrv >= 60 {
                insights.append(ActionableInsight(
                    title: "HRV Elevated — Great Recovery",
                    detail: String(format: "Your HRV is %.0f ms, indicating strong autonomic recovery and low stress load.", hrv),
                    icon: "heart.fill",
                    severity: .positive,
                    actionLabel: "View Details",
                    actionDestination: .openHealth,
                    priority: 3
                ))
            } else if hrv < 35 {
                insights.append(ActionableInsight(
                    title: "Low HRV — Elevated Stress",
                    detail: String(format: "Your HRV is %.0f ms. Elevated cortisol from stress can break down collagen and trigger inflammation.", hrv),
                    icon: "brain.head.profile",
                    severity: .warning,
                    actionLabel: "Manage Stress",
                    actionDestination: .tip("Try 5 minutes of deep breathing or a short walk. Even brief relaxation can lower cortisol."),
                    priority: 7
                ))
            }
        }

        if let uvDose = healthService.todayUVExposure, uvDose > 5 {
            insights.append(ActionableInsight(
                title: "UV Exposure High",
                detail: String(format: "UV dose today: %.1f — above the safe threshold. Prolonged exposure accelerates photoaging.", uvDose),
                icon: "sun.max.trianglebadge.exclamationmark.fill",
                severity: .critical,
                actionLabel: "Apply SPF",
                actionDestination: .tip("Reapply SPF 50+ every 2 hours when outdoors. Seek shade during peak UV hours (10 AM–4 PM)."),
                priority: 9
            ))
        }

        if let waterMl = healthService.todayWaterIntake, waterMl < 2000 {
            let liters = waterMl / 1000
            insights.append(ActionableInsight(
                title: "Hydration Low",
                detail: String(format: "You've had %.1fL today — aim for 2.5L. Dehydrated skin loses elasticity and barrier function.", liters),
                icon: "drop.fill",
                severity: .warning,
                actionLabel: "Hydrate Now",
                actionDestination: .tip("Drink a glass of water now and set hourly reminders. Add electrolytes for better absorption."),
                priority: 7
            ))
        } else if let waterMl = healthService.todayWaterIntake, waterMl >= 2500 {
            insights.append(ActionableInsight(
                title: "Hydration On Point",
                detail: String(format: "%.1fL today — excellent. Your skin barrier is well-supported.", waterMl / 1000),
                icon: "drop.fill",
                severity: .positive,
                actionLabel: "Nice Work",
                actionDestination: .tip("Consistent hydration is one of the easiest ways to support skin health long-term."),
                priority: 2
            ))
        }

        if stressRiskLevel == .high {
            insights.append(ActionableInsight(
                title: "Skin Flare-Up Risk",
                detail: "Low HRV combined with negative mood significantly increases risk of stress-related skin issues like breakouts and sensitivity.",
                icon: "exclamationmark.triangle.fill",
                severity: .critical,
                actionLabel: "Calm Down",
                actionDestination: .tip("Consider a calming activity: meditation, gentle stretching, or a warm bath with magnesium salts."),
                priority: 10
            ))
        }

        if let cal = healthService.todayActiveCalories, cal >= 300 {
            insights.append(ActionableInsight(
                title: "Activity Boosting Skin",
                detail: String(format: "%.0f kcal burned today. Exercise increases blood flow, delivering oxygen and nutrients to skin cells.", cal),
                icon: "figure.run",
                severity: .positive,
                actionLabel: "Keep Moving",
                actionDestination: .openHealth,
                priority: 3
            ))
        }

        return insights.sorted { $0.priority > $1.priority }
    }

    func computeCorrelationStats(from scores: [DailyLongevityScore]) -> [CorrelationStat] {
        guard scores.count >= 5 else { return [] }
        var stats: [CorrelationStat] = []

        let goodSleepDays = scores.filter { $0.sleepScore >= 80 }
        let poorSleepDays = scores.filter { $0.sleepScore > 0 && $0.sleepScore < 60 }
        if goodSleepDays.count >= 3 && poorSleepDays.count >= 2 {
            let goodAvg = goodSleepDays.map(\.skinScore).reduce(0, +) / Double(goodSleepDays.count)
            let poorAvg = poorSleepDays.map(\.skinScore).reduce(0, +) / Double(poorSleepDays.count)
            let delta = goodAvg - poorAvg
            if abs(delta) > 3 {
                stats.append(CorrelationStat(
                    description: String(format: "When you sleep 8+ hours, your skin score is %.0f%% higher", delta),
                    factor: "Sleep",
                    delta: delta
                ))
            }
        }

        let highActivityDays = scores.filter { $0.activityScore >= 70 }
        let lowActivityDays = scores.filter { $0.activityScore > 0 && $0.activityScore < 40 }
        if highActivityDays.count >= 3 && lowActivityDays.count >= 2 {
            let highAvg = highActivityDays.map(\.compositeScore).reduce(0, +) / Double(highActivityDays.count)
            let lowAvg = lowActivityDays.map(\.compositeScore).reduce(0, +) / Double(lowActivityDays.count)
            let delta = highAvg - lowAvg
            if abs(delta) > 3 {
                stats.append(CorrelationStat(
                    description: String(format: "Active days correlate with %.0f%% higher longevity scores", delta),
                    factor: "Activity",
                    delta: delta
                ))
            }
        }

        let goodHydrationDays = scores.filter { $0.hydrationScore >= 75 }
        let poorHydrationDays = scores.filter { $0.hydrationScore > 0 && $0.hydrationScore < 50 }
        if goodHydrationDays.count >= 3 && poorHydrationDays.count >= 2 {
            let goodAvg = goodHydrationDays.map(\.skinScore).reduce(0, +) / Double(goodHydrationDays.count)
            let poorAvg = poorHydrationDays.map(\.skinScore).reduce(0, +) / Double(poorHydrationDays.count)
            let delta = goodAvg - poorAvg
            if abs(delta) > 2 {
                stats.append(CorrelationStat(
                    description: String(format: "Good hydration days show %.0f%% better skin scores", delta),
                    factor: "Hydration",
                    delta: delta
                ))
            }
        }

        let lowStressDays = scores.filter { $0.stressScore >= 70 }
        let highStressDays = scores.filter { $0.stressScore > 0 && $0.stressScore < 45 }
        if lowStressDays.count >= 3 && highStressDays.count >= 2 {
            let lowAvg = lowStressDays.map(\.compositeScore).reduce(0, +) / Double(lowStressDays.count)
            let highAvg = highStressDays.map(\.compositeScore).reduce(0, +) / Double(highStressDays.count)
            let delta = lowAvg - highAvg
            if abs(delta) > 3 {
                stats.append(CorrelationStat(
                    description: String(format: "Low-stress days produce %.0f%% higher overall scores", delta),
                    factor: "Stress",
                    delta: delta
                ))
            }
        }

        return stats
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
