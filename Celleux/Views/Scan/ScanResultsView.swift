import SwiftUI

struct ScanResultsView: View {
    let result: SkinScanResult
    let onNewScan: () -> Void
    let onShowHistory: () -> Void

    @State private var appeared: Bool = false
    @State private var scoreAnimated: Bool = false
    @State private var ringGlow: Bool = false
    @State private var showMetrics: Bool = false
    @State private var celebrationTrigger: Int = 0
    @State private var displayedScore: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                scanCompleteHeader
                scoreHeroCard
                regionBreakdown
                metricsSection
                comparisonPlaceholder
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
        }
    }

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

    private func animateScoreCount() {
        let target = result.overallScore
        let steps = 25
        let interval = 1.4 / Double(steps)

        for step in 0...steps {
            let delay = 0.5 + interval * Double(step)
            let value = Int(Double(target) * (Double(step) / Double(steps)))
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

    private var scoreHeroCard: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 20) {
                HStack {
                    Text("OVERALL SKIN SCORE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1.8)
                    Spacer()
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

                if result.trend != 0 {
                    HStack(spacing: 6) {
                        Image(systemName: result.trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(result.trend > 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))

                        Text(String(format: "%+.1f%% vs last scan", result.trend))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(result.trend > 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
                    }
                }
            }
        }
        .shimmer()
        .staggeredAppear(appeared: appeared, delay: 0.06)
    }

    private var regionBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("REGIONAL BREAKDOWN")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(1.8)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(result.regions.enumerated()), id: \.element.id) { index, region in
                    regionCard(region: region)
                        .staggeredAppear(appeared: appeared, delay: 0.12 + Double(index) * 0.04)
                }
            }
        }
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

                    Image(systemName: showMetrics ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }

            if showMetrics {
                VStack(spacing: 10) {
                    ForEach(result.metrics) { metric in
                        metricRow(metric: metric)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.4)
    }

    private func metricRow(metric: SkinMetric) -> some View {
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
                            .frame(width: geo.size.width * CGFloat(metric.score) / 100.0, height: 5)
                            .shadow(color: scoreBarColors(for: metric.score).first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 0)
                    }
                }
                .frame(height: 5)
            }
        }
    }

    private func scoreBarColors(for score: Int) -> [Color] {
        if score >= 80 { return [Color(hex: "4CAF50"), Color(hex: "66BB6A")] }
        if score >= 60 { return [CelleuxColors.warmGold, Color(hex: "D4A574")] }
        return [Color(hex: "E8A838"), Color(hex: "E53935")]
    }

    private var comparisonPlaceholder: some View {
        GlassCard {
            VStack(spacing: 14) {
                HStack {
                    Text("COMPARISON")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1.8)
                    Spacer()
                }

                HStack(spacing: 24) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [CelleuxColors.silver.opacity(0.1), CelleuxColors.silver.opacity(0.03)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 38
                                    )
                                )
                                .frame(width: 74, height: 74)

                            Circle()
                                .stroke(CelleuxColors.chromeBorder, lineWidth: 0.5)
                                .frame(width: 74, height: 74)

                            Image(systemName: "person.fill")
                                .font(.system(size: 24, weight: .ultraLight))
                                .foregroundStyle(CelleuxColors.silver)
                        }
                        Text("Previous")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(CelleuxColors.silver)

                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [CelleuxColors.warmGold.opacity(0.1), CelleuxColors.warmGold.opacity(0.03)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 38
                                    )
                                )
                                .frame(width: 74, height: 74)

                            Circle()
                                .stroke(
                                    AngularGradient(
                                        colors: [CelleuxColors.warmGold.opacity(0.3), CelleuxColors.warmGold.opacity(0.1), CelleuxColors.warmGold.opacity(0.25)],
                                        center: .center
                                    ),
                                    lineWidth: 0.5
                                )
                                .frame(width: 74, height: 74)

                            Image(systemName: "person.fill")
                                .font(.system(size: 24, weight: .ultraLight))
                                .foregroundStyle(CelleuxColors.warmGold)
                        }
                        Text("Now")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.5)
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
