import SwiftUI
import SwiftData
import Charts

struct SkinForecastCard: View {
    let forecast: SkinForecast
    @State private var animateIn: Bool = false
    @State private var selectedHorizon: ForecastHorizon = .ninety

    enum ForecastHorizon: String, CaseIterable, Identifiable {
        case thirty = "30D"
        case sixty = "60D"
        case ninety = "90D"
        var id: String { rawValue }

        var days: Int {
            switch self {
            case .thirty: 30
            case .sixty: 60
            case .ninety: 90
            }
        }

        func value(in forecast: SkinForecast) -> Double {
            switch self {
            case .thirty: forecast.projectedScore30
            case .sixty: forecast.projectedScore60
            case .ninety: forecast.projectedScore90
            }
        }
    }

    private var visibleProjection: [SkinForecastPoint] {
        let weeks = selectedHorizon.days / 7
        return Array(forecast.projection.prefix(weeks))
    }

    private var visiblePoints: [SkinForecastPoint] {
        forecast.history + visibleProjection
    }

    private var projectedValue: Double {
        selectedHorizon.value(in: forecast)
    }

    private var gainFromCurrent: Double {
        projectedValue - forecast.currentScore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            horizonPicker
            chart
            metricsRow
            summaryPill
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(CelleuxColors.glassEdgeHighlight, lineWidth: 1)
        )
        .celleuxDepthShadow()
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.15)) {
                animateIn = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CelleuxColors.warmGold)
                    Text("SKIN TRAJECTORY")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1.5)
                }

                Text(forecast.confidenceLabel)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
            Spacer()

            HStack(spacing: 4) {
                Image(systemName: gainFromCurrent >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 10, weight: .bold))
                Text(String(format: "%+.0f", gainFromCurrent))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(gainFromCurrent >= 0 ? CelleuxColors.warmGold : Color(hex: "E53935"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill((gainFromCurrent >= 0 ? CelleuxColors.warmGold : Color(hex: "E53935")).opacity(0.1)))
        }
    }

    private var horizonPicker: some View {
        HStack(spacing: 6) {
            ForEach(ForecastHorizon.allCases) { horizon in
                Button {
                    withAnimation(CelleuxSpring.snappy) {
                        selectedHorizon = horizon
                    }
                } label: {
                    Text(horizon.rawValue)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(selectedHorizon == horizon ? CelleuxColors.textPrimary : CelleuxColors.textLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedHorizon == horizon ? Color.white : Color.clear)
                                .shadow(color: selectedHorizon == horizon ? .black.opacity(0.05) : .clear, radius: 3, y: 1)
                        )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selectedHorizon)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(CelleuxColors.silver.opacity(0.08))
        )
    }

    private var chart: some View {
        Chart {
            ForEach(visiblePoints) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Score", animateIn ? point.score : forecast.currentScore)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            CelleuxColors.warmGold.opacity(point.isProjected ? 0.22 : 0.32),
                            CelleuxColors.warmGold.opacity(0.02)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Score", animateIn ? point.score : forecast.currentScore)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(
                    lineWidth: point.isProjected ? 2.0 : 2.5,
                    lineCap: .round,
                    dash: point.isProjected ? [4, 3] : []
                ))
            }

            if let endPoint = visiblePoints.last {
                PointMark(
                    x: .value("Date", endPoint.date),
                    y: .value("Score", animateIn ? endPoint.score : forecast.currentScore)
                )
                .foregroundStyle(CelleuxColors.warmGold)
                .symbolSize(80)
                .annotation(position: .top, spacing: 4) {
                    Text("\(Int(endPoint.score))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color.white.opacity(0.95))
                        )
                        .overlay(
                            Capsule().stroke(CelleuxColors.warmGold.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            if let todayPoint = forecast.history.last {
                RuleMark(x: .value("Today", todayPoint.date))
                    .foregroundStyle(CelleuxColors.silver.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
            }
        }
        .chartYScale(domain: forecast.minY...forecast.maxY)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(7, selectedHorizon.days / 4))) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 9))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisValueLabel()
                    .font(.system(size: 9))
                    .foregroundStyle(CelleuxColors.textLabel)
                AxisGridLine()
                    .foregroundStyle(CelleuxColors.silver.opacity(0.1))
            }
        }
        .frame(height: 170)
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            metricCell(label: "TODAY", value: Int(forecast.currentScore), tone: .current)
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CelleuxColors.textLabel)
            metricCell(label: selectedHorizon.rawValue, value: Int(projectedValue), tone: .projected)
        }
    }

    enum MetricTone { case current, projected }

    private func metricCell(label: String, value: Int, tone: MetricTone) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(1.2)
            Text("\(value)")
                .font(.system(size: 26, weight: .light, design: .rounded))
                .foregroundStyle(tone == .projected ? CelleuxColors.warmGold : CelleuxColors.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tone == .projected ? CelleuxColors.warmGold.opacity(0.06) : CelleuxColors.silver.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tone == .projected ? CelleuxColors.warmGold.opacity(0.25) : CelleuxColors.silver.opacity(0.15), lineWidth: 1)
        )
    }

    private var summaryPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CelleuxColors.warmGold)
            Text(forecast.summary)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CelleuxColors.textSecondary)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(CelleuxColors.warmGold.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(CelleuxColors.warmGold.opacity(0.15), lineWidth: 1)
        )
    }
}

struct SkinForecastCardContainer: View {
    @Query(sort: \SkinScanRecord.date, order: .reverse) private var scans: [SkinScanRecord]
    @Query(sort: \DailyLongevityScore.date, order: .reverse) private var longevityScores: [DailyLongevityScore]

    var body: some View {
        if let forecast = ForecastEngine.shared.computeForecast(scans: scans, longevityScores: longevityScores) {
            SkinForecastCard(forecast: forecast)
        } else {
            EmptyView()
        }
    }
}
