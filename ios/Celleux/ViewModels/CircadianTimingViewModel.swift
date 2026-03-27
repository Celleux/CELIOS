import SwiftUI
import SwiftData
import UserNotifications

struct ScheduleItem: Identifiable, Sendable {
    let id = UUID()
    let time: Date
    let label: String
    let supplements: [String]
    let rationale: String
    let category: String
    var isCompleted: Bool
    var isMissed: Bool
    let icon: String

    var isActive: Bool {
        let now = Date()
        let window: TimeInterval = 30 * 60
        return !isCompleted && !isMissed && abs(now.timeIntervalSince(time)) < window
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }

    var isUpcoming: Bool {
        !isCompleted && !isMissed && time > Date()
    }
}

nonisolated struct TimingScienceCard: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let icon: String
    let explanation: String
}

@Observable
final class CircadianTimingViewModel {
    private let healthService = HealthKitService.shared

    var scheduleItems: [ScheduleItem] = []
    var isLoading: Bool = true
    var wakeTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    var sleepTime: Date = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
    var workoutTime: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    var autoAdjust: Bool = true
    var expandedScienceCards: Set<String> = []
    var workoutDetectedToday: Bool = false
    var lastWorkoutEndTime: Date? = nil
    var isWeekendMode: Bool = false
    var weekendModeEnabled: Bool = UserDefaults.standard.bool(forKey: "weekendModeEnabled")
    var weekendExtraMinutes: Int = UserDefaults.standard.integer(forKey: "weekendExtraMinutes") == 0 ? 60 : UserDefaults.standard.integer(forKey: "weekendExtraMinutes")

    var streakDays: Int = 0
    var weeklyAdherencePercent: Int = 0
    var hasWatchSleepData: Bool = false
    var breathingTimerActive: Bool = false
    var breathingTimerCategory: String? = nil
    var breathingCountdown: Int = 30
    var isMilestoneStreak: Bool = false

    var nextDoseCountdown: String? {
        let now = Date()
        guard let nextItem = scheduleItems.first(where: { $0.isUpcoming }) else { return nil }
        let diff = nextItem.time.timeIntervalSince(now)
        guard diff > 0 else { return nil }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if hours > 0 {
            return "In \(hours)h \(minutes)m"
        } else {
            return "In \(minutes)m"
        }
    }

    var nextDoseItem: ScheduleItem? {
        scheduleItems.first(where: { $0.isUpcoming })
    }

    var currentTimeProgress: Double {
        let calendar = Calendar.current
        let wakeComps = calendar.dateComponents([.hour, .minute], from: wakeTime)
        let sleepComps = calendar.dateComponents([.hour, .minute], from: sleepTime)
        let wakeMinutes = Double((wakeComps.hour ?? 7) * 60 + (wakeComps.minute ?? 0))
        let sleepMinutes = Double((sleepComps.hour ?? 23) * 60 + (sleepComps.minute ?? 0))
        let nowComps = calendar.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = Double((nowComps.hour ?? 12) * 60 + (nowComps.minute ?? 0))
        let totalWindow = sleepMinutes - wakeMinutes
        guard totalWindow > 0 else { return 0.5 }
        return min(1, max(0, (nowMinutes - wakeMinutes) / totalWindow))
    }

    let scienceCards: [TimingScienceCard] = [
        TimingScienceCard(
            title: "Circadian Biology",
            icon: "clock.arrow.circlepath",
            explanation: "Your body's master clock regulates nutrient absorption, hormone production, and cellular repair. Timing supplements to align with these cycles can increase bioavailability by up to 40%."
        ),
        TimingScienceCard(
            title: "Nutrient Absorption Windows",
            icon: "arrow.down.circle",
            explanation: "Fat-soluble vitamins (A, D, E, K) absorb best with morning meals. Collagen peptides peak in absorption during the evening when growth hormone rises. Antioxidants are most effective post-exercise when oxidative stress is highest."
        ),
        TimingScienceCard(
            title: "Sleep-Wake Cycle Integration",
            icon: "bed.double",
            explanation: "Melatonin-supporting nutrients taken 1-2 hours before bed enhance sleep quality. Morning doses of adaptogens align with cortisol's natural peak, supporting stress resilience without disrupting circadian rhythm."
        ),
    ]

    var completedCount: Int {
        scheduleItems.filter(\.isCompleted).count
    }

    var totalCount: Int {
        scheduleItems.count
    }

    var completionProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    func loadSchedule(modelContext: ModelContext) async {
        isLoading = true

        let authorized = await healthService.requestAuthorization()
        if authorized {
            await healthService.fetchAllData()
        }

        if autoAdjust {
            applyHealthKitSchedule()
        }

        await detectWorkout()
        checkWeekendMode()
        await applyAdaptiveAdjustments(modelContext: modelContext)
        generateSchedule()
        loadTodayCompletions(modelContext: modelContext)
        loadStreak()
        loadWeeklyAdherence(modelContext: modelContext)

        isLoading = false
    }

    private func applyHealthKitSchedule() {
        let schedule = healthService.sleepSchedule
        let calendar = Calendar.current

        let hasWake = schedule.wakeHour != nil && schedule.wakeMinute != nil
        let hasSleep = schedule.sleepHour != nil && schedule.sleepMinute != nil
        hasWatchSleepData = hasWake || hasSleep

        if let wakeH = schedule.wakeHour, let wakeM = schedule.wakeMinute {
            if let date = calendar.date(from: DateComponents(hour: wakeH, minute: wakeM)) {
                wakeTime = date
            }
        }

        if let sleepH = schedule.sleepHour, let sleepM = schedule.sleepMinute {
            if let date = calendar.date(from: DateComponents(hour: sleepH, minute: sleepM)) {
                sleepTime = date
            }
        }
    }

    private func detectWorkout() async {
        let workouts = await healthService.queryTodayWorkouts()
        workoutDetectedToday = !workouts.isEmpty
        lastWorkoutEndTime = workouts.first?.endTime
    }

    private func checkWeekendMode() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let isWeekend = weekday == 1 || weekday == 7
        isWeekendMode = isWeekend && weekendModeEnabled
    }

    private func applyAdaptiveAdjustments(modelContext: ModelContext) async {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let predicate = #Predicate<DoseCompletionPattern> { pattern in
            pattern.category == "morning" && pattern.date >= sevenDaysAgo
        }
        let descriptor = FetchDescriptor<DoseCompletionPattern>(predicate: predicate)
        guard let patterns = try? modelContext.fetch(descriptor), patterns.count >= 3 else { return }

        let avgDelay = patterns.map(\.delayMinutes).reduce(0, +) / patterns.count
        if avgDelay > 45 {
            let adjustMinutes = 15
            wakeTime = calendar.date(byAdding: .minute, value: adjustMinutes, to: wakeTime) ?? wakeTime
        }
    }

    private func generateSchedule() {
        let calendar = Calendar.current
        let wakeComps = calendar.dateComponents([.hour, .minute], from: wakeTime)
        let sleepComps = calendar.dateComponents([.hour, .minute], from: sleepTime)

        let today = calendar.startOfDay(for: Date())
        let wakeH = wakeComps.hour ?? 7
        let wakeM = wakeComps.minute ?? 0

        let weekendOffset = isWeekendMode ? weekendExtraMinutes : 0

        let morningTime = calendar.date(byAdding: DateComponents(
            hour: wakeH,
            minute: wakeM + 30 + weekendOffset
        ), to: today) ?? today

        let middayTime = calendar.date(byAdding: DateComponents(
            hour: wakeH + 6,
            minute: wakeM + weekendOffset
        ), to: today) ?? today

        let postWorkoutTime: Date
        let postWorkoutLabel: String
        let postWorkoutIcon: String
        let postWorkoutRationale: String

        if workoutDetectedToday, let endTime = lastWorkoutEndTime {
            postWorkoutTime = endTime.addingTimeInterval(30 * 60)
            postWorkoutLabel = "Post-Workout Recovery"
            postWorkoutIcon = "figure.run"
            postWorkoutRationale = "Workout detected — antioxidants are most protective 30 minutes post-exercise when oxidative stress peaks."
        } else {
            postWorkoutTime = calendar.date(byAdding: DateComponents(
                hour: wakeH + 9,
                minute: wakeM + weekendOffset
            ), to: today) ?? today
            postWorkoutLabel = "Afternoon Antioxidants"
            postWorkoutIcon = "sun.haze"
            postWorkoutRationale = "No workout detected today. Afternoon antioxidant dose supports skin protection during peak UV hours."
        }

        let sleepH = sleepComps.hour ?? 23
        let sleepM = sleepComps.minute ?? 0
        let eveningMinutes = max(0, (sleepH * 60 + sleepM) - 120)
        let eveningTime = calendar.date(byAdding: DateComponents(
            hour: eveningMinutes / 60,
            minute: eveningMinutes % 60
        ), to: today) ?? today

        let now = Date()

        var items: [ScheduleItem] = [
            ScheduleItem(
                time: morningTime,
                label: "Morning Dose",
                supplements: ["Vitamin C (1000mg)", "Vitamin D3 (5000 IU)", "Adaptogen blend"],
                rationale: "Taken 30 min after waking to align with cortisol peak. Vitamin D absorption is highest in the morning with food.",
                category: "morning",
                isCompleted: false,
                isMissed: false,
                icon: "sunrise.fill"
            ),
            ScheduleItem(
                time: middayTime,
                label: "Midday Hydration",
                supplements: ["Hyaluronic acid (200mg)", "Zinc (15mg)"],
                rationale: "Midday dosing supports sustained hydration levels. Zinc absorption is optimized away from morning calcium.",
                category: "midday",
                isCompleted: false,
                isMissed: false,
                icon: "sun.max.fill"
            ),
            ScheduleItem(
                time: postWorkoutTime,
                label: postWorkoutLabel,
                supplements: ["Astaxanthin (12mg)", "CoQ10 (200mg)", "Omega-3 (2000mg)"],
                rationale: postWorkoutRationale,
                category: "postworkout",
                isCompleted: false,
                isMissed: false,
                icon: postWorkoutIcon
            ),
            ScheduleItem(
                time: eveningTime,
                label: "Evening Repair",
                supplements: ["Collagen peptides (10g)", "Magnesium glycinate (400mg)"],
                rationale: "Collagen synthesis peaks during sleep. Magnesium supports GABA activity for deep sleep, enhancing overnight cellular repair.",
                category: "evening",
                isCompleted: false,
                isMissed: false,
                icon: "moon.stars.fill"
            )
        ]

        for i in items.indices {
            if now > items[i].time.addingTimeInterval(3600) && !items[i].isCompleted {
                items[i].isMissed = true
            }
        }

        scheduleItems = items
    }

    private func loadTodayCompletions(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        let predicate = #Predicate<SupplementDose> { dose in
            dose.date >= today && dose.date < tomorrow && dose.isCompleted
        }
        let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)

        guard let completedDoses = try? modelContext.fetch(descriptor) else { return }
        let completedCategories = Set(completedDoses.map(\.category))

        for i in scheduleItems.indices {
            if completedCategories.contains(scheduleItems[i].category) {
                scheduleItems[i].isCompleted = true
                scheduleItems[i].isMissed = false
            }
        }
    }

    func toggleCompletion(item: ScheduleItem, modelContext: ModelContext) {
        guard let index = scheduleItems.firstIndex(where: { $0.id == item.id }) else { return }

        scheduleItems[index].isCompleted.toggle()
        scheduleItems[index].isMissed = false

        let today = Calendar.current.startOfDay(for: Date())

        if scheduleItems[index].isCompleted {
            let dose = SupplementDose(
                date: today,
                name: item.label,
                scheduledTime: item.time,
                completedTime: Date(),
                isCompleted: true,
                category: item.category
            )
            modelContext.insert(dose)

            recordCompletionPattern(item: item, modelContext: modelContext)
            updateAdherenceStreak(modelContext: modelContext)
            AchievementEngine.shared.checkAll(modelContext: modelContext)
            AchievementEngine.shared.recordChallengeCheckIn(modelContext: modelContext)
        } else {
            let category = item.category
            let predicate = #Predicate<SupplementDose> { dose in
                dose.date >= today && dose.category == category
            }
            let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)
            if let doses = try? modelContext.fetch(descriptor) {
                for dose in doses {
                    modelContext.delete(dose)
                }
            }
        }

        try? modelContext.save()
    }

    private func recordCompletionPattern(item: ScheduleItem, modelContext: ModelContext) {
        let calendar = Calendar.current
        let scheduledComps = calendar.dateComponents([.hour, .minute], from: item.time)
        let nowComps = calendar.dateComponents([.hour, .minute], from: Date())

        let scheduledMinute = (scheduledComps.hour ?? 0) * 60 + (scheduledComps.minute ?? 0)
        let actualMinute = (nowComps.hour ?? 0) * 60 + (nowComps.minute ?? 0)
        let delay = max(0, actualMinute - scheduledMinute)

        let pattern = DoseCompletionPattern(
            category: item.category,
            scheduledMinuteOfDay: scheduledMinute,
            actualMinuteOfDay: actualMinute,
            date: Date(),
            delayMinutes: delay
        )
        modelContext.insert(pattern)
    }

    private func updateAdherenceStreak(modelContext: ModelContext) {
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

        UserDefaults.standard.set(streak, forKey: "adherenceStreak")
        let previousStreak = streakDays
        streakDays = streak
        checkMilestoneCelebration(previous: previousStreak, current: streak)
    }

    private func loadStreak() {
        streakDays = UserDefaults.standard.integer(forKey: "adherenceStreak")
    }

    private func loadWeeklyAdherence(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        let predicate = #Predicate<SupplementDose> { dose in
            dose.date >= sevenDaysAgo && dose.isCompleted
        }
        let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)
        let completedCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        let totalPossible = 7 * 4
        weeklyAdherencePercent = totalPossible > 0 ? min(100, (completedCount * 100) / totalPossible) : 0
    }

    private func checkMilestoneCelebration(previous: Int, current: Int) {
        let milestones = [7, 14, 30, 60, 90]
        for m in milestones {
            if previous < m && current >= m {
                isMilestoneStreak = true
                return
            }
        }
    }

    func startBreathingTimer(for category: String) {
        breathingTimerCategory = category
        breathingTimerActive = true
        breathingCountdown = 30
    }

    func stopBreathingTimer() {
        breathingTimerActive = false
        breathingTimerCategory = nil
        breathingCountdown = 30
    }

    func tickBreathingCountdown() {
        guard breathingCountdown > 0 else { return }
        breathingCountdown -= 1
    }

    func scheduleNotifications() {
        let items = scheduleItems
        Task.detached {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                guard granted else { return }
            } catch {
                return
            }

            center.removeAllPendingNotificationRequests()

            let calendar = Calendar.current

            for item in items {
                let content = UNMutableNotificationContent()
                content.title = item.label
                content.body = item.supplements.joined(separator: ", ")
                content.sound = .default

                let comps = calendar.dateComponents([.hour, .minute], from: item.time)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

                let request = UNNotificationRequest(
                    identifier: item.category,
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)

                let reminderContent = UNMutableNotificationContent()
                reminderContent.title = "Gentle Reminder"
                reminderContent.body = "Your \(item.label.lowercased()) is waiting — \(item.supplements.first ?? "supplements") ready to go."
                reminderContent.sound = .default

                let reminderTime = item.time.addingTimeInterval(30 * 60)
                let reminderComps = calendar.dateComponents([.hour, .minute], from: reminderTime)
                let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: reminderComps, repeats: true)

                let reminderRequest = UNNotificationRequest(
                    identifier: "\(item.category)_reminder",
                    content: reminderContent,
                    trigger: reminderTrigger
                )
                try? await center.add(reminderRequest)
            }
        }
    }

    func regenerateSchedule() {
        generateSchedule()
        scheduleNotifications()
    }

    func toggleWeekendMode() {
        weekendModeEnabled.toggle()
        UserDefaults.standard.set(weekendModeEnabled, forKey: "weekendModeEnabled")
        checkWeekendMode()
        generateSchedule()
        scheduleNotifications()
    }

    func doseWindowSegments() -> [(start: Double, end: Double, category: String)] {
        let calendar = Calendar.current
        let wakeComps = calendar.dateComponents([.hour, .minute], from: wakeTime)
        let sleepComps = calendar.dateComponents([.hour, .minute], from: sleepTime)
        let wakeMinutes = Double((wakeComps.hour ?? 7) * 60 + (wakeComps.minute ?? 0))
        let sleepMinutes = Double((sleepComps.hour ?? 23) * 60 + (sleepComps.minute ?? 0))
        let totalWindow = sleepMinutes - wakeMinutes
        guard totalWindow > 0 else { return [] }

        return scheduleItems.map { item in
            let itemComps = calendar.dateComponents([.hour, .minute], from: item.time)
            let itemMinutes = Double((itemComps.hour ?? 0) * 60 + (itemComps.minute ?? 0))
            let center = (itemMinutes - wakeMinutes) / totalWindow
            let halfWidth = 0.06
            return (start: max(0, center - halfWidth), end: min(1, center + halfWidth), category: item.category)
        }
    }
}
