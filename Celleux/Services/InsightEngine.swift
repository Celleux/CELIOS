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

@Observable
final class InsightEngine {
    private let healthService = HealthKitService.shared
    private let correlationService = SkinHealthCorrelationService.shared

    var insights: [PersonalInsight] = []
    var isLoading: Bool = false

    func generateInsights(
        scans: [SkinScanRecord],
        longevityScores: [DailyLongevityScore],
        modelContext: ModelContext
    ) {
        isLoading = true
        var all: [PersonalInsight] = []

        let sortedScans = scans.sorted { $0.date < $1.date }

        all.append(contentsOf: generateTrendAlerts(from: sortedScans))
        all.append(contentsOf: generateCorrelationDiscoveries(from: longevityScores))
        all.append(contentsOf: generateActionItems())
        all.append(contentsOf: generateCelebrations(from: sortedScans))
        all.append(contentsOf: generateWeeklySummary(scans: sortedScans, longevityScores: longevityScores, modelContext: modelContext))

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

        let metrics: [(name: String, old: Double, new: Double, icon: String)] = [
            ("overall score", Double(oldest.overallScore), Double(newest.overallScore), "face.smiling"),
            ("texture", oldest.textureEvennessScore, newest.textureEvennessScore, "circle.grid.cross"),
            ("hydration", oldest.apparentHydrationScore, newest.apparentHydrationScore, "drop.fill"),
            ("brightness", oldest.brightnessRadianceScore, newest.brightnessRadianceScore, "sparkles"),
            ("redness", oldest.rednessScore, newest.rednessScore, "flame"),
            ("pore visibility", oldest.poreVisibilityScore, newest.poreVisibilityScore, "circle.dotted"),
            ("tone uniformity", oldest.toneUniformityScore, newest.toneUniformityScore, "circle.lefthalf.filled"),
            ("wrinkle depth", oldest.wrinkleDepthScore, newest.wrinkleDepthScore, "line.3.horizontal.decrease"),
            ("elasticity", oldest.elasticityProxyScore, newest.elasticityProxyScore, "arrow.up.and.down.circle"),
        ]

        for metric in metrics {
            let delta = metric.new - metric.old
            guard abs(delta) >= 3 else { continue }

            let direction = delta > 0 ? "improved" : "dropped"
            let absPoints = Int(abs(delta))
            let isPositive: Bool
            if metric.name == "redness" || metric.name == "pore visibility" {
                isPositive = delta < 0
            } else {
                isPositive = delta > 0
            }

            let title = isPositive
                ? "Your \(metric.name) is trending up"
                : "Your \(metric.name) needs attention"

            let body = "Your \(metric.name) \(direction) \(absPoints) points over your last \(recentScans.count) scans."

            let detail = isPositive
                ? "Keep up your current routine — it's working well for your \(metric.name)."
                : "Consider adjusting your routine to support \(metric.name) improvement."

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
        let stats = correlationService.computeCorrelationStats(from: scores)
        guard !stats.isEmpty else { return [] }

        return stats.map { stat in
            PersonalInsight(
                type: .correlationDiscovery,
                title: "\(stat.factor) & Skin Connection",
                body: stat.description,
                detail: "This pattern was found by analyzing your historical data. Stronger correlations appear with more consistent tracking.",
                icon: iconForFactor(stat.factor),
                actionLabel: "View Correlations",
                actionDestination: .openHealth,
                priority: abs(stat.delta) > 8 ? 6 : 4,
                timestamp: Date()
            )
        }
    }

    // MARK: - Action Items

    private func generateActionItems() -> [PersonalInsight] {
        var results: [PersonalInsight] = []

        if let hours = healthService.sleepData.totalHours, hours < 6 {
            results.append(PersonalInsight(
                type: .actionItem,
                title: "Your skin repair cycle needs help",
                body: String(format: "You slept %.1f hours last night — below the 7-hour minimum for optimal collagen synthesis.", hours),
                detail: "Try setting a consistent bedtime and avoid screens 1 hour before sleep. Even 30 extra minutes makes a measurable difference.",
                icon: "moon.zzz.fill",
                actionLabel: "Sleep Tips",
                actionDestination: .tip("Aim for 7-9 hours of sleep. Keep your room cool (65-68°F) and dark for best skin recovery."),
                priority: 8,
                timestamp: Date()
            ))
        }

        if let waterMl = healthService.todayWaterIntake, waterMl < 2000 {
            let remaining = Int(2500 - waterMl)
            results.append(PersonalInsight(
                type: .actionItem,
                title: "Hydration is below your baseline",
                body: String(format: "You've had %.1fL today — about %dml short of your target.", waterMl / 1000, max(0, remaining)),
                detail: "Drink a glass of water now and set hourly reminders. Electrolytes improve absorption.",
                icon: "drop.fill",
                actionLabel: "Hydrate Now",
                actionDestination: .tip("Aim for 2.5L of water daily. Add a pinch of sea salt or electrolytes for better cellular hydration."),
                priority: 7,
                timestamp: Date()
            ))
        }

        if let uvDose = healthService.todayUVExposure, uvDose > 5 {
            results.append(PersonalInsight(
                type: .actionItem,
                title: "High UV detected — protect your skin",
                body: String(format: "UV exposure today: %.1f — above the safe threshold for skin longevity.", uvDose),
                detail: "Reapply SPF 50+ every 2 hours when outdoors. Seek shade during peak UV hours (10 AM–4 PM).",
                icon: "sun.max.trianglebadge.exclamationmark.fill",
                actionLabel: "SPF Reminder",
                actionDestination: .tip("Apply broad-spectrum SPF 50+ generously. UV damage is cumulative and accelerates photoaging."),
                priority: 9,
                timestamp: Date()
            ))
        }

        if let hrv = healthService.latestHRV, hrv < 35 {
            results.append(PersonalInsight(
                type: .actionItem,
                title: "Elevated stress may affect your skin",
                body: String(format: "Your HRV is %.0f ms — indicating higher stress load. Cortisol can break down collagen and trigger inflammation.", hrv),
                detail: "Try 5 minutes of deep breathing or a short walk. Brief relaxation measurably lowers cortisol.",
                icon: "brain.head.profile",
                actionLabel: "Breathe",
                actionDestination: .openProtocol,
                priority: 7,
                timestamp: Date()
            ))
        }

        if correlationService.stressRiskLevel == .high {
            results.append(PersonalInsight(
                type: .actionItem,
                title: "Skin flare-up risk is elevated",
                body: "Low HRV combined with negative mood increases your risk of stress-related skin issues today.",
                detail: "Consider a calming activity: meditation, gentle stretching, or a warm bath with magnesium salts.",
                icon: "exclamationmark.triangle.fill",
                actionLabel: "Calm Down",
                actionDestination: .tip("Even 5 minutes of calm focus can reduce cortisol. Try the breathing timer in your protocol view."),
                priority: 10,
                timestamp: Date()
            ))
        }

        return results
    }

    // MARK: - Celebrations

    private func generateCelebrations(from scans: [SkinScanRecord]) -> [PersonalInsight] {
        guard scans.count >= 2 else { return [] }
        var results: [PersonalInsight] = []

        let latest = scans.last!
        let previousBest = scans.dropLast().map(\.overallScore).max() ?? 0

        if latest.overallScore > previousBest && previousBest > 0 {
            results.append(PersonalInsight(
                type: .celebration,
                title: "New personal best!",
                body: "Your overall score hit \(latest.overallScore) — that's the highest you've ever recorded.",
                detail: "Your consistency is paying off. Keep following your current routine to maintain this momentum.",
                icon: "trophy.fill",
                actionLabel: nil,
                actionDestination: nil,
                priority: 8,
                timestamp: latest.date
            ))
        }

        let metricChecks: [(name: String, keyPath: KeyPath<SkinScanRecord, Double>, icon: String)] = [
            ("texture", \.textureEvennessScore, "circle.grid.cross"),
            ("hydration", \.apparentHydrationScore, "drop.fill"),
            ("brightness", \.brightnessRadianceScore, "sparkles"),
            ("tone uniformity", \.toneUniformityScore, "circle.lefthalf.filled"),
            ("elasticity", \.elasticityProxyScore, "arrow.up.and.down.circle"),
        ]

        for metric in metricChecks {
            let latestVal = latest[keyPath: metric.keyPath]
            let prevBest = scans.dropLast().map { $0[keyPath: metric.keyPath] }.max() ?? 0
            guard latestVal > prevBest && prevBest > 0 && (latestVal - prevBest) >= 2 else { continue }

            results.append(PersonalInsight(
                type: .celebration,
                title: "Personal best \(metric.name)!",
                body: String(format: "Your %@ reached %.0f — a new high for you.", metric.name, latestVal),
                detail: "Whatever you've been doing for \(metric.name) is working. Keep it up!",
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
        longevityScores: [DailyLongevityScore],
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

        var bodyParts: [String] = []
        if skinDelta > 0 {
            bodyParts.append("skin +\(skinDelta)")
        } else if skinDelta < 0 {
            bodyParts.append("skin \(skinDelta)")
        } else {
            bodyParts.append("skin steady")
        }

        if let hours = healthService.sleepData.totalHours {
            if hours >= 7.5 {
                bodyParts.append("sleep improved")
            } else if hours >= 6 {
                bodyParts.append("sleep average")
            } else {
                bodyParts.append("sleep needs work")
            }
        }

        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let predicate = #Predicate<SupplementDose> { dose in
            dose.date >= weekStart && dose.isCompleted
        }
        let descriptor = FetchDescriptor<SupplementDose>(predicate: predicate)
        let completedCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        let totalPossible = 7 * 4
        let adherence = totalPossible > 0 ? min(100, (completedCount * 100) / totalPossible) : 0
        bodyParts.append("adherence \(adherence)%")

        let summaryBody = "This week: \(bodyParts.joined(separator: ", "))."
        let title = skinDelta > 0
            ? "Great week for your skin"
            : skinDelta == 0
                ? "Steady week — consistency counts"
                : "A challenging week — here's your plan"

        let detail = skinDelta >= 0
            ? "Your routine is supporting your skin well. Maintain your current habits for continued improvement."
            : "Don't worry — fluctuations are normal. Focus on sleep and hydration this coming week."

        return [PersonalInsight(
            type: .weeklySummary,
            title: title,
            body: summaryBody,
            detail: detail,
            icon: "calendar.badge.checkmark",
            actionLabel: "View Full Report",
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
