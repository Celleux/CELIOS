import SwiftUI

struct ProgressComparisonView: View {
    let currentResult: SkinScanResult?
    let history: [SkinScanResult]
    @Binding var selectedTimeframe: ProgressTimeframe
    let onDismiss: () -> Void

    @State private var appeared: Bool = false

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
        VStack(spacing: 0) {
            headerBar
            timeframePicker
            splitScreenContent
            metricsDelta
        }
        .background(Color(hex: "0A0A10").ignoresSafeArea())
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
                .foregroundStyle(Color(hex: "00F2D8"))
            }

            Spacer()

            Text("PROGRESS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(2)

            Spacer()

            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var timeframePicker: some View {
        HStack(spacing: 6) {
            ForEach(ProgressTimeframe.allCases, id: \.rawValue) { timeframe in
                let isSelected = selectedTimeframe == timeframe
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    Text(timeframe.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? Color(hex: "00F2D8") : .white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color(hex: "00F2D8").opacity(0.12) : Color.white.opacity(0.05))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color(hex: "00F2D8").opacity(0.4) : Color.clear, lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var splitScreenContent: some View {
        HStack(spacing: 2) {
            progressPanel(
                title: "THEN",
                subtitle: comparisonResult?.shortDateString ?? "No data",
                score: comparisonResult?.overallScore ?? 0,
                isPast: true
            )

            Rectangle()
                .fill(Color(hex: "00F2D8").opacity(0.3))
                .frame(width: 1)

            progressPanel(
                title: "NOW",
                subtitle: currentResult?.shortDateString ?? "Today",
                score: currentResult?.overallScore ?? 0,
                isPast: false
            )
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "00F2D8").opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private func progressPanel(title: String, subtitle: String, score: Int, isPast: Bool) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0F1018"), Color(hex: "0A0A10")],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(isPast ? .white.opacity(0.4) : Color(hex: "00F2D8"))
                        .tracking(2)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                }

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 6)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: appeared ? Double(score) / 100.0 : 0)
                        .stroke(
                            LinearGradient(
                                colors: isPast ? [Color.white.opacity(0.3), Color.white.opacity(0.15)] : [Color(hex: "00F2D8"), Color(hex: "8B5CF6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.2).delay(0.3), value: appeared)

                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 32, weight: .ultraLight))
                            .foregroundStyle(isPast ? .white.opacity(0.5) : .white)
                        Text("SCORE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                            .tracking(1)
                    }
                }

                if !isPast, let current = currentResult?.overallScore, let past = comparisonResult?.overallScore {
                    let delta = current - past
                    HStack(spacing: 4) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(String(format: "%+d", delta))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(delta >= 0 ? Color(hex: "4CAF50") : Color(hex: "FF4D6A"))
                }
            }
        }
    }

    private var metricsDelta: some View {
        VStack(spacing: 10) {
            Text("METRIC CHANGES")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)
                .padding(.top, 16)

            if let current = currentResult?.analysisData, let past = comparisonResult?.analysisData {
                HStack(spacing: 0) {
                    deltaMetric(label: "Texture", current: current.textureScore, past: past.textureScore, color: Color(hex: "FF9500"))
                    Spacer()
                    deltaMetric(label: "Hydration", current: current.hydrationScore, past: past.hydrationScore, color: Color(hex: "00B4D8"))
                    Spacer()
                    deltaMetric(label: "Brightness", current: current.brightnessScore, past: past.brightnessScore, color: Color(hex: "8B5CF6"))
                    Spacer()
                    deltaMetric(label: "Redness", current: current.rednessScore, past: past.rednessScore, color: Color(hex: "FF4D6A"))
                }
                .padding(.horizontal, 20)
            } else {
                Text("Complete more scans to see progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.vertical, 20)
            }
        }
        .padding(.bottom, 20)
        .staggeredAppear(appeared: appeared, delay: 0.2)
    }

    private func deltaMetric(label: String, current: Double, past: Double, color: Color) -> some View {
        let delta = current - past
        return VStack(spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 8, weight: .bold))
                Text(String(format: "%+.0f", delta))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
            }
            .foregroundStyle(delta >= 0 ? Color(hex: "4CAF50") : Color(hex: "FF4D6A"))

            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase)
                .tracking(0.5)

            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.3))
                .frame(width: 40, height: 3)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: max(0, min(40, 40 * current / 100)), height: 3)
                }
        }
    }
}
