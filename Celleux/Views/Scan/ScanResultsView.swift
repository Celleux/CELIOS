import SwiftUI
import Charts

struct ScanResultsView: View {
    let result: SkinScanResult
    let history: [SkinScanResult]
    let onNewScan: () -> Void
    let onShowHistory: () -> Void

    @State private var appeared: Bool = false
    @State private var scoreAnimated: Bool = false
    @State private var ringGlow: Bool = false
    @State private var celebrationTrigger: Int = 0
    @State private var displayedScore: Int = 0
    @State private var regionAppeared: Bool = false
    @State private var metricsAppeared: Bool = false
    @State private var heroLabelVisible: Bool = false
    @State private var expandedRegion: String? = nil
    @State private var showComparison: Bool = false
    @State private var shareImage: UIImage? = nil
    @State private var isGeneratingShare: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var isNewHighScore: Bool = false

    private var calibration: CalibrationResult? { result.calibration }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                scanCompleteHeader
                if let cal = calibration, cal.isCalibrating {
                    calibrationBanner(cal)
                }
                scoreHeroCard
                if let cal = calibration, !cal.isCalibrating {
                    confidenceBadge(cal)
                }
                regionBreakdown
                metricDetailCarousel
                comparisonButton
                shareButton
                actionButtons
                disclaimerText
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(CelleuxMeshBackground())
        .sensoryFeedback(.success, trigger: celebrationTrigger)
        .sensoryFeedback(.selection, trigger: expandedRegion)
        .sheet(isPresented: $showComparison) {
            if let previousResult = findPreviousScan() {
                ScanComparisonSheet(current: result, previous: previousResult)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(image: image)
            }
        }
        .onAppear {
            runSequentialAppearAnimation()
            checkNewHighScore()
        }
    }

    // MARK: - Header

    private var scanCompleteHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "4CAF50").opacity(0.15), Color(hex: "4CAF50").opacity(0.03)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 58, height: 58)

                Circle()
                    .stroke(Color(hex: "4CAF50").opacity(0.2), lineWidth: 1)
                    .frame(width: 58, height: 58)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color(hex: "4CAF50"))
                    .symbolEffect(.bounce, value: appeared)
            }
            .shadow(color: Color(hex: "4CAF50").opacity(0.2), radius: 8, x: 0, y: 4)
            .keyframeAnimator(initialValue: ScoreCelebrationKeyframes(), trigger: appeared) { content, value in
                content
                    .offset(y: value.verticalOffset)
                    .scaleEffect(value.scale)
            } keyframes: { _ in
                KeyframeTrack(\.verticalOffset) {
                    SpringKeyframe(-12, duration: 0.3)
                    SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.8, duration: 0.05)
                    SpringKeyframe(1.1, duration: 0.2)
                    SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
                }
            }

            Text("Scan Complete")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(CelleuxColors.textPrimary)

            Text(result.dateString)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
        }
        .frame(maxWidth: .infinity)
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    // MARK: - Score Animation

    private func animateScoreCount() {
        let target = result.overallScore
        let steps = 30
        let interval = 1.4 / Double(steps)

        for step in 0...steps {
            let delay = 0.5 + interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let value = Int(Double(target) * eased)
            Task {
                try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
                withAnimation(.snappy) {
                    displayedScore = value
                }
                if step == steps {
                    celebrationTrigger += 1
                }
            }
        }
    }

    // MARK: - Score Hero Card

    private var scoreHeroCard: some View {
        GlassCard(depth: .elevated, showShimmer: true) {
            VStack(spacing: 20) {
                HStack {
                    Text("OVERALL SKIN SCORE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1.8)
                    Spacer()
                    Text("10 METRICS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))
                        .tracking(1)
                }

                ZStack {
                    ChromeRingView(
                        progress: scoreAnimated ? Double(result.overallScore) / 100.0 : 0,
                        size: 152,
                        lineWidth: 9,
                        glowing: $ringGlow
                    )

                    VStack(spacing: 2) {
                        Text("\(displayedScore)")
                            .font(CelleuxType.metric)
                            .tracking(CelleuxType.metricTracking)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .animatedNumber()

                        Text("Overall Skin Health")
                            .font(CelleuxType.caption)
                            .tracking(CelleuxType.captionTracking)
                            .foregroundStyle(CelleuxColors.textLabel)
                            .textCase(.uppercase)
                            .opacity(heroLabelVisible ? 1 : 0)
                            .offset(y: heroLabelVisible ? 0 : 6)
                    }

                    CelebrationParticleBurst(isActive: celebrationTrigger > 0)
                }

                if let cal = calibration, !cal.isCalibrating, let delta = cal.deltaFromBaseline, abs(delta) >= 3 {
                    baselineDeltaBadge(delta: delta)
                } else if result.trend != 0 {
                    trendBadge(trend: result.trend)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.06)
    }

    private func baselineDeltaBadge(delta: Double) -> some View {
        let positive = delta > 0
        let color = positive ? Color(hex: "4CAF50") : Color(hex: "E53935")
        return HStack(spacing: 6) {
            Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)

            Text(String(format: "%+.0f from baseline", delta))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.08))
        )
        .transition(.scale.combined(with: .opacity))
    }

    private func trendBadge(trend: Double) -> some View {
        let positive = trend > 0
        let color = positive ? Color(hex: "4CAF50") : Color(hex: "E53935")
        return HStack(spacing: 6) {
            Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)

            Text(String(format: "%+.1f vs last scan", trend))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Region Breakdown (2×3 Grid)

    private var regionBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("REGIONAL BREAKDOWN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .tracking(1.8)

                Spacer()

                Text("\(result.regions.count) REGIONS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(CelleuxColors.warmGold.opacity(0.5))
                    .tracking(1)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(result.regions.enumerated()), id: \.element.id) { index, region in
                    regionCard(region: region, index: index)
                        .opacity(regionAppeared ? 1 : 0)
                        .offset(y: regionAppeared ? 0 : 16)
                        .scaleEffect(regionAppeared ? 1 : 0.95)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.05),
                            value: regionAppeared
                        )
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.12)
    }

    private func regionCard(region: SkinRegionResult, index: Int) -> some View {
        let isExpanded = expandedRegion == region.name
        return Button {
            withAnimation(CelleuxSpring.snappy) {
                expandedRegion = isExpanded ? nil : region.name
            }
        } label: {
            CompactGlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        MetricRingMini(score: region.score, size: 32)

                        Spacer()

                        HStack(spacing: 3) {
                            Image(systemName: region.trend.icon)
                                .font(.system(size: 9, weight: .semibold))
                            Text(region.trend.label)
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(region.trend.color)
                    }

                    Text("\(region.score)")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .contentTransition(.numericText())

                    Text(region.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    if isExpanded, let analysisData = result.analysisData {
                        let regionScores = analysisData.regionData[region.name] ?? RegionScores()
                        expandedRegionMetrics(regionScores)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func expandedRegionMetrics(_ scores: RegionScores) -> some View {
        VStack(spacing: 6) {
            PremiumDivider()
            let applicableMetrics = SkinMetricType.allCases.filter { $0 != .overallSkinHealth && $0.isImplemented }
            ForEach(applicableMetrics, id: \.rawValue) { metric in
                let score = Int(scores.score(for: metric).rounded())
                if score > 0 {
                    HStack {
                        Image(systemName: metric.icon)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .frame(width: 14)

                        Text(metric.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(CelleuxColors.textSecondary)

                        Spacer()

                        Text("\(score)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText())
                    }
                }
            }
        }
    }

    // MARK: - 10-Metric Detail Carousel

    private var metricDetailCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("DETAILED METRICS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .tracking(1.8)

                Spacer()

                Text("\(result.metrics.count) METRICS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(CelleuxColors.warmGold.opacity(0.5))
                    .tracking(1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(Array(result.metrics.enumerated()), id: \.element.id) { index, metric in
                        metricDetailCard(metric: metric, index: index)
                            .containerRelativeFrame(.horizontal, count: 1, spacing: 14)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 0)
        }
        .staggeredAppear(appeared: appeared, delay: 0.4)
    }

    private func metricDetailCard(metric: SkinMetric, index: Int) -> some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ChromeIconBadge(metric.icon, size: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)

                        Text(metricExplanation(for: metric.name))
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .lineLimit(2)
                    }

                    Spacer()
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("\(metric.score)")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .animatedNumber()

                    Text("/100")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(CelleuxColors.textLabel)

                    Spacer()

                    if let trend = metric.trend {
                        HStack(spacing: 3) {
                            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                            Text(String(format: "%+d", trend))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .contentTransition(.numericText())
                        }
                        .foregroundStyle(trend >= 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
                    }

                    if let cal = calibration,
                       let metricType = SkinMetricType.allCases.first(where: { $0.rawValue == metric.name }),
                       let confidence = cal.perMetricConfidence[metricType] {
                        confidenceDot(confidence)
                    }
                }

                scoreBarAnimated(score: metric.score, index: index)

                metricSparkline(for: metric.name)
            }
        }
        .opacity(metricsAppeared ? 1 : 0)
        .offset(y: metricsAppeared ? 0 : 12)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.04),
            value: metricsAppeared
        )
    }

    private func scoreBarAnimated(score: Int, index: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CelleuxColors.silver.opacity(0.08))
                    .frame(height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: scoreBarColors(for: score),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: metricsAppeared ? geo.size.width * CGFloat(score) / 100.0 : 0,
                        height: 6
                    )
                    .shadow(color: scoreBarColors(for: score).first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 0)
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.7).delay(Double(index) * 0.05),
                        value: metricsAppeared
                    )
            }
        }
        .frame(height: 6)
    }

    private func metricSparkline(for metricName: String) -> some View {
        Group {
            if let chartData = buildSparklineData(for: metricName), chartData.count >= 2 {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Scan", point.index),
                        y: .value("Score", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                    AreaMark(
                        x: .value("Scan", point.index),
                        y: .value("Score", point.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: 0...100)
                .frame(height: 40)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                    Text("More scans needed for sparkline")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
                .frame(height: 40)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Comparison Button

    private var comparisonButton: some View {
        Group {
            if findPreviousScan() != nil {
                Button {
                    showComparison = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("Compare with Last Scan")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(CelleuxColors.warmGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(GlassButtonStyle(style: .primary))
                .staggeredAppear(appeared: appeared, delay: 0.46)
            }
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            generateShareImage()
        } label: {
            HStack(spacing: 10) {
                if isGeneratingShare {
                    ProgressView()
                        .tint(CelleuxColors.warmGold)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                }
                Text("Share Your Progress")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(CelleuxColors.warmGold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(GlassButtonStyle(style: .primary))
        .disabled(isGeneratingShare)
        .staggeredAppear(appeared: appeared, delay: 0.48)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                onNewScan()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .medium))
                    Text("New Scan")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(CelleuxColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(GlassButtonStyle(style: .secondary))

            Button {
                onShowHistory()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 13, weight: .medium))
                    Text("History")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(CelleuxColors.warmGold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(GlassButtonStyle(style: .primary))
        }
        .staggeredAppear(appeared: appeared, delay: 0.5)
    }

    // MARK: - Calibration

    private func calibrationBanner(_ cal: CalibrationResult) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .symbolEffect(.variableColor.iterative, options: .repeating, isActive: true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Establishing Your Personal Baseline")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)

                        Text("\(cal.calibrationScansRemaining) more scan\(cal.calibrationScansRemaining == 1 ? "" : "s") to calibrate")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    Spacer()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(CelleuxColors.silver.opacity(0.08))
                            .frame(height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.warmGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(cal.calibrationScanCount) / 3.0, height: 4)
                    }
                }
                .frame(height: 4)

                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in
                        HStack(spacing: 4) {
                            Image(systemName: i < cal.calibrationScanCount ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(i < cal.calibrationScanCount ? CelleuxColors.warmGold : CelleuxColors.silver.opacity(0.3))
                            Text("Scan \(i + 1)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(i < cal.calibrationScanCount ? CelleuxColors.textPrimary : CelleuxColors.textLabel)
                        }
                        if i < 2 { Spacer() }
                    }
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.03)
    }

    private func confidenceBadge(_ cal: CalibrationResult) -> some View {
        HStack(spacing: 8) {
            Image(systemName: confidenceIcon(cal.overallConfidence))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(confidenceColor(cal.overallConfidence))

            Text("\(cal.overallConfidence.rawValue) Confidence")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(confidenceColor(cal.overallConfidence))

            Spacer()

            Text(confidenceExplanation(cal.overallConfidence))
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(CelleuxColors.textLabel)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(confidenceColor(cal.overallConfidence).opacity(0.06))
        )
        .overlay(
            Capsule()
                .stroke(confidenceColor(cal.overallConfidence).opacity(0.15), lineWidth: 0.5)
        )
        .staggeredAppear(appeared: appeared, delay: 0.08)
    }

    private func confidenceDot(_ level: ConfidenceLevel) -> some View {
        Circle()
            .fill(confidenceColor(level))
            .frame(width: 6, height: 6)
    }

    private func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .low: Color(hex: "E8A838")
        case .medium: Color(hex: "4A90D9")
        case .high: Color(hex: "4CAF50")
        }
    }

    private func confidenceIcon(_ level: ConfidenceLevel) -> String {
        switch level {
        case .low: "circle.bottomhalf.filled"
        case .medium: "circle.lefthalf.filled"
        case .high: "checkmark.circle.fill"
        }
    }

    private func confidenceExplanation(_ level: ConfidenceLevel) -> String {
        switch level {
        case .low: "< 3 scans"
        case .medium: "3-10 scans"
        case .high: "10+ consistent"
        }
    }

    // MARK: - Sequential Animation

    private func runSequentialAppearAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
            appeared = true
        }
        withAnimation(.easeOut(duration: 1.4).delay(0.3)) {
            scoreAnimated = true
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
            ringGlow = true
        }
        animateScoreCount()

        Task {
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                regionAppeared = true
            }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                metricsAppeared = true
            }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(1600))
            withAnimation(CelleuxSpring.luxury) {
                heroLabelVisible = true
            }
        }
    }

    private func checkNewHighScore() {
        let previousBest = history.filter { $0.id != result.id }.map { $0.overallScore }.max() ?? 0
        if result.overallScore > previousBest && !history.isEmpty {
            isNewHighScore = true
        }
    }

    // MARK: - Share Image Generation

    private func generateShareImage() {
        isGeneratingShare = true
        let renderer = ImageRenderer(content: shareCardContent)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            showShareSheet = true
        }
        isGeneratingShare = false
    }

    private var shareCardContent: some View {
        VStack(spacing: 24) {
            HStack {
                Text("CELLEUX")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Color(hex: "C9A96E"))
                Spacer()
                Text(result.dateString)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "999999"))
            }

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "D4B078"), Color(hex: "C9A96E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: Double(result.overallScore) / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "E8D6A8"), Color(hex: "C9A96E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    Text("\(result.overallScore)")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(Color(hex: "1A1A26"))
                }

                Text("Overall Skin Health")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "888888"))
                    .textCase(.uppercase)
                    .tracking(1)
            }

            HStack {
                Text("Tracked with Celleux")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "AAAAAA"))
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "C9A96E").opacity(0.6))
                Text("On-Device")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "AAAAAA"))
            }
        }
        .padding(28)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "E8DCC8").opacity(0.6), Color(hex: "C9A96E").opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Helpers

    private func scoreBarColors(for score: Int) -> [Color] {
        if score >= 80 { return [Color(hex: "4CAF50"), Color(hex: "66BB6A")] }
        if score >= 60 { return [CelleuxColors.warmGold, Color(hex: "D4A574")] }
        return [Color(hex: "E8A838"), Color(hex: "E53935")]
    }

    private func metricExplanation(for name: String) -> String {
        switch name {
        case "Texture Evenness": "Smoothness and uniformity of skin surface"
        case "Apparent Hydration": "Moisture levels across your skin"
        case "Brightness": "Radiance and luminosity of your skin"
        case "Redness": "Inflammation and redness indicators"
        case "Pore Visibility": "Visibility and size of pores"
        case "Tone Uniformity": "Evenness of skin color across regions"
        case "Under-Eye Quality": "Dark circle and under-eye area health"
        case "Wrinkle Depth": "Fine lines and wrinkle presence"
        case "Elasticity": "Skin firmness and recovery"
        default: "Skin health metric"
        }
    }

    private func findPreviousScan() -> SkinScanResult? {
        let sorted = history.sorted { $0.date > $1.date }
        guard let currentIndex = sorted.firstIndex(where: { $0.id == result.id }) else {
            return sorted.first(where: { $0.id != result.id })
        }
        let nextIndex = sorted.index(after: currentIndex)
        guard nextIndex < sorted.endIndex else { return nil }
        return sorted[nextIndex]
    }

    private func buildSparklineData(for metricName: String) -> [SparklinePoint]? {
        let sorted = history.sorted { $0.date < $1.date }.suffix(10)
        guard sorted.count >= 2 else { return nil }
        return Array(sorted.enumerated().map { index, scan in
            let score = scan.metrics.first(where: { $0.name == metricName })?.score ?? 0
            return SparklinePoint(index: index, score: Double(score))
        })
    }

    private var disclaimerText: some View {
        Text("Skin analysis tracks visual appearance changes over time. This is not a medical assessment. For skin health concerns, consult a dermatologist.")
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(CelleuxColors.textLabel)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .staggeredAppear(appeared: appeared, delay: 0.56)
    }
}

// MARK: - Mini Ring Component

struct MetricRingMini: View {
    let score: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(CelleuxColors.silver.opacity(0.1), lineWidth: 3)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: Double(score) / 100.0)
                .stroke(
                    LinearGradient(
                        colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: CelleuxColors.goldGlow.opacity(0.2), radius: 3, x: 0, y: 0)

            Text("\(score)")
                .font(.system(size: size * 0.3, weight: .semibold))
                .foregroundStyle(CelleuxColors.textPrimary)
        }
    }
}

// MARK: - Sparkline Data

nonisolated struct SparklinePoint: Identifiable, Sendable {
    let id = UUID()
    let index: Int
    let score: Double
}

// MARK: - Scan Comparison Sheet

struct ScanComparisonSheet: View {
    let current: SkinScanResult
    let previous: SkinScanResult

    @State private var appeared: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("SCAN COMPARISON")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1.8)

                    Text("\(previous.shortDateString) → \(current.shortDateString)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CelleuxColors.textSecondary)
                }
                .padding(.top, 12)

                overallComparison

                metricBars
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(CelleuxMeshBackground())
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
        }
    }

    private var overallComparison: some View {
        let delta = current.overallScore - previous.overallScore
        return GlassCard(depth: .elevated) {
            HStack {
                VStack(spacing: 4) {
                    Text("THEN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1)

                    Text("\(previous.overallScore)")
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundStyle(CelleuxColors.textSecondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: delta >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(delta >= 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))

                    Text(String(format: "%+d", delta))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(delta >= 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
                        .contentTransition(.numericText())
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("NOW")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .tracking(1)

                    Text("\(current.overallScore)")
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundStyle(CelleuxColors.textPrimary)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    private var metricBars: some View {
        VStack(spacing: 10) {
            ForEach(Array(current.metrics.enumerated()), id: \.element.id) { index, currentMetric in
                let previousMetric = previous.metrics.first { $0.name == currentMetric.name }
                let prevScore = previousMetric?.score ?? 0
                let delta = currentMetric.score - prevScore
                let improved = delta >= 0

                CompactGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: currentMetric.icon)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CelleuxColors.warmGold)

                            Text(currentMetric.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CelleuxColors.textPrimary)

                            Spacer()

                            HStack(spacing: 3) {
                                Image(systemName: improved ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 9, weight: .bold))
                                Text(String(format: "%+d", delta))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .contentTransition(.numericText())
                            }
                            .foregroundStyle(improved ? Color(hex: "4CAF50") : Color(hex: "E8A838"))
                        }

                        HStack(spacing: 8) {
                            comparisonBar(score: prevScore, label: "Before", isActive: false)
                            comparisonBar(score: currentMetric.score, label: "Now", isActive: true)
                        }
                    }
                }
                .staggeredAppear(appeared: appeared, delay: 0.05 + Double(index) * 0.04)
            }
        }
    }

    private func comparisonBar(score: Int, label: String, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isActive ? CelleuxColors.textSecondary : CelleuxColors.textLabel)

                Spacer()

                Text("\(score)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isActive ? CelleuxColors.textPrimary : CelleuxColors.textLabel)
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CelleuxColors.silver.opacity(0.06))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            isActive
                                ? LinearGradient(colors: [CelleuxColors.warmGold.opacity(0.8), CelleuxColors.warmGold], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [CelleuxColors.silver.opacity(0.3), CelleuxColors.silver.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: appeared ? geo.size.width * CGFloat(score) / 100.0 : 0, height: 4)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: appeared)
                }
            }
            .frame(height: 4)
        }
    }
}
