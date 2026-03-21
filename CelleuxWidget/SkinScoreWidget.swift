import WidgetKit
import SwiftUI

nonisolated struct SkinScoreEntry: TimelineEntry {
    let date: Date
    let score: Int
    let trend: String
    let lastScanDate: Date?
}

nonisolated struct SkinScoreProvider: TimelineProvider {
    private let appGroupID = "group.app.rork.celleux-new-ui"

    func placeholder(in context: Context) -> SkinScoreEntry {
        SkinScoreEntry(date: Date(), score: 82, trend: "up", lastScanDate: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SkinScoreEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SkinScoreEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> SkinScoreEntry {
        let shared = UserDefaults(suiteName: appGroupID)
        let score = shared?.integer(forKey: "widgetSkinScore") ?? 0
        let trend = shared?.string(forKey: "widgetSkinTrend") ?? "stable"
        let lastScanInterval = shared?.double(forKey: "widgetLastScanDate") ?? 0
        let lastScanDate = lastScanInterval > 0 ? Date(timeIntervalSince1970: lastScanInterval) : nil

        return SkinScoreEntry(
            date: Date(),
            score: score,
            trend: trend,
            lastScanDate: lastScanDate
        )
    }
}

private let widgetGold = Color(red: 0.79, green: 0.66, blue: 0.43)
private let widgetGoldLight = Color(red: 0.83, green: 0.77, blue: 0.63)
private let widgetGoldDark = Color(red: 0.72, green: 0.59, blue: 0.42)
private let widgetCream = Color(red: 0.96, green: 0.95, blue: 0.93)

struct SkinScoreWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SkinScoreEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var trendArrow: String {
        switch entry.trend {
        case "up": return "\u{2191}"
        case "down": return "\u{2193}"
        default: return "\u{2192}"
        }
    }

    private var trendWord: String {
        switch entry.trend {
        case "up": return "Improving"
        case "down": return "Declining"
        default: return "Steady"
        }
    }

    private var timeSinceLastScan: String {
        guard let lastScan = entry.lastScanDate else { return "No scans" }
        let interval = Date().timeIntervalSince(lastScan)
        let hours = Int(interval / 3600)
        if hours < 1 { return "Just now" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
        }

    private var hasData: Bool {
        entry.score > 0
    }

    private var isStale: Bool {
        guard let lastScan = entry.lastScanDate else { return true }
        return Date().timeIntervalSince(lastScan) > 86400
    }

    // MARK: - Circular Lock Screen

    private var circularView: some View {
        Group {
            if hasData {
                Gauge(value: Double(entry.score), in: 0...100) {
                    Text("Skin")
                } currentValueLabel: {
                    Text("\(entry.score)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [widgetGoldLight, widgetGold]))
            } else {
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 1) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 18, weight: .light))
                        Text("Scan")
                            .font(.system(size: 9, weight: .medium))
                    }
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "celleux://scan"))
    }

    // MARK: - Rectangular Lock Screen

    private var rectangularView: some View {
        Group {
            if hasData {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 8, weight: .semibold))
                            Text("SKIN SCORE")
                                .font(.system(size: 8, weight: .semibold))
                                .tracking(0.8)
                        }
                        .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(entry.score)")
                                .font(.system(size: 26, design: .rounded, weight: .bold))

                            Text(trendArrow)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(trendWord)
                            .font(.system(size: 10, weight: .medium))
                        Text(timeSinceLastScan)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20, weight: .light))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CELLEUX")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(.secondary)
                        Text("Scan for your score")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "celleux://scan"))
    }

    // MARK: - Small Home Screen

    private var smallView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("CELLEUX")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(widgetGold.opacity(0.9))
                Spacer()
                if hasData && !isStale {
                    Circle()
                        .fill(widgetGold)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.bottom, 6)

            Spacer()

            if hasData {
                ZStack {
                    Circle()
                        .stroke(widgetGold.opacity(0.12), lineWidth: 5)
                        .frame(width: 76, height: 76)

                    Circle()
                        .trim(from: 0, to: CGFloat(entry.score) / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: [widgetGoldLight, widgetGold, widgetGoldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 76, height: 76)
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [widgetGold.opacity(0.06), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 38
                            )
                        )
                        .frame(width: 76, height: 76)

                    VStack(spacing: -1) {
                        Text("\(entry.score)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(trendArrow)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("Skin Score")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)

                    if isStale {
                        Text("Scan for latest")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(widgetGold.opacity(0.8))
                    } else {
                        Text(timeSinceLastScan)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(widgetGold.opacity(0.15), lineWidth: 5)
                            .frame(width: 76, height: 76)

                        Image(systemName: "face.smiling")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundStyle(widgetGold.opacity(0.6))
                    }

                    Text("Scan for\nyour score")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                ContainerRelativeShape()
                    .fill(Color(.systemBackground))

                ContainerRelativeShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                widgetGold.opacity(0.04),
                                Color.clear,
                                widgetGold.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [widgetGold.opacity(0.05), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 120, height: 120)
                            .offset(x: 30, y: 30)
                    }
                }
            }
        }
        .widgetURL(URL(string: "celleux://scan"))
    }

    // MARK: - Medium Home Screen

    private var mediumView: some View {
        HStack(spacing: 16) {
            if hasData {
                ZStack {
                    Circle()
                        .stroke(widgetGold.opacity(0.12), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.score) / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: [widgetGoldLight, widgetGold, widgetGoldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(entry.score)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text(trendArrow)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 6) {
                    Text("CELLEUX")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(widgetGold)
                        .tracking(1.5)

                    Text("Skin Score")
                        .font(.headline)

                    Text(timeSinceLastScan)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                Image(systemName: "face.smiling")
                    .font(.largeTitle)
                    .foregroundStyle(widgetGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("CELLEUX")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(widgetGold)
                        .tracking(1.5)
                    Text("Scan to see your skin score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                ContainerRelativeShape()
                    .fill(Color(.systemBackground))

                ContainerRelativeShape()
                    .fill(
                        LinearGradient(
                            colors: [widgetGold.opacity(0.03), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
}

struct SkinScoreWidget: Widget {
    let kind = "SkinScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SkinScoreProvider()) { entry in
            SkinScoreWidgetView(entry: entry)
        }
        .configurationDisplayName("Skin Score")
        .description("Track your skin health score at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .systemSmall,
            .systemMedium,
        ])
    }
}
