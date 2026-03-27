import SwiftUI

struct SkinConcernOverlayView: View {
    @Binding var selectedMode: HeatMapMode
    @Binding var showHeatMap: Bool
    let scanResult: SkinScanResult?

    @State private var appeared: Bool = false

    private let regionNames = ["Forehead", "Left Cheek", "Right Cheek", "Chin", "Under-Eyes", "Nose"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                headerRow
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                if showHeatMap {
                    modeSelector
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                    if let result = scanResult {
                        regionScoreGrid(result: result)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                        colorScaleLegend
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .padding(.bottom, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "E8D6A8").opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .allowsHitTesting(true)
        .sensoryFeedback(.selection, trigger: selectedMode)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AR SKIN MAP")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "E8D6A8"))
                    .tracking(2)
                Text(selectedMode == .all ? "All metrics overlay" : "\(selectedMode.rawValue) analysis")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .contentTransition(.numericText())
            }
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showHeatMap.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(showHeatMap ? Color(hex: "E8D6A8") : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(showHeatMap ? "ACTIVE" : "OFF")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(showHeatMap ? Color(hex: "E8D6A8") : .white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(showHeatMap ? Color(hex: "E8D6A8").opacity(0.15) : Color.white.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .stroke(showHeatMap ? Color(hex: "E8D6A8").opacity(0.4) : Color.white.opacity(0.15), lineWidth: 0.5)
                )
            }
        }
    }

    private var modeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HeatMapMode.allCases, id: \.rawValue) { mode in
                    let isSelected = selectedMode == mode
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedMode = mode
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 10, weight: .medium))
                            Text(mode.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(isSelected ? mode.accentColor : .white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(isSelected ? mode.accentColor.opacity(0.15) : Color.white.opacity(0.05))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? mode.accentColor.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .contentMargins(.horizontal, 0)
    }

    private func regionScoreGrid(result: SkinScanResult) -> some View {
        let data = result.analysisData
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6)
        ], spacing: 6) {
            ForEach(regionNames, id: \.self) { region in
                let scores = data?.regionData[region] ?? RegionScores()
                let score = regionScore(scores: scores)
                regionScoreCell(name: shortRegionName(region), score: score)
            }
        }
        .padding(.horizontal, 16)
    }

    private func regionScore(scores: RegionScores) -> Int {
        if let metricType = selectedMode.metricType {
            return Int(scores.score(for: metricType).rounded())
        }
        let metrics: [Double] = [
            scores.textureEvennessScore,
            scores.apparentHydrationScore,
            scores.brightnessRadianceScore,
            scores.rednessScore,
            scores.poreVisibilityScore,
            scores.toneUniformityScore
        ]
        let nonZero = metrics.filter { $0 > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return Int((nonZero.reduce(0, +) / Double(nonZero.count)).rounded())
    }

    private func shortRegionName(_ name: String) -> String {
        switch name {
        case "Left Cheek": "L Cheek"
        case "Right Cheek": "R Cheek"
        case "Under-Eyes": "Under-Eye"
        default: name
        }
    }

    private func regionScoreCell(name: String, score: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(score)")
                .font(.system(size: 20, weight: .light, design: .monospaced))
                .foregroundStyle(heatColor(for: score))
                .contentTransition(.numericText())

            Text(name)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(heatColor(for: score).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(heatColor(for: score).opacity(0.15), lineWidth: 0.5)
        )
    }

    private var colorScaleLegend: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "E53935"),
                                    Color(hex: "E8A838"),
                                    Color(hex: "C9A96E"),
                                    Color(hex: "E8D6A8")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("Poor")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "E53935").opacity(0.8))
                    .tracking(0.5)
                Spacer()
                Text("Fair")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "E8A838").opacity(0.8))
                    .tracking(0.5)
                Spacer()
                Text("Good")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "C9A96E").opacity(0.8))
                    .tracking(0.5)
                Spacer()
                Text("Excellent")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "E8D6A8").opacity(0.8))
                    .tracking(0.5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
    }

    private func heatColor(for score: Int) -> Color {
        if score >= 80 { return Color(hex: "E8D6A8") }
        if score >= 60 { return Color(hex: "C9A96E") }
        if score >= 40 { return Color(hex: "E8A838") }
        return Color(hex: "E53935")
    }
}
