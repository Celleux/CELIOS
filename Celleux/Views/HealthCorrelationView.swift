import SwiftUI
import Charts

struct HealthCorrelationView: View {
    @State private var correlationService = SkinHealthCorrelationService.shared
    private let healthService = HealthKitService.shared
    @State private var appeared: Bool = false
    @State private var ringGlow: Bool = false
    @State private var moodHistory: [MoodEntry] = []
    @State private var selectedMoodDate: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                overallScoreSection
                    .staggeredAppear(appeared: appeared, delay: 0)

                factorBreakdownSection
                    .staggeredAppear(appeared: appeared, delay: 0.08)

                if !moodHistory.isEmpty {
                    moodTrendChart
                        .staggeredAppear(appeared: appeared, delay: 0.14)
                }

                if !correlationService.generateInsights().isEmpty {
                    insightsSection
                        .staggeredAppear(appeared: appeared, delay: 0.20)
                }

                stressRiskSection
                    .staggeredAppear(appeared: appeared, delay: 0.26)

                skinImpactGuide
                    .staggeredAppear(appeared: appeared, delay: 0.32)
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
            withAnimation(.spring(duration: 0.8, bounce: 0.15)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
                ringGlow = true
            }
        }
    }

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

    private var factorBreakdownSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Skin Health Factors")

            GlassCard(depth: .elevated) {
                VStack(spacing: 4) {
                    Chart {
                        ForEach(SkinHealthFactor.allCases) { factor in
                            let score = scoreForFactor(factor)
                            let remaining = 100 - score

                            SectorMark(
                                angle: .value("Score", score * factor.weight),
                                innerRadius: .ratio(0.65),
                                angularInset: 2
                            )
                            .cornerRadius(4)
                            .foregroundStyle(colorForFactor(factor))

                            SectorMark(
                                angle: .value("Remaining", remaining * factor.weight),
                                innerRadius: .ratio(0.65),
                                angularInset: 2
                            )
                            .cornerRadius(4)
                            .foregroundStyle(CelleuxColors.silver.opacity(0.08))
                        }
                    }
                    .chartBackground { _ in
                        VStack(spacing: 2) {
                            Text("\(Int(correlationService.overallCorrelationScore))")
                                .font(.system(size: 32, weight: .ultraLight, design: .rounded))
                                .foregroundStyle(CelleuxColors.textPrimary)
                                .contentTransition(.numericText())
                            Text("Overall")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                    }
                    .frame(height: 180)

                    VStack(spacing: 10) {
                        ForEach(SkinHealthFactor.allCases) { factor in
                            factorRow(factor)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private func factorRow(_ factor: SkinHealthFactor) -> some View {
        let score = scoreForFactor(factor)
        return HStack(spacing: 12) {
            Circle()
                .fill(colorForFactor(factor))
                .frame(width: 8, height: 8)

            Image(systemName: factor.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(colorForFactor(factor))
                .frame(width: 20)

            Text(factor.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CelleuxColors.textPrimary)

            Spacer()

            Text("\(Int(factor.weight * 100))%")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)

            Text("\(Int(score))")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(CelleuxColors.textPrimary)
                .contentTransition(.numericText())
                .frame(width: 30, alignment: .trailing)
        }
    }

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

    private var stressRiskSection: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: correlationService.stressRiskLevel.color))
                        Text("STRESS & SKIN RISK")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.55))
                            .tracking(1.2)
                    }
                    Spacer()
                }

                HStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text(correlationService.stressRiskLevel.label)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(hex: correlationService.stressRiskLevel.color))

                        Text("Flare-up risk")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        if let hrv = healthService.latestHRV {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(CelleuxColors.roseGold)
                                Text(String(format: "HRV: %.0f ms", hrv))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textSecondary)
                            }
                        }

                        if let valence = healthService.averageMoodValence {
                            HStack(spacing: 6) {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 10))
                                    .foregroundStyle(CelleuxColors.warmGold)
                                Text(String(format: "Mood: %.2f", valence))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textSecondary)
                            }
                        }
                    }
                }

                if correlationService.stressRiskLevel == .high {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "E53935"))
                        Text("Low HRV + negative mood increases cortisol, risking skin flare-ups.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: "E53935").opacity(0.06))
                    )
                }
            }
        }
    }

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
        if value <= -0.75 { return "😞" }
        if value <= -0.25 { return "😐" }
        if value <= 0.25 { return "🙂" }
        if value <= 0.75 { return "😊" }
        return "😄"
    }

    private func moodValueLabel(_ valence: Double) -> String {
        if valence < -0.5 { return "Very Unpleasant" }
        if valence < -0.15 { return "Unpleasant" }
        if valence < 0.15 { return "Neutral" }
        if valence < 0.5 { return "Pleasant" }
        return "Very Pleasant"
    }
}
