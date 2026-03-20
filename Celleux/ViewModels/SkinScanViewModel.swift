import SwiftUI
import SwiftData
import ARKit

@Observable
final class SkinScanViewModel {
    var phase: ScanPhase = .preScan
    var faceState: FaceDetectionState = .noFace
    var lightingQuality: LightingQuality = .good
    var scanProgress: Double = 0
    var currentResult: SkinScanResult?
    var scanHistory: [SkinScanResult] = []
    var isScanning: Bool = false
    var showMetricsExpanded: Bool = false
    var selectedHistoryItem: SkinScanResult?
    var capturedPixelBuffer: CVPixelBuffer?
    var guidanceText: String = "Position your face in the frame"
    var isFaceDetected: Bool = false
    var analysisStatusText: String = "Initializing scan..."
    var analysisDetailText: String = "CALIBRATING SENSORS"
    var heatMapMode: HeatMapMode = .all
    var showHeatMap: Bool = false
    var selectedTimeframe: ProgressTimeframe = .thirtyDays

    private let analysisService = SkinAnalysisService()

    private let scanPhases: [(range: ClosedRange<Double>, status: String, detail: String)] = [
        (0.0...0.12, "Mapping facial geometry...", "DETECTING FACE MESH"),
        (0.12...0.25, "Analyzing facial structure...", "TRIANGULATING 1,220 VERTICES"),
        (0.25...0.38, "Scanning skin texture...", "TEXTURE ANALYSIS IN PROGRESS"),
        (0.38...0.50, "Measuring hydration levels...", "COLORIMETRIC SAMPLING"),
        (0.50...0.62, "Evaluating radiance...", "L*a*b* COLOR SPACE CONVERSION"),
        (0.62...0.75, "Checking pore visibility...", "LAPLACIAN VARIANCE COMPUTE"),
        (0.75...0.88, "Analyzing redness patterns...", "a* CHANNEL EXTRACTION"),
        (0.88...1.0, "Finalizing analysis...", "COMPILING SKIN REPORT"),
    ]

    var lastScanText: String {
        guard let last = scanHistory.first else { return "No previous scans" }
        let days = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 0
        if days == 0 { return "Last scan: Today" }
        if days == 1 { return "Last scan: Yesterday" }
        return "Last scan: \(days) days ago"
    }

    func loadHistory(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SkinScanRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let records = try? modelContext.fetch(descriptor) else { return }

        scanHistory = records.enumerated().map { index, record in
            let prevRecord = index + 1 < records.count ? records[index + 1] : nil
            let trend = prevRecord != nil ? Double(record.overallScore - prevRecord!.overallScore) : 0

            return SkinScanResult(
                date: record.date,
                overallScore: record.overallScore,
                regions: buildRegions(from: record, prevRecord: prevRecord),
                metrics: buildMetrics(from: record, prevRecord: prevRecord),
                trend: trend,
                analysisData: SkinAnalysisData(
                    brightnessScore: record.brightnessScore,
                    rednessScore: record.rednessScore,
                    textureScore: record.textureScore,
                    hydrationScore: record.hydrationScore,
                    overallScore: Double(record.overallScore)
                )
            )
        }
    }

    private func buildRegions(from record: SkinScanRecord, prevRecord: SkinScanRecord?) -> [SkinRegionResult] {
        let b = Int(record.brightnessScore.rounded())
        let r = Int(record.rednessScore.rounded())
        let t = Int(record.textureScore.rounded())
        let h = Int(record.hydrationScore.rounded())

        func trend(_ current: Int, _ prev: Int?) -> RegionTrend {
            guard let p = prev else { return .stable }
            if current > p + 2 { return .improving }
            if current < p - 2 { return .declining }
            return .stable
        }

        let pb = prevRecord.map { Int($0.brightnessScore.rounded()) }
        let pr = prevRecord.map { Int($0.rednessScore.rounded()) }
        let pt = prevRecord.map { Int($0.textureScore.rounded()) }
        let ph = prevRecord.map { Int($0.hydrationScore.rounded()) }

        return [
            SkinRegionResult(name: "Forehead", icon: "rectangle.portrait.topthird.inset.filled", score: t, keyMetric: "Texture", keyValue: labelFor(t), trend: trend(t, pt)),
            SkinRegionResult(name: "Left Cheek", icon: "rectangle.portrait.leadinghalf.inset.filled", score: h, keyMetric: "Hydration", keyValue: labelFor(h), trend: trend(h, ph)),
            SkinRegionResult(name: "Right Cheek", icon: "rectangle.portrait.trailinghalf.inset.filled", score: h, keyMetric: "Hydration", keyValue: labelFor(h), trend: trend(h, ph)),
            SkinRegionResult(name: "Chin", icon: "rectangle.portrait.bottomthird.inset.filled", score: r, keyMetric: "Clarity", keyValue: labelFor(r), trend: trend(r, pr)),
            SkinRegionResult(name: "Under-Eyes", icon: "eye", score: b, keyMetric: "Dark Circles", keyValue: labelFor(b), trend: trend(b, pb)),
            SkinRegionResult(name: "Nose", icon: "triangle", score: t, keyMetric: "Pores", keyValue: labelFor(t), trend: trend(t, pt))
        ]
    }

    private func buildMetrics(from record: SkinScanRecord, prevRecord: SkinScanRecord?) -> [SkinMetric] {
        [
            SkinMetric(name: "Texture Evenness", score: Int(record.textureScore.rounded()), previousScore: prevRecord.map { Int($0.textureScore.rounded()) }, icon: "square.grid.3x3"),
            SkinMetric(name: "Apparent Hydration", score: Int(record.hydrationScore.rounded()), previousScore: prevRecord.map { Int($0.hydrationScore.rounded()) }, icon: "drop.fill"),
            SkinMetric(name: "Brightness", score: Int(record.brightnessScore.rounded()), previousScore: prevRecord.map { Int($0.brightnessScore.rounded()) }, icon: "sun.max.fill"),
            SkinMetric(name: "Redness", score: Int(record.rednessScore.rounded()), previousScore: prevRecord.map { Int($0.rednessScore.rounded()) }, icon: "flame"),
        ]
    }

    private func labelFor(_ score: Int) -> String {
        if score >= 80 { return "Excellent" }
        if score >= 60 { return "Good" }
        return "Fair"
    }

    func onFaceDetected(_ detected: Bool) {
        isFaceDetected = detected
        if detected {
            faceState = .goodLighting
            guidanceText = "Face detected — ready to scan"
        } else {
            faceState = .noFace
            guidanceText = "Position your face in the frame"
        }
    }

    func onFrameCaptured(_ pixelBuffer: CVPixelBuffer) {
        capturedPixelBuffer = pixelBuffer
    }

    func beginScan(modelContext: ModelContext) {
        guard !isScanning else { return }
        isScanning = true
        scanProgress = 0
        phase = .scanning
        capturedPixelBuffer = nil
        analysisStatusText = "Initializing scan..."
        analysisDetailText = "CALIBRATING SENSORS"

        Task {
            let totalSteps = 80
            for i in 1...totalSteps {
                try? await Task.sleep(for: .milliseconds(100))
                scanProgress = Double(i) / Double(totalSteps)
                updateAnalysisText()
            }

            phase = .analyzing

            if let buffer = capturedPixelBuffer {
                let analysis = await analysisService.analyze(pixelBuffer: buffer)
                let result = buildResult(from: analysis)
                currentResult = result
                scanHistory.insert(result, at: 0)
                saveToSwiftData(analysis: analysis, modelContext: modelContext)
            } else {
                let mockAnalysis = SkinAnalysisData(
                    brightnessScore: Double.random(in: 72...90),
                    rednessScore: Double.random(in: 75...92),
                    textureScore: Double.random(in: 70...88),
                    hydrationScore: Double.random(in: 68...86),
                    overallScore: Double.random(in: 74...88)
                )
                let result = buildResult(from: mockAnalysis)
                currentResult = result
                scanHistory.insert(result, at: 0)
                saveToSwiftData(analysis: mockAnalysis, modelContext: modelContext)
            }

            isScanning = false
            phase = .results
        }
    }

    private func saveToSwiftData(analysis: SkinAnalysisData, modelContext: ModelContext) {
        let record = SkinScanRecord(
            date: Date(),
            overallScore: Int(analysis.overallScore.rounded()),
            brightnessScore: analysis.brightnessScore,
            rednessScore: analysis.rednessScore,
            textureScore: analysis.textureScore,
            hydrationScore: analysis.hydrationScore,
            itaAngle: analysis.itaAngle,
            aStarMean: analysis.aStarMean,
            laplacianVariance: analysis.laplacianVariance,
            saturationVariance: analysis.saturationVariance
        )
        modelContext.insert(record)
        UserDefaults.standard.set(Int(analysis.overallScore.rounded()), forKey: "latestSkinScore")

        checkAchievements(modelContext: modelContext)

        try? modelContext.save()
    }

    private func checkAchievements(modelContext: ModelContext) {
        let scanDescriptor = FetchDescriptor<SkinScanRecord>()
        let scanCount = (try? modelContext.fetchCount(scanDescriptor)) ?? 0

        if scanCount >= 1 {
            unlockAchievement(.firstScan, modelContext: modelContext)
        }
        if scanCount >= 10 {
            unlockAchievement(.skinScientist, modelContext: modelContext)
        }
    }

    private func unlockAchievement(_ def: AchievementDefinition, modelContext: ModelContext) {
        let id = def.rawValue
        let predicate = #Predicate<AchievementRecord> { record in
            record.identifier == id
        }
        let descriptor = FetchDescriptor<AchievementRecord>(predicate: predicate)

        if let existing = try? modelContext.fetch(descriptor).first {
            if existing.unlockedAt == nil {
                existing.unlockedAt = Date()
            }
        } else {
            let record = AchievementRecord(identifier: id, unlockedAt: Date())
            modelContext.insert(record)
        }
    }

    private func updateAnalysisText() {
        for phaseInfo in scanPhases {
            if phaseInfo.range.contains(scanProgress) {
                analysisStatusText = phaseInfo.status
                analysisDetailText = phaseInfo.detail
                return
            }
        }
    }

    func resetScan() {
        phase = .preScan
        scanProgress = 0
        currentResult = nil
        isScanning = false
        capturedPixelBuffer = nil
        analysisStatusText = "Initializing scan..."
        analysisDetailText = "CALIBRATING SENSORS"
    }

    func showHistory() {
        phase = .history
    }

    func showHeatMapMode() {
        showHeatMap = true
        phase = .heatMap
    }

    func showProgressMode() {
        phase = .progress
    }

    func exitHeatMap() {
        showHeatMap = false
        phase = .preScan
    }

    private func buildResult(from analysis: SkinAnalysisData) -> SkinScanResult {
        let overallScore = Int(analysis.overallScore.rounded())
        let prevResult = scanHistory.first

        func regionTrend(current: Int, regionName: String) -> RegionTrend {
            guard let prev = prevResult else { return .stable }
            let prevRegion = prev.regions.first { $0.name == regionName }
            guard let prevScore = prevRegion?.score else { return .stable }
            if current > prevScore + 2 { return .improving }
            if current < prevScore - 2 { return .declining }
            return .stable
        }

        let brightnessInt = Int(analysis.brightnessScore.rounded())
        let rednessInt = Int(analysis.rednessScore.rounded())
        let textureInt = Int(analysis.textureScore.rounded())
        let hydrationInt = Int(analysis.hydrationScore.rounded())

        let regions: [SkinRegionResult] = [
            SkinRegionResult(name: "Forehead", icon: "rectangle.portrait.topthird.inset.filled", score: textureInt, keyMetric: "Texture", keyValue: labelFor(textureInt), trend: regionTrend(current: textureInt, regionName: "Forehead")),
            SkinRegionResult(name: "Left Cheek", icon: "rectangle.portrait.leadinghalf.inset.filled", score: hydrationInt, keyMetric: "Hydration", keyValue: labelFor(hydrationInt), trend: regionTrend(current: hydrationInt, regionName: "Left Cheek")),
            SkinRegionResult(name: "Right Cheek", icon: "rectangle.portrait.trailinghalf.inset.filled", score: hydrationInt, keyMetric: "Hydration", keyValue: labelFor(hydrationInt), trend: regionTrend(current: hydrationInt, regionName: "Right Cheek")),
            SkinRegionResult(name: "Chin", icon: "rectangle.portrait.bottomthird.inset.filled", score: rednessInt, keyMetric: "Clarity", keyValue: labelFor(rednessInt), trend: regionTrend(current: rednessInt, regionName: "Chin")),
            SkinRegionResult(name: "Under-Eyes", icon: "eye", score: brightnessInt, keyMetric: "Dark Circles", keyValue: labelFor(brightnessInt), trend: regionTrend(current: brightnessInt, regionName: "Under-Eyes")),
            SkinRegionResult(name: "Nose", icon: "triangle", score: textureInt, keyMetric: "Pores", keyValue: labelFor(textureInt), trend: regionTrend(current: textureInt, regionName: "Nose"))
        ]

        let prevMetrics = prevResult?.metrics
        func prevScore(for name: String) -> Int? {
            prevMetrics?.first { $0.name == name }?.score
        }

        let metrics: [SkinMetric] = [
            SkinMetric(name: "Texture Evenness", score: textureInt, previousScore: prevScore(for: "Texture Evenness"), icon: "square.grid.3x3"),
            SkinMetric(name: "Apparent Hydration", score: hydrationInt, previousScore: prevScore(for: "Apparent Hydration"), icon: "drop.fill"),
            SkinMetric(name: "Brightness", score: brightnessInt, previousScore: prevScore(for: "Brightness"), icon: "sun.max.fill"),
            SkinMetric(name: "Redness", score: rednessInt, previousScore: prevScore(for: "Redness"), icon: "flame"),
        ]

        let trend: Double
        if let prev = prevResult {
            trend = Double(overallScore - prev.overallScore)
        } else {
            trend = 0
        }

        return SkinScanResult(
            date: Date(),
            overallScore: overallScore,
            regions: regions,
            metrics: metrics,
            trend: trend,
            analysisData: analysis
        )
    }
}
