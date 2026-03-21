import SwiftUI
import SwiftData

@Observable
final class AchievementEngine {
    static let shared = AchievementEngine()

    var unlockQueue: [AchievementDefinition] = []
    var currentUnlock: AchievementDefinition? = nil
    var showingUnlock: Bool = false

    private var isProcessing: Bool = false

    func checkAll(modelContext: ModelContext) {
        let allRecords = (try? modelContext.fetch(FetchDescriptor<AchievementRecord>())) ?? []
        let unlockedIds = Set(allRecords.filter { $0.isUnlocked }.map { $0.identifier })
        let recordMap = Dictionary(uniqueKeysWithValues: allRecords.map { ($0.identifier, $0) })

        let scanDescriptor = FetchDescriptor<SkinScanRecord>()
        let totalScans = (try? modelContext.fetchCount(scanDescriptor)) ?? 0

        let streakDays = UserDefaults.standard.integer(forKey: "adherenceStreak")
        let shareCount = UserDefaults.standard.integer(forKey: "shareCount")
        let healthConnected = UserDefaults.standard.bool(forKey: "healthKitConnected")
        let sleepTrackingDays = UserDefaults.standard.integer(forKey: "sleepTrackingDays")
        let hrvTrackingDays = UserDefaults.standard.integer(forKey: "hrvTrackingDays")

        let scanDesc = FetchDescriptor<SkinScanRecord>(sortBy: [SortDescriptor(\SkinScanRecord.date, order: .reverse)])
        let allScans = (try? modelContext.fetch(scanDesc)) ?? []
        let latestScore = allScans.first.map { Double($0.overallScore) } ?? 0
        let bestScore = allScans.map { Double($0.overallScore) }.max() ?? 0
        let isNewPersonalBest = allScans.count >= 2 && Double(allScans[0].overallScore) >= bestScore

        let latestScan = allScans.first
        let allMetricsAbove80 = latestScan.map { scan in
            scan.textureEvennessScore >= 80 &&
            scan.apparentHydrationScore >= 80 &&
            scan.brightnessRadianceScore >= 80 &&
            scan.toneUniformityScore >= 80 &&
            scan.underEyeQualityScore >= 80 &&
            scan.elasticityProxyScore >= 80
        } ?? false

        let ritualDayComplete = checkRitualDay(modelContext: modelContext)
        let ritualWeekComplete = checkRitualStreak(modelContext: modelContext, days: 7)
        let ritualMonthComplete = checkRitualStreak(modelContext: modelContext, days: 30)

        let context = AchievementContext(
            scanCount: totalScans,
            streakDays: streakDays,
            latestScore: latestScore,
            bestScore: bestScore,
            isNewPersonalBest: isNewPersonalBest,
            allMetricsAbove80: allMetricsAbove80,
            healthConnected: healthConnected,
            sleepTrackingDays: sleepTrackingDays,
            hrvTrackingDays: hrvTrackingDays,
            ritualDayComplete: ritualDayComplete,
            ritualWeekComplete: ritualWeekComplete,
            ritualMonthComplete: ritualMonthComplete,
            shareCount: shareCount
        )

        var newlyUnlocked: [AchievementDefinition] = []

        for def in AchievementDefinition.allCases {
            guard !unlockedIds.contains(def.rawValue) else { continue }
            guard isConditionMet(def, context: context) else { continue }

            if let existing = recordMap[def.rawValue] {
                existing.unlockedAt = Date()
            } else {
                let record = AchievementRecord(identifier: def.rawValue, unlockedAt: Date())
                modelContext.insert(record)
            }
            newlyUnlocked.append(def)
        }

        if !newlyUnlocked.isEmpty {
            try? modelContext.save()
            unlockQueue.append(contentsOf: newlyUnlocked)
            processQueue()
        }
    }

    func recordShare() {
        let current = UserDefaults.standard.integer(forKey: "shareCount")
        UserDefaults.standard.set(current + 1, forKey: "shareCount")
    }

    func dismissCurrent() {
        withAnimation(CelleuxSpring.snappy) {
            showingUnlock = false
            currentUnlock = nil
        }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            processQueue()
        }
    }

    private func processQueue() {
        guard !isProcessing, !unlockQueue.isEmpty else { return }
        isProcessing = true

        let next = unlockQueue.removeFirst()
        currentUnlock = next

        withAnimation(CelleuxSpring.bouncy) {
            showingUnlock = true
        }

        isProcessing = false

        Task {
            try? await Task.sleep(for: .seconds(3))
            if currentUnlock == next {
                dismissCurrent()
            }
        }
    }

    func progress(for def: AchievementDefinition, modelContext: ModelContext) -> Double {
        let scanDescriptor = FetchDescriptor<SkinScanRecord>()
        let totalScans = (try? modelContext.fetchCount(scanDescriptor)) ?? 0
        let streakDays = UserDefaults.standard.integer(forKey: "adherenceStreak")
        let shareCount = UserDefaults.standard.integer(forKey: "shareCount")
        let sleepTrackingDays = UserDefaults.standard.integer(forKey: "sleepTrackingDays")
        let hrvTrackingDays = UserDefaults.standard.integer(forKey: "hrvTrackingDays")

        let scanDesc = FetchDescriptor<SkinScanRecord>(sortBy: [SortDescriptor(\SkinScanRecord.date, order: .reverse)])
        let latestScore = (try? modelContext.fetch(scanDesc).first).map { Double($0.overallScore) } ?? 0

        switch def {
        case .firstScan: return min(1.0, Double(totalScans) / 1.0)
        case .scanTen: return min(1.0, Double(totalScans) / 10.0)
        case .scanFifty: return min(1.0, Double(totalScans) / 50.0)
        case .scanHundred: return min(1.0, Double(totalScans) / 100.0)
        case .scanYear: return min(1.0, Double(totalScans) / 365.0)
        case .streak3: return min(1.0, Double(streakDays) / 3.0)
        case .consistent: return min(1.0, Double(streakDays) / 7.0)
        case .streak14: return min(1.0, Double(streakDays) / 14.0)
        case .committed: return min(1.0, Double(streakDays) / 30.0)
        case .streak60: return min(1.0, Double(streakDays) / 60.0)
        case .dedicated: return min(1.0, Double(streakDays) / 90.0)
        case .personalBest: return totalScans >= 2 ? 0.5 : Double(totalScans) * 0.25
        case .radiant: return min(1.0, latestScore / 80.0)
        case .elite: return min(1.0, latestScore / 90.0)
        case .perfectMetrics: return min(1.0, latestScore / 80.0) * 0.8
        case .healthConnected: return UserDefaults.standard.bool(forKey: "healthKitConnected") ? 1.0 : 0.0
        case .sleepTracker: return min(1.0, Double(sleepTrackingDays) / 7.0)
        case .hrvMaster: return min(1.0, Double(hrvTrackingDays) / 30.0)
        case .ritualDay: return Double(streakDays > 0 ? 1 : 0)
        case .ritualWeek: return min(1.0, Double(streakDays) / 7.0)
        case .ritualMonth: return min(1.0, Double(streakDays) / 30.0)
        case .firstShare: return min(1.0, Double(shareCount))
        case .socialButterfly: return min(1.0, Double(shareCount) / 10.0)
        }
    }

    func totalPoints(modelContext: ModelContext) -> Int {
        let allRecords = (try? modelContext.fetch(FetchDescriptor<AchievementRecord>())) ?? []
        let unlockedIds = Set(allRecords.filter { $0.isUnlocked }.map { $0.identifier })
        return AchievementDefinition.allCases
            .filter { unlockedIds.contains($0.rawValue) }
            .reduce(0) { $0 + $1.points }
    }

    private func isConditionMet(_ def: AchievementDefinition, context: AchievementContext) -> Bool {
        switch def {
        case .firstScan: return context.scanCount >= 1
        case .scanTen: return context.scanCount >= 10
        case .scanFifty: return context.scanCount >= 50
        case .scanHundred: return context.scanCount >= 100
        case .scanYear: return context.scanCount >= 365
        case .streak3: return context.streakDays >= 3
        case .consistent: return context.streakDays >= 7
        case .streak14: return context.streakDays >= 14
        case .committed: return context.streakDays >= 30
        case .streak60: return context.streakDays >= 60
        case .dedicated: return context.streakDays >= 90
        case .personalBest: return context.isNewPersonalBest && context.scanCount >= 2
        case .radiant: return context.latestScore >= 80
        case .elite: return context.latestScore >= 90
        case .perfectMetrics: return context.allMetricsAbove80
        case .healthConnected: return context.healthConnected
        case .sleepTracker: return context.sleepTrackingDays >= 7
        case .hrvMaster: return context.hrvTrackingDays >= 30
        case .ritualDay: return context.ritualDayComplete
        case .ritualWeek: return context.ritualWeekComplete
        case .ritualMonth: return context.ritualMonthComplete
        case .firstShare: return context.shareCount >= 1
        case .socialButterfly: return context.shareCount >= 10
        }
    }

    private func checkRitualDay(modelContext: ModelContext) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let predicate = #Predicate<SupplementDose> { dose in
            dose.date >= today && dose.date < tomorrow && dose.isCompleted
        }
        let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count >= 3
    }

    private func checkRitualStreak(modelContext: ModelContext, days: Int) -> Bool {
        let calendar = Calendar.current
        for offset in 0..<days {
            guard let dayStart = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date())),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return false }
            let start = dayStart
            let end = dayEnd
            let predicate = #Predicate<SupplementDose> { dose in
                dose.date >= start && dose.date < end && dose.isCompleted
            }
            let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)
            let count = (try? modelContext.fetchCount(descriptor)) ?? 0
            if count < 3 { return false }
        }
        return true
    }
}

private struct AchievementContext {
    let scanCount: Int
    let streakDays: Int
    let latestScore: Double
    let bestScore: Double
    let isNewPersonalBest: Bool
    let allMetricsAbove80: Bool
    let healthConnected: Bool
    let sleepTrackingDays: Int
    let hrvTrackingDays: Int
    let ritualDayComplete: Bool
    let ritualWeekComplete: Bool
    let ritualMonthComplete: Bool
    let shareCount: Int
}
