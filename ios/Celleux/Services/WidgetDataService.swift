import Foundation
import WidgetKit

final class WidgetDataService {
    static let shared = WidgetDataService()

    private let suiteName = "group.app.rork.celleux-new-ui"
    private let widgetKind = "SkinScoreWidget"

    private enum Keys {
        static let skinScore = "widgetSkinScore"
        static let skinTrend = "widgetSkinTrend"
        static let lastScanDate = "widgetLastScanDate"
        static let textureScore = "widgetTextureScore"
        static let hydrationScore = "widgetHydrationScore"
        static let radianceScore = "widgetRadianceScore"
    }

    private var shared: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    func writeAllData(
        score: Int,
        trend: String,
        lastScanDate: Date?,
        textureScore: Int,
        hydrationScore: Int,
        radianceScore: Int
    ) {
        guard let defaults = shared else { return }
        defaults.set(score, forKey: Keys.skinScore)
        defaults.set(trend, forKey: Keys.skinTrend)
        if let date = lastScanDate {
            defaults.set(date.timeIntervalSince1970, forKey: Keys.lastScanDate)
        }
        defaults.set(textureScore, forKey: Keys.textureScore)
        defaults.set(hydrationScore, forKey: Keys.hydrationScore)
        defaults.set(radianceScore, forKey: Keys.radianceScore)
        defaults.synchronize()
        reloadTimelines()
    }

    func writeScanResult(
        score: Int,
        textureScore: Int,
        hydrationScore: Int,
        radianceScore: Int
    ) {
        guard let defaults = shared else { return }
        defaults.set(score, forKey: Keys.skinScore)
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastScanDate)
        defaults.set(textureScore, forKey: Keys.textureScore)
        defaults.set(hydrationScore, forKey: Keys.hydrationScore)
        defaults.set(radianceScore, forKey: Keys.radianceScore)
        defaults.synchronize()
        reloadTimelines()
    }

    func writeTrend(_ trend: String) {
        guard let defaults = shared else { return }
        defaults.set(trend, forKey: Keys.skinTrend)
        defaults.synchronize()
    }

    func readData() -> WidgetSkinData {
        guard let defaults = shared else {
            return WidgetSkinData.empty
        }
        let score = defaults.integer(forKey: Keys.skinScore)
        let trend = defaults.string(forKey: Keys.skinTrend) ?? "stable"
        let lastScanInterval = defaults.double(forKey: Keys.lastScanDate)
        let lastScanDate = lastScanInterval > 0 ? Date(timeIntervalSince1970: lastScanInterval) : nil
        let texture = defaults.integer(forKey: Keys.textureScore)
        let hydration = defaults.integer(forKey: Keys.hydrationScore)
        let radiance = defaults.integer(forKey: Keys.radianceScore)

        return WidgetSkinData(
            score: score,
            trend: trend,
            lastScanDate: lastScanDate,
            textureScore: texture,
            hydrationScore: hydration,
            radianceScore: radiance
        )
    }

    func reloadTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}

nonisolated struct WidgetSkinData: Sendable {
    let score: Int
    let trend: String
    let lastScanDate: Date?
    let textureScore: Int
    let hydrationScore: Int
    let radianceScore: Int

    static let empty = WidgetSkinData(
        score: 0,
        trend: "stable",
        lastScanDate: nil,
        textureScore: 0,
        hydrationScore: 0,
        radianceScore: 0
    )
}
