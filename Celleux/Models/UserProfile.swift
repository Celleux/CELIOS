import SwiftData
import Foundation

@Model
final class UserProfile {
    var name: String
    var ageRange: String
    var goals: [String]
    var skinConcerns: [String]
    var gender: String
    var createdAt: Date

    init(name: String, ageRange: String = "", goals: [String] = [], skinConcerns: [String] = [], gender: String = "", createdAt: Date = Date()) {
        self.name = name
        self.ageRange = ageRange
        self.goals = goals
        self.skinConcerns = skinConcerns
        self.gender = gender
        self.createdAt = createdAt
    }
}
