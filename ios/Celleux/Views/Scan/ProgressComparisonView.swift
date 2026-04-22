import SwiftUI

struct ProgressComparisonView: View {
    let currentResult: SkinScanResult?
    let history: [SkinScanResult]
    @Binding var selectedTimeframe: ProgressTimeframe
    let onDismiss: () -> Void

    @State private var appeared: Bool = false
    @State private var showAllMetrics: Bool = false

    private static let primaryMetrics: Set<SkinMetricType> = [
        .textureEvenness, .apparentHydration, .brightnessRadiance,
        .rednessInflammation, .poreVisibility, .toneUniformity
    ]

    private var comparisonResult: SkinScanResult? {
        let calendar = Calendar.current
        let daysBack: Int
        switch selectedTimeframe {
        case .thirtyDays: daysBack = 30
        case .sixtyDays: daysBack = 60
        case .ninetyDays: daysBack = 90
        }

        let targetDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        return history.min(by: { abs($0.date.timeIntervalSince(targetDate)) < abs($1.date.timeIntervalSince(targetDate)) })
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                headerBar
                timeframePicker
                overallDelta
                metricComparisonList
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(CelleuxMeshBackground())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .medium))
                    Text("Back")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(CelleuxColors.warmGold)
            }

            Spacer()

            Text("PROGRESS")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(1.8)

            Spacer()

            Color.clear.frame(width: 60)
        }
    }

    private var timeframePicker: some View {
        HStack(spacing: 6) {
            ForEach(ProgressTimeframe.allCases, id: \.rawValue) { timeframe in
                let isSelected = selectedTimeframe == timeframe
                Button {
                    withAnimation(CelleuxSpring.snappy) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    Text(timeframe.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? CelleuxColors.warmGold : CelleuxColors.textLabel)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? CelleuxColors.warmGold.opacity(0.1) : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? CelleuxColors.warmGold.opacity(0.3) : Color.clear, lineWidth: 0.5)
                        )
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedTimeframe)
    }

    private var overallDelta: some View {
        GlassCard(depth: .elevated) {
            HStack {
                VStack(spacing: 6) {
                    Text("THEN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1)

                    Text(comparisonResult?.shortDateString ?? "—")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)

                    Text("\(comparisonResult?.overallScore ?? 0)")
                        .font(.system(size: 38, weight: .ultraLight))
                        .foregroundStyle(CelleuxColors.textSecondary)
                        .contentTransition(.numericText())
                }

                Spacer()

                if let current = currentResult?.overallScore, let past = comparisonResult?.overallScore {
                    let delta = current - past
                    VStack(spacing: 4) {
                        Image(systemName: delta >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(delta >= 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))

                        Text(String(format: "%+d", delta))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(delta >= 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
                            .contentTransition(.numericText())
                    }
                }

                Spacer()

                VStack(spacing: 6) {
                    Text("NOW")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .tracking(1)

                    Text(currentResult?.shortDateString ?? "Today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)

                    Text("\(currentResult?.overallScore ?? 0)")
                        .font(.system(size: 38, weight: .ultraLight))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .contentTransition(.numericText())
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    private var metricComparisonList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("METRIC CHANGES")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(1.8)

            if let currentData = currentResult?.analysisData, let pastData = comparisonResult?.analysisData {
                let allMetrics = SkinMetricType.allCases.filter { $0 != .overallSkinHealth && $0.isImplemented }
                let primary = allMetrics.filter { Self.primaryMetrics.contains($0) }
                let secondary = allMetrics.filter { !Self.primaryMetrics.contains($0) }

                ForEach(Array(primary.enumerated()), id: \.element.rawValue) { index, metric in
                    progressMetricRow(metric: metric, currentData: currentData, pastData: pastData, index: index)
                }

                if !secondary.isEmpty {
                    if showAllMetrics {
                        ForEach(Array(secondary.enumerated()), id: \.element.rawValue) { index, metric in
                            progressMetricRow(metric: metric, currentData: currentData, pastData: pastData, index: primary.count + index)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    } else {
                        Button {
                            withAnimation(CelleuxSpring.luxury) {
                                showAllMetrics = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .medium))
                                Text("See All Metrics")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(CelleuxColors.warmGold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(GlassButtonStyle(style: .primary))
                    }
                }
            } else {
                GlassCard {
                    VStack(spacing: 12) {
                        ChromeIconBadge("chart.bar.xaxis", size: 48)
                        Text("Complete more scans to see progress comparisons")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .staggeredAppear(appeared: appeared, delay: 0.1)
            }
        }
    }

    private func progressMetricRow(metric: SkinMetricType, currentData: SkinAnalysisData, pastData: SkinAnalysisData, index: Int) -> some View {
        let current = currentData.score(for: metric)
        let past = pastData.score(for: metric)
        let delta = current - past
        let improved = delta >= 0

        return CompactGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: metric.icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CelleuxColors.warmGold)

                    Text(metric.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: improved ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(String(format: "%+.0f", delta))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(improved ? Color(hex: "4CAF50") : Color(hex: "E8A838"))
                }

                HStack(spacing: 8) {
                    progressComparisonBar(score: past, label: "Before", isActive: false)
                    progressComparisonBar(score: current, label: "Now", isActive: true)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.08 + Double(index) * 0.04)
    }

    private func progressComparisonBar(score: Double, label: String, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isActive ? CelleuxColors.textSecondary : CelleuxColors.textLabel)

                Spacer()

                Text("\(Int(score.rounded()))")
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
