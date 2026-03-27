import SwiftData
import Foundation

@Model
final class UserProfile {
    var name: String
    var ageRange: String
    var goals: [String]
    var skinConcerns: [String]
    var gender: String
    var skinType: String
    var createdAt: Date

    init(name: String, ageRange: String = "", goals: [String] = [], skinConcerns: [String] = [], gender: String = "", skinType: String = "", createdAt: Date = Date()) {
        self.name = name
        self.ageRange = ageRange
        self.goals = goals
        self.skinConcerns = skinConcerns
        self.gender = gender
        self.skinType = skinType
        self.createdAt = createdAt
    }
}

nonisolated enum FitzpatrickType: String, CaseIterable, Identifiable, Sendable {
    case typeI = "Type I"
    case typeII = "Type II"
    case typeIII = "Type III"
    case typeIV = "Type IV"
    case typeV = "Type V"
    case typeVI = "Type VI"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .typeI: "Very Fair"
        case .typeII: "Fair"
        case .typeIII: "Medium"
        case .typeIV: "Olive"
        case .typeV: "Brown"
        case .typeVI: "Dark"
        }
    }

    var badge: String { "\(rawValue) · \(label)" }
}
