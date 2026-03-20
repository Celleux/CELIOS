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

nonisolated enum AchievementDefinition: String, CaseIterable, Identifiable, Sendable {
    case firstScan
    case consistent
    case committed
    case dedicated
    case skinScientist
    case nightOwl
    case earlyBird
    case dataDriven
    case verified
    case radiant
    case topTenPercent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstScan: "First Scan"
        case .consistent: "Consistent"
        case .committed: "Committed"
        case .dedicated: "Dedicated"
        case .skinScientist: "Skin Scientist"
        case .nightOwl: "Night Owl"
        case .earlyBird: "Early Bird"
        case .dataDriven: "Data Driven"
        case .verified: "Verified"
        case .radiant: "Radiant"
        case .topTenPercent: "Top 10%"
        }
    }

    var subtitle: String {
        switch self {
        case .firstScan: "Completed your first skin scan"
        case .consistent: "7-day adherence streak"
        case .committed: "30-day adherence streak"
        case .dedicated: "90-day adherence streak"
        case .skinScientist: "Completed 10 skin scans"
        case .nightOwl: "7 consecutive evening doses"
        case .earlyBird: "7 morning doses before 8am"
        case .dataDriven: "30 daily check-ins completed"
        case .verified: "NFC product verification"
        case .radiant: "Longevity score reached 80+"
        case .topTenPercent: "90%+ adherence over 30 days"
        }
    }

    var icon: String {
        switch self {
        case .firstScan: "star.fill"
        case .consistent: "flame.fill"
        case .committed: "trophy.fill"
        case .dedicated: "crown.fill"
        case .skinScientist: "microscope"
        case .nightOwl: "moon.stars.fill"
        case .earlyBird: "sunrise.fill"
        case .dataDriven: "chart.bar.fill"
        case .verified: "checkmark.seal.fill"
        case .radiant: "sparkles"
        case .topTenPercent: "medal.fill"
        }
    }
}
