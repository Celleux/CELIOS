import SwiftData
import Foundation

@Model
final class DailyCheckIn {
    var date: Date
    var mood: String
    var energy: String
    var note: String
    var adherence: Bool
    var skinScanCompleted: Bool

    init(date: Date = Date(), mood: String = "", energy: String = "", note: String = "", adherence: Bool = false, skinScanCompleted: Bool = false) {
        self.date = date
        self.mood = mood
        self.energy = energy
        self.note = note
        self.adherence = adherence
        self.skinScanCompleted = skinScanCompleted
    }
}
