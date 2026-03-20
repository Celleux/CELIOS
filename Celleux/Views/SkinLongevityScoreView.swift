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

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                heroSection
                    .staggeredAppear(appeared: appeared, delay: 0)

                if !viewModel.hasWatchData && !viewModel.isLoading {
                    connectWatchCard
                        .staggeredAppear(appeared: appeared, delay: 0.08)
                }

                factorsSection
                    .staggeredAppear(appeared: appeared, delay: 0.12)

                historySection
                    .staggeredAppear(appeared: appeared, delay: 0.20)

                calculationSection
                    .staggeredAppear(appeared: appeared, delay: 0.26)
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
        .task {
            await viewModel.loadData(modelContext: modelContext)
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
    }

    private var heroSection: some View {
        VStack(spacing: 20) {
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

            if viewModel.trend != 0 {
                trendBadge
            }
        }
        .padding(.vertical, 16)
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

    private var connectWatchCard: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
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
                            .frame(width: 52, height: 52)

                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.5)],
                                    center: .center
                                ),
                                lineWidth: 1
                            )
                            .frame(width: 52, height: 52)

                        Image(systemName: "applewatch")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(CelleuxColors.warmGold)
                    }
                    .shadow(color: CelleuxColors.warmGold.opacity(0.2), radius: 10, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connect Apple Watch")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)

                        Text("Unlock sleep, HRV, activity, and circadian insights for a complete longevity score.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .lineSpacing(2)
                    }
                }

                Button {} label: {
                    Text("Open Health Settings")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(GlassButtonStyle(style: .primary))
            }
        }
    }

    private var factorsSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Contributing factors")

            LazyVStack(spacing: 12) {
                ForEach(LongevityFactor.allCases) { factor in
                    if viewModel.hasWatchData || !factor.requiresWatch {
                        factorCard(factor)
                    }
                }
            }
        }
    }

    private func factorCard(_ factor: LongevityFactor) -> some View {
        let score = viewModel.scoreForFactor(factor)
        let detail = viewModel.detailForFactor(factor)
        let isGold = factor == .adherence

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
                            .foregroundStyle(isGold ? CelleuxColors.goldGradient : CelleuxColors.silverGradient)
                    }
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(factor.title.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .tracking(1.2)

                        Text(detail)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(CelleuxColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("\(Int(score))")
                        .font(.system(size: 24, weight: .thin))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .contentTransition(.numericText())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(CelleuxColors.silver.opacity(0.08))
                            .frame(height: 4)

                        Capsule()
                            .fill(isGold ? CelleuxColors.goldGradient : CelleuxColors.silverGradient)
                            .frame(width: geo.size.width * min(1, score / 100), height: 4)
                    }
                }
                .frame(height: 4)

                if factor.requiresWatch {
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
                        LineMark(
                            x: .value("Date", score.date),
                            y: .value("Score", score.compositeScore)
                        )
                        .foregroundStyle(CelleuxColors.dataGold)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        AreaMark(
                            x: .value("Date", score.date),
                            y: .value("Score", score.compositeScore)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "6B3FA0").opacity(0.15), Color(hex: "6B3FA0").opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
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
                    HStack {
                        Text(score.date, style: .date)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                        Spacer()
                        Text("\(Int(score.compositeScore))/100")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CelleuxColors.warmGold)
                    }
                }
            }
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
