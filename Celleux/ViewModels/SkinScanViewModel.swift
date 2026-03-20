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
    var capturedPixelBuffers: [CVPixelBuffer] = []
    var captureFailed: Bool = false
    var guidanceText: String = "Position your face in the frame"
    var isFaceDetected: Bool = false
    var analysisStatusText: String = "Initializing scan..."
    var analysisDetailText: String = "CALIBRATING SENSORS"
    var heatMapMode: HeatMapMode = .all
    var showHeatMap: Bool = false
    var selectedTimeframe: ProgressTimeframe = .thirtyDays
    var scanError: String?
    var latestRegionScores: [String: RegionScores] = [:]
    var blendShapeElasticity: Double?
    var currentLightingConditions: LightingConditions?
    var calibrationResult: CalibrationResult?
    var isCalibrating: Bool = false
    var calibrationScansRemaining: Int = 3

    private let analysisService = SkinAnalysisService()
    private let calibrationService = CalibrationService()

    private let scanPhases: [(range: ClosedRange<Double>, status: String, detail: String)] = [
        (0.0...0.10, "Mapping facial geometry...", "DETECTING 1,220 VERTICES"),
        (0.10...0.20, "Capturing skin texture...", "LAPLACIAN VARIANCE COMPUTE"),
        (0.20...0.30, "Measuring hydration...", "SATURATION ANALYSIS"),
        (0.30...0.40, "Evaluating radiance...", "L*a*b* COLOR SPACE"),
        (0.40...0.50, "Analyzing redness...", "a* CHANNEL EXTRACTION"),
        (0.50...0.60, "Scanning pore density...", "HIGH-FREQ ENERGY MAP"),
        (0.60...0.70, "Checking tone uniformity...", "L* STDDEV ACROSS REGIONS"),
        (0.70...0.80, "Mapping under-eye area...", "DELTA-L* COMPUTATION"),
        (0.80...0.90, "Detecting wrinkle depth...", "GABOR FILTER BANK"),
        (0.90...1.0, "Measuring elasticity...", "BLEND SHAPE ANALYSIS"),
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
                regions: buildRegionsFromRecord(record, prevRecord: prevRecord),
                metrics: buildMetricsFromRecord(record, prevRecord: prevRecord),
                trend: trend,
                analysisData: SkinAnalysisData(
                    textureEvennessScore: record.textureEvennessScore,
                    apparentHydrationScore: record.apparentHydrationScore,
                    brightnessRadianceScore: record.brightnessRadianceScore,
                    rednessScore: record.rednessScore,
                    poreVisibilityScore: record.poreVisibilityScore,
                    toneUniformityScore: record.toneUniformityScore,
                    underEyeQualityScore: record.underEyeQualityScore,
                    wrinkleDepthScore: record.wrinkleDepthScore,
                    elasticityProxyScore: record.elasticityProxyScore,
                    overallScore: Double(record.overallScore),
                    itaAngle: record.itaAngle,
                    aStarMean: record.aStarMean,
                    bStarMean: record.bStarMean,
                    laplacianVariance: record.laplacianVariance,
                    saturationVariance: record.saturationVariance,
                    poreHFEnergy: record.poreHFEnergy,
                    gaborEnergy: record.gaborEnergy,
                    toneStdDev: record.toneStdDev,
                    underEyeDeltaL: record.underEyeDeltaL,
                    elasticityRecoverySpeed: record.elasticityRecoverySpeed,
                    regionData: extractRegionDataFromRecord(record)
                )
            )
        }
    }

    private func extractRegionDataFromRecord(_ record: SkinScanRecord) -> [String: RegionScores] {
        var data: [String: RegionScores] = [:]
        let regionNames = ["Forehead", "Left Cheek", "Right Cheek", "Chin", "Under-Eyes", "Nose"]
        for name in regionNames {
            let scores = record.regionScores(for: name)
            if scores.textureEvennessScore > 0 || scores.rednessScore > 0 || scores.brightnessRadianceScore > 0 || scores.apparentHydrationScore > 0 {
                data[name] = scores
            }
        }
        return data
    }

    private func buildRegionsFromRecord(_ record: SkinScanRecord, prevRecord: SkinScanRecord?) -> [SkinRegionResult] {
        let regionDefs: [(name: String, icon: String, keyMetric: String)] = [
            ("Forehead", "rectangle.portrait.topthird.inset.filled", "Texture"),
            ("Left Cheek", "rectangle.portrait.leadinghalf.inset.filled", "Hydration"),
            ("Right Cheek", "rectangle.portrait.trailinghalf.inset.filled", "Hydration"),
            ("Chin", "rectangle.portrait.bottomthird.inset.filled", "Clarity"),
            ("Under-Eyes", "eye", "Dark Circles"),
            ("Nose", "triangle", "Pores")
        ]

        return regionDefs.map { def in
            let scores = record.regionScores(for: def.name)
            let prevScores = prevRecord?.regionScores(for: def.name)
            let score = primaryScore(for: def.keyMetric, from: scores)
            let prevScore = prevScores.map { primaryScore(for: def.keyMetric, from: $0) }

            return SkinRegionResult(
                name: def.name,
                icon: def.icon,
                score: score,
                keyMetric: def.keyMetric,
                keyValue: labelFor(score),
                trend: computeTrend(current: score, previous: prevScore)
            )
        }
    }

    private func buildMetricsFromRecord(_ record: SkinScanRecord, prevRecord: SkinScanRecord?) -> [SkinMetric] {
        var metrics: [SkinMetric] = []
        for metricType in SkinMetricType.allCases where metricType != .overallSkinHealth && metricType.isImplemented {
            let current = scoreFromRecord(record, metric: metricType)
            let previous = prevRecord.map { scoreFromRecord($0, metric: metricType) }
            metrics.append(SkinMetric(
                name: metricType.rawValue,
                score: Int(current.rounded()),
                previousScore: previous.map { Int($0.rounded()) },
                icon: metricType.icon
            ))
        }
        return metrics
    }

    private func scoreFromRecord(_ record: SkinScanRecord, metric: SkinMetricType) -> Double {
        switch metric {
        case .textureEvenness: record.textureEvennessScore
        case .apparentHydration: record.apparentHydrationScore
        case .brightnessRadiance: record.brightnessRadianceScore
        case .rednessInflammation: record.rednessScore
        case .poreVisibility: record.poreVisibilityScore
        case .toneUniformity: record.toneUniformityScore
        case .underEyeQuality: record.underEyeQualityScore
        case .wrinkleDepth: record.wrinkleDepthScore
        case .elasticityProxy: record.elasticityProxyScore
        case .overallSkinHealth: Double(record.overallScore)
        }
    }

    private func primaryScore(for keyMetric: String, from scores: RegionScores) -> Int {
        switch keyMetric {
        case "Texture": return Int(scores.textureEvennessScore.rounded())
        case "Pores": return Int(scores.poreVisibilityScore > 0 ? scores.poreVisibilityScore.rounded() : scores.textureEvennessScore.rounded())
        case "Hydration": return Int(scores.apparentHydrationScore.rounded())
        case "Clarity": return Int(scores.rednessScore.rounded())
        case "Dark Circles": return Int(scores.underEyeQualityScore > 0 ? scores.underEyeQualityScore.rounded() : scores.brightnessRadianceScore.rounded())
        default: return Int(scores.brightnessRadianceScore.rounded())
        }
    }

    private func computeTrend(current: Int, previous: Int?) -> RegionTrend {
        guard let p = previous else { return .stable }
        if current > p + 2 { return .improving }
        if current < p - 2 { return .declining }
        return .stable
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
        capturedPixelBuffers.append(pixelBuffer)
    }

    func onAllCapturesFailed() {
        captureFailed = true
    }

    func onElasticityComputed(_ score: Double) {
        blendShapeElasticity = score
    }

    func onLightingUpdated(_ conditions: LightingConditions) {
        currentLightingConditions = conditions
        lightingQuality = conditions.qualityLevel
        if conditions.qualityLevel == .poor {
            guidanceText = "Find better lighting"
        } else if isFaceDetected {
            guidanceText = "Face detected \u{2014} ready to scan"
        }
    }

    func beginScan(modelContext: ModelContext) {
        guard !isScanning else { return }
        isScanning = true
        scanProgress = 0
        phase = .scanning
        capturedPixelBuffer = nil
        capturedPixelBuffers = []
        captureFailed = false
        scanError = nil
        blendShapeElasticity = nil
        currentLightingConditions = nil
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

            if capturedPixelBuffers.isEmpty {
                scanError = "Unable to capture frame — please try again in better lighting"
                isScanning = false
                phase = .preScan
                return
            }

            var analysis: SkinAnalysisData?
            for buffer in capturedPixelBuffers.reversed() {
                if let result = await analysisService.analyze(pixelBuffer: buffer, blendShapeElasticity: blendShapeElasticity, lightingConditions: currentLightingConditions) {
                    analysis = result
                    break
                }
            }

            guard let analysis else {
                scanError = "Analysis failed — ensure your face is well-lit and centered"
                isScanning = false
                phase = .preScan
                return
            }

            latestRegionScores = analysis.regionData

            let calResult = calibrationService.processCalibration(analysis: analysis, modelContext: modelContext)
            saveToSwiftData(analysis: analysis, calibration: calResult, modelContext: modelContext)
            calibrationResult = calResult
            isCalibrating = calResult.isCalibrating
            calibrationScansRemaining = calResult.calibrationScansRemaining

            let result = buildResult(from: analysis, calibration: calResult)
            currentResult = result
            scanHistory.insert(result, at: 0)

            isScanning = false
            phase = .results
        }
    }

    private func saveToSwiftData(analysis: SkinAnalysisData, calibration calResult: CalibrationResult, modelContext: ModelContext) {
        let record = SkinScanRecord(
            date: Date(),
            overallScore: Int(analysis.overallScore.rounded()),
            textureEvennessScore: analysis.textureEvennessScore,
            apparentHydrationScore: analysis.apparentHydrationScore,
            brightnessRadianceScore: analysis.brightnessRadianceScore,
            rednessScore: analysis.rednessScore,
            poreVisibilityScore: analysis.poreVisibilityScore,
            toneUniformityScore: analysis.toneUniformityScore,
            underEyeQualityScore: analysis.underEyeQualityScore,
            wrinkleDepthScore: analysis.wrinkleDepthScore,
            elasticityProxyScore: analysis.elasticityProxyScore,
            itaAngle: analysis.itaAngle,
            aStarMean: analysis.aStarMean,
            bStarMean: analysis.bStarMean,
            laplacianVariance: analysis.laplacianVariance,
            saturationVariance: analysis.saturationVariance,
            poreHFEnergy: analysis.poreHFEnergy,
            gaborEnergy: analysis.gaborEnergy,
            toneStdDev: analysis.toneStdDev,
            underEyeDeltaL: analysis.underEyeDeltaL,
            elasticityRecoverySpeed: analysis.elasticityRecoverySpeed,
            lightingAmbientIntensity: analysis.lightingConditions?.ambientIntensity ?? 0,
            lightingColorTemperature: analysis.lightingConditions?.colorTemperature ?? 0,
            lightingCorrectionApplied: analysis.lightingConditions?.correctionApplied ?? false,
            isCalibrationPhase: calResult.isCalibrating,
            confidenceLevel: calResult.overallConfidence.rawValue,
            deltaFromBaseline: calResult.deltaFromBaseline ?? 0
        )

        for metric in SkinMetricType.allCases where metric != .overallSkinHealth && metric.isImplemented {
            let confidence = calResult.perMetricConfidence[metric] ?? .low
            record.setConfidenceForMetric(metric, level: confidence.rawValue)
        }

        let regionNames = ["Forehead", "Left Cheek", "Right Cheek", "Chin", "Under-Eyes", "Nose"]
        for name in regionNames {
            if let scores = analysis.regionData[name] {
                record.storeRegionScores(scores, for: name)
            }
        }

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
        capturedPixelBuffers = []
        captureFailed = false
        scanError = nil
        blendShapeElasticity = nil
        currentLightingConditions = nil
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

    private func buildResult(from analysis: SkinAnalysisData, calibration: CalibrationResult? = nil) -> SkinScanResult {
        let overallScore = Int(analysis.overallScore.rounded())
        let prevResult = scanHistory.first

        let regionDefs: [(name: String, icon: String, keyMetric: String)] = [
            ("Forehead", "rectangle.portrait.topthird.inset.filled", "Texture"),
            ("Left Cheek", "rectangle.portrait.leadinghalf.inset.filled", "Hydration"),
            ("Right Cheek", "rectangle.portrait.trailinghalf.inset.filled", "Hydration"),
            ("Chin", "rectangle.portrait.bottomthird.inset.filled", "Clarity"),
            ("Under-Eyes", "eye", "Dark Circles"),
            ("Nose", "triangle", "Pores")
        ]

        let regions: [SkinRegionResult] = regionDefs.map { def in
            let regionScores = analysis.regionData[def.name] ?? RegionScores(
                textureEvennessScore: analysis.textureEvennessScore,
                apparentHydrationScore: analysis.apparentHydrationScore,
                brightnessRadianceScore: analysis.brightnessRadianceScore,
                rednessScore: analysis.rednessScore
            )
            let score = primaryScore(for: def.keyMetric, from: regionScores)
            let prevRegion = prevResult?.regions.first { $0.name == def.name }

            return SkinRegionResult(
                name: def.name,
                icon: def.icon,
                score: score,
                keyMetric: def.keyMetric,
                keyValue: labelFor(score),
                trend: computeTrend(current: score, previous: prevRegion?.score)
            )
        }

        let prevMetrics = prevResult?.metrics
        func prevScore(for name: String) -> Int? {
            prevMetrics?.first { $0.name == name }?.score
        }

        var metrics: [SkinMetric] = []
        for metricType in SkinMetricType.allCases where metricType != .overallSkinHealth && metricType.isImplemented {
            metrics.append(SkinMetric(
                name: metricType.rawValue,
                score: Int(analysis.score(for: metricType).rounded()),
                previousScore: prevScore(for: metricType.rawValue),
                icon: metricType.icon
            ))
        }

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
            analysisData: analysis,
            calibration: calibration
        )
    }
}
