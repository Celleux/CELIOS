import SwiftData
import Foundation

@Model
final class DailyLongevityScore {
    var date: Date
    var compositeScore: Double
    var sleepScore: Double
    var hrvScore: Double
    var restingHRScore: Double
    var vo2MaxScore: Double
    var skinScore: Double
    var adherenceScore: Double
    var activityScore: Double
    var circadianScore: Double
    var stressScore: Double
    var hydrationScore: Double
    var uvScore: Double
    var moodValence: Double
    var skinHealthIndex: Double

    init(date: Date, compositeScore: Double, sleepScore: Double = 0, hrvScore: Double = 0, restingHRScore: Double = 0, vo2MaxScore: Double = 0, skinScore: Double = 0, adherenceScore: Double = 0, activityScore: Double = 0, circadianScore: Double = 0, stressScore: Double = 0, hydrationScore: Double = 0, uvScore: Double = 0, moodValence: Double = 0, skinHealthIndex: Double = 0) {
        self.date = date
        self.compositeScore = compositeScore
        self.sleepScore = sleepScore
        self.hrvScore = hrvScore
        self.restingHRScore = restingHRScore
        self.vo2MaxScore = vo2MaxScore
        self.skinScore = skinScore
        self.adherenceScore = adherenceScore
        self.activityScore = activityScore
        self.circadianScore = circadianScore
        self.stressScore = stressScore
        self.hydrationScore = hydrationScore
        self.uvScore = uvScore
        self.moodValence = moodValence
        self.skinHealthIndex = skinHealthIndex
    }
}

@Model
final class SupplementDose {
    var date: Date
    var name: String
    var scheduledTime: Date
    var completedTime: Date?
    var isCompleted: Bool
    var category: String

    init(date: Date, name: String, scheduledTime: Date, completedTime: Date? = nil, isCompleted: Bool = false, category: String = "") {
        self.date = date
        self.name = name
        self.scheduledTime = scheduledTime
        self.completedTime = completedTime
        self.isCompleted = isCompleted
        self.category = category
    }
}

nonisolated enum HistoryPeriod: String, CaseIterable, Sendable {
    case thirtyDays = "30D"
    case sixtyDays = "60D"
    case ninetyDays = "90D"

    var days: Int {
        switch self {
        case .thirtyDays: 30
        case .sixtyDays: 60
        case .ninetyDays: 90
        }
    }
}

nonisolated enum LongevityFactor: String, Identifiable, CaseIterable, Sendable {
    case sleep
    case hrv
    case skinAnalysis
    case adherence
    case activity
    case circadian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep: "Sleep Quality"
        case .hrv: "Heart Rate Variability"
        case .skinAnalysis: "Skin Analysis"
        case .adherence: "Protocol Adherence"
        case .activity: "Activity & Fitness"
        case .circadian: "Circadian Rhythm"
        }
    }

    var icon: String {
        switch self {
        case .sleep: "moon.fill"
        case .hrv: "heart.text.square"
        case .skinAnalysis: "viewfinder"
        case .adherence: "checkmark.circle.fill"
        case .activity: "figure.run"
        case .circadian: "sun.and.horizon"
        }
    }

    var requiresWatch: Bool {
        switch self {
        case .sleep, .hrv, .activity, .circadian: true
        case .skinAnalysis, .adherence: false
        }
    }

    var weight: Double {
        switch self {
        case .sleep: 0.20
        case .hrv: 0.15
        case .skinAnalysis: 0.25
        case .adherence: 0.20
        case .activity: 0.10
        case .circadian: 0.10
        }
    }

    var noWatchWeight: Double {
        switch self {
        case .skinAnalysis: 0.55
        case .adherence: 0.45
        default: 0
        }
    }
}
