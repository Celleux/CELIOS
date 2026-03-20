import SwiftUI

struct ScanResultsView: View {
    let result: SkinScanResult
    let onNewScan: () -> Void
    let onShowHistory: () -> Void

    @State private var appeared: Bool = false
    @State private var scoreAnimated: Bool = false
    @State private var ringGlow: Bool = false
    @State private var showMetrics: Bool = true
    @State private var celebrationTrigger: Int = 0
    @State private var displayedScore: Int = 0
    @State private var regionAppeared: Bool = false
    @State private var metricsAppeared: Bool = false

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
                metricsSection
                actionButtons
                disclaimerText
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(CelleuxMeshBackground())
        .sensoryFeedback(.success, trigger: celebrationTrigger)
        .onAppear {
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
        GlassCard(depth: .elevated) {
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
                        size: 144,
                        lineWidth: 8,
                        glowing: $ringGlow
                    )

                    VStack(spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(displayedScore)")
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

                        Text("SKIN HEALTH")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.45))
                            .tracking(0.8)
                            .textCase(.uppercase)
                    }

                    CelebrationParticleBurst(isActive: celebrationTrigger > 0)
                }

                if let cal = calibration, !cal.isCalibrating, let delta = cal.deltaFromBaseline, delta != 0 {
                    baselineDeltaBadge(delta: delta)
                } else if result.trend != 0 {
                    trendBadge(trend: result.trend)
                }
            }
        }
        .shimmer()
        .staggeredAppear(appeared: appeared, delay: 0.06)
    }

    private func baselineDeltaBadge(delta: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: delta > 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(delta > 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))

            Text(String(format: "%+.0f points vs your baseline", delta))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(delta > 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill((delta > 0 ? Color(hex: "4CAF50") : Color(hex: "E53935")).opacity(0.08))
        )
        .transition(.scale.combined(with: .opacity))
    }

    private func trendBadge(trend: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(trend > 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))

            Text(String(format: "%+.1f vs last scan", trend))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(trend > 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
        }
    }

    // MARK: - Region Breakdown

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
                    regionCard(region: region)
                        .opacity(regionAppeared ? 1 : 0)
                        .offset(y: regionAppeared ? 0 : 16)
                        .scaleEffect(regionAppeared ? 1 : 0.95)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.06),
                            value: regionAppeared
                        )
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.12)
    }

    private func regionCard(region: SkinRegionResult) -> some View {
        CompactGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ChromeIconBadge(region.icon, size: 28)

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
                    .font(.system(size: 30, weight: .ultraLight))
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .contentTransition(.numericText())

                Text(region.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textPrimary)

                HStack(spacing: 4) {
                    Text(region.keyMetric + ":")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                    Text(region.keyValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CelleuxColors.warmGold)
                }
            }
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showMetrics.toggle()
                }
            } label: {
                HStack {
                    Text("DETAILED METRICS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1.8)

                    Spacer()

                    HStack(spacing: 6) {
                        Text("\(result.metrics.count)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))

                        Image(systemName: showMetrics ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: showMetrics)

            if showMetrics {
                VStack(spacing: 10) {
                    ForEach(Array(result.metrics.enumerated()), id: \.element.id) { index, metric in
                        metricRow(metric: metric, index: index)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.4)
    }

    private func metricRow(metric: SkinMetric, index: Int) -> some View {
        CompactGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ChromeIconBadge(metric.icon, size: 24)

                    Text(metric.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Spacer()

                    Text("\(metric.score)")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .contentTransition(.numericText())

                    if let trend = metric.trend {
                        HStack(spacing: 2) {
                            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 9, weight: .bold))
                            Text("\(abs(trend))")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(trend >= 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
                    }

                    if let cal = calibration,
                       let metricType = SkinMetricType.allCases.first(where: { $0.rawValue == metric.name }),
                       let confidence = cal.perMetricConfidence[metricType] {
                        confidenceDot(confidence)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(CelleuxColors.silver.opacity(0.08))
                            .frame(height: 5)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: scoreBarColors(for: metric.score),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: metricsAppeared ? geo.size.width * CGFloat(metric.score) / 100.0 : 0,
                                height: 5
                            )
                            .shadow(color: scoreBarColors(for: metric.score).first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 0)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.7).delay(Double(index) * 0.05),
                                value: metricsAppeared
                            )
                    }
                }
                .frame(height: 5)
            }
        }
        .opacity(metricsAppeared ? 1 : 0)
        .offset(y: metricsAppeared ? 0 : 12)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.04),
            value: metricsAppeared
        )
    }

    private func scoreBarColors(for score: Int) -> [Color] {
        if score >= 80 { return [Color(hex: "4CAF50"), Color(hex: "66BB6A")] }
        if score >= 60 { return [CelleuxColors.warmGold, Color(hex: "D4A574")] }
        return [Color(hex: "E8A838"), Color(hex: "E53935")]
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
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: false)

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

    // MARK: - Disclaimer

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
