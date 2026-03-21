import SwiftData
import Foundation

@Model
final class AchievementRecord {
    var identifier: String
    var unlockedAt: Date?

    init(identifier: String, unlockedAt: Date? = nil) {
        self.identifier = identifier
        self.unlockedAt = unlockedAt
    }

    var isUnlocked: Bool { unlockedAt != nil }
}

nonisolated enum AchievementCategory: String, CaseIterable, Sendable {
    case scanMilestones = "Scan Milestones"
    case streaks = "Streaks"
    case score = "Score"
    case health = "Health"
    case ritual = "Ritual"
    case social = "Social"

    var icon: String {
        switch self {
        case .scanMilestones: "viewfinder"
        case .streaks: "flame.fill"
        case .score: "star.fill"
        case .health: "heart.fill"
        case .ritual: "leaf.fill"
        case .social: "square.and.arrow.up.fill"
        }
    }
}

nonisolated enum AchievementDefinition: String, CaseIterable, Identifiable, Sendable {
    case firstScan
    case scanTen
    case scanFifty
    case scanHundred
    case scanYear

    case streak3
    case consistent
    case streak14
    case committed
    case streak60
    case dedicated

    case personalBest
    case radiant
    case elite
    case perfectMetrics

    case healthConnected
    case sleepTracker
    case hrvMaster

    case ritualDay
    case ritualWeek
    case ritualMonth

    case firstShare
    case socialButterfly

    var id: String { rawValue }

    var category: AchievementCategory {
        switch self {
        case .firstScan, .scanTen, .scanFifty, .scanHundred, .scanYear:
            .scanMilestones
        case .streak3, .consistent, .streak14, .committed, .streak60, .dedicated:
            .streaks
        case .personalBest, .radiant, .elite, .perfectMetrics:
            .score
        case .healthConnected, .sleepTracker, .hrvMaster:
            .health
        case .ritualDay, .ritualWeek, .ritualMonth:
            .ritual
        case .firstShare, .socialButterfly:
            .social
        }
    }

    var title: String {
        switch self {
        case .firstScan: "First Scan"
        case .scanTen: "Skin Scientist"
        case .scanFifty: "Devoted"
        case .scanHundred: "Centurion"
        case .scanYear: "Year of Skin"
        case .streak3: "Getting Started"
        case .consistent: "Consistent"
        case .streak14: "Two Weeks Strong"
        case .committed: "Committed"
        case .streak60: "Iron Will"
        case .dedicated: "Dedicated"
        case .personalBest: "New Heights"
        case .radiant: "Radiant"
        case .elite: "Elite"
        case .perfectMetrics: "Flawless"
        case .healthConnected: "Data Driven"
        case .sleepTracker: "Sleep Watcher"
        case .hrvMaster: "HRV Master"
        case .ritualDay: "Perfect Day"
        case .ritualWeek: "Perfect Week"
        case .ritualMonth: "Perfect Month"
        case .firstShare: "First Share"
        case .socialButterfly: "Social Butterfly"
        }
    }

    var subtitle: String {
        switch self {
        case .firstScan: "Completed your first skin scan"
        case .scanTen: "Completed 10 skin scans"
        case .scanFifty: "Completed 50 skin scans"
        case .scanHundred: "Completed 100 skin scans"
        case .scanYear: "Completed 365 skin scans"
        case .streak3: "3-day adherence streak"
        case .consistent: "7-day adherence streak"
        case .streak14: "14-day adherence streak"
        case .committed: "30-day adherence streak"
        case .streak60: "60-day adherence streak"
        case .dedicated: "90-day adherence streak"
        case .personalBest: "Set a new personal best score"
        case .radiant: "Achieved a score of 80+"
        case .elite: "Achieved a score of 90+"
        case .perfectMetrics: "All metrics above 80"
        case .healthConnected: "Connected HealthKit"
        case .sleepTracker: "7 days of sleep tracking"
        case .hrvMaster: "30 days of HRV data"
        case .ritualDay: "100% ritual adherence in a day"
        case .ritualWeek: "100% ritual adherence for a week"
        case .ritualMonth: "100% ritual adherence for a month"
        case .firstShare: "Shared your results"
        case .socialButterfly: "Shared results 10 times"
        }
    }

    var icon: String {
        switch self {
        case .firstScan: "star.fill"
        case .scanTen: "microscope"
        case .scanFifty: "heart.circle.fill"
        case .scanHundred: "shield.checkered"
        case .scanYear: "calendar.badge.checkmark"
        case .streak3: "flame"
        case .consistent: "flame.fill"
        case .streak14: "bolt.fill"
        case .committed: "trophy.fill"
        case .streak60: "figure.strengthtraining.traditional"
        case .dedicated: "crown.fill"
        case .personalBest: "arrow.up.circle.fill"
        case .radiant: "sparkles"
        case .elite: "medal.fill"
        case .perfectMetrics: "checkmark.seal.fill"
        case .healthConnected: "heart.text.clipboard"
        case .sleepTracker: "moon.stars.fill"
        case .hrvMaster: "waveform.path.ecg"
        case .ritualDay: "sunrise.fill"
        case .ritualWeek: "leaf.fill"
        case .ritualMonth: "laurel.leading"
        case .firstShare: "square.and.arrow.up"
        case .socialButterfly: "person.2.fill"
        }
    }

    var points: Int {
        switch self {
        case .firstScan: 10
        case .scanTen: 25
        case .scanFifty: 75
        case .scanHundred: 150
        case .scanYear: 500
        case .streak3: 10
        case .consistent: 25
        case .streak14: 40
        case .committed: 75
        case .streak60: 150
        case .dedicated: 300
        case .personalBest: 20
        case .radiant: 50
        case .elite: 100
        case .perfectMetrics: 200
        case .healthConnected: 15
        case .sleepTracker: 30
        case .hrvMaster: 75
        case .ritualDay: 10
        case .ritualWeek: 50
        case .ritualMonth: 150
        case .firstShare: 10
        case .socialButterfly: 50
        }
    }

    static func definitions(for category: AchievementCategory) -> [AchievementDefinition] {
        allCases.filter { $0.category == category }
    }
}
