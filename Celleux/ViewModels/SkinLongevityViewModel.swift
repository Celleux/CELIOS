import SwiftUI
import SwiftData

@Observable
final class SkinLongevityViewModel {
    private let healthService = HealthKitService.shared
    private let correlationService = SkinHealthCorrelationService.shared

    var compositeScore: Double = 0
    var animatedScore: Double = 0
    var trend: Double = 0
    var isLoading: Bool = true
    var selectedPeriod: HistoryPeriod = .thirtyDays

    var sleepScore: Double = 0
    var hrvScore: Double = 0
    var restingHRScore: Double = 0
    var vo2MaxScore: Double = 0
    var skinScore: Double = 0
    var adherenceScore: Double = 0
    var activityScore: Double = 0
    var circadianScore: Double = 0
    var stressScore: Double = 0
    var hydrationScore: Double = 0
    var uvScore: Double = 0
    var skinHealthIndex: Double = 0
    var moodValence: Double = 0

    var sleepHours: Double { healthService.sleepData.totalHours ?? 0 }
    var deepSleepPercent: Double {
        guard let total = healthService.sleepData.totalMinutes, total > 0,
              let deep = healthService.sleepData.deepMinutes else { return 0 }
        return (deep / total) * 100
    }
    var remSleepPercent: Double {
        guard let total = healthService.sleepData.totalMinutes, total > 0,
              let rem = healthService.sleepData.remMinutes else { return 0 }
        return (rem / total) * 100
    }
    var hrvValue: Double { healthService.latestHRV ?? 0 }
    var restingHR: Double { healthService.latestRestingHR ?? 0 }
    var vo2Max: Double { healthService.latestVO2Max ?? 0 }
    var activeCalories: Double { healthService.todayActiveCalories ?? 0 }
    var wristTemp: Double { healthService.latestWristTemperature ?? 0 }
    var waterIntake: Double { healthService.todayWaterIntake ?? 0 }
    var uvExposure: Double { healthService.todayUVExposure ?? 0 }

    var hasWatchData: Bool { healthService.hasWatchData }
    var hasMoodData: Bool { healthService.averageMoodValence != nil }

    var latestSkinScanScore: Int {
        UserDefaults.standard.integer(forKey: "latestSkinScore")
    }

    func loadData(modelContext: ModelContext) async {
        isLoading = true

        let authorized = await healthService.requestAuthorization()
        if authorized {
            await healthService.fetchAllData()
        }

        correlationService.computeCorrelation()
        computeScores()
        saveDailyScore(modelContext: modelContext)
        computeTrend(modelContext: modelContext)

        isLoading = false
    }

    func animateScoreIn() {
        withAnimation(.easeOut(duration: 1.4)) {
            animatedScore = compositeScore
        }
    }

    private func computeScores() {
        sleepScore = computeSleepScore()
        hrvScore = computeHRVScore()
        restingHRScore = computeRestingHRScore()
        vo2MaxScore = computeVO2MaxScore()
        skinScore = computeSkinAnalysisScore()
        adherenceScore = computeAdherenceScore()
        activityScore = computeActivityScore()
        circadianScore = computeCircadianScore()

        stressScore = correlationService.stressScore
        hydrationScore = correlationService.hydrationScore
        uvScore = correlationService.uvScore
        skinHealthIndex = correlationService.overallCorrelationScore
        moodValence = healthService.averageMoodValence ?? 0

        if hasWatchData {
            compositeScore = sleepScore * LongevityFactor.sleep.weight
                + hrvScore * LongevityFactor.hrv.weight
                + skinScore * LongevityFactor.skinAnalysis.weight
                + adherenceScore * LongevityFactor.adherence.weight
                + activityScore * LongevityFactor.activity.weight
                + circadianScore * LongevityFactor.circadian.weight
        } else {
            compositeScore = skinScore * LongevityFactor.skinAnalysis.noWatchWeight
                + adherenceScore * LongevityFactor.adherence.noWatchWeight
        }

        compositeScore = min(100, max(0, compositeScore))
    }

    private func computeSleepScore() -> Double {
        guard let hours = healthService.sleepData.totalHours else { return 0 }
        let hoursComponent = min(1.0, hours / 8.0) * 0.3
        let deepComponent = min(1.0, deepSleepPercent / 20.0) * 0.4
        let remComponent = min(1.0, remSleepPercent / 25.0) * 0.3
        return (hoursComponent + deepComponent + remComponent) * 100
    }

    private func computeHRVScore() -> Double {
        guard let hrv = healthService.latestHRV else { return 0 }
        let ageAdjustedMax: Double = 80
        return min(100, max(0, (hrv / ageAdjustedMax) * 100))
    }

    private func computeRestingHRScore() -> Double {
        guard let rhr = healthService.latestRestingHR else { return 0 }
        if rhr <= 50 { return 95 }
        if rhr <= 60 { return 85 }
        if rhr <= 70 { return 70 }
        if rhr <= 80 { return 55 }
        return max(20, 55 - (rhr - 80) * 2)
    }

    private func computeVO2MaxScore() -> Double {
        guard let vo2 = healthService.latestVO2Max else { return 0 }
        if vo2 >= 50 { return min(100, 90 + (vo2 - 50) * 0.5) }
        if vo2 >= 40 { return 70 + (vo2 - 40) * 2 }
        if vo2 >= 30 { return 50 + (vo2 - 30) * 2 }
        return max(20, 50 - (30 - vo2) * 2)
    }

    private func computeSkinAnalysisScore() -> Double {
        let stored = latestSkinScanScore
        guard stored > 0 else { return 72 }
        return Double(stored)
    }

    private func computeAdherenceScore() -> Double {
        let streak = UserDefaults.standard.integer(forKey: "adherenceStreak")
        if streak >= 30 { return 95 }
        if streak >= 14 { return 80 + Double(streak - 14) * (15.0 / 16.0) }
        if streak >= 7 { return 60 + Double(streak - 7) * (20.0 / 7.0) }
        return max(20, Double(streak) * (60.0 / 7.0))
    }

    private func computeActivityScore() -> Double {
        let vo2Component = computeVO2MaxScore() * 0.5
        let calComponent: Double
        if let cal = healthService.todayActiveCalories {
            calComponent = min(100, (cal / 500) * 100) * 0.5
        } else {
            calComponent = 0
        }
        return vo2Component + calComponent
    }

    private func computeCircadianScore() -> Double {
        var score: Double = 50
        if let temp = healthService.latestWristTemperature {
            let amplitude = abs(temp)
            if amplitude < 0.5 { score += 25 }
            else if amplitude < 1.0 { score += 15 }
            else { score += 5 }
        }
        if healthService.sleepSchedule.wakeHour != nil {
            score += 25
        }
        return min(100, score)
    }

    private func saveDailyScore(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let predicate = #Predicate<DailyLongevityScore> { score in
            score.date >= today
        }
        let descriptor = FetchDescriptor<DailyLongevityScore>(predicate: predicate)

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.compositeScore = compositeScore
            existing.sleepScore = sleepScore
            existing.hrvScore = hrvScore
            existing.restingHRScore = restingHRScore
            existing.vo2MaxScore = vo2MaxScore
            existing.skinScore = skinScore
            existing.adherenceScore = adherenceScore
            existing.activityScore = activityScore
            existing.circadianScore = circadianScore
            existing.stressScore = stressScore
            existing.hydrationScore = hydrationScore
            existing.uvScore = uvScore
            existing.moodValence = moodValence
            existing.skinHealthIndex = skinHealthIndex
        } else {
            let newScore = DailyLongevityScore(
                date: today,
                compositeScore: compositeScore,
                sleepScore: sleepScore,
                hrvScore: hrvScore,
                restingHRScore: restingHRScore,
                vo2MaxScore: vo2MaxScore,
                skinScore: skinScore,
                adherenceScore: adherenceScore,
                activityScore: activityScore,
                circadianScore: circadianScore,
                stressScore: stressScore,
                hydrationScore: hydrationScore,
                uvScore: uvScore,
                moodValence: moodValence,
                skinHealthIndex: skinHealthIndex
            )
            modelContext.insert(newScore)
        }

        try? modelContext.save()
    }

    private func computeTrend(modelContext: ModelContext) {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }

        let predicate = #Predicate<DailyLongevityScore> { score in
            score.date >= weekAgo
        }
        let descriptor = FetchDescriptor<DailyLongevityScore>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        guard let scores = try? modelContext.fetch(descriptor), scores.count >= 2 else {
            trend = 0
            return
        }

        let oldest = scores.first?.compositeScore ?? compositeScore
        trend = compositeScore - oldest
    }

    func scoreForFactor(_ factor: LongevityFactor) -> Double {
        switch factor {
        case .sleep: sleepScore
        case .hrv: hrvScore
        case .skinAnalysis: skinScore
        case .adherence: adherenceScore
        case .activity: activityScore
        case .circadian: circadianScore
        }
    }

    func detailForFactor(_ factor: LongevityFactor) -> String {
        switch factor {
        case .sleep:
            guard sleepHours > 0 else { return "No data" }
            return String(format: "%.1fh · %.0f%% deep · %.0f%% REM", sleepHours, deepSleepPercent, remSleepPercent)
        case .hrv:
            guard hrvValue > 0 else { return "No data" }
            return String(format: "%.0f ms · %.0f BPM resting", hrvValue, restingHR)
        case .skinAnalysis:
            let score = latestSkinScanScore
            guard score > 0 else { return "No scan yet" }
            return "Latest scan: \(score)/100"
        case .adherence:
            let streak = UserDefaults.standard.integer(forKey: "adherenceStreak")
            return "\(streak) day streak"
        case .activity:
            guard vo2Max > 0 || activeCalories > 0 else { return "No data" }
            if vo2Max > 0 && activeCalories > 0 {
                return String(format: "VO₂ %.1f · %.0f kcal", vo2Max, activeCalories)
            } else if vo2Max > 0 {
                return String(format: "VO₂ max: %.1f mL/kg/min", vo2Max)
            }
            return String(format: "%.0f kcal active", activeCalories)
        case .circadian:
            guard wristTemp != 0 else { return "No data" }
            return String(format: "Temp Δ%.1f°C", wristTemp)
        }
    }

    var stressRiskLevel: StressRiskLevel {
        correlationService.stressRiskLevel
    }

    var skinHealthInsights: [SkinCorrelationInsight] {
        correlationService.generateInsights()
    }

    var moodTrendDescription: String {
        guard let valence = healthService.averageMoodValence else { return "No mood data" }
        if valence > 0.3 { return "Positive mood trend" }
        if valence > -0.3 { return "Neutral mood" }
        return "Low mood detected"
    }

    var hydrationDetail: String {
        guard waterIntake > 0 else { return "No data" }
        return String(format: "%.0f mL today", waterIntake)
    }

    var uvDetail: String {
        guard uvExposure > 0 else { return "No data" }
        return String(format: "UV dose: %.1f", uvExposure)
    }
}
