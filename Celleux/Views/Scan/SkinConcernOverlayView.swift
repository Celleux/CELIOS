import SwiftUI

struct SkinConcernOverlayView: View {
    @Binding var selectedMode: HeatMapMode
    @Binding var showHeatMap: Bool
    let scanResult: SkinScanResult?

    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AR SKIN MAP")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "E8D6A8"))
                            .tracking(2)
                        Text("Real-time concern overlay")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
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
                .padding(.horizontal, 16)
                .padding(.top, 14)

                if showHeatMap {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            concernFilterChip(mode: .all, label: "All", icon: "square.grid.3x3.fill", color: Color(hex: "E8D6A8"))
                            concernFilterChip(mode: .redness, label: "Redness", icon: "flame.fill", color: Color(hex: "D4A574"))
                            concernFilterChip(mode: .texture, label: "Texture", icon: "square.grid.3x3.fill", color: Color(hex: "C9A96E"))
                            concernFilterChip(mode: .darkSpots, label: "Dark Spots", icon: "circle.dotted", color: Color(hex: "B0B8C4"))
                            concernFilterChip(mode: .dehydration, label: "Hydration", icon: "drop.triangle.fill", color: Color(hex: "C0C8D4"))
                        }
                        .padding(.horizontal, 16)
                    }
                    .contentMargins(.horizontal, 0)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                    if let result = scanResult {
                        concernMetricsBar(result: result)
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
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func concernFilterChip(mode: HeatMapMode, label: String, icon: String, color: Color) -> some View {
        let isSelected = selectedMode == mode
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedMode = mode
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isSelected ? color : .white.opacity(0.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
    }

    private func concernMetricsBar(result: SkinScanResult) -> some View {
        HStack(spacing: 0) {
            concernMetricItem(label: "Redness", value: Int(result.analysisData?.rednessScore ?? 0), color: Color(hex: "D4A574"))
            Spacer()
            concernMetricItem(label: "Texture", value: Int(result.analysisData?.textureScore ?? 0), color: Color(hex: "C9A96E"))
            Spacer()
            concernMetricItem(label: "Clarity", value: Int(result.analysisData?.brightnessScore ?? 0), color: Color(hex: "B0B8C4"))
            Spacer()
            concernMetricItem(label: "Hydration", value: Int(result.analysisData?.hydrationScore ?? 0), color: Color(hex: "C0C8D4"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func concernMetricItem(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}
