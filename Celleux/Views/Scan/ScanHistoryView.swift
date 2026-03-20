import SwiftUI

struct ScanHistoryView: View {
    let history: [SkinScanResult]
    let onSelectScan: (SkinScanResult) -> Void
    let onBack: () -> Void

    @State private var appeared: Bool = false
    @State private var chartAnimated: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                progressChart
                scanTimeline
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(CelleuxMeshBackground())
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                chartAnimated = true
            }
        }
    }

    private var progressChart: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("SCORE PROGRESSION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1.8)
                    Spacer()
                    Text("\(history.count) scans")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }

                if history.count >= 2 {
                    historyChart
                } else {
                    VStack(spacing: 12) {
                        ChromeIconBadge("chart.line.uptrend.xyaxis", size: 48)
                        Text("Complete more scans to see trends")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    private var historyChart: some View {
        let sortedHistory = history.sorted { $0.date < $1.date }
        let scores = sortedHistory.map { Double($0.overallScore) }
        let minScore = (scores.min() ?? 60) - 5
        let maxScore = (scores.max() ?? 90) + 5
        let range = maxScore - minScore

        return GeometryReader { geo in
            let width = geo.size.width
            let height: CGFloat = 120
            let stepX = scores.count > 1 ? width / CGFloat(scores.count - 1) : width

            ZStack(alignment: .bottomLeading) {
                ForEach(0..<4, id: \.self) { i in
                    let y = height * CGFloat(i) / 3.0
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(CelleuxColors.silver.opacity(0.08), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                }

                Path { path in
                    for (index, score) in scores.enumerated() {
                        let x = stepX * CGFloat(index)
                        let y = height - ((score - minScore) / range * height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            let prev = scores[index - 1]
                            let prevX = stepX * CGFloat(index - 1)
                            let prevY = height - ((prev - minScore) / range * height)
                            let cx1 = prevX + stepX * 0.4
                            let cx2 = x - stepX * 0.4
                            path.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: cx1, y: prevY),
                                control2: CGPoint(x: cx2, y: y)
                            )
                        }
                    }
                }
                .trim(from: 0, to: chartAnimated ? 1 : 0)
                .stroke(
                    LinearGradient(colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: CelleuxColors.warmGold.opacity(0.3), radius: 8, x: 0, y: 2)

                ForEach(Array(scores.enumerated()), id: \.offset) { index, score in
                    let x = stepX * CGFloat(index)
                    let y = height - ((score - minScore) / range * height)

                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .shadow(color: CelleuxColors.warmGold.opacity(0.3), radius: 4, x: 0, y: 1)
                        Circle()
                            .fill(CelleuxColors.warmGold.opacity(0.7))
                            .frame(width: 5, height: 5)
                    }
                    .position(x: x, y: y)
                    .opacity(chartAnimated ? 1 : 0)
                }

                ForEach(Array(sortedHistory.enumerated()), id: \.element.id) { index, scan in
                    let x = stepX * CGFloat(index)
                    Text(scan.shortDateString)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .position(x: x, y: height + 16)
                }
            }
        }
        .frame(height: 145)
    }

    private var scanTimeline: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SCAN HISTORY")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(1.8)

            if history.isEmpty {
                emptyState
            } else {
                ForEach(Array(history.enumerated()), id: \.element.id) { index, scan in
                    Button {
                        onSelectScan(scan)
                    } label: {
                        scanTimelineRow(scan: scan, isLast: index == history.count - 1)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: false)
                    .staggeredAppear(appeared: appeared, delay: 0.12 + Double(index) * 0.06)
                }
            }
        }
    }

    private func scanTimelineRow(scan: SkinScanResult, isLast: Bool) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                GlowingAccentBadge("faceid", color: CelleuxColors.warmGold, size: 44)

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.silver.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1.5, height: 24)
                }
            }

            CompactGlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scan.dateString)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textPrimary)

                        HStack(spacing: 8) {
                            Text("Score: \(scan.overallScore)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(CelleuxColors.warmGold)

                            if scan.trend != 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: scan.trend > 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 9, weight: .semibold))
                                    Text(String(format: "%+.1f%%", scan.trend))
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundStyle(scan.trend > 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
                            }
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(CelleuxColors.silver.opacity(0.1), lineWidth: 3)
                            .frame(width: 38, height: 38)

                        Circle()
                            .trim(from: 0, to: Double(scan.overallScore) / 100.0)
                            .stroke(CelleuxColors.goldGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 38, height: 38)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: CelleuxColors.goldGlow.opacity(0.2), radius: 3, x: 0, y: 0)

                        Text("\(scan.overallScore)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 16) {
                ChromeIconBadge("faceid", size: 58)

                Text("No scans yet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textPrimary)

                Text("Complete your first skin scan to start tracking your progress over time.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .staggeredAppear(appeared: appeared, delay: 0.12)
    }
}
