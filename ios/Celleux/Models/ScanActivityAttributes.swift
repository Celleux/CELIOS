import ActivityKit
import Foundation

nonisolated struct ScanActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable, Sendable {
        var progress: Double
        var statusText: String
        var detailText: String
        var currentMetric: String
        var estimatedSecondsRemaining: Int
    }

    let scanStartDate: Date
}
