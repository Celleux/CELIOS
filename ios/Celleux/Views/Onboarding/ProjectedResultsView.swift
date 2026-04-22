import SwiftUI
import Charts

struct ProjectedResultsView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared: Bool = false
    @State private var chartProgress: CGFloat = 0
    @State private var scoreValue: Int = 42
    @State private var hapticTrigger: Int = 0

    private var dataPoints: [ProjectionPoint] {
        [
            ProjectionPoint(week: 0, score: 42, kind: .baseline),
            ProjectionPoint(week: 2, score: 51, kind: .projected),
            ProjectionPoint(week: 4, score: 62, kind: .projected),
            ProjectionPoint(week: 6, score: 70, kind: .projected),
            ProjectionPoint(week: 8, score: 76, kind: .projected),
            ProjectionPoint(week: 12, score: 83, kind: .projected)
        ]
    }

    private var userLabel: String {
        let name = viewModel.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "You" : name
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: CelleuxSpacing.lg) {
                    header
                        .staggeredAppear(appeared: appeared, delay: 0)
                        .padding(.top, CelleuxSpacing.xl)

                    chartCard
                        .staggeredAppear(appeared: appeared, delay: 0.12)
                        .padding(.horizontal, CelleuxSpacing.lg)

                    insightsCard
                        .staggeredAppear(appeared: appeared, delay: 0.22)
                        .padding(.horizontal, CelleuxSpacing.lg)

                    disclaimer
                        .staggeredAppear(appeared: appeared, delay: 0.32)
                        .padding(.horizontal, CelleuxSpacing.xl)

                    Spacer().frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)

            Button {
                hapticTrigger += 1
                onContinue()
            } label: {
                HStack(spacing: 10) {
                    Text("Unlock My Plan")
                        .font(.system(size: 17, weight: .medium))
                        .tracking(0.5)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(CelleuxColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .buttonStyle(Premium3DButtonStyle())
            .padding(.horizontal, CelleuxSpacing.lg)
            .padding(.bottom, 40)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)
        }
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 2.0).delay(0.4)) {
                chartProgress = 1.0
            }
            animateScore()
        }
    }

    private var header: some View {
        VStack(spacing: CelleuxSpacing.sm) {
            Text("BASED ON YOUR PROFILE")
                .font(CelleuxType.label)
                .tracking(CelleuxType.labelTracking)
                .foregroundStyle(CelleuxColors.warmGold.opacity(0.8))

            Text("\(userLabel), here's your\nprojected trajectory")
                .font(.system(size: 28, weight: .light))
                .tracking(0.5)
                .foregroundStyle(CelleuxColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Users matching your profile see an\naverage 41-point improvement in 12 weeks.")
                .font(CelleuxType.body)
                .foregroundStyle(CelleuxColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CelleuxType.bodyLineSpacing)
                .padding(.horizontal, CelleuxSpacing.md)
                .padding(.top, 4)
        }
    }

    private var chartCard: some View {
        GlassCard(cornerRadius: 24, depth: .elevated, showShimmer: true) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LONGEVITY SCORE")
                            .font(CelleuxType.label)
                            .tracking(CelleuxType.labelTracking)
                            .foregroundStyle(CelleuxColors.textLabel)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(scoreValue)")
                                .font(.system(size: 44, weight: .thin))
                                .foregroundStyle(CelleuxColors.textPrimary)
                                .contentTransition(.numericText(countsDown: false))

                            Text("/ 100")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
                        Text("+41")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(CelleuxColors.warmGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(CelleuxColors.warmGold.opacity(0.12))
                    )
                }

                chart
                    .frame(height: 180)

                HStack {
                    legendDot(color: CelleuxColors.silver, label: "Today")
                    Spacer()
                    legendDot(color: CelleuxColors.warmGold, label: "Week 12")
                }
                .padding(.top, 4)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { idx, point in
                let progressCutoff = Double(dataPoints.count - 1) * Double(chartProgress)
                if Double(idx) <= progressCutoff + 0.5 {
                    AreaMark(
                        x: .value("Week", point.week),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CelleuxColors.warmGold.opacity(0.35), CelleuxColors.warmGold.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Week", point.week),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CelleuxColors.silver, CelleuxColors.warmGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    if idx == 0 || idx == dataPoints.count - 1 {
                        PointMark(
                            x: .value("Week", point.week),
                            y: .value("Score", point.score)
                        )
                        .foregroundStyle(idx == 0 ? CelleuxColors.silver : CelleuxColors.warmGold)
                        .symbolSize(80)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: [0, 4, 8, 12]) { value in
                AxisValueLabel {
                    if let week = value.as(Int.self) {
                        Text(week == 0 ? "Now" : "Wk \(week)")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
                AxisGridLine()
                    .foregroundStyle(CelleuxColors.silverBorder.opacity(0.2))
            }
        }
        .chartYAxis {
            AxisMarks(values: [30, 50, 70, 90]) { value in
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text("\(v)")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
                AxisGridLine()
                    .foregroundStyle(CelleuxColors.silverBorder.opacity(0.2))
            }
        }
        .chartYScale(domain: 30...95)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(CelleuxColors.textLabel)
                .textCase(.uppercase)
        }
    }

    private var insightsCard: some View {
        VStack(spacing: 10) {
            insightRow(icon: "sparkles", title: "Visible glow", detail: "By week 3", gradient: CelleuxColors.iconGoldGradient)
            insightRow(icon: "waveform.path.ecg", title: "Baseline established", detail: "Within 7 days", gradient: CelleuxColors.iconAmberGradient)
            insightRow(icon: "leaf.fill", title: "Plan adapts to you", detail: "Every scan refines it", gradient: CelleuxColors.iconLavenderGradient)
        }
    }

    private func insightRow(icon: String, title: String, detail: String, gradient: LinearGradient) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 38, height: 38)

                Circle()
                    .stroke(CelleuxColors.goldChromeBorder, lineWidth: 0.8)
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(gradient)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(CelleuxColors.textPrimary)

                Text(detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(CelleuxColors.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CelleuxColors.chromeBorder, lineWidth: 1)
        )
    }

    private var disclaimer: some View {
        Text("Projections are estimates based on anonymized user data. Individual results depend on adherence, biology, and lifestyle.")
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(CelleuxColors.textLabel)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
    }

    private func animateScore() {
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            let steps = 40
            let duration = 1.8
            let interval = duration / Double(steps)
            for step in 0...steps {
                let value = 42 + Int(Double(83 - 42) * Double(step) / Double(steps))
                withAnimation(.linear(duration: interval)) {
                    scoreValue = value
                }
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
            }
        }
    }
}

private struct ProjectionPoint: Identifiable {
    let week: Int
    let score: Int
    let kind: Kind
    var id: Int { week }

    enum Kind { case baseline, projected }
}
