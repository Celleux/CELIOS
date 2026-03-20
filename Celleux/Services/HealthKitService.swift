import HealthKit

nonisolated struct HealthSleepData: Sendable {
    var totalHours: Double?
    var deepMinutes: Double?
    var remMinutes: Double?
    var totalMinutes: Double?
}

nonisolated struct SleepScheduleData: Sendable {
    var wakeHour: Int?
    var wakeMinute: Int?
    var sleepHour: Int?
    var sleepMinute: Int?
}

nonisolated struct SleepSampleInfo: Sendable {
    let startTimeInterval: TimeInterval
    let endTimeInterval: TimeInterval
    let value: Int
}

nonisolated struct MoodEntry: Sendable {
    let date: Date
    let valence: Double
    let kind: Int
    let labels: [Int]
    let associations: [Int]
}

@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    var isAuthorized: Bool = false

    var latestHRV: Double?
    var latestRestingHR: Double?
    var latestVO2Max: Double?
    var todayActiveCalories: Double?
    var todaySteps: Double?
    var latestOxygenSaturation: Double?
    var latestRespiratoryRate: Double?
    var latestWristTemperature: Double?
    var todayWaterIntake: Double?
    var todayUVExposure: Double?
    var todayExerciseMinutes: Double?

    var sleepData: HealthSleepData = HealthSleepData()
    var sleepSchedule: SleepScheduleData = SleepScheduleData()

    var latestMoodValence: Double?
    var recentMoodEntries: [MoodEntry] = []
    var averageMoodValence: Double?

    var hasWatchData: Bool {
        latestHRV != nil || sleepData.totalHours != nil || latestRestingHR != nil
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private init() {}

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        var readTypes: Set<HKObjectType> = [
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.vo2Max),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.stepCount),
            HKQuantityType(.oxygenSaturation),
            HKQuantityType(.respiratoryRate),
            HKQuantityType(.appleSleepingWristTemperature),
            HKQuantityType(.dietaryWater),
            HKQuantityType(.uvExposure),
            HKQuantityType(.appleExerciseTime),
            HKCategoryType(.sleepAnalysis),
            HKSampleType.stateOfMindType(),
        ]

        let shareTypes: Set<HKSampleType> = [
            HKSampleType.stateOfMindType(),
        ]

        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }

    func fetchAllData() async {
        async let hrv: Double? = queryLatestQuantity(
            typeId: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli)
        )
        async let rhr: Double? = queryLatestQuantity(
            typeId: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute())
        )
        async let vo2: Double? = queryLatestQuantity(
            typeId: .vo2Max,
            unit: HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        )
        async let cal: Double? = queryTodayCumulative(
            typeId: .activeEnergyBurned,
            unit: .kilocalorie()
        )
        async let steps: Double? = queryTodayCumulative(
            typeId: .stepCount,
            unit: .count()
        )
        async let o2: Double? = queryLatestQuantity(
            typeId: .oxygenSaturation,
            unit: .percent()
        )
        async let resp: Double? = queryLatestQuantity(
            typeId: .respiratoryRate,
            unit: HKUnit.count().unitDivided(by: .minute())
        )
        async let temp: Double? = queryLatestQuantity(
            typeId: .appleSleepingWristTemperature,
            unit: .degreeCelsius()
        )
        async let water: Double? = queryTodayCumulative(
            typeId: .dietaryWater,
            unit: .literUnit(with: .milli)
        )
        async let uv: Double? = queryTodayCumulative(
            typeId: .uvExposure,
            unit: .count()
        )
        async let exercise: Double? = queryTodayCumulative(
            typeId: .appleExerciseTime,
            unit: .minute()
        )
        async let sleep: HealthSleepData = querySleepData()
        async let schedule: SleepScheduleData = queryAverageSleepSchedule()
        async let moods: [MoodEntry] = queryRecentStateOfMind(days: 7)

        latestHRV = await hrv
        latestRestingHR = await rhr
        latestVO2Max = await vo2
        todayActiveCalories = await cal
        todaySteps = await steps
        latestOxygenSaturation = await o2
        latestRespiratoryRate = await resp
        latestWristTemperature = await temp
        todayWaterIntake = await water
        todayUVExposure = await uv
        todayExerciseMinutes = await exercise
        sleepData = await sleep
        sleepSchedule = await schedule
        recentMoodEntries = await moods

        if !recentMoodEntries.isEmpty {
            latestMoodValence = recentMoodEntries.first?.valence
            averageMoodValence = recentMoodEntries.map(\.valence).reduce(0, +) / Double(recentMoodEntries.count)
        }
    }

    func saveStateOfMind(
        valence: Double,
        kind: HKStateOfMind.Kind,
        labels: [HKStateOfMind.Label],
        associations: [HKStateOfMind.Association]
    ) async -> Bool {
        guard isAvailable else { return false }

        let sample = HKStateOfMind(
            date: Date(),
            kind: kind,
            valence: valence,
            labels: labels,
            associations: associations
        )

        do {
            try await store.save(sample)
            await fetchRecentMoods()
            return true
        } catch {
            return false
        }
    }

    private func fetchRecentMoods() async {
        recentMoodEntries = await queryRecentStateOfMind(days: 7)
        if !recentMoodEntries.isEmpty {
            latestMoodValence = recentMoodEntries.first?.valence
            averageMoodValence = recentMoodEntries.map(\.valence).reduce(0, +) / Double(recentMoodEntries.count)
        }
    }

    func queryRecentStateOfMind(days: Int) async -> [MoodEntry] {
        guard isAvailable else { return [] }

        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return [] }

        let stateOfMindType = HKSampleType.stateOfMindType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: stateOfMindType,
                predicate: predicate,
                limit: 50,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let stateOfMindSamples = samples as? [HKStateOfMind] else {
                    continuation.resume(returning: [])
                    return
                }
                let entries = stateOfMindSamples.map { sample in
                    MoodEntry(
                        date: sample.startDate,
                        valence: sample.valence,
                        kind: sample.kind.rawValue,
                        labels: sample.labels.map(\.rawValue),
                        associations: sample.associations.map(\.rawValue)
                    )
                }
                continuation.resume(returning: entries)
            }
            store.execute(query)
        }
    }

    func queryMoodHistory(days: Int) async -> [MoodEntry] {
        await queryRecentStateOfMind(days: days)
    }

    private func queryLatestQuantity(typeId: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard isAvailable else { return nil }

        let quantityType = HKQuantityType(typeId)

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func queryTodayCumulative(typeId: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard isAvailable else { return nil }

        let quantityType = HKQuantityType(typeId)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func querySleepData() async -> HealthSleepData {
        guard isAvailable else { return HealthSleepData() }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: endDate)) else {
            return HealthSleepData()
        }

        let samples = await fetchSleepSamples(from: startDate, to: endDate)

        var totalMinutes: Double = 0
        var deepMinutes: Double = 0
        var remMinutes: Double = 0

        for sample in samples {
            let duration = (sample.endTimeInterval - sample.startTimeInterval) / 60.0
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deepMinutes += duration
                totalMinutes += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                remMinutes += duration
                totalMinutes += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                totalMinutes += duration
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                totalMinutes += duration
            default:
                break
            }
        }

        guard totalMinutes > 0 else { return HealthSleepData() }

        return HealthSleepData(
            totalHours: totalMinutes / 60.0,
            deepMinutes: deepMinutes,
            remMinutes: remMinutes,
            totalMinutes: totalMinutes
        )
    }

    private func queryAverageSleepSchedule() async -> SleepScheduleData {
        guard isAvailable else { return SleepScheduleData() }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            return SleepScheduleData()
        }

        let samples = await fetchSleepSamples(from: startDate, to: endDate)

        let sleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        ]

        let sleepSamples = samples.filter { sleepValues.contains($0.value) }
        guard !sleepSamples.isEmpty else { return SleepScheduleData() }

        var dayRanges: [String: (start: TimeInterval, end: TimeInterval)] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for sample in sleepSamples {
            let endDate = Date(timeIntervalSinceReferenceDate: sample.endTimeInterval)
            let dayKey = dateFormatter.string(from: endDate)
            if let existing = dayRanges[dayKey] {
                dayRanges[dayKey] = (
                    start: min(existing.start, sample.startTimeInterval),
                    end: max(existing.end, sample.endTimeInterval)
                )
            } else {
                dayRanges[dayKey] = (start: sample.startTimeInterval, end: sample.endTimeInterval)
            }
        }

        guard !dayRanges.isEmpty else { return SleepScheduleData() }

        var sleepHours: [Int] = []
        var sleepMinutes: [Int] = []
        var wakeHours: [Int] = []
        var wakeMinutes: [Int] = []

        for (_, range) in dayRanges {
            let startDate = Date(timeIntervalSinceReferenceDate: range.start)
            let endDate = Date(timeIntervalSinceReferenceDate: range.end)

            let startComps = calendar.dateComponents([.hour, .minute], from: startDate)
            let endComps = calendar.dateComponents([.hour, .minute], from: endDate)

            if let h = startComps.hour, let m = startComps.minute {
                sleepHours.append(h)
                sleepMinutes.append(m)
            }
            if let h = endComps.hour, let m = endComps.minute {
                wakeHours.append(h)
                wakeMinutes.append(m)
            }
        }

        guard !sleepHours.isEmpty else { return SleepScheduleData() }

        let avgSleepH = sleepHours.reduce(0, +) / sleepHours.count
        let avgSleepM = sleepMinutes.reduce(0, +) / sleepMinutes.count
        let avgWakeH = wakeHours.reduce(0, +) / wakeHours.count
        let avgWakeM = wakeMinutes.reduce(0, +) / wakeMinutes.count

        return SleepScheduleData(
            wakeHour: avgWakeH,
            wakeMinute: avgWakeM,
            sleepHour: avgSleepH,
            sleepMinute: avgSleepM
        )
    }

    private func fetchSleepSamples(from startDate: Date, to endDate: Date) async -> [SleepSampleInfo] {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                    continuation.resume(returning: [])
                    return
                }
                let infos = categorySamples.map { sample in
                    SleepSampleInfo(
                        startTimeInterval: sample.startDate.timeIntervalSinceReferenceDate,
                        endTimeInterval: sample.endDate.timeIntervalSinceReferenceDate,
                        value: sample.value
                    )
                }
                continuation.resume(returning: infos)
            }
            store.execute(query)
        }
    }
}
