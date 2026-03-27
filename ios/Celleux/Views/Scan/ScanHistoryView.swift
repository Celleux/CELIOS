import SwiftUI
import Charts

struct ScanHistoryView: View {
    let history: [SkinScanResult]
    let onSelectScan: (SkinScanResult) -> Void
    let onBack: () -> Void
    var onCompare: ((SkinScanResult, SkinScanResult) -> Void)? = nil

    @State private var appeared: Bool = false
    @State private var chartAnimated: Bool = false
    @State private var selectedTimeRange: HistoryTimeRange = .all
    @State private var selectedDataPoint: SkinScanResult? = nil
    @State private var compareMode: Bool = false
    @State private var firstCompareScan: SkinScanResult? = nil

    private var filteredHistory: [SkinScanResult] {
        let now = Date()
        let calendar = Calendar.current
        return history.filter { scan in
            switch selectedTimeRange {
            case .sevenDays:
                guard let cutoff = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
                return scan.date >= cutoff
            case .thirtyDays:
                guard let cutoff = calendar.date(byAdding: .day, value: -30, to: now) else { return true }
                return scan.date >= cutoff
            case .ninetyDays:
                guard let cutoff = calendar.date(byAdding: .day, value: -90, to: now) else { return true }
                return scan.date >= cutoff
            case .all:
                return true
            }
        }
    }

    private var sortedFiltered: [SkinScanResult] {
        filteredHistory.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                timeRangeSelector
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

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: 6) {
            ForEach(HistoryTimeRange.allCases, id: \.rawValue) { range in
                let isSelected = selectedTimeRange == range
                Button {
                    withAnimation(CelleuxSpring.snappy) {
                        selectedTimeRange = range
                        selectedDataPoint = nil
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? CelleuxColors.warmGold : CelleuxColors.textLabel)
                        .padding(.horizontal, 14)
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
        .sensoryFeedback(.selection, trigger: selectedTimeRange)
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    // MARK: - Progress Chart

    private var progressChart: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("SCORE PROGRESSION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1.8)
                    Spacer()
                    Text("\(filteredHistory.count) scans")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }

                if sortedFiltered.count >= 2 {
                    areaChart
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

                if let selected = selectedDataPoint {
                    selectedScanInfo(selected)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.06)
    }

    private var areaChart: some View {
        let data = sortedFiltered
        let scores = data.map { Double($0.overallScore) }
        let minY = max(0, (scores.min() ?? 60) - 10)
        let maxY = min(100, (scores.max() ?? 90) + 10)

        return Chart(Array(data.enumerated()), id: \.element.id) { index, scan in
            LineMark(
                x: .value("Date", scan.date),
                y: .value("Score", chartAnimated ? Double(scan.overallScore) : minY)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

            AreaMark(
                x: .value("Date", scan.date),
                y: .value("Score", chartAnimated ? Double(scan.overallScore) : minY)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        CelleuxColors.warmGold.opacity(0.2),
                        CelleuxColors.warmGold.opacity(0.05),
                        CelleuxColors.warmGold.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            if let selected = selectedDataPoint, selected.id == scan.id {
                PointMark(
                    x: .value("Date", scan.date),
                    y: .value("Score", Double(scan.overallScore))
                )
                .symbol {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .shadow(color: CelleuxColors.warmGold.opacity(0.4), radius: 4, x: 0, y: 2)
                        Circle()
                            .fill(CelleuxColors.warmGold)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(CelleuxColors.silver.opacity(0.08))
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisValueLabel {
                    if let score = value.as(Int.self) {
                        Text("\(score)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(CelleuxColors.silver.opacity(0.06))
            }
        }
        .chartYScale(domain: minY...maxY)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let date: Date = proxy.value(atX: location.x) else { return }
                        let closest = data.min(by: {
                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                        })
                        withAnimation(CelleuxSpring.snappy) {
                            selectedDataPoint = closest
                        }
                    }
            }
        }
        .frame(height: 180)
        .animation(.easeOut(duration: 1.0), value: chartAnimated)
    }

    private func selectedScanInfo(_ scan: SkinScanResult) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(scan.dateString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CelleuxColors.textPrimary)

                Text("Score: \(scan.overallScore)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CelleuxColors.warmGold)
            }

            Spacer()

            Button {
                onSelectScan(scan)
            } label: {
                Text("View Details")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CelleuxColors.warmGold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
            }
            .buttonStyle(OutlineGlassButtonStyle())
        }
        .padding(.top, 4)
    }

    // MARK: - Scan Timeline

    private var scanTimeline: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(compareMode ? "SELECT SECOND SCAN" : "SCAN HISTORY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(compareMode ? CelleuxColors.warmGold : CelleuxColors.textLabel)
                    .tracking(1.8)
                    .contentTransition(.numericText())

                Spacer()

                if compareMode {
                    Button {
                        withAnimation(CelleuxSpring.snappy) {
                            compareMode = false
                            firstCompareScan = nil
                        }
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                } else if onCompare != nil && filteredHistory.count >= 2 {
                    Button {
                        withAnimation(CelleuxSpring.snappy) {
                            compareMode = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 10, weight: .medium))
                            Text("Compare")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(CelleuxColors.warmGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(CelleuxColors.warmGold.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(CelleuxColors.warmGold.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                }
            }

            if compareMode, let first = firstCompareScan {
                compareSelectionBanner(first: first)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if filteredHistory.isEmpty {
                emptyState
            } else {
                let sortedDesc = filteredHistory.sorted { $0.date > $1.date }
                ForEach(Array(sortedDesc.enumerated()), id: \.element.id) { index, scan in
                    Button {
                        handleScanTap(scan)
                    } label: {
                        scanTimelineRow(scan: scan, isLast: index == sortedDesc.count - 1)
                            .overlay {
                                if compareMode {
                                    if firstCompareScan?.id == scan.id {
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(CelleuxColors.warmGold, lineWidth: 2)
                                            .padding(.leading, 58)
                                    } else if firstCompareScan != nil {
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(CelleuxColors.warmGold.opacity(0.3), lineWidth: 1)
                                            .padding(.leading, 58)
                                    }
                                }
                            }
                    }
                    .buttonStyle(PressableButtonStyle())
                    .sensoryFeedback(.selection, trigger: false)
                    .staggeredAppear(appeared: appeared, delay: 0.12 + Double(index) * 0.06)
                }
            }
        }
    }

    private func handleScanTap(_ scan: SkinScanResult) {
        if compareMode {
            if firstCompareScan == nil {
                withAnimation(CelleuxSpring.snappy) {
                    firstCompareScan = scan
                }
            } else if firstCompareScan?.id != scan.id {
                let first = firstCompareScan!
                let sorted = [first, scan].sorted { $0.date < $1.date }
                withAnimation(CelleuxSpring.snappy) {
                    compareMode = false
                    firstCompareScan = nil
                }
                onCompare?(sorted[0], sorted[1])
            }
        } else {
            onSelectScan(scan)
        }
    }

    private func compareSelectionBanner(first: SkinScanResult) -> some View {
        CompactGlassCard {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(CelleuxColors.warmGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("First scan selected")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)
                    Text("\(first.shortDateString) \u{2022} Score: \(first.overallScore)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }

                Spacer()

                Text("Tap another")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(CelleuxColors.warmGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(CelleuxColors.warmGold.opacity(0.1))
                    )
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
                                    Text(String(format: "%+.0f", scan.trend))
                                        .font(.system(size: 10, weight: .semibold))
                                        .contentTransition(.numericText())
                                }
                                .foregroundStyle(scan.trend > 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
                            }
                        }
                    }

                    Spacer()

                    MetricRingMini(score: scan.overallScore, size: 38)

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

nonisolated enum HistoryTimeRange: String, CaseIterable, Sendable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case all = "All"
}
