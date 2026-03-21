import SwiftUI
import SwiftData
import ARKit
import CoreImage
import AVFoundation

struct ScanView: View {
    @State private var viewModel = SkinScanViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var scanTrigger: Bool = false
    @State private var appeared: Bool = false
    @State private var progressRingGlow: Bool = false
    @State private var scanHapticMilestone: Int = 0
    @State private var showFlash: Bool = false
    @State private var celebrationBurst: Bool = false
    @State private var faceGuidePulse: Bool = false
    @State private var analysisMetricIndex: Int = 0
    @State private var showBeforeAfter: Bool = false
    @State private var compareBeforeScan: SkinScanResult?
    @State private var compareAfterScan: SkinScanResult?
    @State private var showAgingSimulation: Bool = false
    @State private var cameraPermissionDenied: Bool = false

    private let analysisMetricNames: [String] = [
        "Texture Evenness",
        "Apparent Hydration",
        "Brightness & Radiance",
        "Redness Detection",
        "Pore Visibility",
        "Tone Uniformity",
        "Under-Eye Analysis",
        "Wrinkle Mapping",
        "Elasticity Proxy"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.phase {
                case .preScan:
                    preScanContent
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                case .scanning:
                    scanningContent
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                case .analyzing:
                    analyzingContent
                        .transition(.opacity)
                case .results:
                    if let result = viewModel.currentResult {
                        ZStack {
                            ScanResultsView(
                                result: result,
                                history: viewModel.scanHistory,
                                onNewScan: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                        viewModel.resetScan()
                                    }
                                },
                                onShowHistory: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                        viewModel.showHistory()
                                    }
                                },
                                onShowAgingSimulation: {
                                    showAgingSimulation = true
                                }
                            )

                            FlashOverlayView(isActive: showFlash)
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                        .onAppear {
                            showFlash = true
                            celebrationBurst = true
                        }
                    }
                case .history:
                    ScanHistoryView(
                        history: viewModel.scanHistory,
                        onSelectScan: { scan in
                            viewModel.currentResult = scan
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                viewModel.phase = .results
                            }
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                viewModel.resetScan()
                            }
                        },
                        onCompare: { before, after in
                            compareBeforeScan = before
                            compareAfterScan = after
                            showBeforeAfter = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                case .heatMap:
                    heatMapContent
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                case .progress:
                    ProgressComparisonView(
                        currentResult: viewModel.currentResult ?? viewModel.scanHistory.first,
                        history: viewModel.scanHistory,
                        selectedTimeframe: $viewModel.selectedTimeframe,
                        onDismiss: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                viewModel.resetScan()
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(navigationTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isDarkPhase ? .white : CelleuxColors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.phase == .preScan {
                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                    viewModel.showProgressMode()
                                }
                            } label: {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(CelleuxColors.warmGold)
                            }
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                    viewModel.showHistory()
                                }
                            } label: {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(CelleuxColors.warmGold)
                            }
                        }
                    }
                    if viewModel.phase == .results || viewModel.phase == .history {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                viewModel.resetScan()
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(CelleuxColors.warmGold)
                        }
                    }
                    if viewModel.phase == .heatMap {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                viewModel.exitHeatMap()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.phase == .history || viewModel.phase == .results {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                viewModel.resetScan()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Scan")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundStyle(CelleuxColors.warmGold)
                        }
                    }
                    if viewModel.phase == .heatMap {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                viewModel.exitHeatMap()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Back")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: "E8D6A8"))
                        }
                    }
                }
            }
            .toolbarBackground(isDarkPhase ? .hidden : .visible, for: .navigationBar)
            .toolbarColorScheme(isDarkPhase ? .dark : .light, for: .navigationBar)
            .task {
                viewModel.loadHistory(modelContext: modelContext)
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
            .fullScreenCover(isPresented: $showAgingSimulation) {
                if let result = viewModel.currentResult {
                    AgingSimulationView(
                        result: result,
                        capturedImage: capturedImageFromBuffer(),
                        onDismiss: {
                            showAgingSimulation = false
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showBeforeAfter) {
                if let before = compareBeforeScan, let after = compareAfterScan {
                    BeforeAfterComparisonView(
                        beforeScan: before,
                        afterScan: after,
                        allScans: viewModel.scanHistory,
                        onDismiss: {
                            showBeforeAfter = false
                        }
                    )
                }
            }
        }
    }

    private func capturedImageFromBuffer() -> UIImage? {
        guard let buffer = viewModel.capturedPixelBuffer else { return nil }
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private var isDarkPhase: Bool {
        viewModel.phase == .scanning || viewModel.phase == .analyzing || viewModel.phase == .heatMap
    }

    private var navigationTitle: String {
        switch viewModel.phase {
        case .preScan: "Skin Analysis"
        case .scanning: "Scanning"
        case .analyzing: "Analyzing"
        case .results: "Results"
        case .history: "History"
        case .heatMap: "AR Skin Map"
        case .progress: "Progress"
        }
    }

    // MARK: - Pre-Scan

    private var preScanContent: some View {
        ZStack {
            CelleuxMeshBackground()

            if cameraPermissionDenied {
                VStack {
                    Spacer()
                    ErrorStateView(
                        type: .cameraPermissionDenied,
                        action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        },
                        secondaryAction: nil,
                        secondaryLabel: nil
                    )
                    .padding(.horizontal, 16)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    cameraContainer(isScanning: false, showHeatMap: false)
                    Spacer(minLength: 16)
                    preScanBottomPanel
                        .padding(.bottom, 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
        }
        .task {
            await checkCameraPermission()
        }
    }

    private func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .denied, .restricted:
            cameraPermissionDenied = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraPermissionDenied = !granted
        default:
            cameraPermissionDenied = false
        }
    }

    private var preScanBottomPanel: some View {
        VStack(spacing: 14) {
            faceDetectionGuidance

            HStack(spacing: 16) {
                scanInfoItem(icon: "clock", value: "~8s", label: "Duration")
                Rectangle().fill(LinearGradient(colors: [Color(hex: "D4C4A0").opacity(0.05), Color(hex: "C9A96E").opacity(0.15), Color(hex: "D4C4A0").opacity(0.05)], startPoint: .top, endPoint: .bottom)).frame(width: 1, height: 28)
                scanInfoItem(icon: "lock.shield", value: "Private", label: "On-Device")
                Rectangle().fill(LinearGradient(colors: [Color(hex: "D4C4A0").opacity(0.05), Color(hex: "C9A96E").opacity(0.15), Color(hex: "D4C4A0").opacity(0.05)], startPoint: .top, endPoint: .bottom)).frame(width: 1, height: 28)
                scanInfoItem(icon: "chart.bar", value: "10", label: "Metrics")
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(premiumInfoBarBackground)

            HStack(spacing: 10) {
                Button {
                    scanTrigger.toggle()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        viewModel.beginScan(modelContext: modelContext)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.system(size: 16, weight: .light))
                        Text("Scan")
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(0.3)
                    }
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(Premium3DButtonStyle())
                .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.8), trigger: scanTrigger)
                .accessibilityLabel("Start skin scan")
                .accessibilityHint("Begins analyzing your skin using the front camera")

                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        viewModel.showHeatMapMode()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                        Text("AR Map")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "E8D6A8"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(hex: "0A0A10"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(hex: "E8D6A8").opacity(0.3), lineWidth: 1)
                    )
                }
                .shadow(color: Color(hex: "E8D6A8").opacity(0.15), radius: 10, x: 0, y: 4)
                .accessibilityLabel("AR skin map")
                .accessibilityHint("Shows an augmented reality heat map of your skin")
            }

            Text(viewModel.lastScanText)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
        }
    }

    private var faceDetectionGuidance: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(viewModel.isFaceDetected ? Color(hex: "4CAF50").opacity(0.12) : Color(hex: "E8A838").opacity(0.12))
                    .frame(width: 32, height: 32)
                    .scaleEffect(faceGuidePulse ? 1.15 : 1.0)

                Image(systemName: viewModel.isFaceDetected ? "face.smiling" : "viewfinder")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(viewModel.isFaceDetected ? Color(hex: "4CAF50") : Color(hex: "E8A838"))
                    .symbolEffect(.bounce, value: viewModel.isFaceDetected)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.guidanceText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(viewModel.isFaceDetected ? Color(hex: "4CAF50") : CelleuxColors.textPrimary)
                    .contentTransition(.numericText())

                HStack(spacing: 6) {
                    Image(systemName: viewModel.lightingQuality.icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(viewModel.lightingQuality.color)
                    Text(viewModel.lightingQuality.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(viewModel.lightingQuality.color)
                }
            }

            Spacer()

            if viewModel.isFaceDetected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "4CAF50"))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    viewModel.isFaceDetected ? Color(hex: "4CAF50").opacity(0.2) : CelleuxColors.silverLight.opacity(0.4),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isFaceDetected)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.lightingQuality)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.isFaceDetected ? "Face detected, ready to scan" : "Position your face in the camera")
        .accessibilityValue("Lighting: \(viewModel.lightingQuality.rawValue)")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                faceGuidePulse = true
            }
        }
    }

    // MARK: - Scanning

    private var scanningContent: some View {
        ZStack {
            Color(hex: "0A0A10").ignoresSafeArea()

            VStack(spacing: 0) {
                cameraContainer(isScanning: true, showHeatMap: false)
                Spacer(minLength: 16)

                VStack(spacing: 12) {
                    Text(viewModel.analysisStatusText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.analysisStatusText)

                    Text(viewModel.analysisDetailText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(hex: "E8D6A8").opacity(0.8))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.analysisDetailText)

                    scanProgressCapsules
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "E8D6A8").opacity(0.15), lineWidth: 0.5)
                )
                .padding(.bottom, 90)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                progressRingGlow = true
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: scanHapticMilestone)
        .onChange(of: viewModel.scanProgress) { oldValue, newValue in
            let oldMilestone = Int(oldValue * 4)
            let newMilestone = Int(newValue * 4)
            if newMilestone > oldMilestone {
                scanHapticMilestone = newMilestone
            }
        }
    }

    private var scanProgressCapsules: some View {
        HStack(spacing: 4) {
            ForEach(0..<8, id: \.self) { i in
                let isFilled = viewModel.scanProgress > Double(i) / 8.0
                Capsule()
                    .fill(isFilled ? Color(hex: "E8D6A8") : Color.white.opacity(0.08))
                    .frame(height: 4)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.scanProgress)
            }
        }
        .padding(.top, 4)
    }

    private var scanningOverlayContent: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    Circle().fill(Color.black.opacity(0.4)).frame(width: 56, height: 56)
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 2.5).frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: viewModel.scanProgress)
                        .stroke(
                            AngularGradient(colors: [Color(hex: "E8D6A8"), Color(hex: "C0C8D4"), Color(hex: "E8D6A8")], center: .center),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(viewModel.scanProgress * 100))%")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "E8D6A8"))
                        .contentTransition(.numericText(countsDown: false))
                }
                .padding(.top, 20)
                .padding(.trailing, 20)
            }
            Spacer()
        }
    }

    // MARK: - Analyzing

    private var analyzingContent: some View {
        ZStack {
            Color(hex: "0A0A10").ignoresSafeArea()

            VStack(spacing: 32) {
                AnalyzingBrainView(isActive: true)

                VStack(spacing: 10) {
                    Text("Computing 10 skin metrics")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(analysisMetricNames[analysisMetricIndex])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "E8D6A8").opacity(0.9))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: analysisMetricIndex)
                        .id(analysisMetricIndex)
                }

                HStack(spacing: 6) {
                    ForEach(0..<9, id: \.self) { i in
                        Circle()
                            .fill(i <= analysisMetricIndex ? Color(hex: "E8D6A8") : Color.white.opacity(0.12))
                            .frame(width: 6, height: 6)
                            .scaleEffect(i == analysisMetricIndex ? 1.4 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: analysisMetricIndex)
                    }
                }

                Text("PROCESSING ON-DEVICE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
                    .tracking(2)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.3), trigger: analysisMetricIndex)
        .onAppear {
            startAnalysisMetricCycling()
        }
    }

    private func startAnalysisMetricCycling() {
        analysisMetricIndex = 0
        for i in 1..<analysisMetricNames.count {
            Task {
                try? await Task.sleep(for: .milliseconds(280 * i))
                withAnimation {
                    analysisMetricIndex = i
                }
            }
        }
    }

    // MARK: - Camera Container

    private func cameraContainer(isScanning: Bool, showHeatMap: Bool) -> some View {
        ZStack {
            if showHeatMap {
                RoundedRectangle(cornerRadius: 34)
                    .fill(Color(hex: "0A0A10"))
                    .padding(-4)

                RoundedRectangle(cornerRadius: 34)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(hex: "E8D6A8").opacity(0.6),
                                Color(hex: "C0C8D4").opacity(0.3),
                                Color(hex: "E8D6A8").opacity(0.2),
                                Color(hex: "D4A574").opacity(0.2),
                                Color(hex: "E8D6A8").opacity(0.5),
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .padding(-4)
            } else {
                RoundedRectangle(cornerRadius: 34)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "D0D6DC").opacity(0.6),
                                Color(hex: "B8C0C8").opacity(0.5),
                                Color(hex: "C9A96E").opacity(0.25),
                                Color(hex: "B0B8C1").opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(-4)

                RoundedRectangle(cornerRadius: 34)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color(hex: "C9A96E").opacity(0.7),
                                Color(hex: "B0B8C1").opacity(0.5),
                                Color.white.opacity(0.85),
                                Color(hex: "D4C4A0").opacity(0.6),
                                Color(hex: "C0C8D0").opacity(0.4),
                                Color.white.opacity(0.9),
                                Color(hex: "C9A96E").opacity(0.5),
                                Color(hex: "B8C0C8").opacity(0.6),
                                Color.white.opacity(0.95)
                            ],
                            center: .center
                        ),
                        lineWidth: 3.5
                    )
                    .padding(-4)

                RoundedRectangle(cornerRadius: 33)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .padding(-2.5)
            }

            RoundedRectangle(cornerRadius: 32)
                .fill(showHeatMap ? Color(hex: "0A0A10") : Color(hex: "F0EDE8"))

            Group {
                #if targetEnvironment(simulator)
                simulatorPlaceholder(darkMode: showHeatMap)
                #else
                if ARFaceTrackingConfiguration.isSupported {
                    ARFaceTrackingView(
                        isScanning: isScanning,
                        scanProgress: viewModel.scanProgress,
                        heatMapMode: viewModel.heatMapMode,
                        showHeatMap: showHeatMap,
                        regionScores: viewModel.latestRegionScores,
                        onFaceDetected: { detected in
                            viewModel.onFaceDetected(detected)
                        },
                        onFrameCaptured: { buffer in
                            viewModel.onFrameCaptured(buffer)
                        },
                        onElasticityComputed: { score in
                            viewModel.onElasticityComputed(score)
                        },
                        onAllCapturesFailed: {
                            viewModel.onAllCapturesFailed()
                        },
                        onLightingUpdated: { conditions in
                            viewModel.onLightingUpdated(conditions)
                        }
                    )
                } else {
                    simulatorPlaceholder(darkMode: showHeatMap)
                }
                #endif
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .padding(4)

            if isScanning {
                ScanGridOverlayView(progress: viewModel.scanProgress, isActive: true)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .padding(4)
                    .allowsHitTesting(false)
            }

            if !showHeatMap {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        LinearGradient(
                            colors: [Color.black.opacity(0.08), Color.black.opacity(0.02), Color.black.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                    .padding(2)
            }

            if isScanning {
                scanningOverlayContent
            }

            if let error = viewModel.scanError {
                scanErrorOverlay(error)
            }
        }
        .shadow(color: showHeatMap ? Color(hex: "E8D6A8").opacity(0.1) : Color.black.opacity(0.04), radius: showHeatMap ? 20 : 1, x: 0, y: showHeatMap ? 0 : 1)
        .shadow(color: showHeatMap ? Color(hex: "D4C4A0").opacity(0.08) : CelleuxColors.goldGlow.opacity(0.15), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.1), radius: 24, x: 0, y: 12)
    }

    private func scanErrorOverlay(_ error: String) -> some View {
        let errorType: ErrorStateType = {
            let lower = error.lowercased()
            if lower.contains("lighting") || lower.contains("dim") {
                return .scanFailedLighting
            } else if lower.contains("face") || lower.contains("centered") {
                return .scanFailedNoFace
            } else if lower.contains("still") || lower.contains("movement") {
                return .scanFailedMovement
            }
            return .scanFailedGeneric(error)
        }()

        return ScanErrorBanner(
            message: errorType.message,
            icon: errorType.icon,
            onDismiss: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    viewModel.scanError = nil
                }
            }
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    viewModel.scanError = nil
                }
            }
        }
    }

    private func simulatorPlaceholder(darkMode: Bool) -> some View {
        ZStack {
            if darkMode {
                LinearGradient(
                    colors: [Color(hex: "0F1018"), Color(hex: "0A0A10")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [Color(hex: "F5F2ED"), Color(hex: "EBE8E3"), Color(hex: "E5E2DD")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(darkMode ? Color(hex: "E8D6A8").opacity(0.2) : CelleuxColors.warmGold.opacity(0.2), lineWidth: 1)
                        .frame(width: 120, height: 120)
                    Circle()
                        .stroke(darkMode ? Color(hex: "E8D6A8").opacity(0.1) : CelleuxColors.warmGold.opacity(0.1), lineWidth: 1)
                        .frame(width: 180, height: 180)
                    Image(systemName: "faceid")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundStyle(darkMode ? Color(hex: "E8D6A8").opacity(0.7) : CelleuxColors.warmGold.opacity(0.7))
                }
                Text("AR Face Tracking")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(darkMode ? .white : CelleuxColors.textPrimary)
                Text("Install this app on your device\nvia the Rork App for the AR scan experience.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(darkMode ? .white.opacity(0.5) : CelleuxColors.textLabel)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Heat Map

    private var heatMapContent: some View {
        ZStack {
            Color(hex: "0A0A10").ignoresSafeArea()

            VStack(spacing: 0) {
                cameraContainer(isScanning: false, showHeatMap: true)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                Spacer()
            }

            SkinConcernOverlayView(
                selectedMode: $viewModel.heatMapMode,
                showHeatMap: $viewModel.showHeatMap,
                scanResult: viewModel.currentResult ?? viewModel.scanHistory.first
            )
            .padding(.bottom, 90)
        }
    }

    // MARK: - Helpers

    private var premiumInfoBarBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.98), Color(hex: "FAF9F7"), Color(hex: "F5F3F0")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), Color.white.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color(hex: "C0C8D0").opacity(0.4),
                            Color(hex: "C9A96E").opacity(0.25),
                            Color.white.opacity(0.7),
                            Color(hex: "B0B8C1").opacity(0.3),
                            Color.white.opacity(0.85)
                        ],
                        center: .center
                    ),
                    lineWidth: 1
                )

            RoundedRectangle(cornerRadius: 19)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
                .padding(1)

            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.02))
                    .frame(height: 1)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 0.5)
            }
        }
        .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
        .shadow(color: .black.opacity(0.04), radius: 20, x: 0, y: 8)
    }

    private func scanInfoItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CelleuxColors.textPrimary)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(CelleuxColors.textLabel)
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}
