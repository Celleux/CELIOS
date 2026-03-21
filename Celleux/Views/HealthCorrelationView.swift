import SwiftUI
import Charts
import SwiftData

struct HealthCorrelationView: View {
    @State private var correlationService = SkinHealthCorrelationService.shared
    private let healthService = HealthKitService.shared
    @State private var appeared: Bool = false
    @State private var ringGlow: Bool = false
    @State private var moodHistory: [MoodEntry] = []
    @State private var selectedMoodDate: Date?
    @State private var selectedFactor: SkinHealthFactor?
    @State private var dailyScores: [DailyLongevityScore] = []
    @State private var sleepSkinPoints: [SleepSkinDataPoint] = []
    @State private var environmentalPeriod: SheetPeriod = .sevenDays
    @State private var selectedEnvDate: Date?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if !healthService.hasWatchData {
                    watchConnectionBanner
                        .staggeredAppear(appeared: appeared, delay: 0)
                }

                overallScoreSection
                    .staggeredAppear(appeared: appeared, delay: 0)

                correlationCardsSection
                    .staggeredAppear(appeared: appeared, delay: 0.06)

                sleepSkinCorrelationSection
                    .staggeredAppear(appeared: appeared, delay: 0.12)

                stressVisualizationSection
                    .staggeredAppear(appeared: appeared, delay: 0.18)

                environmentalFactorsSection
                    .staggeredAppear(appeared: appeared, delay: 0.22)

                environmentalImpactChartSection
                    .staggeredAppear(appeared: appeared, delay: 0.26)

                if !moodHistory.isEmpty {
                    moodTrendChart
                        .staggeredAppear(appeared: appeared, delay: 0.30)
                }

                if !correlationService.generateInsights().isEmpty {
                    insightsSection
                        .staggeredAppear(appeared: appeared, delay: 0.34)
                }

                skinImpactGuide
                    .staggeredAppear(appeared: appeared, delay: 0.38)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(CelleuxMeshBackground())
        .navigationTitle("Skin & Health")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await healthService.fetchAllData()
            correlationService.computeCorrelation()
            moodHistory = await healthService.queryMoodHistory(days: 30)
            loadDailyScores()
            withAnimation(.spring(duration: 0.8, bounce: 0.15)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
                ringGlow = true
            }
        }
        .sheet(item: $selectedFactor) { factor in
            FactorDetailSheet(
                factor: factor,
                score: scoreForFactor(factor),
                dailyScores: dailyScores,
                correlationService: correlationService,
                healthService: healthService
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationContentInteraction(.scrolls)
        }
    }

    private func loadDailyScores() {
        let calendar = Calendar.current
        guard let ninetyAgo = calendar.date(byAdding: .day, value: -90, to: Date()) else { return }
        let predicate = #Predicate<DailyLongevityScore> { s in s.date >= ninetyAgo }
        let descriptor = FetchDescriptor<DailyLongevityScore>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .forward)])
        dailyScores = (try? modelContext.fetch(descriptor)) ?? []
        sleepSkinPoints = correlationService.computeSleepSkinScatterData(from: dailyScores)
    }

    // MARK: - Overall Score

    private var overallScoreSection: some View {
        VStack(spacing: 20) {
            ZStack {
                LuxuryBezelRing(
                    progress: correlationService.overallCorrelationScore / 100,
                    size: 180,
                    lineWidth: 10,
                    glowing: $ringGlow
                )

                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(correlationService.overallCorrelationScore))")
                            .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .contentTransition(.numericText())

                        Text("/100")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    Text("SKIN HEALTH INDEX")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.45))
                        .tracking(0.8)
                        .textCase(.uppercase)
                }
            }
            .frame(maxWidth: .infinity)

            if let avgMood = healthService.averageMoodValence {
                moodIndicatorBadge(valence: avgMood)
            }
        }
        .padding(.vertical, 12)
    }

    private func moodIndicatorBadge(valence: Double) -> some View {
        let label: String
        let icon: String
        if valence > 0.3 { label = "Positive mood trend"; icon = "face.smiling" }
        else if valence > -0.3 { label = "Neutral mood trend"; icon = "face.smiling" }
        else { label = "Low mood detected"; icon = "cloud.rain" }

        return HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(valence > 0 ? CelleuxColors.warmGold : Color(hex: "FF9800"))

            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(valence > 0 ? CelleuxColors.warmGold : Color(hex: "FF9800"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(valence > 0 ? CelleuxColors.warmGold.opacity(0.08) : Color(hex: "FF9800").opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(valence > 0 ? CelleuxColors.warmGold.opacity(0.2) : Color(hex: "FF9800").opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Correlation Cards

    private var correlationCardsSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Health Factors")

            VStack(spacing: 12) {
                ForEach(SkinHealthFactor.allCases) { factor in
                    CorrelationFactorCard(
                        factor: factor,
                        score: scoreForFactor(factor),
                        currentValue: correlationService.currentValueString(for: factor),
                        hasData: correlationService.factorHasData(factor),
                        dailyScores: dailyScores,
                        impactLevel: correlationService.impactLevel(for: scoreForFactor(factor))
                    ) {
                        selectedFactor = factor
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedFactor)
    }

    // MARK: - Sleep-Skin Correlation

    private var sleepSkinCorrelationSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Sleep \u2194 Skin Correlation")

            GlassCard(depth: .elevated) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        ChromeIconBadge("moon.zzz.fill", size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sleep & Skin Score")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(CelleuxColors.textPrimary)
                            if let hours = healthService.sleepData.totalHours {
                                Text(String(format: "Last night: %.1fh", hours))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                        }
                        Spacer()
                    }

                    if sleepSkinPoints.count >= 5 {
                        sleepSkinScatterChart
                    } else {
                        sleepSkinEmptyState
                    }

                    if let insight = correlationService.computeSleepSkinInsight(from: sleepSkinPoints) {
                        HStack(spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CelleuxColors.warmGold)

                            Text(insight)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CelleuxColors.textSecondary)
                                .lineSpacing(2)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(CelleuxColors.warmGold.opacity(0.06))
                        )
                    }

                    if let hours = healthService.sleepData.totalHours, hours > 0 {
                        sleepBreakdownRow
                    }
                }
            }
        }
    }

    private var sleepSkinScatterChart: some View {
        let regression = correlationService.computeLinearRegression(from: sleepSkinPoints)
        let minX = (sleepSkinPoints.map(\.sleepHours).min() ?? 4) - 0.5
        let maxX = (sleepSkinPoints.map(\.sleepHours).max() ?? 10) + 0.5

        return Chart {
            ForEach(sleepSkinPoints) { point in
                PointMark(
                    x: .value("Sleep", point.sleepHours),
                    y: .value("Skin", point.skinScore)
                )
                .foregroundStyle(CelleuxColors.warmGold)
                .symbolSize(40)
            }

            if let reg = regression {
                let steps = stride(from: minX, through: maxX, by: 0.5)
                ForEach(Array(steps.enumerated()), id: \.offset) { _, x in
                    let band = correlationService.computeConfidenceBand(regression: reg, points: sleepSkinPoints, at: x)
                    AreaMark(
                        x: .value("Sleep", x),
                        yStart: .value("Lower", band.lower),
                        yEnd: .value("Upper", band.upper)
                    )
                    .foregroundStyle(CelleuxColors.warmGold.opacity(0.08))
                    .interpolationMethod(.catmullRom)
                }

                LineMark(
                    x: .value("Sleep", minX),
                    y: .value("Skin", reg.slope * minX + reg.intercept)
                )
                .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))

                LineMark(
                    x: .value("Sleep", maxX),
                    y: .value("Skin", reg.slope * maxX + reg.intercept)
                )
                .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
        }
        .chartXAxisLabel("Sleep (hours)", alignment: .center)
        .chartYAxisLabel("Skin Score")
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 4]))
                    .foregroundStyle(CelleuxColors.silver.opacity(0.15))
                AxisValueLabel()
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 4]))
                    .foregroundStyle(CelleuxColors.silver.opacity(0.15))
                AxisValueLabel()
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
        .frame(height: 200)
    }

    private var sleepSkinEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.dots.scatter")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(CelleuxColors.silver)

            Text("Keep scanning to unlock sleep-skin insights")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
                .multilineTextAlignment(.center)

            Text("\(sleepSkinPoints.count)/5 data points collected")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(CelleuxColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }

    private var sleepBreakdownRow: some View {
        HStack(spacing: 0) {
            sleepMetricPill(
                label: "Total",
                value: String(format: "%.1fh", healthService.sleepData.totalHours ?? 0)
            )
            Spacer()
            sleepMetricPill(
                label: "Deep",
                value: {
                    guard let total = healthService.sleepData.totalMinutes, total > 0,
                          let deep = healthService.sleepData.deepMinutes else { return "\u2014" }
                    return String(format: "%.0f%%", (deep / total) * 100)
                }()
            )
            Spacer()
            sleepMetricPill(
                label: "REM",
                value: {
                    guard let total = healthService.sleepData.totalMinutes, total > 0,
                          let rem = healthService.sleepData.remMinutes else { return "\u2014" }
                    return String(format: "%.0f%%", (rem / total) * 100)
                }()
            )
        }
    }

    private func sleepMetricPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CelleuxColors.textPrimary)
                .contentTransition(.numericText())
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stress Visualization

    private var stressVisualizationSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Stress & Recovery")

            GlassCard(depth: .elevated) {
                VStack(spacing: 16) {
                    HStack {
                        HStack(spacing: 8) {
                            ChromeIconBadge("brain.head.profile", size: 36,
                                gradient: stressGradient)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Stress Level")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(CelleuxColors.textPrimary)

                                Text(correlationService.stressRiskLevel.label)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color(hex: correlationService.stressRiskLevel.color))
                            }
                        }
                        Spacer()
                        stressRiskBadge
                    }

                    hrvTrendChart

                    HStack(spacing: 10) {
                        Image(systemName: stressInsightIcon)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(stressInsightColor)

                        Text(correlationService.stressInsight())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textSecondary)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(stressInsightColor.opacity(0.06))
                    )

                    if healthService.averageMoodValence == nil {
                        HStack(spacing: 8) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CelleuxColors.silver)
                            Text("Log your mood for deeper stress-skin analysis")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }
                }
            }
        }
    }

    private var stressGradient: LinearGradient {
        let riskColor = Color(hex: correlationService.stressRiskLevel.color)
        return LinearGradient(
            colors: [riskColor.opacity(0.8), riskColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var stressRiskBadge: some View {
        let risk = correlationService.stressRiskLevel
        return Text(risk.label)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color(hex: risk.color))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(hex: risk.color).opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(Color(hex: risk.color).opacity(0.25), lineWidth: 0.5)
            )
    }

    private var stressInsightIcon: String {
        switch correlationService.stressRiskLevel {
        case .high: "exclamationmark.triangle.fill"
        case .moderate: "info.circle.fill"
        case .low: "checkmark.circle.fill"
        case .unknown: "questionmark.circle"
        }
    }

    private var stressInsightColor: Color {
        switch correlationService.stressRiskLevel {
        case .high: Color(hex: "E53935")
        case .moderate: Color(hex: "FF9800")
        case .low: Color(hex: "4CAF50")
        case .unknown: CelleuxColors.silver
        }
    }

    private var hrvTrendChart: some View {
        let recentScores = Array(dailyScores.suffix(7))
        let hasHRVData = recentScores.contains { $0.hrvScore > 0 }

        return Group {
            if hasHRVData {
                Chart {
                    ForEach(Array(recentScores.enumerated()), id: \.offset) { _, score in
                        if score.hrvScore > 0 {
                            AreaMark(
                                x: .value("Date", score.date),
                                y: .value("HRV", score.hrvScore)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Date", score.date),
                                y: .value("HRV", score.hrvScore)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }
                    }

                    ForEach(recentMoodDotsForChart, id: \.date) { entry in
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("HRV", moodToHRVScale(entry.valence, scores: recentScores))
                        )
                        .foregroundStyle(entry.valence >= 0 ? CelleuxColors.warmGold : Color(hex: "FF9800"))
                        .symbolSize(25)
                        .symbol {
                            Circle()
                                .fill(entry.valence >= 0 ? CelleuxColors.warmGold : Color(hex: "FF9800"))
                                .frame(width: 6, height: 6)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 4]))
                            .foregroundStyle(CelleuxColors.silver.opacity(0.15))
                        AxisValueLabel()
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
                .frame(height: 160)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(CelleuxColors.silver)
                    Text("Connect Apple Watch for HRV stress tracking")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            }
        }
    }

    private var recentMoodDotsForChart: [MoodEntry] {
        guard !moodHistory.isEmpty, !dailyScores.isEmpty else { return [] }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return moodHistory.filter { $0.date >= sevenDaysAgo }
    }

    private func moodToHRVScale(_ valence: Double, scores: [DailyLongevityScore]) -> Double {
        let hrvScores = scores.compactMap { $0.hrvScore > 0 ? $0.hrvScore : nil }
        let minHRV = hrvScores.min() ?? 30
        let maxHRV = hrvScores.max() ?? 90
        let normalized = (valence + 1) / 2
        return minHRV + normalized * (maxHRV - minHRV)
    }

    // MARK: - Mood Trend Chart

    private var moodTrendChart: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Mood Trend (7 days)")

            GlassCard(depth: .elevated) {
                VStack(alignment: .leading, spacing: 12) {
                    Chart {
                        ForEach(Array(moodHistory.prefix(30).reversed().enumerated()), id: \.offset) { _, entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Valence", entry.valence)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                            AreaMark(
                                x: .value("Date", entry.date),
                                y: .value("Valence", entry.valence)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Valence", entry.valence)
                            )
                            .foregroundStyle(entry.valence >= 0 ? CelleuxColors.warmGold : Color(hex: "FF9800"))
                            .symbolSize(30)
                        }

                        RuleMark(y: .value("Neutral", 0))
                            .foregroundStyle(CelleuxColors.silver.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    }
                    .chartYScale(domain: -1...1)
                    .chartYAxis {
                        AxisMarks(values: [-1, -0.5, 0, 0.5, 1]) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 4]))
                                .foregroundStyle(CelleuxColors.silver.opacity(0.15))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(moodAxisLabel(v))
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(CelleuxColors.textLabel)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                            AxisValueLabel()
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }
                    .chartXSelection(value: $selectedMoodDate)
                    .frame(height: 200)

                    if let selected = selectedMoodDate,
                       let closest = moodHistory.min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }) {
                        HStack {
                            Text(closest.date, style: .date)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                            Spacer()
                            Text(moodValueLabel(closest.valence))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(closest.valence >= 0 ? CelleuxColors.warmGold : Color(hex: "FF9800"))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Skin-Health Insights")

            VStack(spacing: 10) {
                ForEach(correlationService.generateInsights()) { insight in
                    insightCard(insight)
                }
            }
        }
    }

    private func insightCard(_ insight: SkinCorrelationInsight) -> some View {
        CompactGlassCard(cornerRadius: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [insightColor(insight.severity).opacity(0.12), insightColor(insight.severity).opacity(0.02)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)

                    Circle()
                        .stroke(insightColor(insight.severity).opacity(0.3), lineWidth: 1)
                        .frame(width: 44, height: 44)

                    Image(systemName: insight.icon)
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(insightColor(insight.severity))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text(insight.detail)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .lineSpacing(2)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Watch Connection Banner

    private var watchConnectionBanner: some View {
        CompactGlassCard(cornerRadius: 20) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [CelleuxColors.silver.opacity(0.12), CelleuxColors.silver.opacity(0.02)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 22
                                )
                            )
                            .frame(width: 44, height: 44)

                        Circle()
                            .stroke(CelleuxColors.silver.opacity(0.3), lineWidth: 1)
                            .frame(width: 44, height: 44)

                        Image(systemName: "applewatch")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(CelleuxColors.silver)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connect Apple Watch")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)

                        Text("Unlock HRV, sleep stages, wrist temperature & activity tracking for deeper skin-health insights")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .lineSpacing(2)
                    }
                }

                HStack(spacing: 0) {
                    watchFactorPill(icon: "heart.text.square", label: "HRV")
                    Spacer()
                    watchFactorPill(icon: "moon.fill", label: "Sleep")
                    Spacer()
                    watchFactorPill(icon: "thermometer.medium", label: "Temp")
                    Spacer()
                    watchFactorPill(icon: "figure.run", label: "Activity")
                }
            }
        }
    }

    private func watchFactorPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(CelleuxColors.silver)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CelleuxColors.textLabel)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(CelleuxColors.silver.opacity(0.06))
        )
        .overlay(
            Capsule()
                .stroke(CelleuxColors.silver.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Environmental Factors

    private var environmentalFactorsSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Environmental Factors")

            VStack(spacing: 12) {
                uvExposureCard
                waterIntakeCard
                wristTemperatureCard
            }
        }
    }

    private var uvExposureCard: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        ChromeIconBadge("sun.max.fill", size: 36,
                            gradient: CelleuxColors.iconAmberGradient)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("UV Exposure")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(CelleuxColors.textPrimary)
                            if let uv = healthService.todayUVExposure {
                                Text(uvRiskLabel(uv))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(uvRiskColor(uv))
                            } else {
                                Text("No data today")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                        }
                    }
                    Spacer()
                    if let uv = healthService.todayUVExposure {
                        Text(String(format: "%.1f", uv))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText())
                    } else {
                        Text("\u2014")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }

                let uvData = recentUVData
                if uvData.contains(where: { $0.value > 0 }) {
                    envSparkline(data: uvData, color: CelleuxP3.chartGold)
                }

                if let uv = healthService.todayUVExposure {
                    uvImpactInsight(uv: uv)
                } else {
                    envEmptyPrompt(icon: "sun.max.fill", text: "UV data appears when your device detects sun exposure")
                }
            }
        }
    }

    private var waterIntakeCard: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        ChromeIconBadge("drop.fill", size: 36,
                            gradient: LinearGradient(
                                colors: [Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85).opacity(0.9), Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Water Intake")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(CelleuxColors.textPrimary)
                            if let water = healthService.todayWaterIntake {
                                Text(String(format: "%.0f mL of 2,500 mL", water))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            } else {
                                Text("No data logged")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                        }
                    }
                    Spacer()
                    waterProgressRing
                }

                let hydrationData = recentHydrationData
                if hydrationData.contains(where: { $0.value > 0 }) {
                    envSparkline(data: hydrationData, color: Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85))
                }

                if healthService.todayWaterIntake == nil {
                    envEmptyPrompt(icon: "drop.fill", text: "Log water intake in the Health app to track hydration")
                }
            }
        }
    }

    private var waterProgressRing: some View {
        let ratio = min(1.0, (healthService.todayWaterIntake ?? 0) / 2500)
        let hydrationColor = Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85)
        return ZStack {
            Circle()
                .stroke(hydrationColor.opacity(0.15), lineWidth: 5)
                .frame(width: 42, height: 42)

            Circle()
                .trim(from: 0, to: ratio)
                .stroke(hydrationColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 42, height: 42)
                .rotationEffect(.degrees(-90))

            if let water = healthService.todayWaterIntake {
                Text(String(format: "%.1fL", water / 1000))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(CelleuxColors.textPrimary)
            } else {
                Text("\u2014")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
    }

    private var wristTemperatureCard: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        ChromeIconBadge("thermometer.medium", size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wrist Temperature")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(CelleuxColors.textPrimary)
                            if let temp = healthService.latestWristTemperature {
                                Text(tempContextLabel(temp))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(tempContextColor(temp))
                            } else {
                                Text("Requires Apple Watch")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                        }
                    }
                    Spacer()
                    if let temp = healthService.latestWristTemperature {
                        HStack(spacing: 2) {
                            Text(String(format: "%+.1f", temp))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(CelleuxColors.textPrimary)
                                .contentTransition(.numericText())
                            Text("°C")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    } else {
                        Text("\u2014")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }

                if healthService.latestWristTemperature == nil {
                    envEmptyPrompt(icon: "applewatch", text: "Connect Apple Watch to track wrist temperature changes")
                } else if let temp = healthService.latestWristTemperature {
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)

                        Text(tempSkinInsight(temp))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textSecondary)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(CelleuxColors.warmGold.opacity(0.06))
                    )
                }
            }
        }
    }

    // MARK: - Environmental Impact Chart

    private var environmentalImpactChartSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Environmental Impact Over Time")

            GlassCard(depth: .elevated) {
                VStack(spacing: 14) {
                    Picker("Period", selection: $environmentalPeriod) {
                        ForEach(SheetPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .sensoryFeedback(.selection, trigger: environmentalPeriod)

                    let chartScores = filteredEnvironmentalScores
                    let hasAnyData = chartScores.contains { $0.skinScore > 0 || $0.uvScore > 0 || $0.hydrationScore > 0 }

                    if hasAnyData {
                        environmentalImpactChart(scores: chartScores)

                        if let selected = selectedEnvDate,
                           let closest = chartScores.min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }) {
                            envDatePopover(score: closest)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        HStack(spacing: 16) {
                            envLegendDot(color: CelleuxColors.warmGold, label: "Skin")
                            envLegendDot(color: CelleuxP3.chartGold, label: "UV")
                            envLegendDot(color: Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85), label: "Hydration")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(CelleuxColors.silver)

                            Text("Not enough data to show environmental impact")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                                .multilineTextAlignment(.center)

                            Text("Keep scanning and logging health data to unlock trends")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(CelleuxColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                    }
                }
            }
        }
    }

    private var filteredEnvironmentalScores: [DailyLongevityScore] {
        let days = environmentalPeriod.days
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return dailyScores.filter { $0.date >= cutoff }
    }

    private func environmentalImpactChart(scores: [DailyLongevityScore]) -> some View {
        Chart {
            ForEach(scores, id: \.date) { score in
                if score.skinScore > 0 {
                    AreaMark(
                        x: .value("Date", score.date),
                        y: .value("Skin", score.skinScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CelleuxColors.warmGold.opacity(0.18), CelleuxColors.warmGold.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", score.date),
                        y: .value("Skin", score.skinScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }

                if score.uvScore > 0 {
                    LineMark(
                        x: .value("Date", score.date),
                        y: .value("UV", score.uvScore)
                    )
                    .foregroundStyle(CelleuxP3.chartGold.opacity(0.7))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 4]))
                }

                if score.hydrationScore > 0 {
                    LineMark(
                        x: .value("Date", score.date),
                        y: .value("Hydration", score.hydrationScore)
                    )
                    .foregroundStyle(Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85).opacity(0.7))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 3]))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 4]))
                    .foregroundStyle(CelleuxColors.silver.opacity(0.15))
                AxisValueLabel()
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
        .chartXSelection(value: $selectedEnvDate)
        .frame(height: 200)
    }

    private func envDatePopover(score: DailyLongevityScore) -> some View {
        HStack(spacing: 12) {
            Text(score.date, style: .date)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)

            Spacer()

            if score.skinScore > 0 {
                HStack(spacing: 4) {
                    Circle().fill(CelleuxColors.warmGold).frame(width: 6, height: 6)
                    Text(String(format: "%.0f", score.skinScore))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)
                }
            }

            if score.uvScore > 0 {
                HStack(spacing: 4) {
                    Circle().fill(CelleuxP3.chartGold).frame(width: 6, height: 6)
                    Text(String(format: "%.0f", score.uvScore))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)
                }
            }

            if score.hydrationScore > 0 {
                HStack(spacing: 4) {
                    Circle().fill(Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85)).frame(width: 6, height: 6)
                    Text(String(format: "%.0f", score.hydrationScore))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(CelleuxColors.silverLight.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func envLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
        }
    }

    private func envSparkline(data: [(index: Int, value: Double)], color: Color) -> some View {
        let filtered = data.filter { $0.value > 0 }
        return Group {
            if filtered.count >= 2 {
                Chart(filtered, id: \.index) { item in
                    AreaMark(
                        x: .value("Day", item.index),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.12), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Day", item.index),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(color.opacity(0.6))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 60)
            }
        }
    }

    private func envEmptyPrompt(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CelleuxColors.silver)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
        }
    }

    private var recentUVData: [(index: Int, value: Double)] {
        let recent = Array(dailyScores.suffix(7))
        return recent.enumerated().map { idx, score in
            (index: idx, value: score.uvScore)
        }
    }

    private var recentHydrationData: [(index: Int, value: Double)] {
        let recent = Array(dailyScores.suffix(7))
        return recent.enumerated().map { idx, score in
            (index: idx, value: score.hydrationScore)
        }
    }

    private func uvRiskLabel(_ uv: Double) -> String {
        if uv <= 2 { return "Low risk" }
        if uv <= 5 { return "Moderate risk" }
        if uv <= 8 { return "High risk" }
        return "Very high risk"
    }

    private func uvRiskColor(_ uv: Double) -> Color {
        if uv <= 2 { return Color(hex: "4CAF50") }
        if uv <= 5 { return Color(hex: "FF9800") }
        return Color(hex: "E53935")
    }

    private func uvImpactInsight(uv: Double) -> some View {
        let text: String
        let icon: String
        let color: Color
        if uv <= 2 {
            text = "Low UV today — minimal photoaging risk"
            icon = "checkmark.circle.fill"
            color = Color(hex: "4CAF50")
        } else if uv <= 5 {
            text = "Moderate UV — wear SPF 30+ when outdoors"
            icon = "info.circle.fill"
            color = Color(hex: "FF9800")
        } else {
            text = "High UV exposure — reapply SPF 50+ every 2 hours"
            icon = "exclamationmark.triangle.fill"
            color = Color(hex: "E53935")
        }

        return HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CelleuxColors.textSecondary)
                .lineSpacing(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.06))
        )
    }

    private func tempContextLabel(_ temp: Double) -> String {
        if abs(temp) < 0.2 { return "Within baseline" }
        if temp > 0 { return "Above baseline" }
        return "Below baseline"
    }

    private func tempContextColor(_ temp: Double) -> Color {
        if abs(temp) < 0.2 { return Color(hex: "4CAF50") }
        if abs(temp) < 0.5 { return Color(hex: "FF9800") }
        return Color(hex: "E53935")
    }

    private func tempSkinInsight(_ temp: Double) -> String {
        if abs(temp) < 0.2 {
            return "Temperature is stable — normal skin thermoregulation."
        } else if temp > 0.5 {
            return "Elevated temperature may increase skin sensitivity and redness."
        } else if temp < -0.5 {
            return "Lower temperature may indicate vasoconstriction — skin may appear dull."
        } else if temp > 0 {
            return "Slight temperature elevation — monitor for skin reactivity."
        }
        return "Slight temperature decrease — stay hydrated and warm."
    }

    // MARK: - Skin Impact Guide

    private var skinImpactGuide: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CelleuxColors.warmGold)
                    Text("HOW HEALTH IMPACTS YOUR SKIN")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.55))
                        .tracking(1.2)
                }

                ForEach(SkinHealthFactor.allCases) { factor in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: factor.icon)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(colorForFactor(factor))
                            Text(factor.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(CelleuxColors.textPrimary)
                            Spacer()
                            Text("\(Int(factor.weight * 100))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                        Text(factor.skinImpact)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .lineSpacing(2)
                    }

                    if factor != SkinHealthFactor.allCases.last {
                        PremiumDivider()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func scoreForFactor(_ factor: SkinHealthFactor) -> Double {
        switch factor {
        case .sleep: correlationService.sleepScore
        case .stress: correlationService.stressScore
        case .hydration: correlationService.hydrationScore
        case .uvExposure: correlationService.uvScore
        case .activity: correlationService.activityScore
        }
    }

    private func colorForFactor(_ factor: SkinHealthFactor) -> Color {
        switch factor {
        case .sleep: CelleuxP3.chartSilver
        case .stress: CelleuxColors.roseGold
        case .hydration: Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85)
        case .uvExposure: CelleuxP3.chartGold
        case .activity: CelleuxP3.chartChampagne
        }
    }

    private func insightColor(_ severity: InsightSeverity) -> Color {
        switch severity {
        case .positive: CelleuxColors.warmGold
        case .neutral: CelleuxColors.silver
        case .warning: Color(hex: "FF9800")
        case .critical: Color(hex: "E53935")
        }
    }

    private func moodAxisLabel(_ value: Double) -> String {
        if value <= -0.75 { return "\u{1F61E}" }
        if value <= -0.25 { return "\u{1F610}" }
        if value <= 0.25 { return "\u{1F642}" }
        if value <= 0.75 { return "\u{1F60A}" }
        return "\u{1F604}"
    }

    private func moodValueLabel(_ valence: Double) -> String {
        if valence < -0.5 { return "Very Unpleasant" }
        if valence < -0.15 { return "Unpleasant" }
        if valence < 0.15 { return "Neutral" }
        if valence < 0.5 { return "Pleasant" }
        return "Very Pleasant"
    }
}

// MARK: - Correlation Factor Card

struct CorrelationFactorCard: View {
    let factor: SkinHealthFactor
    let score: Double
    let currentValue: String
    let hasData: Bool
    let dailyScores: [DailyLongevityScore]
    let impactLevel: ImpactLevel
    let onTap: () -> Void

    private var impactColor: Color {
        switch impactLevel {
        case .strongPositive, .moderatePositive: CelleuxColors.warmGold
        case .neutral: CelleuxColors.silver
        case .negative: Color(hex: "E53935")
        }
    }

    private var sparklineData: [(index: Int, value: Double)] {
        let recent = Array(dailyScores.suffix(7))
        return recent.enumerated().map { idx, score in
            let val: Double
            switch factor {
            case .sleep: val = score.sleepScore
            case .stress: val = score.stressScore
            case .hydration: val = score.hydrationScore
            case .uvExposure: val = score.uvScore
            case .activity: val = score.activityScore
            }
            return (index: idx, value: val)
        }
    }

    var body: some View {
        Button(action: onTap) {
            CompactGlassCard(cornerRadius: 20) {
                HStack(spacing: 14) {
                    factorIcon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(factor.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)

                        if hasData {
                            HStack(spacing: 6) {
                                Text(currentValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textSecondary)

                                Text("\u00B7")
                                    .foregroundStyle(CelleuxColors.textLabel)

                                Text(impactLevel.label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(impactColor)
                            }
                        } else {
                            Text("No data available")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }

                    Spacer()

                    if hasData && sparklineData.contains(where: { $0.value > 0 }) {
                        sparklineChart
                    }

                    scoreLabel
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var factorIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [impactColor.opacity(0.12), impactColor.opacity(0.02)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)

            Circle()
                .stroke(impactColor.opacity(0.25), lineWidth: 1)
                .frame(width: 40, height: 40)

            Image(systemName: factor.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(impactColor)
        }
    }

    private var sparklineChart: some View {
        let filtered = sparklineData.filter { $0.value > 0 }
        return Chart(filtered, id: \.index) { item in
            LineMark(
                x: .value("Day", item.index),
                y: .value("Score", item.value)
            )
            .foregroundStyle(impactColor.opacity(0.6))
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(width: 50, height: 28)
    }

    private var scoreLabel: some View {
        Group {
            if hasData {
                Text("\(Int(score))")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .contentTransition(.numericText())
            } else {
                Text("\u2014")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
        .frame(width: 36, alignment: .trailing)
    }
}

// MARK: - Factor Detail Bottom Sheet

struct FactorDetailSheet: View {
    let factor: SkinHealthFactor
    let score: Double
    let dailyScores: [DailyLongevityScore]
    let correlationService: SkinHealthCorrelationService
    let healthService: HealthKitService

    @State private var selectedPeriod: SheetPeriod = .sevenDays
    @State private var selectedChartDate: Date?

    private var filteredScores: [DailyLongevityScore] {
        let days = selectedPeriod.days
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return dailyScores.filter { $0.date >= cutoff }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                sheetHeader
                scoreRing
                periodPicker
                historicalChart
                factorInsightCard
                dataSourceInfo
                detailMetrics
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(CelleuxColors.background.ignoresSafeArea())
    }

    private var sheetHeader: some View {
        HStack(spacing: 12) {
            GlowingAccentBadge(factor.icon, color: factorColor, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(factor.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textPrimary)

                Text("Weight: \(Int(factor.weight * 100))% of Skin Health Index")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
            }

            Spacer()
        }
    }

    private var scoreRing: some View {
        let hasData = correlationService.factorHasData(factor)
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(CelleuxColors.silverLight.opacity(0.3), lineWidth: 6)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: hasData ? score / 100 : 0)
                    .stroke(factorColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                if hasData {
                    Text("\(Int(score))")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .contentTransition(.numericText())
                } else {
                    Text("\u2014")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }

            if hasData {
                Text(correlationService.impactLevel(for: score).label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(factorColor)

                Text(correlationService.currentValueString(for: factor))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CelleuxColors.textSecondary)
            } else {
                Text("No data available")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(SheetPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: selectedPeriod)
    }

    private var historicalChart: some View {
        GlassCard(depth: .standard) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(factor.title) over \(selectedPeriod.rawValue)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .textCase(.uppercase)
                    .tracking(0.8)

                let chartData = filteredScores.filter { factorValue(from: $0) > 0 }

                if chartData.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(CelleuxColors.silver)
                        Text("No historical data yet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)

                        Text(factorDataSourceHint)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                } else {
                    Chart {
                        ForEach(chartData, id: \.date) { score in
                            AreaMark(
                                x: .value("Date", score.date),
                                y: .value("Score", factorValue(from: score))
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxColors.warmGold.opacity(0.18), CelleuxColors.warmGold.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Date", score.date),
                                y: .value("Score", factorValue(from: score))
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                            if score.skinScore > 0 {
                                LineMark(
                                    x: .value("Date", score.date),
                                    y: .value("Skin", score.skinScore)
                                )
                                .foregroundStyle(factorColor.opacity(0.5))
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 3]))
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 4]))
                                .foregroundStyle(CelleuxColors.silver.opacity(0.15))
                            AxisValueLabel()
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }
                    .chartXSelection(value: $selectedChartDate)
                    .frame(height: 180)

                    if let selected = selectedChartDate,
                       let closest = chartData.min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }) {
                        sheetDatePopover(score: closest)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    HStack(spacing: 16) {
                        sheetLegendDot(color: CelleuxColors.warmGold, label: factor.title)
                        if chartData.contains(where: { $0.skinScore > 0 }) {
                            sheetLegendDot(color: factorColor, label: "Skin Score")
                        }
                    }
                }
            }
        }
    }

    private func sheetDatePopover(score: DailyLongevityScore) -> some View {
        HStack(spacing: 12) {
            Text(score.date, style: .date)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)

            Spacer()

            HStack(spacing: 4) {
                Circle().fill(CelleuxColors.warmGold).frame(width: 6, height: 6)
                Text(String(format: "%.0f", factorValue(from: score)))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textPrimary)
            }

            if score.skinScore > 0 {
                HStack(spacing: 4) {
                    Circle().fill(factorColor).frame(width: 6, height: 6)
                    Text(String(format: "%.0f", score.skinScore))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(CelleuxColors.silverLight.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func sheetLegendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
        }
    }

    private var factorInsightCard: some View {
        let insights = correlationService.generateInsights().filter { $0.factor == factor }
        return Group {
            if let insight = insights.first {
                CompactGlassCard(cornerRadius: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: insight.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(insightColor(insight.severity))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(insight.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(CelleuxColors.textPrimary)
                            Text(insight.detail)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(CelleuxColors.textLabel)
                                .lineSpacing(2)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var dataSourceInfo: some View {
        Group {
            if !correlationService.factorHasData(factor) {
                CompactGlassCard(cornerRadius: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: factorRequiresWatch ? "applewatch" : "heart.text.square")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(CelleuxColors.silver)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(factorRequiresWatch ? "Requires Apple Watch" : "Data Not Available")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(CelleuxColors.textPrimary)
                            Text(factorDataSourceHint)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(CelleuxColors.textLabel)
                                .lineSpacing(2)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var factorRequiresWatch: Bool {
        switch factor {
        case .sleep, .stress, .activity: true
        case .hydration, .uvExposure: false
        }
    }

    private var factorDataSourceHint: String {
        switch factor {
        case .sleep: "Connect Apple Watch to track sleep stages and duration"
        case .stress: "Connect Apple Watch for HRV-based stress analysis"
        case .hydration: "Log water intake in the Health app"
        case .uvExposure: "UV data appears when your device detects sun exposure"
        case .activity: "Connect Apple Watch to track active calories and exercise"
        }
    }

    private var detailMetrics: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("How this affects your skin")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(factor.skinImpact)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(CelleuxColors.textSecondary)
                    .lineSpacing(4)
            }
        }
    }

    private func factorValue(from score: DailyLongevityScore) -> Double {
        switch factor {
        case .sleep: score.sleepScore
        case .stress: score.stressScore
        case .hydration: score.hydrationScore
        case .uvExposure: score.uvScore
        case .activity: score.activityScore
        }
    }

    private var factorColor: Color {
        switch factor {
        case .sleep: CelleuxP3.chartSilver
        case .stress: CelleuxColors.roseGold
        case .hydration: Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85)
        case .uvExposure: CelleuxP3.chartGold
        case .activity: CelleuxP3.chartChampagne
        }
    }

    private func insightColor(_ severity: InsightSeverity) -> Color {
        switch severity {
        case .positive: CelleuxColors.warmGold
        case .neutral: CelleuxColors.silver
        case .warning: Color(hex: "FF9800")
        case .critical: Color(hex: "E53935")
        }
    }
}

nonisolated enum SheetPeriod: String, Identifiable, CaseIterable, Sendable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .sevenDays: 7
        case .thirtyDays: 30
        case .ninetyDays: 90
        }
    }
}
