import SwiftUI
import SwiftData

nonisolated enum XPAction: String, Sendable {
    case scanCompleted
    case doseLogged
    case moodLogged
    case waterLogged
    case breathingCompleted
    case dailyAllDosesComplete
    case streakMilestone
    case personalBest
    case challengeCheckIn

    var points: Int {
        switch self {
        case .scanCompleted: 50
        case .doseLogged: 15
        case .moodLogged: 10
        case .waterLogged: 5
        case .breathingCompleted: 20
        case .dailyAllDosesComplete: 40
        case .streakMilestone: 100
        case .personalBest: 75
        case .challengeCheckIn: 25
        }
    }

    var label: String {
        switch self {
        case .scanCompleted: "Scan completed"
        case .doseLogged: "Supplement logged"
        case .moodLogged: "Mood logged"
        case .waterLogged: "Hydration logged"
        case .breathingCompleted: "Mindful minute"
        case .dailyAllDosesComplete: "Ritual complete"
        case .streakMilestone: "Streak milestone"
        case .personalBest: "New personal best"
        case .challengeCheckIn: "Challenge check-in"
        }
    }
}

nonisolated struct CelleuxLevel: Sendable {
    let level: Int
    let title: String
    let currentXP: Int
    let nextLevelXP: Int
    let totalXP: Int

    var progress: Double {
        let range = Double(nextLevelXP - previousLevelXP)
        guard range > 0 else { return 1 }
        return Double(currentXP - previousLevelXP) / range
    }

    var previousLevelXP: Int {
        CelleuxLevel.thresholds[max(0, level - 1)]
    }

    static let thresholds: [Int] = [0, 100, 250, 500, 900, 1500, 2300, 3300, 4500, 6000, 8000, 10500, 13500, 17000, 21000, 26000, 32000, 40000, 50000, 62000]

    static let titles: [String] = [
        "Seed", "Bloom", "Glow Novice", "Glow Adept", "Glow Keeper",
        "Radiance Keeper", "Luminous", "Ageless", "Longevity Sage", "Cellular Master",
        "Celestial", "Alchemist", "Dawn Bearer", "Phoenix", "Eternal",
        "Celleux Luminary", "Platinum", "Diamond", "Legend", "Immortal"
    ]

    static func forTotalXP(_ total: Int) -> CelleuxLevel {
        var level = 1
        for (idx, threshold) in thresholds.enumerated() {
            if total >= threshold { level = idx + 1 } else { break }
        }
        let nextIdx = min(level, thresholds.count - 1)
        let next = thresholds[nextIdx] == thresholds[level - 1]
            ? thresholds[level - 1] + 10000
            : thresholds[nextIdx]
        let titleIdx = min(level - 1, titles.count - 1)
        return CelleuxLevel(
            level: level,
            title: titles[titleIdx],
            currentXP: total,
            nextLevelXP: next,
            totalXP: total
        )
    }
}

nonisolated struct DailyQuest: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let xp: Int
    let progress: Double
    let isComplete: Bool
}

@Observable
final class GamificationEngine {
    static let shared = GamificationEngine()

    var totalXP: Int = UserDefaults.standard.integer(forKey: "celleuxTotalXP")
    var recentGain: Int = 0
    var showXPGain: Bool = false
    var lastAction: XPAction? = nil
    var lastLevelUp: Int? = nil
    var showLevelUp: Bool = false

    var level: CelleuxLevel {
        CelleuxLevel.forTotalXP(totalXP)
    }

    private init() {}

    func award(_ action: XPAction, multiplier: Double = 1.0) {
        let prevLevel = level.level
        let gain = Int(Double(action.points) * multiplier)
        totalXP += gain
        UserDefaults.standard.set(totalXP, forKey: "celleuxTotalXP")

        recentGain = gain
        lastAction = action
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showXPGain = true
        }

        let newLevel = level.level
        if newLevel > prevLevel {
            lastLevelUp = newLevel
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.5)) {
                showLevelUp = true
            }
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.3)) {
                showXPGain = false
            }
        }
    }

    func dismissLevelUp() {
        withAnimation(.easeOut(duration: 0.3)) {
            showLevelUp = false
        }
    }

    func todayQuests(modelContext: ModelContext) -> [DailyQuest] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        let dosePredicate = #Predicate<SupplementDose> { dose in
            dose.date >= today && dose.date < tomorrow && dose.isCompleted
        }
        let completedDoses = (try? modelContext.fetchCount(FetchDescriptor<SupplementDose>(predicate: dosePredicate))) ?? 0

        let scanPredicate = #Predicate<SkinScanRecord> { scan in
            scan.date >= today
        }
        let scansToday = (try? modelContext.fetchCount(FetchDescriptor<SkinScanRecord>(predicate: scanPredicate))) ?? 0

        let checkInPredicate = #Predicate<DailyCheckIn> { entry in
            entry.date >= today
        }
        let checkInsToday = (try? modelContext.fetchCount(FetchDescriptor<DailyCheckIn>(predicate: checkInPredicate))) ?? 0

        let water = HealthKitService.shared.todayWaterIntake ?? 0
        let waterGoal: Double = 2500
        let waterProgress = min(1.0, water / waterGoal)

        return [
            DailyQuest(
                id: "scan",
                title: "Scan your skin",
                subtitle: scansToday > 0 ? "Done" : "Capture today's baseline",
                icon: "viewfinder",
                xp: XPAction.scanCompleted.points,
                progress: scansToday > 0 ? 1.0 : 0.0,
                isComplete: scansToday > 0
            ),
            DailyQuest(
                id: "ritual",
                title: "Complete all 3 doses",
                subtitle: "\(completedDoses)/3 logged",
                icon: "pill.fill",
                xp: XPAction.dailyAllDosesComplete.points,
                progress: Double(completedDoses) / 3.0,
                isComplete: completedDoses >= 3
            ),
            DailyQuest(
                id: "hydrate",
                title: "Drink 2.5L water",
                subtitle: String(format: "%.1fL / 2.5L", water / 1000),
                icon: "drop.fill",
                xp: XPAction.waterLogged.points * 5,
                progress: waterProgress,
                isComplete: waterProgress >= 1.0
            ),
            DailyQuest(
                id: "mood",
                title: "Log your mood",
                subtitle: checkInsToday > 0 ? "Done" : "30 seconds",
                icon: "face.smiling",
                xp: XPAction.moodLogged.points,
                progress: checkInsToday > 0 ? 1.0 : 0.0,
                isComplete: checkInsToday > 0
            ),
        ]
    }

    func completedQuestCount(modelContext: ModelContext) -> Int {
        todayQuests(modelContext: modelContext).filter(\.isComplete).count
    }
}
