import Foundation
import SwiftData

nonisolated enum PersonalInsightType: String, Sendable {
    case trendAlert
    case correlationDiscovery
    case actionItem
    case celebration
    case weeklySummary
}

nonisolated struct PersonalInsight: Identifiable, Sendable {
    let id = UUID()
    let type: PersonalInsightType
    let title: String
    let body: String
    let detail: String?
    let icon: String
    let actionLabel: String?
    let actionDestination: InsightAction?
    let priority: Int
    let timestamp: Date

    var accentColor: String {
        switch type {
        case .celebration: return "gold"
        case .trendAlert: return "silver"
        case .actionItem: return "amber"
        case .correlationDiscovery: return "champagne"
        case .weeklySummary: return "muted"
        }
    }
}

nonisolated struct InsightDataSources: Sendable {
    let hasScans: Bool
    let hasHealthKit: Bool
    let hasSupplements: Bool

    var activeCount: Int {
        [hasScans, hasHealthKit, hasSupplements].filter { $0 }.count
    }

    var hasAnyData: Bool { activeCount > 0 }
}

@Observable
final class InsightEngine {
    private let healthService = HealthKitService.shared
    private let correlationService = SkinHealthCorrelationService.shared

    var insights: [PersonalInsight] = []
    var isLoading: Bool = false
    var dataSources: InsightDataSources = InsightDataSources(hasScans: false, hasHealthKit: false, hasSupplements: false)

    func generateInsights(
        scans: [SkinScanRecord],
        longevityScores: [DailyLongevityScore],
        modelContext: ModelContext
    ) {
        isLoading = true

        let sortedScans = scans.sorted { $0.date < $1.date }
        let hasWatch = healthService.hasWatchData
        let hasEnoughScans = sortedScans.count >= 3

        let today = Calendar.current.startOfDay(for: Date())
        let weekStart = Calendar.current.date(byAdding: .day, value: -6, to: today) ?? today
        let supplementPredicate = #Predicate<SupplementDose> { dose in
            dose.date >= weekStart
        }
        let supplementDescriptor = FetchDescriptor<SupplementDose>(predicate: supplementPredicate)
        let supplementCount = (try? modelContext.fetchCount(supplementDescriptor)) ?? 0
        let hasSupplements = supplementCount > 0

        dataSources = InsightDataSources(
            hasScans: !sortedScans.isEmpty,
            hasHealthKit: hasWatch,
            hasSupplements: hasSupplements
        )

        var all: [PersonalInsight] = []

        if hasEnoughScans {
            all.append(contentsOf: generateTrendAlerts(from: sortedScans))
            all.append(contentsOf: generateCelebrations(from: sortedScans))
        }

        if hasWatch {
            all.append(contentsOf: generateCorrelationDiscoveries(from: longevityScores))
            all.append(contentsOf: generateHealthActionItems())
        }

        if hasEnoughScans {
            all.append(contentsOf: generateWeeklySummary(
                scans: sortedScans,
                hasWatch: hasWatch,
                hasSupplements: hasSupplements,
                modelContext: modelContext
            ))
        }

        insights = all.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            return lhs.timestamp > rhs.timestamp
        }
        isLoading = false
    }

    // MARK: - Trend Alerts

    private func generateTrendAlerts(from scans: [SkinScanRecord]) -> [PersonalInsight] {
        guard scans.count >= 3 else { return [] }
        var results: [PersonalInsight] = []

        let recentScans = Array(scans.suffix(5))
        guard recentScans.count >= 3 else { return [] }
        let oldest = recentScans.first!
        let newest = recentScans.last!
        let scanSpan = recentScans.count

        let metrics: [(name: String, old: Double, new: Double, icon: String, tip: String)] = [
            ("overall score", Double(oldest.overallScore), Double(newest.overallScore), "face.smiling",
             "Stay consistent with your current routine — your skin is responding well."),
            ("texture", oldest.textureEvennessScore, newest.textureEvennessScore, "circle.grid.cross",
             "Gentle exfoliation 2–3 times a week can help maintain smooth texture."),
            ("hydration", oldest.apparentHydrationScore, newest.apparentHydrationScore, "drop.fill",
             "A glass of water and a hydrating serum can help your skin bounce back."),
            ("brightness", oldest.brightnessRadianceScore, newest.brightnessRadianceScore, "sparkles",
             "Vitamin C serum in the morning helps protect and enhance your natural glow."),
            ("redness", oldest.rednessScore, newest.rednessScore, "flame",
             "A calming moisturizer with centella or niacinamide can soothe redness over time."),
            ("pore visibility", oldest.poreVisibilityScore, newest.poreVisibilityScore, "circle.dotted",
             "Consistent cleansing and a BHA toner can help keep pores refined."),
            ("tone uniformity", oldest.toneUniformityScore, newest.toneUniformityScore, "circle.lefthalf.filled",
             "Daily SPF is the single best thing you can do for even skin tone."),
            ("wrinkle depth", oldest.wrinkleDepthScore, newest.wrinkleDepthScore, "line.3.horizontal.decrease",
             "Retinol at night and SPF during the day are your best allies here."),
            ("elasticity", oldest.elasticityProxyScore, newest.elasticityProxyScore, "arrow.up.and.down.circle",
             "Collagen-supporting supplements and good sleep help maintain skin elasticity."),
        ]

        for metric in metrics {
            let delta = metric.new - metric.old
            guard abs(delta) >= 3 else { continue }

            let absPoints = Int(abs(delta))
            let isPositive: Bool
            if metric.name == "redness" || metric.name == "pore visibility" {
                isPositive = delta < 0
            } else {
                isPositive = delta > 0
            }

            let title: String
            let body: String
            let detail: String

            if isPositive {
                title = "Your \(metric.name) is looking great"
                body = "Up \(absPoints) points over your last \(scanSpan) scans — whatever you're doing is working beautifully."
                detail = "This kind of steady improvement is exactly what healthy skin looks like. \(metric.tip)"
            } else {
                title = "A little dip in \(metric.name)"
                body = "Down \(absPoints) points over your last \(scanSpan) scans — totally normal, and easy to turn around."
                detail = "Small fluctuations happen to everyone. \(metric.tip)"
            }

            results.append(PersonalInsight(
                type: .trendAlert,
                title: title,
                body: body,
                detail: detail,
                icon: metric.icon,
                actionLabel: "View Scan History",
                actionDestination: .openScan,
                priority: isPositive ? 5 : 7,
                timestamp: newest.date
            ))
        }

        return results
    }

    // MARK: - Correlation Discoveries

    private func generateCorrelationDiscoveries(from scores: [DailyLongevityScore]) -> [PersonalInsight] {
        guard healthService.hasWatchData else { return [] }
        let stats = correlationService.computeCorrelationStats(from: scores)
        guard !stats.isEmpty else { return [] }

        return stats.map { stat in
            let warmDetail = "We noticed this by looking at your personal history. The more you track, the sharper these patterns become — you're building a unique picture of what works for your skin."

            return PersonalInsight(
                type: .correlationDiscovery,
                title: "Your \(stat.factor.lowercased()) & skin are connected",
                body: stat.description,
                detail: warmDetail,
                icon: iconForFactor(stat.factor),
                actionLabel: "Explore This Pattern",
                actionDestination: .openHealth,
                priority: abs(stat.delta) > 8 ? 6 : 4,
                timestamp: Date()
            )
        }
    }

    // MARK: - Health Action Items

    private func generateHealthActionItems() -> [PersonalInsight] {
        guard healthService.hasWatchData else { return [] }
        var results: [PersonalInsight] = []

        if let hours = healthService.sleepData.totalHours, hours < 6 {
            let deficit = String(format: "%.1f", 7.0 - hours)
            results.append(PersonalInsight(
                type: .actionItem,
                title: "Your skin could use more rest tonight",
                body: String(format: "Last night was %.1f hours — about %@ hours short of your skin's sweet spot. Your body does its best repair work during deep sleep.", hours, deficit),
                detail: "Tonight, try winding down 30 minutes earlier. Dim the lights, put your phone away, and let your skin do its overnight recovery. Even one extra hour can make a visible difference by morning.",
                icon: "moon.zzz.fill",
                actionLabel: "Set a Bedtime Reminder",
                actionDestination: .tip("Try going to bed 30 minutes earlier tonight. Keep your room cool (65–68°F) and dark for the best skin recovery."),
                priority: 8,
                timestamp: Date()
            ))
        }

        if let waterMl = healthService.todayWaterIntake, waterMl < 2000 {
            let glassesLeft = max(1, Int((2500 - waterMl) / 250))
            results.append(PersonalInsight(
                type: .actionItem,
                title: "Your skin is thirsty",
                body: String(format: "You've had about %.1fL so far today. Just %d more glasses of water and you'll be back on track.", waterMl / 1000, glassesLeft),
                detail: "Grab a glass right now — your skin barrier needs steady hydration to stay plump and resilient. Adding a pinch of electrolytes helps your cells absorb water better.",
                icon: "drop.fill",
                actionLabel: "Log a Glass",
                actionDestination: .tip("Pour yourself a glass of water right now. Aim for 2–2.5L throughout the day for well-hydrated skin."),
                priority: 7,
                timestamp: Date()
            ))
        }

        if let uvDose = healthService.todayUVExposure, uvDose > 5 {
            results.append(PersonalInsight(
                type: .actionItem,
                title: "High UV today — your skin needs extra protection",
                body: String(format: "UV index reached %.1f today. That level of exposure speeds up photoaging if your skin isn't shielded.", uvDose),
                detail: "If you're heading outside, reapply SPF 50+ now. Seek shade between 10 AM and 4 PM when rays are strongest. A wide-brim hat is your skin's best friend on days like this.",
                icon: "sun.max.trianglebadge.exclamationmark.fill",
                actionLabel: "SPF Reminder Set",
                actionDestination: .tip("Apply broad-spectrum SPF 50+ generously. UV damage adds up over time — protecting now pays off for years."),
                priority: 9,
                timestamp: Date()
            ))
        }

        if let hrv = healthService.latestHRV, hrv < 35 {
            results.append(PersonalInsight(
                type: .actionItem,
                title: "Your body is carrying some stress today",
                body: String(format: "Your HRV is %.0f ms — lower than usual, which means stress hormones like cortisol may be elevated. That can show up on your skin as inflammation or breakouts.", hrv),
                detail: "Take 5 minutes for yourself right now. A few slow, deep breaths can lower cortisol noticeably. Even a short walk outside helps your body reset. Your skin will thank you.",
                icon: "brain.head.profile",
                actionLabel: "Start Breathing Timer",
                actionDestination: .openProtocol,
                priority: 7,
                timestamp: Date()
            ))
        }

        if correlationService.stressRiskLevel == .high {
            results.append(PersonalInsight(
                type: .actionItem,
                title: "Let's take care of you today",
                body: "Your stress markers are elevated — low HRV combined with your mood means your skin is more vulnerable to flare-ups right now.",
                detail: "This is a great time for something calming: a warm bath, gentle stretching, or just sitting quietly for a few minutes. Your skin's stress response calms down when you do. Try the breathing timer in your protocol.",
                icon: "leaf.fill",
                actionLabel: "Open Breathing Timer",
                actionDestination: .openProtocol,
                priority: 10,
                timestamp: Date()
            ))
        }

        return results
    }

    // MARK: - Celebrations

    private func generateCelebrations(from scans: [SkinScanRecord]) -> [PersonalInsight] {
        guard scans.count >= 3 else { return [] }
        var results: [PersonalInsight] = []

        let latest = scans.last!
        let previousBest = scans.dropLast().map(\.overallScore).max() ?? 0

        if latest.overallScore > previousBest && previousBest > 0 {
            results.append(PersonalInsight(
                type: .celebration,
                title: "You just set a new personal best!",
                body: "Your overall score reached \(latest.overallScore) — the highest you've ever recorded. Your consistency is truly paying off.",
                detail: "This is what happens when you show up for your skin day after day. You've earned this. Keep riding the momentum — your routine is clearly working.",
                icon: "trophy.fill",
                actionLabel: nil,
                actionDestination: nil,
                priority: 8,
                timestamp: latest.date
            ))
        }

        let metricChecks: [(name: String, keyPath: KeyPath<SkinScanRecord, Double>, icon: String, cheerMsg: String)] = [
            ("texture", \.textureEvennessScore, "circle.grid.cross",
             "Smoother skin doesn't happen by accident — your care routine is making a real difference."),
            ("hydration", \.apparentHydrationScore, "drop.fill",
             "Well-hydrated skin is happy skin. Whatever you're drinking and applying, keep it up!"),
            ("brightness", \.brightnessRadianceScore, "sparkles",
             "That natural glow? You've earned it. Your skin is radiant."),
            ("tone uniformity", \.toneUniformityScore, "circle.lefthalf.filled",
             "More even tone means your skin is healthy at a deeper level. Wonderful progress."),
            ("elasticity", \.elasticityProxyScore, "arrow.up.and.down.circle",
             "Better elasticity is a sign of strong, resilient skin. You're doing great."),
        ]

        for metric in metricChecks {
            let latestVal = latest[keyPath: metric.keyPath]
            let prevBest = scans.dropLast().map { $0[keyPath: metric.keyPath] }.max() ?? 0
            guard latestVal > prevBest && prevBest > 0 && (latestVal - prevBest) >= 2 else { continue }

            results.append(PersonalInsight(
                type: .celebration,
                title: "New \(metric.name) personal best!",
                body: String(format: "Your %@ just hit %.0f — a new high for you.", metric.name, latestVal),
                detail: metric.cheerMsg,
                icon: metric.icon,
                actionLabel: nil,
                actionDestination: nil,
                priority: 6,
                timestamp: latest.date
            ))
        }

        return results
    }

    // MARK: - Weekly Summary

    private func generateWeeklySummary(
        scans: [SkinScanRecord],
        hasWatch: Bool,
        hasSupplements: Bool,
        modelContext: ModelContext
    ) -> [PersonalInsight] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let hour = calendar.component(.hour, from: Date())

        guard weekday == 1 || (scans.count >= 2 && hour >= 18) else { return [] }

        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekScans = scans.filter { $0.date >= sevenDaysAgo }

        guard weekScans.count >= 2 else { return [] }

        let firstScore = weekScans.first!.overallScore
        let lastScore = weekScans.last!.overallScore
        let skinDelta = lastScore - firstScore

        var highlights: [String] = []

        if skinDelta > 0 {
            highlights.append("your skin improved by \(skinDelta) points")
        } else if skinDelta < 0 {
            highlights.append("your skin dipped \(abs(skinDelta)) points — nothing to worry about")
        } else {
            highlights.append("your skin held steady — consistency pays off")
        }

        if hasWatch, let hours = healthService.sleepData.totalHours {
            if hours >= 7.5 {
                highlights.append("sleep was solid at \(String(format: "%.1f", hours)) hours")
            } else if hours >= 6 {
                highlights.append("sleep was okay but could be better")
            } else {
                highlights.append("sleep was light — an earlier bedtime could help")
            }
        }

        if hasSupplements {
            let today = calendar.startOfDay(for: Date())
            let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            let predicate = #Predicate<SupplementDose> { dose in
                dose.date >= weekStart && dose.isCompleted
            }
            let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)
            let completedCount = (try? modelContext.fetchCount(descriptor)) ?? 0
            let totalPossible = 7 * 4
            let adherence = totalPossible > 0 ? min(100, (completedCount * 100) / totalPossible) : 0
            if adherence >= 80 {
                highlights.append("you nailed \(adherence)% of your supplements")
            } else if adherence > 0 {
                highlights.append("supplement adherence was \(adherence)% — every dose counts")
            }
        }

        let summaryBody = "This week, \(highlights.joined(separator: ", "))."

        let title: String
        let detail: String

        if skinDelta > 0 {
            title = "What a week for your skin"
            detail = "You're building real momentum. Keep doing what you're doing — your skin is clearly responding to your care."
        } else if skinDelta == 0 {
            title = "Steady week — that's a win"
            detail = "Holding your ground is progress too. Consistency is the foundation of great skin. You're doing the right things."
        } else {
            title = "A bumpy week — you've got this"
            detail = "Everyone has weeks like this. Your skin is resilient, and a few small adjustments can turn things around fast. Focus on sleep and hydration this coming week."
        }

        return [PersonalInsight(
            type: .weeklySummary,
            title: title,
            body: summaryBody,
            detail: detail,
            icon: "calendar.badge.checkmark",
            actionLabel: "See Full Breakdown",
            actionDestination: .openHealth,
            priority: 3,
            timestamp: Date()
        )]
    }

    // MARK: - Helpers

    private func iconForFactor(_ factor: String) -> String {
        switch factor.lowercased() {
        case "sleep": return "moon.fill"
        case "activity": return "figure.run"
        case "hydration": return "drop.fill"
        case "stress": return "brain.head.profile"
        default: return "chart.xyaxis.line"
        }
    }
}
