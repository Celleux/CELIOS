import SwiftData
import Foundation

@Model
final class SkinTransformationChallenge {
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var isCompleted: Bool

    var baselineScore: Int
    var baselineTexture: Double
    var baselineHydration: Double
    var baselineRadiance: Double
    var baselineTone: Double
    var baselineUnderEye: Double
    var baselineElasticity: Double

    var finalScore: Int
    var finalTexture: Double
    var finalHydration: Double
    var finalRadiance: Double
    var finalTone: Double
    var finalUnderEye: Double
    var finalElasticity: Double

    var milestone7Date: Date?
    var milestone14Date: Date?
    var milestone30Date: Date?
    var milestone60Date: Date?
    var milestone90Date: Date?

    var checkedInDates: [Date]

    init(
        startDate: Date = Date(),
        baselineScore: Int = 0,
        baselineTexture: Double = 0,
        baselineHydration: Double = 0,
        baselineRadiance: Double = 0,
        baselineTone: Double = 0,
        baselineUnderEye: Double = 0,
        baselineElasticity: Double = 0
    ) {
        self.startDate = startDate
        self.isActive = true
        self.isCompleted = false
        self.baselineScore = baselineScore
        self.baselineTexture = baselineTexture
        self.baselineHydration = baselineHydration
        self.baselineRadiance = baselineRadiance
        self.baselineTone = baselineTone
        self.baselineUnderEye = baselineUnderEye
        self.baselineElasticity = baselineElasticity
        self.finalScore = 0
        self.finalTexture = 0
        self.finalHydration = 0
        self.finalRadiance = 0
        self.finalTone = 0
        self.finalUnderEye = 0
        self.finalElasticity = 0
        self.checkedInDates = []
    }

    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Calendar.current.startOfDay(for: Date())).day ?? 0
    }

    var currentDay: Int {
        min(daysSinceStart + 1, 90)
    }

    var progress: Double {
        Double(min(daysSinceStart, 90)) / 90.0
    }

    var daysRemaining: Int {
        max(0, 90 - daysSinceStart)
    }

    var checkedInDayCount: Int {
        let unique = Set(checkedInDates.map { Calendar.current.startOfDay(for: $0) })
        return unique.count
    }

    var currentMilestoneTarget: Int {
        let day = daysSinceStart
        if day < 7 { return 7 }
        if day < 14 { return 14 }
        if day < 30 { return 30 }
        if day < 60 { return 60 }
        return 90
    }

    func isCheckedIn(on date: Date) -> Bool {
        let target = Calendar.current.startOfDay(for: date)
        return checkedInDates.contains { Calendar.current.isDate($0, inSameDayAs: target) }
    }

    func isTodayCheckedIn() -> Bool {
        isCheckedIn(on: Date())
    }

    func recordCheckIn() {
        guard !isTodayCheckedIn() else { return }
        checkedInDates.append(Date())
        updateMilestones()
    }

    private func updateMilestones() {
        let day = daysSinceStart
        if day >= 7 && milestone7Date == nil { milestone7Date = Date() }
        if day >= 14 && milestone14Date == nil { milestone14Date = Date() }
        if day >= 30 && milestone30Date == nil { milestone30Date = Date() }
        if day >= 60 && milestone60Date == nil { milestone60Date = Date() }
        if day >= 90 && milestone90Date == nil {
            milestone90Date = Date()
            isCompleted = true
            isActive = false
            endDate = Date()
        }
    }

    func complete(
        finalScore: Int,
        texture: Double,
        hydration: Double,
        radiance: Double,
        tone: Double,
        underEye: Double,
        elasticity: Double
    ) {
        self.finalScore = finalScore
        self.finalTexture = texture
        self.finalHydration = hydration
        self.finalRadiance = radiance
        self.finalTone = tone
        self.finalUnderEye = underEye
        self.finalElasticity = elasticity
        self.isCompleted = true
        self.isActive = false
        self.endDate = Date()
    }

    func abandon() {
        isActive = false
        endDate = Date()
    }
}

nonisolated struct ChallengeMilestone: Identifiable, Sendable {
    let id: Int
    let day: Int
    let title: String
    let icon: String
    let reachedDate: Date?

    var isReached: Bool { reachedDate != nil }
}
