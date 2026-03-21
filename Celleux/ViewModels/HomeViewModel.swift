import SwiftUI
import SwiftData
import WidgetKit

@Observable
final class HomeViewModel {
    var skinScore: Double = 0
    var targetScore: Double = 0
    var scoreTrend: Double = 0
    var userName: String = ""
    var narrativeInsight: NarrativeInsight = NarrativeInsight(text: "Loading insights...", icon: "sparkles", priority: 0)

    var lastScanDate: Date?
    var scanCount: Int = 0

    var protocolItems: [ProtocolItem] = []
    var weeklyScores: [DailyScore] = []
    var streakDays: Int = 0
    var uvIndex: Int = 4
    var uvLabel: String = "Moderate"
    var latestAchievement: Achievement? = nil
    var nextAchievement: NextAchievementInfo? = nil
    var newAchievementUnlocked: Bool = false
    var isRefreshing: Bool = false
    var refreshTrigger: Bool = false

    var sleepScore: Double = 0
    var hrvScore: Double = 0
    var skinAnalysisScore: Double = 0
    var adherenceScore: Double = 0
    var activityScore: Double = 0
    var circadianScore: Double = 0

    var longevityHistoryScores: [DailyLongevityScore] = []

    var selectedWeeklyScore: DailyScore? = nil
    var protocolCompletionTrigger: Bool = false

    private let healthService = HealthKitService.shared
    private let correlationService = SkinHealthCorrelationService.shared

    var completedCount: Int {
        protocolItems.filter(\.isCompleted).count
    }

    var totalCount: Int {
        protocolItems.count
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    var hasData: Bool {
        targetScore > 0
    }

    var isScanOverdue: Bool {
        guard let lastScan = lastScanDate else { return false }
        return Date().timeIntervalSince(lastScan) > 86400
    }

    var lastScanRelativeString: String {
        guard let lastScan = lastScanDate else { return "" }
        let interval = Date().timeIntervalSince(lastScan)
        if interval < 60 { return "Scanned just now" }
        if interval < 3600 { return "Scanned \(Int(interval / 60))m ago" }
        if interval < 86400 { return "Scanned \(Int(interval / 3600))h ago" }
        let days = Int(interval / 86400)
        return "Scanned \(days)d ago"
    }

    var hasWatchData: Bool {
        healthService.hasWatchData
    }

    var nextDoseItem: ProtocolItem? {
        let now = Date()
        return protocolItems.first { !$0.isCompleted && ($0.scheduledDate ?? now) >= now }
    }

    var nextDoseCountdownString: String? {
        guard let next = nextDoseItem, let scheduled = next.scheduledDate else { return nil }
        let interval = scheduled.timeIntervalSince(Date())
        guard interval > 0 else { return nil }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "Next in \(hours)h \(minutes)m"
        }
        return "Next in \(minutes)m"
    }

    var hasHealthSnapshotData: Bool {
        healthService.sleepData.totalHours != nil ||
        healthService.latestHRV != nil ||
        healthService.todayWaterIntake != nil
    }

    var sleepValueString: String? {
        guard let hours = healthService.sleepData.totalHours, hours > 0 else { return nil }
        return String(format: "%.1fh", hours)
    }

    var sleepDetailString: String? {
        guard let total = healthService.sleepData.totalMinutes, total > 0 else { return nil }
        let deep = healthService.sleepData.deepMinutes ?? 0
        let pct = Int((deep / total) * 100)
        return "\(pct)% deep sleep"
    }

    var hrvValueString: String? {
        guard let hrv = healthService.latestHRV else { return nil }
        return String(format: "%.0f ms", hrv)
    }

    var hrvDetailString: String? {
        guard let rhr = healthService.latestRestingHR else { return nil }
        return String(format: "%.0f BPM resting", rhr)
    }

    var hydrationValueString: String? {
        guard let water = healthService.todayWaterIntake, water > 0 else { return nil }
        if water >= 1000 {
            return String(format: "%.1fL", water / 1000)
        }
        return String(format: "%.0f mL", water)
    }

    var hydrationDetailString: String? {
        guard let water = healthService.todayWaterIntake, water > 0 else { return nil }
        let goal: Double = 2500
        let pct = Int((water / goal) * 100)
        return "\(min(pct, 100))% of daily goal"
    }

    var sleepSparkline: [Double] {
        longevityHistoryScores.suffix(7).map { $0.sleepScore }
    }

    var hrvSparkline: [Double] {
        longevityHistoryScores.suffix(7).map { $0.hrvScore }
    }

    var hydrationSparkline: [Double] {
        longevityHistoryScores.suffix(7).map { $0.hydrationScore }
    }

    func scoreForFactor(_ factor: LongevityFactor) -> Double {
        switch factor {
        case .sleep: sleepScore
        case .hrv: hrvScore
        case .skinAnalysis: skinAnalysisScore
        case .adherence: adherenceScore
        case .activity: activityScore
        case .circadian: circadianScore
        }
    }

    func factorHasData(_ factor: LongevityFactor) -> Bool {
        if factor.requiresWatch && !hasWatchData { return false }
        return scoreForFactor(factor) > 0
    }

    func detailForFactor(_ factor: LongevityFactor) -> String {
        switch factor {
        case .sleep:
            guard let hours = healthService.sleepData.totalHours, hours > 0 else { return "No data" }
            let total = healthService.sleepData.totalMinutes ?? 0
            let deep = healthService.sleepData.deepMinutes ?? 0
            let deepPct = total > 0 ? (deep / total) * 100 : 0
            return String(format: "%.1fh · %.0f%% deep", hours, deepPct)
        case .hrv:
            guard let hrv = healthService.latestHRV else { return "No data" }
            if let rhr = healthService.latestRestingHR {
                return String(format: "%.0f ms · %.0f BPM", hrv, rhr)
            }
            return String(format: "%.0f ms", hrv)
        case .skinAnalysis:
            guard skinAnalysisScore > 0 else { return "No scan yet" }
            return "Latest: \(Int(skinAnalysisScore))/100"
        case .adherence:
            return "\(streakDays) day streak"
        case .activity:
            let vo2 = healthService.latestVO2Max ?? 0
            let cal = healthService.todayActiveCalories ?? 0
            guard vo2 > 0 || cal > 0 else { return "No data" }
            if vo2 > 0 && cal > 0 {
                return String(format: "VO₂ %.1f · %.0f kcal", vo2, cal)
            } else if vo2 > 0 {
                return String(format: "VO₂ max: %.1f", vo2)
            }
            return String(format: "%.0f kcal active", cal)
        case .circadian:
            guard let temp = healthService.latestWristTemperature else { return "No data" }
            return String(format: "Temp Δ%.1f°C", temp)
        }
    }

    func historicalScoresForFactor(_ factor: LongevityFactor) -> [(date: Date, score: Double)] {
        longevityHistoryScores.suffix(7).map { entry in
            let score: Double = switch factor {
            case .sleep: entry.sleepScore
            case .hrv: entry.hrvScore
            case .skinAnalysis: entry.skinScore
            case .adherence: entry.adherenceScore
            case .activity: entry.activityScore
            case .circadian: entry.circadianScore
            }
            return (date: entry.date, score: score)
        }
    }

    func loadData(modelContext: ModelContext) {
        loadUserName(modelContext: modelContext)
        loadSkinScore(modelContext: modelContext)
        loadProtocol(modelContext: modelContext)
        loadWeeklyScores(modelContext: modelContext)
        loadStreak()
        loadLatestAchievement(modelContext: modelContext)
        loadLongevityFactors(modelContext: modelContext)
        loadLongevityHistory(modelContext: modelContext)
        loadNarrativeInsight(modelContext: modelContext)
        updateWidgetData(modelContext: modelContext)
    }

    private func updateWidgetData(modelContext: ModelContext) {
        let trendString: String
        if scoreTrend > 1 {
            trendString = "up"
        } else if scoreTrend < -1 {
            trendString = "down"
        } else {
            trendString = "stable"
        }

        let scanDesc = FetchDescriptor<SkinScanRecord>(sortBy: [SortDescriptor(\SkinScanRecord.date, order: .reverse)])
        let latest = try? modelContext.fetch(scanDesc).first

        WidgetDataService.shared.writeAllData(
            score: Int(targetScore),
            trend: trendString,
            lastScanDate: lastScanDate,
            textureScore: Int(latest?.textureEvennessScore.rounded() ?? 0),
            hydrationScore: Int(latest?.apparentHydrationScore.rounded() ?? 0),
            radianceScore: Int(latest?.brightnessRadianceScore.rounded() ?? 0)
        )
    }

    private func loadUserName(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            userName = profile.name.isEmpty ? "there" : profile.name
        } else {
            userName = "there"
        }
    }

    private func loadSkinScore(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let predicate = #Predicate<DailyLongevityScore> { score in
            score.date >= today
        }
        let descriptor = FetchDescriptor<DailyLongevityScore>(predicate: predicate)
        if let todayScore = try? modelContext.fetch(descriptor).first {
            targetScore = todayScore.compositeScore
        } else {
            let scanDescriptor = FetchDescriptor<SkinScanRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            if let latestScan = try? modelContext.fetch(scanDescriptor).first {
                targetScore = Double(latestScan.overallScore) * 0.55 + computeAdherenceScoreValue() * 0.45
            }
        }

        let scanDescriptor = FetchDescriptor<SkinScanRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let allScans = (try? modelContext.fetch(scanDescriptor)) ?? []
        scanCount = allScans.count
        lastScanDate = allScans.first?.date

        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        if allScans.count >= 3 {
            let recentScores = allScans.prefix(3).map { Double($0.overallScore) }
            let olderScans = allScans.dropFirst(3)
            if let olderFirst = olderScans.first {
                let recentAvg = recentScores.reduce(0, +) / Double(recentScores.count)
                scoreTrend = recentAvg - Double(olderFirst.overallScore)
            }
        } else {
            let weekPredicate = #Predicate<DailyLongevityScore> { score in
                score.date >= weekAgo
            }
            let weekDescriptor = FetchDescriptor<DailyLongevityScore>(predicate: weekPredicate, sortBy: [SortDescriptor(\.date)])
            if let scores = try? modelContext.fetch(weekDescriptor), scores.count >= 2 {
                let oldest = scores.first?.compositeScore ?? targetScore
                scoreTrend = targetScore - oldest
            }
        }
    }

    private func computeAdherenceScoreValue() -> Double {
        let streak = UserDefaults.standard.integer(forKey: "adherenceStreak")
        if streak >= 30 { return 95 }
        if streak >= 14 { return 80 }
        if streak >= 7 { return 60 }
        return max(20, Double(streak) * 8.5)
    }

    private func loadLongevityFactors(modelContext: ModelContext) {
        let latestSkinScore = UserDefaults.standard.integer(forKey: "latestSkinScore")
        skinAnalysisScore = latestSkinScore > 0 ? Double(latestSkinScore) : 0

        adherenceScore = computeAdherenceScoreValue()

        if let hours = healthService.sleepData.totalHours, hours > 0 {
            let total = healthService.sleepData.totalMinutes ?? 0
            let deep = healthService.sleepData.deepMinutes ?? 0
            let rem = healthService.sleepData.remMinutes ?? 0
            let hoursComp = min(1.0, hours / 8.0) * 0.3
            let deepComp = total > 0 ? min(1.0, (deep / total * 100) / 20.0) * 0.4 : 0
            let remComp = total > 0 ? min(1.0, (rem / total * 100) / 25.0) * 0.3 : 0
            sleepScore = (hoursComp + deepComp + remComp) * 100
        } else {
            sleepScore = 0
        }

        if let hrv = healthService.latestHRV {
            hrvScore = min(100, max(0, (hrv / 80.0) * 100))
        } else {
            hrvScore = 0
        }

        if let vo2 = healthService.latestVO2Max, let cal = healthService.todayActiveCalories {
            let vo2Comp: Double
            if vo2 >= 50 { vo2Comp = min(100, 90 + (vo2 - 50) * 0.5) }
            else if vo2 >= 40 { vo2Comp = 70 + (vo2 - 40) * 2 }
            else if vo2 >= 30 { vo2Comp = 50 + (vo2 - 30) * 2 }
            else { vo2Comp = max(20, 50 - (30 - vo2) * 2) }
            let calComp = min(100, (cal / 500) * 100)
            activityScore = vo2Comp * 0.5 + calComp * 0.5
        } else if let cal = healthService.todayActiveCalories {
            activityScore = min(100, (cal / 500) * 100)
        } else {
            activityScore = 0
        }

        var circScore: Double = 0
        if let temp = healthService.latestWristTemperature {
            let amplitude = abs(temp)
            if amplitude < 0.5 { circScore = 75 }
            else if amplitude < 1.0 { circScore = 65 }
            else { circScore = 55 }
        }
        if healthService.sleepSchedule.wakeHour != nil {
            circScore += 25
        }
        circadianScore = circScore > 0 ? min(100, circScore) : 0
    }

    private func loadLongevityHistory(modelContext: ModelContext) {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        let predicate = #Predicate<DailyLongevityScore> { score in
            score.date >= weekAgo
        }
        let descriptor = FetchDescriptor<DailyLongevityScore>(predicate: predicate, sortBy: [SortDescriptor(\.date)])
        longevityHistoryScores = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func loadNarrativeInsight(modelContext: ModelContext) {
        let latestSkinScore = UserDefaults.standard.integer(forKey: "latestSkinScore")
        correlationService.computeCorrelation()
        narrativeInsight = correlationService.generateNarrativeInsight(
            latestSkinScore: latestSkinScore,
            hasScanData: scanCount > 0
        )
    }

    private func loadProtocol(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        let predicate = #Predicate<SupplementDose> { dose in
            dose.date >= today && dose.date < tomorrow && dose.isCompleted
        }
        let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)
        let completedCategories = Set((try? modelContext.fetch(descriptor))?.map(\.category) ?? [])

        let schedule = healthService.sleepSchedule
        let wakeH = schedule.wakeHour ?? 7
        let wakeM = schedule.wakeMinute ?? 0
        let sleepH = schedule.sleepHour ?? 23

        let morningH = wakeH
        let morningM = wakeM + 30
        let eveningMinutes = max(0, sleepH * 60 - 90)
        let morningDate = calendar.date(byAdding: DateComponents(hour: morningH, minute: morningM % 60), to: today)
        let middayDate = calendar.date(byAdding: DateComponents(hour: 12, minute: 30), to: today)
        let eveningDate = calendar.date(byAdding: DateComponents(hour: eveningMinutes / 60, minute: eveningMinutes % 60), to: today)

        protocolItems = [
            ProtocolItem(
                time: String(format: "%d:%02d AM", morningH > 12 ? morningH - 12 : (morningH == 0 ? 12 : morningH), morningM % 60),
                title: "AeonDerm + Vitamin C boost",
                icon: "sunrise.fill",
                period: "Morning",
                isCompleted: completedCategories.contains("morning"),
                category: "morning",
                scheduledDate: morningDate
            ),
            ProtocolItem(
                time: "12:30 PM",
                title: "Hydration reminder",
                icon: "drop.fill",
                period: "Afternoon",
                isCompleted: completedCategories.contains("midday"),
                category: "midday",
                scheduledDate: middayDate
            ),
            ProtocolItem(
                time: String(format: "%d:%02d PM", eveningMinutes / 60 > 12 ? eveningMinutes / 60 - 12 : eveningMinutes / 60, eveningMinutes % 60),
                title: "AeonDerm collagen dose",
                icon: "moon.stars.fill",
                period: "Evening",
                isCompleted: completedCategories.contains("evening"),
                category: "evening",
                scheduledDate: eveningDate
            )
        ]
    }

    private func loadWeeklyScores(modelContext: ModelContext) {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }

        let scanPredicate = #Predicate<SkinScanRecord> { scan in
            scan.date >= weekAgo
        }
        let scanDescriptor = FetchDescriptor<SkinScanRecord>(predicate: scanPredicate, sortBy: [SortDescriptor(\.date)])
        let scans = (try? modelContext.fetch(scanDescriptor)) ?? []

        if scans.isEmpty {
            weeklyScores = []
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        weeklyScores = scans.map { scan in
            DailyScore(day: formatter.string(from: scan.date), score: Double(scan.overallScore), date: scan.date)
        }
    }

    var streakMilestone: StreakMilestone {
        StreakMilestone.current(for: streakDays)
    }

    private func loadStreak() {
        streakDays = UserDefaults.standard.integer(forKey: "adherenceStreak")
    }

    private func loadLatestAchievement(modelContext: ModelContext) {
        AchievementEngine.shared.checkAll(modelContext: modelContext)

        let predicate = #Predicate<AchievementRecord> { record in
            record.unlockedAt != nil
        }
        let descriptor = FetchDescriptor<AchievementRecord>(predicate: predicate, sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)])

        if let record = try? modelContext.fetch(descriptor).first,
           let def = AchievementDefinition(rawValue: record.identifier) {
            latestAchievement = Achievement(title: def.title, subtitle: def.subtitle, icon: def.icon)
        } else {
            latestAchievement = nil
        }

        loadNextAchievement(modelContext: modelContext)
    }

    private func loadNextAchievement(modelContext: ModelContext) {
        let allRecords = (try? modelContext.fetch(FetchDescriptor<AchievementRecord>())) ?? []
        let unlockedIds = Set(allRecords.filter { $0.isUnlocked }.map { $0.identifier })
        let engine = AchievementEngine.shared

        let locked = AchievementDefinition.allCases.filter { !unlockedIds.contains($0.rawValue) }

        var best: (def: AchievementDefinition, progress: Double)? = nil
        for def in locked {
            let progress = engine.progress(for: def, modelContext: modelContext)
            if let current = best {
                if progress > current.progress {
                    best = (def, progress)
                }
            } else {
                best = (def, progress)
            }
        }

        if let best {
            nextAchievement = NextAchievementInfo(
                title: best.def.title,
                subtitle: best.def.subtitle,
                icon: best.def.icon,
                progress: min(best.progress, 0.99)
            )
        } else {
            nextAchievement = nil
        }
    }

    func refreshAll(modelContext: ModelContext) async {
        isRefreshing = true
        refreshTrigger.toggle()
        await healthService.fetchAllData()
        loadData(modelContext: modelContext)
        try? await Task.sleep(for: .milliseconds(600))
        isRefreshing = false
    }

    func toggleProtocolItem(_ item: ProtocolItem, modelContext: ModelContext) {
        guard let index = protocolItems.firstIndex(where: { $0.id == item.id }) else { return }
        protocolItems[index].isCompleted.toggle()

        let today = Calendar.current.startOfDay(for: Date())
        let category = item.category

        if protocolItems[index].isCompleted {
            let dose = SupplementDose(
                date: today,
                name: item.title,
                scheduledTime: Date(),
                completedTime: Date(),
                isCompleted: true,
                category: category
            )
            modelContext.insert(dose)
        } else {
            let predicate = #Predicate<SupplementDose> { dose in
                dose.date >= today && dose.category == category
            }
            let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)
            if let doses = try? modelContext.fetch(descriptor) {
                for dose in doses { modelContext.delete(dose) }
            }
        }

        updateStreak(modelContext: modelContext)
        try? modelContext.save()
    }

    private func updateStreak(modelContext: ModelContext) {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for _ in 0..<365 {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? checkDate
            let currentDate = checkDate
            let predicate = #Predicate<SupplementDose> { dose in
                dose.date >= currentDate && dose.date < nextDay && dose.isCompleted
            }
            let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)
            guard let count = try? modelContext.fetchCount(descriptor), count > 0 else { break }
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        streakDays = streak
        UserDefaults.standard.set(streak, forKey: "adherenceStreak")
    }

    func animateScore() {
        skinScore = targetScore
    }
}

struct ProtocolItem: Identifiable {
    let id = UUID()
    let time: String
    let title: String
    let icon: String
    let period: String
    var isCompleted: Bool
    var category: String = ""
    var scheduledDate: Date? = nil
}

struct DailyScore: Identifiable {
    let id = UUID()
    let day: String
    let score: Double
    var date: Date = Date()
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

struct NextAchievementInfo: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let progress: Double
}

struct StreakMilestone {
    let current: Int
    let next: Int
    let progress: Double
    let daysRemaining: Int

    static let milestones = [7, 14, 30, 60, 90, 180, 365]

    static func current(for days: Int) -> StreakMilestone {
        let next = milestones.first(where: { $0 > days }) ?? (milestones.last! + 1)
        let prev = milestones.last(where: { $0 <= days }) ?? 0
        let progress = next > prev ? Double(days - prev) / Double(next - prev) : 1.0
        return StreakMilestone(current: days, next: next, progress: progress, daysRemaining: next - days)
    }
}
