import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SkinScanRecord.date, order: .reverse) private var scans: [SkinScanRecord]
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]
    @Query(sort: \DailyLongevityScore.date, order: .reverse) private var longevityScores: [DailyLongevityScore]
    @State private var appeared: Bool = false
    @State private var selectedTimeframe: Timeframe = .month
    @State private var chartAnimated: Bool = false
    @State private var shareHaptic: Int = 0
    @State private var selectedChartDate: Date?
    @State private var showHealthCorrelation: Bool = false
    @State private var insightEngine: InsightEngine = InsightEngine()
    @State private var expandedInsightID: UUID? = nil
    @State private var cardTapTrigger: Int = 0
    @State private var isRefreshing: Bool = false

    private var totalDays: Int { checkIns.count }
    private var hasEnoughData: Bool { totalDays >= 7 }
    private var hasEnoughScans: Bool { scans.count >= 3 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    insightFeedSection

                    if hasEnoughData {
                        timeframePicker
                        skinScoreTrendChart
                        healthCorrelationCard
                        moodCorrelationSection
                        factorDonutChart
                    } else {
                        earlyDaysCard
                    }
                    achievementSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .refreshable {
                isRefreshing = true
                insightEngine.generateInsights(
                    scans: scans,
                    longevityScores: longevityScores,
                    modelContext: modelContext
                )
                try? await Task.sleep(for: .milliseconds(600))
                isRefreshing = false
            }
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.4), trigger: isRefreshing)
            .background(CelleuxMeshBackground())
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        shareHaptic += 1
                        shareInsights()
                    } label: {
                        ChromeToolbarButton(icon: "square.and.arrow.up")
                    }
                    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: shareHaptic)
                }
            }
            .navigationDestination(isPresented: $showHealthCorrelation) {
                HealthCorrelationView()
            }
            .sensoryFeedback(.selection, trigger: cardTapTrigger)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                    appeared = true
                }
                withAnimation(.easeOut(duration: 1.2).delay(0.5)) {
                    chartAnimated = true
                }
                insightEngine.generateInsights(
                    scans: scans,
                    longevityScores: longevityScores,
                    modelContext: modelContext
                )
            }
        }
    }

    // MARK: - Insight Feed

    private var insightFeedSection: some View {
        VStack(spacing: 16) {
            HStack {
                SectionHeader(title: "Your Insights")
                Spacer()
                if !insightEngine.insights.isEmpty {
                    Text("\(insightEngine.insights.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(CelleuxColors.goldGradient)
                        )
                }
            }

            if !hasEnoughScans {
                notEnoughScansCard
            } else if insightEngine.insights.isEmpty {
                noInsightsCard
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(insightEngine.insights.prefix(8).enumerated()), id: \.element.id) { index, insight in
                        insightCard(insight)
                            .staggeredAppear(appeared: appeared, delay: Double(index) * 0.05)
                    }
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    private var notEnoughScansCard: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 20) {
                ChromeIconBadge("viewfinder", size: 56)
                    .symbolEffect(.breathe, isActive: appeared)

                VStack(spacing: 8) {
                    Text("Scan more to unlock insights")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text("Complete \(max(0, 3 - scans.count)) more scans to start seeing personalized trends and recommendations.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                ZStack {
                    Capsule()
                        .fill(Color(hex: "F0ECE6"))
                        .frame(height: 6)
                    GeometryReader { geo in
                        Capsule()
                            .fill(CelleuxColors.goldGradient)
                            .frame(width: geo.size.width * min(1, Double(scans.count) / 3.0))
                    }
                    .frame(height: 6)
                }
                .frame(maxWidth: 200)

                Text("\(scans.count) of 3 scans")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var noInsightsCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                ChromeIconBadge("sparkles", size: 48)
                Text("No new insights right now")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(CelleuxColors.textSecondary)
                Text("Keep tracking — insights appear as patterns emerge in your data.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func insightCard(_ insight: PersonalInsight) -> some View {
        let isExpanded = expandedInsightID == insight.id

        Button {
            cardTapTrigger += 1
            withAnimation(CelleuxSpring.snappy) {
                if expandedInsightID == insight.id {
                    expandedInsightID = nil
                } else {
                    expandedInsightID = insight.id
                }
            }
        } label: {
            HStack(spacing: 0) {
                accentStrip(for: insight.type)

                VStack(alignment: .leading, spacing: isExpanded ? 16 : 10) {
                    HStack(alignment: .top, spacing: 12) {
                        ChromeIconBadge(insight.icon, size: 36, gradient: gradientForType(insight.type))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(insight.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(CelleuxColors.textPrimary)
                                    .lineLimit(isExpanded ? nil : 1)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(CelleuxColors.textLabel)
                                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            }

                            Text(insight.body)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(CelleuxColors.textSecondary)
                                .lineLimit(isExpanded ? nil : 2)
                                .lineSpacing(2)
                        }
                    }

                    HStack {
                        insightTypeBadge(insight.type)
                        Spacer()
                        Text(relativeDate(insight.timestamp))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    if isExpanded {
                        PremiumDivider()

                        if let detail = insight.detail {
                            Text(detail)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(CelleuxColors.textSecondary)
                                .lineSpacing(3)
                        }

                        if let actionLabel = insight.actionLabel {
                            Button {
                                handleInsightAction(insight)
                            } label: {
                                Text(actionLabel)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(CelleuxColors.warmGold)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GlassButtonStyle(style: .primary))
                        }
                    }
                }
                .padding(16)
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.92))
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [
                                CelleuxColors.silverLight.opacity(0.5),
                                CelleuxColors.warmGold.opacity(0.3),
                                Color.white.opacity(0.7),
                                CelleuxColors.silverBorder.opacity(0.4),
                                CelleuxColors.silverLight.opacity(0.5)
                            ],
                            center: .center
                        ),
                        lineWidth: 1
                    )
            )
            .celleuxDepthShadow()
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func accentStrip(for type: PersonalInsightType) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(colorForType(type))
            .frame(width: 3)
            .padding(.vertical, 12)
            .padding(.leading, 2)
    }

    private func colorForType(_ type: PersonalInsightType) -> Color {
        switch type {
        case .celebration: return CelleuxColors.warmGold
        case .trendAlert: return CelleuxColors.silver
        case .actionItem: return Color(hex: "D4A054")
        case .correlationDiscovery: return CelleuxP3.champagne
        case .weeklySummary: return CelleuxColors.silverLight
        }
    }

    private func gradientForType(_ type: PersonalInsightType) -> LinearGradient {
        switch type {
        case .celebration: return CelleuxColors.iconGoldGradient
        case .trendAlert: return CelleuxColors.silverGradient
        case .actionItem: return CelleuxColors.iconAmberGradient
        case .correlationDiscovery: return CelleuxColors.iconGoldGradient
        case .weeklySummary: return CelleuxColors.iconBlueGradient
        }
    }

    private func insightTypeBadge(_ type: PersonalInsightType) -> some View {
        let label: String
        switch type {
        case .celebration: label = "Celebration"
        case .trendAlert: label = "Trend"
        case .actionItem: label = "Action"
        case .correlationDiscovery: label = "Discovery"
        case .weeklySummary: label = "Weekly"
        }

        return Text(label.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(colorForType(type))
            .tracking(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(colorForType(type).opacity(0.1))
            )
    }

    private func handleInsightAction(_ insight: PersonalInsight) {
        guard let destination = insight.actionDestination else { return }
        switch destination {
        case .openHealth:
            showHealthCorrelation = true
        case .openScan, .openProtocol:
            break
        case .tip:
            break
        }
    }

    // MARK: - Early Days Card

    private var earlyDaysCard: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.90, green: 0.88, blue: 0.86), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: min(1.0, Double(totalDays) / 30.0))
                        .stroke(CelleuxColors.goldGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(totalDays)")
                            .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                            .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20))
                            .contentTransition(.numericText())
                        Text("of 30")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.4))
                    }
                }

                VStack(spacing: 8) {
                    Text("Building your insights")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(red: 0.12, green: 0.12, blue: 0.18))
                    Text("Complete \(max(0, 7 - totalDays)) more days of check-ins to unlock your first insights report.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    // MARK: - Timeframe Picker

    private var timeframePicker: some View {
        HStack(spacing: 0) {
            ForEach(Timeframe.allCases, id: \.self) { frame in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTimeframe = frame
                    }
                } label: {
                    Text(frame.label)
                        .font(.system(size: 13, weight: selectedTimeframe == frame ? .bold : .regular))
                        .foregroundStyle(selectedTimeframe == frame ? CelleuxColors.textPrimary : CelleuxColors.textSecondary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(
                            ZStack {
                                if selectedTimeframe == frame {
                                    Capsule()
                                        .fill(LinearGradient(colors: [Color.white.opacity(0.95), Color(hex: "F5F0E8")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .shadow(color: CelleuxColors.goldGlow.opacity(0.3), radius: 10, x: 0, y: 4)
                                    Capsule().stroke(CelleuxColors.goldChromeBorder, lineWidth: 1)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selectedTimeframe)
            }
        }
        .padding(4)
        .background(
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(LinearGradient(colors: [Color.white.opacity(0.7), Color(hex: "F2F0ED")], startPoint: .topLeading, endPoint: .bottomTrailing))
                Capsule().stroke(CelleuxColors.goldChromeBorder, lineWidth: 0.5)
            }
        )
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    // MARK: - Skin Score Trend Chart

    private var skinScoreTrendChart: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Skin Score Trend")

                if filteredScans.count >= 2 {
                    let improvement = filteredScans.last!.overallScore - filteredScans.first!.overallScore
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%+d%%", improvement))
                            .font(.system(size: 38, weight: .ultraLight))
                            .foregroundStyle(improvement >= 0 ? CelleuxColors.warmGold : Color(hex: "E53935"))
                            .contentTransition(.numericText())
                        Text("change")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    Chart {
                        ForEach(filteredScans, id: \.date) { scan in
                            LineMark(
                                x: .value("Date", scan.date),
                                y: .value("Score", scan.overallScore)
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
                                x: .value("Date", scan.date),
                                y: .value("Score", scan.overallScore)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        if let selected = selectedChartDate,
                           let scan = filteredScans.min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }) {
                            RuleMark(x: .value("Selected", scan.date))
                                .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                            PointMark(
                                x: .value("Date", scan.date),
                                y: .value("Score", scan.overallScore)
                            )
                            .foregroundStyle(CelleuxColors.warmGold)
                            .symbolSize(60)
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                            AxisValueLabel()
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: [0, 25, 50, 75, 100]) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 4]))
                                .foregroundStyle(CelleuxColors.silver.opacity(0.2))
                            AxisValueLabel()
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }
                    .chartXSelection(value: $selectedChartDate)
                    .chartScrollableAxes(.horizontal)
                    .chartXVisibleDomain(length: 86400 * max(7, filteredScans.count))
                    .frame(height: 200)

                    if let selected = selectedChartDate,
                       let scan = filteredScans.min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }) {
                        HStack {
                            Text(scan.date, style: .date)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                            Spacer()
                            Text("\(scan.overallScore)/100")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(CelleuxColors.warmGold)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        ChromeIconBadge("chart.line.uptrend.xyaxis", size: 48)
                        Text("Complete more scans to see trends")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.06)
    }

    // MARK: - Health Correlation Card

    private var healthCorrelationCard: some View {
        Button { showHealthCorrelation = true } label: {
            GlassCard(depth: .elevated) {
                VStack(spacing: 16) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CelleuxColors.warmGold)
                            Text("SKIN & HEALTH CORRELATION")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.55))
                                .tracking(1.2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    HStack(spacing: 16) {
                        ForEach(SkinHealthFactor.allCases.prefix(4)) { factor in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [CelleuxColors.warmGold.opacity(0.08), CelleuxColors.warmGold.opacity(0.02)],
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 18
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                    Image(systemName: factor.icon)
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundStyle(CelleuxColors.silverGradient)
                                }
                                Text(factor.title)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(CelleuxColors.textLabel)
                                    .lineLimit(1)
                                Text("\(Int(factor.weight * 100))%")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(CelleuxColors.warmGold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    Text("Tap to see how your health data impacts your skin")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.3), trigger: showHealthCorrelation)
        .staggeredAppear(appeared: appeared, delay: 0.12)
    }

    // MARK: - Mood Correlation

    private var moodCorrelationSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Mood & Skin")

            if !filteredLongevityScores.isEmpty {
                GlassCard(depth: .elevated) {
                    VStack(alignment: .leading, spacing: 12) {
                        Chart {
                            ForEach(filteredLongevityScores, id: \.date) { score in
                                BarMark(
                                    x: .value("Date", score.date, unit: .day),
                                    y: .value("Mood", (score.moodValence + 1) / 2 * 100)
                                )
                                .foregroundStyle(
                                    score.moodValence >= 0 ?
                                    CelleuxColors.warmGold.opacity(0.6) :
                                    Color(hex: "FF9800").opacity(0.6)
                                )
                                .cornerRadius(4)
                            }

                            RuleMark(y: .value("Neutral", 50))
                                .foregroundStyle(CelleuxColors.silver.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(values: [0, 50, 100]) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [4, 4]))
                                    .foregroundStyle(CelleuxColors.silver.opacity(0.15))
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(v == 0 ? "😞" : v == 50 ? "😐" : "😊")
                                            .font(.system(size: 10))
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
                        .frame(height: 150)
                    }
                }
            } else {
                GlassCard {
                    VStack(spacing: 12) {
                        ChromeIconBadge("face.smiling", size: 42)
                        Text("Log your mood to see correlations")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.18)
    }

    // MARK: - Factor Breakdown

    private var factorDonutChart: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Score Breakdown")

            HStack(spacing: 12) {
                correlationCard(
                    title: "Adherence",
                    correlation: adherenceCorrelation,
                    icon: "checkmark.circle",
                    insight: adherenceInsight
                )
                correlationCard(
                    title: "Consistency",
                    correlation: consistencyCorrelation,
                    icon: "flame",
                    insight: consistencyInsight
                )
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.24)
    }

    // MARK: - Filtered Data

    private var filteredScans: [SkinScanRecord] {
        let days: Int
        switch selectedTimeframe {
        case .week: days = 7
        case .month: days = 30
        case .quarter: days = 90
        case .year: days = 365
        }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return scans.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    private var filteredLongevityScores: [DailyLongevityScore] {
        let days: Int
        switch selectedTimeframe {
        case .week: days = 7
        case .month: days = 30
        case .quarter: days = 90
        case .year: days = 365
        }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return longevityScores.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    private var adherenceCorrelation: String {
        let streak = UserDefaults.standard.integer(forKey: "adherenceStreak")
        if streak >= 14 { return "+0.85" }
        if streak >= 7 { return "+0.62" }
        return "+0.30"
    }

    private var adherenceInsight: String {
        let streak = UserDefaults.standard.integer(forKey: "adherenceStreak")
        if streak >= 14 { return "Strong positive impact" }
        if streak >= 7 { return "Good momentum building" }
        return "Keep building your streak"
    }

    private var consistencyCorrelation: String {
        if scans.count >= 5 { return "+0.74" }
        if scans.count >= 2 { return "+0.45" }
        return "—"
    }

    private var consistencyInsight: String {
        if scans.count >= 5 { return "Regular scanning helps" }
        if scans.count >= 2 { return "More data needed" }
        return "Start scanning regularly"
    }

    private func correlationCard(title: String, correlation: String, icon: String, insight: String) -> some View {
        CompactGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                ChromeIconBadge(icon, size: 38)
                Text(correlation)
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundStyle(CelleuxColors.warmGold)
                    .contentTransition(.numericText())
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textPrimary)
                Text(insight)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Achievement Section

    private var achievementSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recent Activity")

            if checkIns.isEmpty && scans.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        ChromeIconBadge("chart.bar", size: 48)
                            .symbolEffect(.breathe, isActive: appeared)
                        Text("No activity yet")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(CelleuxColors.textSecondary)
                        Text("Complete scans and check-ins to see your activity history.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(recentActivity.prefix(5), id: \.date) { item in
                        CompactGlassCard(cornerRadius: 16) {
                            HStack(spacing: 12) {
                                ChromeIconBadge(item.icon, size: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(CelleuxColors.textPrimary)
                                    Text(item.subtitle)
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(CelleuxColors.textLabel)
                                }
                                Spacer()
                                Text(relativeDate(item.date))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                        }
                    }
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.30)
    }

    private struct ActivityItem {
        let date: Date
        let icon: String
        let title: String
        let subtitle: String
    }

    private var recentActivity: [ActivityItem] {
        var items: [ActivityItem] = []

        for scan in scans.prefix(3) {
            items.append(ActivityItem(date: scan.date, icon: "faceid", title: "Skin Scan", subtitle: "Score: \(scan.overallScore)/100"))
        }
        for checkIn in checkIns.prefix(3) {
            let mood = checkIn.mood.isEmpty ? "Logged" : checkIn.mood
            items.append(ActivityItem(date: checkIn.date, icon: "face.smiling", title: "Mood Check-In", subtitle: mood))
        }

        return items.sorted { $0.date > $1.date }
    }

    private func relativeDate(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days)d ago"
    }

    private func shareInsights() {
        var text = "My Celleux Insights\n\n"
        text += "Scans completed: \(scans.count)\n"
        text += "Check-ins: \(checkIns.count)\n"
        text += "Adherence streak: \(UserDefaults.standard.integer(forKey: "adherenceStreak")) days\n"
        if let latest = scans.first {
            text += "Latest skin score: \(latest.overallScore)/100\n"
        }

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

nonisolated enum Timeframe: String, CaseIterable {
    case week, month, quarter, year

    var label: String {
        switch self {
        case .week: "1W"
        case .month: "1M"
        case .quarter: "3M"
        case .year: "1Y"
        }
    }
}
