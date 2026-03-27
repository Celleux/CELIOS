import SwiftUI

enum ComparisonMode: String, CaseIterable {
    case slider = "Slider"
    case sideBySide = "Side by Side"
    case timelapse = "Time-lapse"

    var icon: String {
        switch self {
        case .slider: "slider.horizontal.below.rectangle"
        case .sideBySide: "rectangle.split.2x1"
        case .timelapse: "film.stack"
        }
    }
}

struct BeforeAfterComparisonView: View {
    let beforeScan: SkinScanResult
    let afterScan: SkinScanResult
    let allScans: [SkinScanResult]
    let onDismiss: () -> Void

    @State private var mode: ComparisonMode = .slider
    @State private var sliderPosition: CGFloat = 0.5
    @State private var showMetricBadges: Bool = false
    @State private var appeared: Bool = false
    @State private var timelapseIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var playbackTimer: Task<Void, Never>?
    @State private var shareImage: UIImage?
    @State private var showShareSheet: Bool = false
    @State private var isGeneratingShare: Bool = false

    private var sortedScans: [SkinScanResult] {
        allScans.sorted { $0.date < $1.date }
    }

    private var regionDeltas: [RegionDelta] {
        let regions = ["Forehead", "Left Cheek", "Right Cheek", "Chin", "Under-Eyes", "Nose"]
        return regions.compactMap { name in
            let beforeScore = beforeScan.regions.first { $0.name == name }?.score ?? 0
            let afterScore = afterScan.regions.first { $0.name == name }?.score ?? 0
            let delta = afterScore - beforeScore
            guard beforeScore > 0 || afterScore > 0 else { return nil }
            return RegionDelta(name: name, delta: delta, beforeScore: beforeScore, afterScore: afterScore, position: regionPosition(for: name))
        }
    }

    var body: some View {
        ZStack {
            Color(.displayP3, red: 0.06, green: 0.06, blue: 0.10)
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [CelleuxColors.warmGold.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(y: -100)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                headerBar
                modeSelector
                    .padding(.top, 8)

                Spacer(minLength: 12)

                Group {
                    switch mode {
                    case .slider:
                        sliderComparisonView
                    case .sideBySide:
                        sideBySideView
                    case .timelapse:
                        timelapseView
                    }
                }
                .frame(maxHeight: .infinity)

                if mode != .timelapse {
                    metricBadgeToggle
                        .padding(.top, 8)
                }

                bottomActions
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(image: image)
            }
        }
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
        }
        .onDisappear {
            stopPlayback()
        }
        .sensoryFeedback(.selection, trigger: mode)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("BEFORE / AFTER")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CelleuxColors.warmGold)
                    .tracking(2)

                Text("\(beforeScan.shortDateString) → \(afterScan.shortDateString)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            Spacer()

            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.top, 8)
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        HStack(spacing: 4) {
            ForEach(ComparisonMode.allCases, id: \.rawValue) { m in
                let isSelected = mode == m
                Button {
                    withAnimation(CelleuxSpring.snappy) {
                        if mode == .timelapse { stopPlayback() }
                        mode = m
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: m.icon)
                            .font(.system(size: 10, weight: .medium))
                        Text(m.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(isSelected ? CelleuxColors.warmGold : Color.white.opacity(0.4))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(isSelected ? CelleuxColors.warmGold.opacity(0.15) : Color.white.opacity(0.05))
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? CelleuxColors.warmGold.opacity(0.3) : Color.clear, lineWidth: 0.5)
                    )
                }
            }
        }
    }

    // MARK: - Slider Comparison

    private var sliderComparisonView: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                faceVisualization(scan: beforeScan, label: "BEFORE", width: width, height: height)

                faceVisualization(scan: afterScan, label: "AFTER", width: width, height: height)
                    .clipShape(
                        SliderClipShape(position: sliderPosition)
                    )

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [CelleuxColors.warmGold.opacity(0.8), CelleuxColors.champagneGold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: height)
                    .position(x: width * sliderPosition, y: height / 2)
                    .shadow(color: CelleuxColors.goldGlow, radius: 8, x: 0, y: 0)

                Circle()
                    .fill(Color(.displayP3, red: 0.12, green: 0.12, blue: 0.16))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        CelleuxColors.warmGold.opacity(0.8),
                                        Color.white.opacity(0.6),
                                        CelleuxColors.warmGold.opacity(0.5),
                                        Color.white.opacity(0.7),
                                        CelleuxColors.warmGold.opacity(0.8)
                                    ],
                                    center: .center
                                ),
                                lineWidth: 2
                            )
                    )
                    .overlay(
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 8, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundStyle(CelleuxColors.warmGold)
                    )
                    .position(x: width * sliderPosition, y: height / 2)
                    .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPos = value.location.x / width
                                sliderPosition = max(0.05, min(0.95, newPos))
                            }
                    )

                HStack {
                    Text("BEFORE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.4)))

                    Spacer()

                    Text("AFTER")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(CelleuxColors.warmGold.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.4)))
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .frame(maxHeight: .infinity, alignment: .top)

                if showMetricBadges {
                    metricBadgesOverlay(width: width, height: height)
                }
            }
            .clipShape(.rect(cornerRadius: 20))
        }
    }

    // MARK: - Side by Side

    private var sideBySideView: some View {
        GeometryReader { geo in
            let halfWidth = (geo.size.width - 8) / 2
            let height = geo.size.height

            HStack(spacing: 8) {
                ZStack {
                    faceVisualization(scan: beforeScan, label: "BEFORE", width: halfWidth, height: height)

                    if showMetricBadges {
                        metricBadgesOverlay(width: halfWidth, height: height, showBefore: true)
                    }
                }
                .clipShape(.rect(cornerRadius: 16))

                ZStack {
                    faceVisualization(scan: afterScan, label: "AFTER", width: halfWidth, height: height)

                    if showMetricBadges {
                        metricBadgesOverlay(width: halfWidth, height: height, showBefore: false)
                    }
                }
                .clipShape(.rect(cornerRadius: 16))
            }
        }
    }

    // MARK: - Timelapse

    private var timelapseView: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                let currentScan = sortedScans.indices.contains(timelapseIndex) ? sortedScans[timelapseIndex] : beforeScan

                ZStack {
                    faceVisualization(scan: currentScan, label: "", width: geo.size.width, height: geo.size.height)
                        .id(currentScan.id)
                        .transition(.opacity)

                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currentScan.shortDateString)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.8))
                                Text("Score: \(currentScan.overallScore)")
                                    .font(.system(size: 18, weight: .thin))
                                    .foregroundStyle(CelleuxColors.warmGold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.black.opacity(0.5))
                                    .background(.ultraThinMaterial.opacity(0.3))
                            )
                            .clipShape(.rect(cornerRadius: 12))

                            Spacer()
                        }
                        .padding(12)

                        Spacer()
                    }
                }
                .clipShape(.rect(cornerRadius: 20))
                .animation(.easeInOut(duration: 0.6), value: timelapseIndex)
            }

            timelapseControls
        }
    }

    private var timelapseControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(Array(sortedScans.enumerated()), id: \.element.id) { index, scan in
                    Button {
                        withAnimation(CelleuxSpring.snappy) {
                            timelapseIndex = index
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(index == timelapseIndex ? CelleuxColors.warmGold : Color.white.opacity(0.2))
                                .frame(width: index == timelapseIndex ? 10 : 6, height: index == timelapseIndex ? 10 : 6)
                                .shadow(color: index == timelapseIndex ? CelleuxColors.goldGlow : .clear, radius: 4, x: 0, y: 0)

                            if sortedScans.count <= 8 {
                                Text(scan.shortDateString)
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundStyle(index == timelapseIndex ? CelleuxColors.warmGold : Color.white.opacity(0.3))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 8)

            GeometryReader { geo in
                let count = max(1, sortedScans.count - 1)
                let dotX = geo.size.width * CGFloat(timelapseIndex) / CGFloat(count)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.warmGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(3, dotX), height: 3)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let fraction = value.location.x / geo.size.width
                            let idx = Int(round(fraction * CGFloat(sortedScans.count - 1)))
                            let clamped = max(0, min(sortedScans.count - 1, idx))
                            if clamped != timelapseIndex {
                                withAnimation(CelleuxSpring.snappy) {
                                    timelapseIndex = clamped
                                }
                            }
                        }
                )
            }
            .frame(height: 3)
            .padding(.horizontal, 8)

            Button {
                if isPlaying {
                    stopPlayback()
                } else {
                    startPlayback()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .medium))
                    Text(isPlaying ? "Pause" : "Play")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(CelleuxColors.warmGold)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(CelleuxColors.warmGold.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(CelleuxColors.warmGold.opacity(0.3), lineWidth: 0.5)
                )
            }
            .sensoryFeedback(.selection, trigger: isPlaying)
        }
    }

    // MARK: - Metric Badge Toggle

    private var metricBadgeToggle: some View {
        Button {
            withAnimation(CelleuxSpring.snappy) {
                showMetricBadges.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showMetricBadges ? "eye.fill" : "eye.slash")
                    .font(.system(size: 11, weight: .medium))
                Text(showMetricBadges ? "Hide Changes" : "Show Changes")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(showMetricBadges ? CelleuxColors.warmGold : Color.white.opacity(0.5))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(showMetricBadges ? CelleuxColors.warmGold.opacity(0.12) : Color.white.opacity(0.06))
            )
            .overlay(
                Capsule()
                    .stroke(showMetricBadges ? CelleuxColors.warmGold.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .sensoryFeedback(.selection, trigger: showMetricBadges)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                generateComparisonExport()
            } label: {
                HStack(spacing: 8) {
                    if isGeneratingShare {
                        ProgressView()
                            .tint(CelleuxColors.warmGold)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .medium))
                    }
                    Text("Share Comparison")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color(.displayP3, red: 0.06, green: 0.06, blue: 0.10))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [CelleuxColors.warmGold, CelleuxColors.champagneGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: CelleuxColors.goldGlow, radius: 12, x: 0, y: 4)
            }
            .disabled(isGeneratingShare)
        }
    }

    // MARK: - Face Visualization

    private func faceVisualization(scan: SkinScanResult, label: String, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Color(.displayP3, red: 0.08, green: 0.08, blue: 0.12)

            RadialGradient(
                colors: [
                    CelleuxColors.warmGold.opacity(0.04),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: min(width, height) * 0.5
            )

            VStack(spacing: 0) {
                Spacer()

                faceRegionGrid(scan: scan, width: width, height: height)

                Spacer()
            }

            if !label.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 2) {
                            Text("\(scan.overallScore)")
                                .font(.system(size: 32, weight: .ultraLight))
                                .foregroundStyle(Color.white.opacity(0.9))
                            Text("SCORE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))
                                .tracking(1.5)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.4))
                                .background(.ultraThinMaterial.opacity(0.2))
                        )
                        .clipShape(.rect(cornerRadius: 14))
                        .padding(12)
                    }
                }
            }
        }
    }

    private func faceRegionGrid(scan: SkinScanResult, width: CGFloat, height: CGFloat) -> some View {
        let regions = scan.regions
        let centerX = width / 2
        let centerY = height / 2

        return ZStack {
            ForEach(regions, id: \.id) { region in
                let pos = regionPosition(for: region.name)
                let score = region.score
                let scoreNormalized = CGFloat(score) / 100.0
                let regionColor = colorForScore(score)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [regionColor.opacity(0.5), regionColor.opacity(0.15), regionColor.opacity(0.02)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 35 + scoreNormalized * 15
                        )
                    )
                    .frame(width: 80 + scoreNormalized * 30, height: 80 + scoreNormalized * 30)
                    .position(
                        x: centerX + pos.x * (width * 0.35),
                        y: centerY + pos.y * (height * 0.32)
                    )

                Circle()
                    .stroke(regionColor.opacity(0.3), lineWidth: 1)
                    .frame(width: 44, height: 44)
                    .position(
                        x: centerX + pos.x * (width * 0.35),
                        y: centerY + pos.y * (height * 0.32)
                    )

                VStack(spacing: 1) {
                    Text("\(score)")
                        .font(.system(size: 16, weight: .thin))
                        .foregroundStyle(Color.white.opacity(0.9))
                    Text(region.name.replacingOccurrences(of: " ", with: "\n"))
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .position(
                    x: centerX + pos.x * (width * 0.35),
                    y: centerY + pos.y * (height * 0.32)
                )
            }

            ForEach(0..<5) { i in
                Circle()
                    .stroke(CelleuxColors.warmGold.opacity(0.04 + Double(i) * 0.01), lineWidth: 0.5)
                    .frame(width: CGFloat(60 + i * 40), height: CGFloat(60 + i * 40))
                    .position(x: centerX, y: centerY)
            }
        }
    }

    // MARK: - Metric Badges Overlay

    private func metricBadgesOverlay(width: CGFloat, height: CGFloat, showBefore: Bool? = nil) -> some View {
        let centerX = width / 2
        let centerY = height / 2

        return ZStack {
            ForEach(Array(regionDeltas.enumerated()), id: \.element.name) { index, rd in
                let displayDelta = showBefore == nil ? rd.delta : (showBefore == true ? rd.beforeScore : rd.afterScore)
                let displayText = showBefore == nil ? String(format: "%+d", rd.delta) : "\(displayDelta)"
                let badgeColor = showBefore == nil ? (rd.delta >= 0 ? Color(hex: "4CAF50") : Color(hex: "E8A838")) : CelleuxColors.warmGold

                HStack(spacing: 3) {
                    if showBefore == nil {
                        Image(systemName: rd.delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 7, weight: .bold))
                    }
                    Text(displayText)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(badgeColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.55))
                        .background(.ultraThinMaterial.opacity(0.3))
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(badgeColor.opacity(0.4), lineWidth: 0.5)
                )
                .position(
                    x: centerX + rd.position.x * (width * 0.35) + 28,
                    y: centerY + rd.position.y * (height * 0.32) - 22
                )
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.4).delay(Double(index) * 0.06), value: appeared)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func regionPosition(for name: String) -> CGPoint {
        switch name {
        case "Forehead": CGPoint(x: 0, y: -0.6)
        case "Left Cheek": CGPoint(x: -0.55, y: 0)
        case "Right Cheek": CGPoint(x: 0.55, y: 0)
        case "Chin": CGPoint(x: 0, y: 0.65)
        case "Under-Eyes": CGPoint(x: 0, y: -0.15)
        case "Nose": CGPoint(x: 0, y: 0.2)
        default: CGPoint(x: 0, y: 0)
        }
    }

    private func colorForScore(_ score: Int) -> Color {
        if score >= 80 { return Color(hex: "4CAF50") }
        if score >= 60 { return CelleuxColors.warmGold }
        return Color(hex: "E8A838")
    }

    private func startPlayback() {
        isPlaying = true
        playbackTimer = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { break }
                let nextIndex = (timelapseIndex + 1) % sortedScans.count
                withAnimation(.easeInOut(duration: 0.6)) {
                    timelapseIndex = nextIndex
                }
                if nextIndex == sortedScans.count - 1 {
                    try? await Task.sleep(for: .seconds(2))
                    stopPlayback()
                    break
                }
            }
        }
    }

    private func stopPlayback() {
        isPlaying = false
        playbackTimer?.cancel()
        playbackTimer = nil
    }

    // MARK: - Export

    private func generateComparisonExport() {
        isGeneratingShare = true
        let exportView = ComparisonExportCard(
            beforeScan: beforeScan,
            afterScan: afterScan
        )
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            showShareSheet = true
        }
        isGeneratingShare = false
    }
}

// MARK: - Slider Clip Shape

struct SliderClipShape: Shape {
    var position: CGFloat

    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(
            x: rect.width * position,
            y: 0,
            width: rect.width * (1 - position),
            height: rect.height
        ))
        return path
    }
}

// MARK: - Region Delta Model

struct RegionDelta {
    let name: String
    let delta: Int
    let beforeScore: Int
    let afterScore: Int
    let position: CGPoint
}

// MARK: - Branded Export Card

struct ComparisonExportCard: View {
    let beforeScan: SkinScanResult
    let afterScan: SkinScanResult

    private let delta: Int

    init(beforeScan: SkinScanResult, afterScan: SkinScanResult) {
        self.beforeScan = beforeScan
        self.afterScan = afterScan
        self.delta = afterScan.overallScore - beforeScan.overallScore
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("CELLEUX")
                .font(.system(size: 13, weight: .bold))
                .tracking(4)
                .foregroundStyle(Color(hex: "C9A96E"))
                .padding(.top, 24)

            Text("Skin Progress Report")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "999999"))
                .padding(.top, 4)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "C9A96E").opacity(0.1), Color(hex: "C9A96E").opacity(0.5), Color(hex: "C9A96E").opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 40)
                .padding(.top, 16)

            HStack(spacing: 20) {
                exportScoreColumn(scan: beforeScan, label: "BEFORE")

                VStack(spacing: 4) {
                    Image(systemName: delta >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(delta >= 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))

                    Text(String(format: "%+d", delta))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(delta >= 0 ? Color(hex: "4CAF50") : Color(hex: "E53935"))
                }

                exportScoreColumn(scan: afterScan, label: "AFTER")
            }
            .padding(.top, 20)

            exportMetricChanges
                .padding(.top, 16)
                .padding(.horizontal, 20)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "D4B078"), Color(hex: "C9A96E"), Color(hex: "B89A5D")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .padding(.horizontal, 30)
                .padding(.top, 20)

            HStack {
                Text("Tracked with Celleux")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(hex: "AAAAAA"))
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color(hex: "C9A96E").opacity(0.5))
                    Text("On-Device Analysis")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color(hex: "AAAAAA"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "E8DCC8").opacity(0.6), Color(hex: "C9A96E").opacity(0.3), Color(hex: "E8DCC8").opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func exportScoreColumn(scan: SkinScanResult, label: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(label == "AFTER" ? Color(hex: "C9A96E") : Color(hex: "999999"))
                .tracking(1)

            ZStack {
                Circle()
                    .stroke(Color(hex: "EEEEEE"), lineWidth: 4)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: Double(scan.overallScore) / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "D4B078"), Color(hex: "C9A96E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                Text("\(scan.overallScore)")
                    .font(.system(size: 26, weight: .thin))
                    .foregroundStyle(Color(hex: "1A1A26"))
            }

            Text(scan.shortDateString)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(hex: "999999"))
        }
    }

    private var exportMetricChanges: some View {
        let metricPairs = zip(beforeScan.metrics, afterScan.metrics)

        return VStack(spacing: 4) {
            ForEach(Array(metricPairs.enumerated().prefix(6)), id: \.offset) { _, pair in
                let (before, after) = pair
                let d = after.score - before.score
                HStack(spacing: 8) {
                    Text(after.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "666666"))
                        .lineLimit(1)

                    Spacer()

                    Text("\(before.score)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: "999999"))
                        .frame(width: 24, alignment: .trailing)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(Color(hex: "CCCCCC"))

                    Text("\(after.score)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: "333333"))
                        .frame(width: 24, alignment: .trailing)

                    Text(String(format: "%+d", d))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(d >= 0 ? Color(hex: "4CAF50") : Color(hex: "E8A838"))
                        .frame(width: 26, alignment: .trailing)
                }
            }
        }
    }
}
