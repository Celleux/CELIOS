import SwiftUI
import SwiftData

@Observable
final class HomeViewModel {
    var skinScore: Double = 0
    var targetScore: Double = 0
    var scoreTrend: Double = 0
    var userName: String = ""

    var protocolItems: [ProtocolItem] = []

    var weeklyScores: [DailyScore] = []

    var streakDays: Int = 0
    var uvIndex: Int = 4
    var uvLabel: String = "Moderate"

    var latestAchievement: Achievement? = nil

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

    func loadData(modelContext: ModelContext) {
        loadUserName(modelContext: modelContext)
        loadSkinScore(modelContext: modelContext)
        loadProtocol(modelContext: modelContext)
        loadWeeklyScores(modelContext: modelContext)
        loadStreak()
        loadLatestAchievement(modelContext: modelContext)
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
                targetScore = Double(latestScan.overallScore) * 0.55 + computeAdherenceScore() * 0.45
            }
        }

        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        let weekPredicate = #Predicate<DailyLongevityScore> { score in
            score.date >= weekAgo
        }
        let weekDescriptor = FetchDescriptor<DailyLongevityScore>(predicate: weekPredicate, sortBy: [SortDescriptor(\.date)])
        if let scores = try? modelContext.fetch(weekDescriptor), scores.count >= 2 {
            let oldest = scores.first?.compositeScore ?? targetScore
            scoreTrend = targetScore - oldest
        }
    }

    private func computeAdherenceScore() -> Double {
        let streak = UserDefaults.standard.integer(forKey: "adherenceStreak")
        if streak >= 30 { return 95 }
        if streak >= 14 { return 80 }
        if streak >= 7 { return 60 }
        return max(20, Double(streak) * 8.5)
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

        let healthService = HealthKitService.shared
        let schedule = healthService.sleepSchedule
        let wakeH = schedule.wakeHour ?? 7
        let wakeM = schedule.wakeMinute ?? 0
        let sleepH = schedule.sleepHour ?? 23

        let morningH = wakeH
        let morningM = wakeM + 30
        let eveningMinutes = max(0, sleepH * 60 - 90)

        protocolItems = [
            ProtocolItem(
                time: String(format: "%d:%02d AM", morningH > 12 ? morningH - 12 : (morningH == 0 ? 12 : morningH), morningM % 60),
                title: "AeonDerm + Vitamin C boost",
                icon: "sunrise.fill",
                period: "Morning",
                isCompleted: completedCategories.contains("morning"),
                category: "morning"
            ),
            ProtocolItem(
                time: "12:30 PM",
                title: "Hydration reminder",
                icon: "drop.fill",
                period: "Afternoon",
                isCompleted: completedCategories.contains("midday"),
                category: "midday"
            ),
            ProtocolItem(
                time: String(format: "%d:%02d PM", eveningMinutes / 60 > 12 ? eveningMinutes / 60 - 12 : eveningMinutes / 60, eveningMinutes % 60),
                title: "AeonDerm collagen dose",
                icon: "moon.stars.fill",
                period: "Evening",
                isCompleted: completedCategories.contains("evening"),
                category: "evening"
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
            DailyScore(day: formatter.string(from: scan.date), score: Double(scan.overallScore))
        }
    }

    private func loadStreak() {
        streakDays = UserDefaults.standard.integer(forKey: "adherenceStreak")
    }

    private func loadLatestAchievement(modelContext: ModelContext) {
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
}

struct DailyScore: Identifiable {
    let id = UUID()
    let day: String
    let score: Double
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}
