import SwiftUI
import SwiftData

@Observable
final class SkinLongevityViewModel {
    private let healthService = HealthKitService.shared
    private let correlationService = SkinHealthCorrelationService.shared

    var compositeScore: Double? = nil
    var animatedScore: Double = 0
    var trend: Double = 0
    var isLoading: Bool = true
    var selectedPeriod: HistoryPeriod = .thirtyDays
    var lastUpdated: Date? = nil

    var sleepScore: Double? = nil
    var hrvScore: Double? = nil
    var restingHRScore: Double? = nil
    var vo2MaxScore: Double? = nil
    var skinScore: Double? = nil
    var adherenceScore: Double = 0
    var activityScore: Double? = nil
    var circadianScore: Double? = nil
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
    var hasSkinScan: Bool { skinScore != nil }

    var lastUpdatedString: String {
        guard let date = lastUpdated else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Updated just now" }
        if interval < 3600 { return "Updated \(Int(interval / 60))m ago" }
        return "Updated \(Int(interval / 3600))h ago"
    }

    private var refreshTimer: Timer?

    func loadData(modelContext: ModelContext) async {
        isLoading = true

        let authorized = await healthService.requestAuthorization()
        if authorized {
            await healthService.fetchAllData()
        }

        correlationService.computeCorrelation()
        computeScores(modelContext: modelContext)
        saveDailyScore(modelContext: modelContext)
        computeTrend(modelContext: modelContext)

        lastUpdated = Date()
        isLoading = false
    }

    func startAutoRefresh(modelContext: ModelContext) {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refreshData(modelContext: modelContext)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refreshData(modelContext: ModelContext) async {
        await healthService.fetchAllData()
        correlationService.computeCorrelation()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            computeScores(modelContext: modelContext)
            saveDailyScore(modelContext: modelContext)
            computeTrend(modelContext: modelContext)
            lastUpdated = Date()
        }
    }

    func animateScoreIn() {
        withAnimation(.easeOut(duration: 1.4)) {
            animatedScore = compositeScore ?? 0
        }
    }

    private func computeScores(modelContext: ModelContext) {
        sleepScore = computeSleepScore()
        hrvScore = computeHRVScore()
        restingHRScore = computeRestingHRScore()
        vo2MaxScore = computeVO2MaxScore()
        skinScore = computeSkinAnalysisScore(modelContext: modelContext)
        adherenceScore = computeAdherenceScore(modelContext: modelContext)
        activityScore = computeActivityScore()
        circadianScore = computeCircadianScore(modelContext: modelContext)

        stressScore = correlationService.stressScore
        hydrationScore = correlationService.hydrationScore
        uvScore = correlationService.uvScore
        skinHealthIndex = correlationService.overallCorrelationScore
        moodValence = healthService.averageMoodValence ?? 0

        var weightedSum: Double = 0
        var totalWeight: Double = 0

        if hasWatchData {
            if let s = sleepScore {
                weightedSum += s * LongevityFactor.sleep.weight
                totalWeight += LongevityFactor.sleep.weight
            }
            if let h = hrvScore {
                weightedSum += h * LongevityFactor.hrv.weight
                totalWeight += LongevityFactor.hrv.weight
            }
            if let sk = skinScore {
                weightedSum += sk * LongevityFactor.skinAnalysis.weight
                totalWeight += LongevityFactor.skinAnalysis.weight
            }
            weightedSum += adherenceScore * LongevityFactor.adherence.weight
            totalWeight += LongevityFactor.adherence.weight
            if let a = activityScore {
                weightedSum += a * LongevityFactor.activity.weight
                totalWeight += LongevityFactor.activity.weight
            }
            if let c = circadianScore {
                weightedSum += c * LongevityFactor.circadian.weight
                totalWeight += LongevityFactor.circadian.weight
            }
        } else {
            if let sk = skinScore {
                weightedSum += sk * LongevityFactor.skinAnalysis.noWatchWeight
                totalWeight += LongevityFactor.skinAnalysis.noWatchWeight
            }
            weightedSum += adherenceScore * LongevityFactor.adherence.noWatchWeight
            totalWeight += LongevityFactor.adherence.noWatchWeight
        }

        if totalWeight > 0 {
            compositeScore = min(100, max(0, weightedSum))
        } else {
            compositeScore = nil
        }
    }

    private func computeSleepScore() -> Double? {
        guard let hours = healthService.sleepData.totalHours, hours > 0 else { return nil }

        let durationScore: Double
        if hours >= 7 && hours <= 9 {
            durationScore = 90 + min(10, (hours - 7) * 5)
        } else if hours >= 6 {
            durationScore = 60 + (hours - 6) * 30
        } else if hours >= 5 {
            durationScore = 40 + (hours - 5) * 20
        } else {
            durationScore = max(20, hours * 8)
        }

        let deepScore = min(100, deepSleepPercent * 5)
        let remScore = min(100, remSleepPercent * 4)

        return durationScore * 0.30 + deepScore * 0.40 + remScore * 0.30
    }

    private func computeHRVScore() -> Double? {
        guard let hrv = healthService.latestHRV else { return nil }
        if hrv >= 60 { return min(100, 85 + (hrv - 60) * 0.5) }
        if hrv >= 40 { return 55 + (hrv - 40) * 1.5 }
        if hrv >= 20 { return 25 + (hrv - 20) * 1.5 }
        return max(10, hrv * 1.25)
    }

    private func computeRestingHRScore() -> Double? {
        guard let rhr = healthService.latestRestingHR else { return nil }
        if rhr <= 50 { return 95 }
        if rhr <= 60 { return 85 }
        if rhr <= 70 { return 70 }
        if rhr <= 80 { return 55 }
        return max(20, 55 - (rhr - 80) * 2)
    }

    private func computeVO2MaxScore() -> Double? {
        guard let vo2 = healthService.latestVO2Max else { return nil }
        if vo2 >= 50 { return min(100, 90 + (vo2 - 50) * 0.5) }
        if vo2 >= 40 { return 70 + (vo2 - 40) * 2 }
        if vo2 >= 30 { return 50 + (vo2 - 30) * 2 }
        return max(20, 50 - (30 - vo2) * 2)
    }

    private func computeSkinAnalysisScore(modelContext: ModelContext) -> Double? {
        let descriptor = FetchDescriptor<SkinScanRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let latestScan = try? modelContext.fetch(descriptor).first else { return nil }
        let score = latestScan.overallScore
        guard score > 0 else { return nil }
        UserDefaults.standard.set(score, forKey: "latestSkinScore")
        return Double(score)
    }

    private func computeAdherenceScore(modelContext: ModelContext) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        let completedPredicate = #Predicate<SupplementDose> { dose in
            dose.date >= today && dose.date < tomorrow && dose.isCompleted
        }
        let completedDescriptor = FetchDescriptor<SupplementDose>(predicate: completedPredicate)
        let completedCount = (try? modelContext.fetchCount(completedDescriptor)) ?? 0

        let totalDoses = 4
        let baseScore = Double(completedCount) / Double(totalDoses) * 80

        let streak = UserDefaults.standard.integer(forKey: "adherenceStreak")
        let streakBonus: Double
        if streak >= 30 { streakBonus = 15 }
        else if streak >= 14 { streakBonus = 10 }
        else if streak >= 7 { streakBonus = 5 }
        else { streakBonus = 0 }

        return min(100, baseScore + streakBonus)
    }

    private func computeActivityScore() -> Double? {
        let hasVO2 = healthService.latestVO2Max != nil
        let hasCal = healthService.todayActiveCalories != nil
        guard hasVO2 || hasCal else { return nil }

        var score: Double = 0
        var components = 0

        if let vo2 = healthService.latestVO2Max {
            let vo2Score: Double
            if vo2 >= 50 { vo2Score = min(100, 90 + (vo2 - 50) * 0.5) }
            else if vo2 >= 40 { vo2Score = 70 + (vo2 - 40) * 2 }
            else if vo2 >= 30 { vo2Score = 50 + (vo2 - 30) * 2 }
            else { vo2Score = max(20, 50 - (30 - vo2) * 2) }
            score += vo2Score
            components += 1
        }

        if let cal = healthService.todayActiveCalories {
            let target: Double = 300
            let calScore = min(100, (cal / target) * 100)
            score += calScore
            components += 1
        }

        return components > 0 ? score / Double(components) : nil
    }

    private func computeCircadianScore(modelContext: ModelContext) -> Double? {
        var hasAnyData = false
        var score: Double = 0
        var components: Double = 0

        if let temp = healthService.latestWristTemperature {
            hasAnyData = true
            let amplitude = abs(temp)
            let tempScore: Double
            if amplitude < 0.5 { tempScore = 90 }
            else if amplitude < 1.0 { tempScore = 70 }
            else { tempScore = 50 }
            score += tempScore
            components += 1
        }

        if healthService.sleepSchedule.wakeHour != nil {
            hasAnyData = true
            score += 85
            components += 1
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        let completedPredicate = #Predicate<SupplementDose> { dose in
            dose.date >= today && dose.date < tomorrow && dose.isCompleted
        }
        let completedDescriptor = FetchDescriptor<SupplementDose>(predicate: completedPredicate)
        let completedDoses = (try? modelContext.fetch(completedDescriptor)) ?? []

        if !completedDoses.isEmpty {
            hasAnyData = true
            var timingScore: Double = 0
            var doseCount = 0
            for dose in completedDoses {
                if let completed = dose.completedTime {
                    let diff = abs(completed.timeIntervalSince(dose.scheduledTime))
                    let minutesDiff = diff / 60
                    if minutesDiff <= 15 { timingScore += 100 }
                    else if minutesDiff <= 30 { timingScore += 80 }
                    else if minutesDiff <= 60 { timingScore += 60 }
                    else { timingScore += 30 }
                    doseCount += 1
                }
            }
            if doseCount > 0 {
                score += timingScore / Double(doseCount)
                components += 1
            }
        }

        guard hasAnyData, components > 0 else { return nil }
        return min(100, score / components)
    }

    private func saveDailyScore(modelContext: ModelContext) {
        guard let composite = compositeScore else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let predicate = #Predicate<DailyLongevityScore> { score in
            score.date >= today
        }
        let descriptor = FetchDescriptor<DailyLongevityScore>(predicate: predicate)

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.compositeScore = composite
            existing.sleepScore = sleepScore ?? 0
            existing.hrvScore = hrvScore ?? 0
            existing.restingHRScore = restingHRScore ?? 0
            existing.vo2MaxScore = vo2MaxScore ?? 0
            existing.skinScore = skinScore ?? 0
            existing.adherenceScore = adherenceScore
            existing.activityScore = activityScore ?? 0
            existing.circadianScore = circadianScore ?? 0
            existing.stressScore = stressScore
            existing.hydrationScore = hydrationScore
            existing.uvScore = uvScore
            existing.moodValence = moodValence
            existing.skinHealthIndex = skinHealthIndex
        } else {
            let newScore = DailyLongevityScore(
                date: today,
                compositeScore: composite,
                sleepScore: sleepScore ?? 0,
                hrvScore: hrvScore ?? 0,
                restingHRScore: restingHRScore ?? 0,
                vo2MaxScore: vo2MaxScore ?? 0,
                skinScore: skinScore ?? 0,
                adherenceScore: adherenceScore,
                activityScore: activityScore ?? 0,
                circadianScore: circadianScore ?? 0,
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

        let oldest = scores.first?.compositeScore ?? (compositeScore ?? 0)
        trend = (compositeScore ?? 0) - oldest
    }

    func scoreForFactor(_ factor: LongevityFactor) -> Double? {
        switch factor {
        case .sleep: sleepScore
        case .hrv: hrvScore
        case .skinAnalysis: skinScore
        case .adherence: adherenceScore
        case .activity: activityScore
        case .circadian: circadianScore
        }
    }

    func factorHasData(_ factor: LongevityFactor) -> Bool {
        scoreForFactor(factor) != nil
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
            guard let score = skinScore else { return "No scan yet" }
            return "Latest scan: \(Int(score))/100"
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
