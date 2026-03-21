import SwiftUI
import SwiftData
import Charts

struct SkinLongevityScoreView: View {
    @State private var viewModel = SkinLongevityViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyLongevityScore.date, order: .reverse) private var storedScores: [DailyLongevityScore]
    @State private var appeared: Bool = false
    @State private var ringGlow: Bool = false
    @State private var selectedChartDate: Date?
    @State private var showCalculation: Bool = false
    @State private var refreshPulse: Bool = false
    @State private var navigateToScan: Bool = false
    @State private var insightTipTrigger: Bool = false
    @State private var navigateToProtocol: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if viewModel.compositeScore != nil {
                    heroSection
                        .staggeredAppear(appeared: appeared, delay: 0)
                } else if !viewModel.isLoading {
                    emptyScanCTA
                        .staggeredAppear(appeared: appeared, delay: 0)
                }

                if !viewModel.missingDataSources.isEmpty && !viewModel.isLoading {
                    missingDataSection
                        .staggeredAppear(appeared: appeared, delay: 0.06)
                }

                if !viewModel.actionableInsights.isEmpty {
                    insightsSection
                        .staggeredAppear(appeared: appeared, delay: 0.10)
                }

                factorsSection
                    .staggeredAppear(appeared: appeared, delay: 0.16)

                historySection
                    .staggeredAppear(appeared: appeared, delay: 0.22)

                if !viewModel.correlationStats.isEmpty {
                    correlationStatsSection
                        .staggeredAppear(appeared: appeared, delay: 0.28)
                }

                calculationSection
                    .staggeredAppear(appeared: appeared, delay: 0.32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(CelleuxMeshBackground())
        .navigationTitle("Skin Longevity")
        .navigationBarTitleDisplayMode(.large)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.3), trigger: showCalculation)
        .sensoryFeedback(.success, trigger: refreshPulse)
        .sensoryFeedback(.selection, trigger: insightTipTrigger)
        .navigationDestination(isPresented: $navigateToScan) {
            ScanView()
        }
        .navigationDestination(isPresented: $navigateToProtocol) {
            RitualView()
        }
        .sheet(item: $viewModel.showInsightTip) { tipItem in
            insightTipSheet(tipItem.text)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.loadData(modelContext: modelContext)
            viewModel.startAutoRefresh(modelContext: modelContext)
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 1.6).delay(0.3)) {
                viewModel.animateScoreIn()
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(1.0)) {
                ringGlow = true
            }
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                longevityRing

                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(viewModel.animatedScore))")
                            .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .contentTransition(.numericText(countsDown: false))

                        Text("/100")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    Text("SKIN LONGEVITY")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.45))
                        .tracking(0.8)
                        .textCase(.uppercase)
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(refreshPulse ? 1.02 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: refreshPulse)

            if !viewModel.lastUpdatedString.isEmpty {
                Text(viewModel.lastUpdatedString)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .contentTransition(.numericText())
            }

            if viewModel.trend != 0 {
                trendBadge
            }
        }
        .padding(.vertical, 16)
    }

    private var emptyScanCTA: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 20) {
                ZStack {
                    LuxuryBezelRing(
                        progress: 0,
                        size: 160,
                        lineWidth: 10,
                        glowing: .constant(false)
                    )

                    VStack(spacing: 6) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 36, weight: .ultraLight))
                            .foregroundStyle(CelleuxColors.silverGradient)

                        Text("—")
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }

                VStack(spacing: 8) {
                    Text("Take Your First Scan")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text("Your Skin Longevity score combines scan data with health metrics for a complete picture.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(CelleuxColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                Button {
                    navigateToScan = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                            .font(.system(size: 15, weight: .medium))
                        Text("Start Scan")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(CelleuxColors.warmGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(GlassButtonStyle(style: .primary))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var longevityRing: some View {
        LuxuryBezelRing(
            progress: viewModel.animatedScore / 100,
            size: 200,
            lineWidth: 12,
            glowing: $ringGlow
        )
    }

    private var trendBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.trend > 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(viewModel.trend > 0 ? CelleuxColors.warmGold : Color(hex: "E53935"))

            Text(String(format: "%+.1f this week", viewModel.trend))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(viewModel.trend > 0 ? CelleuxColors.warmGold : Color(hex: "E53935"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(viewModel.trend > 0 ? CelleuxColors.warmGold.opacity(0.08) : Color(hex: "E53935").opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(viewModel.trend > 0 ? CelleuxColors.warmGold.opacity(0.2) : Color(hex: "E53935").opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Missing Data

    private var missingDataSection: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.missingDataSources) { source in
                missingDataCard(source)
            }
        }
    }

    private func missingDataCard(_ source: MissingDataSource) -> some View {
        CompactGlassCard(cornerRadius: 18) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.10), CelleuxColors.warmGold.opacity(0.02)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)

                    Circle()
                        .stroke(CelleuxColors.goldChromeBorder, lineWidth: 0.8)
                        .frame(width: 40, height: 40)

                    Image(systemName: source.icon)
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(CelleuxColors.warmGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(source.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text(source.detail)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Button {
                    handleMissingDataAction(source.action)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.warmGold)
                }
            }
        }
    }

    private func handleMissingDataAction(_ action: MissingDataAction) {
        switch action {
        case .connectWatch:
            if let url = URL(string: "x-apple-health://") {
                UIApplication.shared.open(url)
            }
        case .takeScan:
            navigateToScan = true
        case .setupProtocol:
            navigateToProtocol = true
        }
    }

    // MARK: - Correlation Insights

    private var insightsSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Health & Skin Insights")

            VStack(spacing: 10) {
                ForEach(viewModel.actionableInsights) { insight in
                    actionableInsightCard(insight)
                }
            }
        }
    }

    private func actionableInsightCard(_ insight: ActionableInsight) -> some View {
        let accentColor = insightAccentColor(insight.severity)

        return CompactGlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [accentColor.opacity(0.14), accentColor.opacity(0.02)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 22
                                )
                            )
                            .frame(width: 44, height: 44)

                        Circle()
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            .frame(width: 44, height: 44)

                        Image(systemName: insight.icon)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
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

                Button {
                    insightTipTrigger.toggle()
                    handleInsightAction(insight.actionDestination)
                } label: {
                    HStack(spacing: 6) {
                        Text(insight.actionLabel)
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .stroke(accentColor.opacity(0.2), lineWidth: 0.5)
                    )
                }
            }
        }
    }

    private func handleInsightAction(_ action: InsightAction) {
        switch action {
        case .openHealth:
            if let url = URL(string: "x-apple-health://") {
                UIApplication.shared.open(url)
            }
        case .openScan:
            navigateToScan = true
        case .openProtocol:
            navigateToProtocol = true
        case .tip(let text):
            viewModel.showInsightTip = InsightTipItem(text: text)
        }
    }

    private func insightTipSheet(_ tip: String) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.12), CelleuxColors.warmGold.opacity(0.02)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 28
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(CelleuxColors.warmGold)
                }

                Text("Recommendation")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textPrimary)
            }

            Text(tip)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(CelleuxColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    private func insightAccentColor(_ severity: InsightSeverity) -> Color {
        switch severity {
        case .positive: CelleuxColors.warmGold
        case .neutral: CelleuxColors.silver
        case .warning: Color(hex: "FF9800")
        case .critical: Color(hex: "E53935")
        }
    }

    // MARK: - Factors

    private var factorsSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Contributing factors")

            LazyVStack(spacing: 12) {
                ForEach(LongevityFactor.allCases) { factor in
                    if viewModel.hasWatchData || !factor.requiresWatch {
                        factorCard(factor)
                    } else {
                        grayedOutFactorCard(factor)
                    }
                }
            }
        }
    }

    private func factorCard(_ factor: LongevityFactor) -> some View {
        let score = viewModel.scoreForFactor(factor)
        let detail = viewModel.detailForFactor(factor)
        let isGold = factor == .adherence
        let hasData = score != nil

        return CompactGlassCard(cornerRadius: 20) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: isGold
                                        ? [CelleuxColors.warmGold.opacity(0.12), CelleuxColors.warmGold.opacity(0.02)]
                                        : [Color(hex: "E8ECF0").opacity(0.6), Color(hex: "D0D6DC").opacity(0.2)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 42, height: 42)

                        Circle()
                            .stroke(
                                isGold ? CelleuxColors.goldChromeBorder : CelleuxColors.chromeBorder,
                                lineWidth: 0.8
                            )
                            .frame(width: 42, height: 42)

                        Image(systemName: factor.icon)
                            .font(.system(size: 17, weight: .light))
                            .foregroundStyle(hasData ? (isGold ? CelleuxColors.goldGradient : CelleuxColors.silverGradient) : CelleuxColors.silverGradient)
                            .opacity(hasData ? 1 : 0.4)
                    }
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(factor.title.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .tracking(1.2)

                        Text(detail)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(hasData ? CelleuxColors.textSecondary : CelleuxColors.textLabel)
                            .lineLimit(1)
                    }

                    Spacer()

                    if let scoreVal = score {
                        Text("\(Int(scoreVal))")
                            .font(.system(size: 24, weight: .thin))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText())
                    } else {
                        Text("—")
                            .font(.system(size: 24, weight: .thin))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(CelleuxColors.silver.opacity(0.08))
                            .frame(height: 4)

                        if let scoreVal = score {
                            Capsule()
                                .fill(isGold ? CelleuxColors.goldGradient : CelleuxColors.silverGradient)
                                .frame(width: geo.size.width * min(1, scoreVal / 100), height: 4)
                        }
                    }
                }
                .frame(height: 4)

                if factor.requiresWatch && !viewModel.hasWatchData {
                    HStack(spacing: 4) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(CelleuxColors.silver)

                        Text("Apple Watch")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(CelleuxColors.silver)
                            .tracking(0.5)

                        Spacer()
                    }
                }
            }
        }
    }

    private func grayedOutFactorCard(_ factor: LongevityFactor) -> some View {
        CompactGlassCard(cornerRadius: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CelleuxColors.silver.opacity(0.08), CelleuxColors.silver.opacity(0.02)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 42, height: 42)

                    Circle()
                        .stroke(CelleuxColors.chromeBorder, lineWidth: 0.8)
                        .frame(width: 42, height: 42)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(CelleuxColors.silver.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(factor.title.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CelleuxColors.textLabel.opacity(0.5))
                        .tracking(1.2)

                    HStack(spacing: 4) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(CelleuxColors.silver.opacity(0.6))

                        Text("Requires Apple Watch")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel.opacity(0.5))
                    }
                }

                Spacer()

                Text("—")
                    .font(.system(size: 24, weight: .thin))
                    .foregroundStyle(CelleuxColors.textLabel.opacity(0.3))
            }
        }
        .opacity(0.7)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Score history")

            Picker("Period", selection: $viewModel.selectedPeriod) {
                ForEach(HistoryPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)

            if filteredScores.isEmpty {
                emptyHistoryCard
            } else {
                historyChart

                factorOverlayToggles
            }
        }
    }

    private var filteredScores: [DailyLongevityScore] {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -viewModel.selectedPeriod.days, to: Date()) else {
            return storedScores
        }
        return storedScores.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    private var historyChart: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Chart {
                    ForEach(filteredScores, id: \.date) { score in
                        AreaMark(
                            x: .value("Date", score.date),
                            y: .value("Score", score.compositeScore)
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
                            y: .value("Score", score.compositeScore)
                        )
                        .foregroundStyle(CelleuxColors.dataGold)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }

                    ForEach(Array(viewModel.enabledFactorOverlays), id: \.self) { factor in
                        ForEach(filteredScores, id: \.date) { score in
                            LineMark(
                                x: .value("Date", score.date),
                                y: .value(factor.title, viewModel.scoreForFactorFromDaily(factor, score: score)),
                                series: .value("Factor", factor.title)
                            )
                            .foregroundStyle(colorForOverlayFactor(factor))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        }
                    }

                    if let selected = selectedChartDate,
                       let score = filteredScores.min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }) {
                        RuleMark(x: .value("Selected", score.date))
                            .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                        PointMark(
                            x: .value("Date", score.date),
                            y: .value("Score", score.compositeScore)
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
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if let date: Date = proxy.value(atX: value.location.x) {
                                            selectedChartDate = date
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedChartDate = nil
                                    }
                            )
                    }
                }
                .frame(height: 200)

                if let selected = selectedChartDate,
                   let score = filteredScores.min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }) {
                    selectedDayBreakdown(score)
                }
            }
        }
    }

    private func selectedDayBreakdown(_ score: DailyLongevityScore) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(score.date, style: .date)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
                Spacer()
                Text("\(Int(score.compositeScore))/100")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CelleuxColors.warmGold)
                    .contentTransition(.numericText())
            }

            PremiumDivider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                dayBreakdownPill(label: "Sleep", value: score.sleepScore)
                dayBreakdownPill(label: "HRV", value: score.hrvScore)
                dayBreakdownPill(label: "Skin", value: score.skinScore)
                dayBreakdownPill(label: "Adherence", value: score.adherenceScore)
                dayBreakdownPill(label: "Activity", value: score.activityScore)
                dayBreakdownPill(label: "Circadian", value: score.circadianScore)
            }
        }
    }

    private func dayBreakdownPill(label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(value > 0 ? "\(Int(value))" : "—")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(value > 0 ? CelleuxColors.textPrimary : CelleuxColors.textLabel)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(CelleuxColors.silver.opacity(0.04))
        )
    }

    private var factorOverlayToggles: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LongevityFactor.allCases) { factor in
                    let isActive = viewModel.enabledFactorOverlays.contains(factor)
                    Button {
                        withAnimation(CelleuxSpring.snappy) {
                            viewModel.toggleFactorOverlay(factor)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(colorForOverlayFactor(factor))
                                .frame(width: 6, height: 6)

                            Text(factor.title)
                                .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                                .foregroundStyle(isActive ? CelleuxColors.textPrimary : CelleuxColors.textLabel)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(isActive ? colorForOverlayFactor(factor).opacity(0.10) : CelleuxColors.silver.opacity(0.04))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isActive ? colorForOverlayFactor(factor).opacity(0.3) : CelleuxColors.silver.opacity(0.1), lineWidth: 0.5)
                        )
                    }
                }
            }
        }
        .contentMargins(.horizontal, 4)
    }

    private func colorForOverlayFactor(_ factor: LongevityFactor) -> Color {
        switch factor {
        case .sleep: CelleuxP3.chartSilver
        case .hrv: CelleuxColors.roseGold
        case .skinAnalysis: CelleuxColors.warmGold
        case .adherence: CelleuxP3.chartGold
        case .activity: Color(.displayP3, red: 0.4, green: 0.7, blue: 0.85)
        case .circadian: CelleuxP3.chartChampagne
        }
    }

    private var emptyHistoryCard: some View {
        GlassCard(cornerRadius: 22) {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(CelleuxColors.silverGradient)

                Text("Score history will appear here")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CelleuxColors.textSecondary)

                Text("Check back daily to build your trend data.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Correlation Stats

    private var correlationStatsSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Discovered correlations")

            VStack(spacing: 10) {
                ForEach(Array(viewModel.correlationStats.enumerated()), id: \.offset) { _, stat in
                    correlationStatCard(stat)
                }
            }
        }
    }

    private func correlationStatCard(_ stat: CorrelationStat) -> some View {
        CompactGlassCard(cornerRadius: 18) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.12), CelleuxColors.warmGold.opacity(0.02)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 18
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(CelleuxColors.warmGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(stat.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .lineLimit(2)

                    Text("Based on your \(stat.factor.lowercased()) data")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                }

                Spacer(minLength: 0)

                Text(String(format: "%+.0f%%", stat.delta))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(stat.delta > 0 ? CelleuxColors.warmGold : Color(hex: "FF9800"))
                    .contentTransition(.numericText())
            }
        }
    }

    // MARK: - Calculation

    private var calculationSection: some View {
        GlassCard(cornerRadius: 20) {
            DisclosureGroup(isExpanded: $showCalculation) {
                VStack(alignment: .leading, spacing: 12) {
                    PremiumDivider()

                    if viewModel.hasWatchData {
                        calculationRow(factor: "Sleep Quality", weight: "20%")
                        calculationRow(factor: "HRV", weight: "15%")
                        calculationRow(factor: "Skin Analysis", weight: "25%")
                        calculationRow(factor: "Protocol Adherence", weight: "20%")
                        calculationRow(factor: "Activity & Fitness", weight: "10%")
                        calculationRow(factor: "Circadian Rhythm", weight: "10%")
                    } else {
                        calculationRow(factor: "Skin Analysis", weight: "55%")
                        calculationRow(factor: "Protocol Adherence", weight: "45%")
                    }

                    PremiumDivider()

                    Text("Scores are computed from real Apple Health data and your Celleux protocol adherence. Connect Apple Watch to unlock all factors.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .lineSpacing(3)
                }
                .padding(.top, 8)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "function")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CelleuxColors.warmGold)

                    Text("How is this calculated?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CelleuxColors.textPrimary)
                }
            }
            .tint(CelleuxColors.warmGold)
        }
    }

    private func calculationRow(factor: String, weight: String) -> some View {
        HStack {
            Text(factor)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(CelleuxColors.textSecondary)
            Spacer()
            Text(weight)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CelleuxColors.textPrimary)
        }
    }
}
