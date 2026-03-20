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

    func loadSchedule(modelContext: ModelContext) async {
        isLoading = true

        let authorized = await healthService.requestAuthorization()
        if authorized {
            await healthService.fetchAllData()
        }

        if autoAdjust {
            applyHealthKitSchedule()
        }

        loadTodayCompletions(modelContext: modelContext)
        generateSchedule()

        isLoading = false
    }

    private func applyHealthKitSchedule() {
        let schedule = healthService.sleepSchedule
        let calendar = Calendar.current

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

    private func generateSchedule() {
        let calendar = Calendar.current
        let wakeComps = calendar.dateComponents([.hour, .minute], from: wakeTime)
        let sleepComps = calendar.dateComponents([.hour, .minute], from: sleepTime)
        let workoutComps = calendar.dateComponents([.hour, .minute], from: workoutTime)

        let today = calendar.startOfDay(for: Date())

        let morningTime = calendar.date(byAdding: DateComponents(
            hour: (wakeComps.hour ?? 7),
            minute: (wakeComps.minute ?? 0) + 30
        ), to: today) ?? today

        let middayTime = calendar.date(byAdding: DateComponents(
            hour: 12, minute: 30
        ), to: today) ?? today

        let postWorkoutTime = calendar.date(byAdding: DateComponents(
            hour: (workoutComps.hour ?? 17),
            minute: (workoutComps.minute ?? 0) + 15
        ), to: today) ?? today

        let eveningTime: Date
        let sleepH = sleepComps.hour ?? 23
        let sleepM = sleepComps.minute ?? 0
        let eveningMinutes = max(0, (sleepH * 60 + sleepM) - 90)
        eveningTime = calendar.date(byAdding: DateComponents(
            hour: eveningMinutes / 60,
            minute: eveningMinutes % 60
        ), to: today) ?? today

        let now = Date()

        var items: [ScheduleItem] = []

        items.append(ScheduleItem(
            time: morningTime,
            label: "Morning Dose",
            supplements: ["Vitamin C (1000mg)", "Vitamin D3 (5000 IU)", "Adaptogen blend"],
            rationale: "Taken 30 min after waking to align with cortisol peak. Vitamin D absorption is highest in the morning with food.",
            category: "morning",
            isCompleted: false,
            isMissed: !items.isEmpty ? false : (now > morningTime.addingTimeInterval(3600) && !false)
        ))

        items.append(ScheduleItem(
            time: middayTime,
            label: "Midday Hydration",
            supplements: ["Hyaluronic acid (200mg)", "Zinc (15mg)"],
            rationale: "Midday dosing supports sustained hydration levels. Zinc absorption is optimized away from morning calcium.",
            category: "midday",
            isCompleted: false,
            isMissed: false
        ))

        items.append(ScheduleItem(
            time: postWorkoutTime,
            label: "Post-Activity Antioxidants",
            supplements: ["Astaxanthin (12mg)", "CoQ10 (200mg)", "Omega-3 (2000mg)"],
            rationale: "Post-exercise oxidative stress creates a window where antioxidants are most protective for skin cells.",
            category: "postworkout",
            isCompleted: false,
            isMissed: false
        ))

        items.append(ScheduleItem(
            time: eveningTime,
            label: "Evening Repair",
            supplements: ["Collagen peptides (10g)", "Magnesium glycinate (400mg)"],
            rationale: "Collagen synthesis peaks during sleep. Magnesium supports GABA activity for deep sleep, enhancing overnight cellular repair.",
            category: "evening",
            isCompleted: false,
            isMissed: false
        ))

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

            updateAdherenceStreak(modelContext: modelContext)
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
            }
        }
    }

    func regenerateSchedule() {
        generateSchedule()
        scheduleNotifications()
    }
}
