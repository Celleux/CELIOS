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
        case "up": "\u{2191}"
        case "down": "\u{2193}"
        default: "\u{2192}"
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

    // MARK: - Circular Lock Screen

    private var circularView: some View {
        Group {
            if hasData {
                Gauge(value: Double(entry.score), in: 0...100) {
                    Text("\(entry.score)")
                        .font(.system(.body, design: .rounded, weight: .bold))
                } currentValueLabel: {
                    Text("\(entry.score)")
                        .font(.system(.body, design: .rounded, weight: .bold))
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "face.smiling")
                        .font(.title3)
                    Text("Scan")
                        .font(.caption2)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Rectangular Lock Screen

    private var rectangularView: some View {
        Group {
            if hasData {
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Skin Score")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text("\(entry.score)")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                            Text(trendArrow)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(timeSinceLastScan)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "face.smiling")
                    Text("Scan for your skin score")
                        .font(.caption)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Small Home Screen

    private var smallView: some View {
        VStack(spacing: 8) {
            if hasData {
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.91, green: 0.84, blue: 0.67).opacity(0.2), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.score) / 100.0)
                        .stroke(
                            Color(red: 0.91, green: 0.84, blue: 0.67),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.score)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                .frame(width: 72, height: 72)

                Text("Skin Score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "face.smiling")
                    .font(.largeTitle)
                    .foregroundStyle(Color(red: 0.91, green: 0.84, blue: 0.67))
                Text("Scan for\nyour score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Medium Home Screen

    private var mediumView: some View {
        HStack(spacing: 16) {
            if hasData {
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.91, green: 0.84, blue: 0.67).opacity(0.2), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: CGFloat(entry.score) / 100.0)
                        .stroke(
                            Color(red: 0.91, green: 0.84, blue: 0.67),
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
                        .foregroundStyle(Color(red: 0.91, green: 0.84, blue: 0.67))
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
                    .foregroundStyle(Color(red: 0.91, green: 0.84, blue: 0.67))

                VStack(alignment: .leading, spacing: 4) {
                    Text("CELLEUX")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.91, green: 0.84, blue: 0.67))
                        .tracking(1.5)
                    Text("Scan to see your skin score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
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
