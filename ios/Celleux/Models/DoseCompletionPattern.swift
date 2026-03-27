import SwiftData
import Foundation

@Model
final class DoseCompletionPattern {
    var category: String
    var scheduledMinuteOfDay: Int
    var actualMinuteOfDay: Int
    var date: Date
    var delayMinutes: Int

    init(category: String, scheduledMinuteOfDay: Int, actualMinuteOfDay: Int, date: Date = Date(), delayMinutes: Int = 0) {
        self.category = category
        self.scheduledMinuteOfDay = scheduledMinuteOfDay
        self.actualMinuteOfDay = actualMinuteOfDay
        self.date = date
        self.delayMinutes = delayMinutes
    }
}
