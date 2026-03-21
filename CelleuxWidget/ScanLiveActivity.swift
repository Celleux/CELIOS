import ActivityKit
import WidgetKit
import SwiftUI

private let liveGold = Color(red: 0.79, green: 0.66, blue: 0.43)
private let liveGoldLight = Color(red: 0.83, green: 0.77, blue: 0.63)
private let liveGoldDark = Color(red: 0.72, green: 0.59, blue: 0.42)

struct ScanLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ScanActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: "faceid")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(liveGold)
                        Text("CELLEUX")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(liveGold.opacity(0.7))
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 6) {
                        Text(context.state.statusText)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)

                        ProgressView(value: context.state.progress)
                            .tint(LinearGradient(
                                colors: [liveGoldLight, liveGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))

                        Text(context.state.detailText)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(liveGold)

                        if context.state.estimatedSecondsRemaining > 0 {
                            Text("\(context.state.estimatedSecondsRemaining)s")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "faceid")
                        .font(.system(size: 12))
                        .foregroundStyle(liveGold)
                }
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(liveGold)
            } minimal: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(liveGold)
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<ScanActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "faceid")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(liveGold)
                    Text("CELLEUX SCAN")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(liveGold)
                }

                Spacer()

                Text("\(Int(context.state.progress * 100))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            ProgressView(value: context.state.progress)
                .tint(LinearGradient(
                    colors: [liveGoldLight, liveGold, liveGoldDark],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .scaleEffect(y: 1.5)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.statusText)
                        .font(.system(size: 13, weight: .semibold))
                    Text(context.state.detailText)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if context.state.estimatedSecondsRemaining > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.estimatedSecondsRemaining)s")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text("remaining")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if context.state.progress > 0.1 {
                HStack(spacing: 12) {
                    metricPill("Texture", active: context.state.progress >= 0.1)
                    metricPill("Hydration", active: context.state.progress >= 0.2)
                    metricPill("Radiance", active: context.state.progress >= 0.3)
                    metricPill("Pores", active: context.state.progress >= 0.5)
                    metricPill("Tone", active: context.state.progress >= 0.6)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
    }

    private func metricPill(_ name: String, active: Bool) -> some View {
        Text(name)
            .font(.system(size: 9, weight: active ? .semibold : .regular))
            .foregroundStyle(active ? .primary : .tertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(active ? liveGold.opacity(0.15) : Color(.tertiarySystemFill))
            )
    }
}
