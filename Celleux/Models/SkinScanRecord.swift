import SwiftData
import Foundation

@Model
final class SkinScanRecord {
    var date: Date
    var overallScore: Int

    var textureEvennessScore: Double
    var apparentHydrationScore: Double
    var brightnessRadianceScore: Double
    var rednessScore: Double
    var poreVisibilityScore: Double
    var toneUniformityScore: Double
    var underEyeQualityScore: Double
    var wrinkleDepthScore: Double
    var elasticityProxyScore: Double

    var itaAngle: Double
    var aStarMean: Double
    var bStarMean: Double
    var laplacianVariance: Double
    var saturationVariance: Double
    var poreHFEnergy: Double
    var gaborEnergy: Double
    var toneStdDev: Double
    var underEyeDeltaL: Double
    var elasticityRecoverySpeed: Double
    var photoPath: String?

    var lightingAmbientIntensity: Double
    var lightingColorTemperature: Double
    var lightingCorrectionApplied: Bool

    var isCalibrationPhase: Bool
    var confidenceLevel: String
    var deltaFromBaseline: Double

    var confidenceTextureEvenness: String
    var confidenceApparentHydration: String
    var confidenceBrightnessRadiance: String
    var confidenceRedness: String
    var confidencePoreVisibility: String
    var confidenceToneUniformity: String
    var confidenceUnderEyeQuality: String
    var confidenceWrinkleDepth: String
    var confidenceElasticity: String

    var foreheadTexture: Double
    var foreheadHydration: Double
    var foreheadBrightness: Double
    var foreheadRedness: Double
    var foreheadPores: Double
    var foreheadTone: Double
    var foreheadWrinkles: Double
    var foreheadElasticity: Double
    var foreheadMeanL: Double
    var foreheadMeanA: Double
    var foreheadMeanB: Double
    var foreheadLaplacianVar: Double
    var foreheadSatVar: Double
    var foreheadHFEnergy: Double
    var foreheadGaborEnergy: Double

    var leftCheekTexture: Double
    var leftCheekHydration: Double
    var leftCheekBrightness: Double
    var leftCheekRedness: Double
    var leftCheekPores: Double
    var leftCheekTone: Double
    var leftCheekWrinkles: Double
    var leftCheekElasticity: Double
    var leftCheekMeanL: Double
    var leftCheekMeanA: Double
    var leftCheekMeanB: Double
    var leftCheekLaplacianVar: Double
    var leftCheekSatVar: Double
    var leftCheekHFEnergy: Double
    var leftCheekGaborEnergy: Double

    var rightCheekTexture: Double
    var rightCheekHydration: Double
    var rightCheekBrightness: Double
    var rightCheekRedness: Double
    var rightCheekPores: Double
    var rightCheekTone: Double
    var rightCheekWrinkles: Double
    var rightCheekElasticity: Double
    var rightCheekMeanL: Double
    var rightCheekMeanA: Double
    var rightCheekMeanB: Double
    var rightCheekLaplacianVar: Double
    var rightCheekSatVar: Double
    var rightCheekHFEnergy: Double
    var rightCheekGaborEnergy: Double

    var chinTexture: Double
    var chinHydration: Double
    var chinBrightness: Double
    var chinRedness: Double
    var chinPores: Double
    var chinTone: Double
    var chinWrinkles: Double
    var chinElasticity: Double
    var chinMeanL: Double
    var chinMeanA: Double
    var chinMeanB: Double
    var chinLaplacianVar: Double
    var chinSatVar: Double
    var chinHFEnergy: Double
    var chinGaborEnergy: Double

    var underEyeTexture: Double
    var underEyeHydration: Double
    var underEyeBrightness: Double
    var underEyeRedness: Double
    var underEyePores: Double
    var underEyeTone: Double
    var underEyeWrinkles: Double
    var underEyeElasticity: Double
    var underEyeQuality: Double
    var underEyeMeanL: Double
    var underEyeMeanA: Double
    var underEyeMeanB: Double
    var underEyeLaplacianVar: Double
    var underEyeSatVar: Double
    var underEyeHFEnergy: Double
    var underEyeGaborEnergy: Double

    var noseTexture: Double
    var noseHydration: Double
    var noseBrightness: Double
    var noseRedness: Double
    var nosePores: Double
    var noseTone: Double
    var noseWrinkles: Double
    var noseElasticity: Double
    var noseMeanL: Double
    var noseMeanA: Double
    var noseMeanB: Double
    var noseLaplacianVar: Double
    var noseSatVar: Double
    var noseHFEnergy: Double
    var noseGaborEnergy: Double

    init(
        date: Date = Date(),
        overallScore: Int = 0,
        textureEvennessScore: Double = 0,
        apparentHydrationScore: Double = 0,
        brightnessRadianceScore: Double = 0,
        rednessScore: Double = 0,
        poreVisibilityScore: Double = 0,
        toneUniformityScore: Double = 0,
        underEyeQualityScore: Double = 0,
        wrinkleDepthScore: Double = 0,
        elasticityProxyScore: Double = 0,
        itaAngle: Double = 0,
        aStarMean: Double = 0,
        bStarMean: Double = 0,
        laplacianVariance: Double = 0,
        saturationVariance: Double = 0,
        poreHFEnergy: Double = 0,
        gaborEnergy: Double = 0,
        toneStdDev: Double = 0,
        underEyeDeltaL: Double = 0,
        elasticityRecoverySpeed: Double = 0,
        photoPath: String? = nil,
        lightingAmbientIntensity: Double = 0,
        lightingColorTemperature: Double = 0,
        lightingCorrectionApplied: Bool = false,
        isCalibrationPhase: Bool = false,
        confidenceLevel: String = "Low",
        deltaFromBaseline: Double = 0,
        confidenceTextureEvenness: String = "Low",
        confidenceApparentHydration: String = "Low",
        confidenceBrightnessRadiance: String = "Low",
        confidenceRedness: String = "Low",
        confidencePoreVisibility: String = "Low",
        confidenceToneUniformity: String = "Low",
        confidenceUnderEyeQuality: String = "Low",
        confidenceWrinkleDepth: String = "Low",
        confidenceElasticity: String = "Low"
    ) {
        self.date = date
        self.overallScore = overallScore
        self.textureEvennessScore = textureEvennessScore
        self.apparentHydrationScore = apparentHydrationScore
        self.brightnessRadianceScore = brightnessRadianceScore
        self.rednessScore = rednessScore
        self.poreVisibilityScore = poreVisibilityScore
        self.toneUniformityScore = toneUniformityScore
        self.underEyeQualityScore = underEyeQualityScore
        self.wrinkleDepthScore = wrinkleDepthScore
        self.elasticityProxyScore = elasticityProxyScore
        self.itaAngle = itaAngle
        self.aStarMean = aStarMean
        self.bStarMean = bStarMean
        self.laplacianVariance = laplacianVariance
        self.saturationVariance = saturationVariance
        self.poreHFEnergy = poreHFEnergy
        self.gaborEnergy = gaborEnergy
        self.toneStdDev = toneStdDev
        self.underEyeDeltaL = underEyeDeltaL
        self.elasticityRecoverySpeed = elasticityRecoverySpeed
        self.photoPath = photoPath
        self.lightingAmbientIntensity = lightingAmbientIntensity
        self.lightingColorTemperature = lightingColorTemperature
        self.lightingCorrectionApplied = lightingCorrectionApplied
        self.isCalibrationPhase = isCalibrationPhase
        self.confidenceLevel = confidenceLevel
        self.deltaFromBaseline = deltaFromBaseline
        self.confidenceTextureEvenness = confidenceTextureEvenness
        self.confidenceApparentHydration = confidenceApparentHydration
        self.confidenceBrightnessRadiance = confidenceBrightnessRadiance
        self.confidenceRedness = confidenceRedness
        self.confidencePoreVisibility = confidencePoreVisibility
        self.confidenceToneUniformity = confidenceToneUniformity
        self.confidenceUnderEyeQuality = confidenceUnderEyeQuality
        self.confidenceWrinkleDepth = confidenceWrinkleDepth
        self.confidenceElasticity = confidenceElasticity

        self.foreheadTexture = 0; self.foreheadHydration = 0; self.foreheadBrightness = 0
        self.foreheadRedness = 0; self.foreheadPores = 0; self.foreheadTone = 0
        self.foreheadWrinkles = 0; self.foreheadElasticity = 0
        self.foreheadMeanL = 0; self.foreheadMeanA = 0; self.foreheadMeanB = 0
        self.foreheadLaplacianVar = 0; self.foreheadSatVar = 0
        self.foreheadHFEnergy = 0; self.foreheadGaborEnergy = 0

        self.leftCheekTexture = 0; self.leftCheekHydration = 0; self.leftCheekBrightness = 0
        self.leftCheekRedness = 0; self.leftCheekPores = 0; self.leftCheekTone = 0
        self.leftCheekWrinkles = 0; self.leftCheekElasticity = 0
        self.leftCheekMeanL = 0; self.leftCheekMeanA = 0; self.leftCheekMeanB = 0
        self.leftCheekLaplacianVar = 0; self.leftCheekSatVar = 0
        self.leftCheekHFEnergy = 0; self.leftCheekGaborEnergy = 0

        self.rightCheekTexture = 0; self.rightCheekHydration = 0; self.rightCheekBrightness = 0
        self.rightCheekRedness = 0; self.rightCheekPores = 0; self.rightCheekTone = 0
        self.rightCheekWrinkles = 0; self.rightCheekElasticity = 0
        self.rightCheekMeanL = 0; self.rightCheekMeanA = 0; self.rightCheekMeanB = 0
        self.rightCheekLaplacianVar = 0; self.rightCheekSatVar = 0
        self.rightCheekHFEnergy = 0; self.rightCheekGaborEnergy = 0

        self.chinTexture = 0; self.chinHydration = 0; self.chinBrightness = 0
        self.chinRedness = 0; self.chinPores = 0; self.chinTone = 0
        self.chinWrinkles = 0; self.chinElasticity = 0
        self.chinMeanL = 0; self.chinMeanA = 0; self.chinMeanB = 0
        self.chinLaplacianVar = 0; self.chinSatVar = 0
        self.chinHFEnergy = 0; self.chinGaborEnergy = 0

        self.underEyeTexture = 0; self.underEyeHydration = 0; self.underEyeBrightness = 0
        self.underEyeRedness = 0; self.underEyePores = 0; self.underEyeTone = 0
        self.underEyeWrinkles = 0; self.underEyeElasticity = 0; self.underEyeQuality = 0
        self.underEyeMeanL = 0; self.underEyeMeanA = 0; self.underEyeMeanB = 0
        self.underEyeLaplacianVar = 0; self.underEyeSatVar = 0
        self.underEyeHFEnergy = 0; self.underEyeGaborEnergy = 0

        self.noseTexture = 0; self.noseHydration = 0; self.noseBrightness = 0
        self.noseRedness = 0; self.nosePores = 0; self.noseTone = 0
        self.noseWrinkles = 0; self.noseElasticity = 0
        self.noseMeanL = 0; self.noseMeanA = 0; self.noseMeanB = 0
        self.noseLaplacianVar = 0; self.noseSatVar = 0
        self.noseHFEnergy = 0; self.noseGaborEnergy = 0
    }

    var brightnessScore: Double { brightnessRadianceScore }
    var textureScore: Double { textureEvennessScore }
    var hydrationScore: Double { apparentHydrationScore }

    func confidenceForMetric(_ metric: SkinMetricType) -> String {
        switch metric {
        case .textureEvenness: confidenceTextureEvenness
        case .apparentHydration: confidenceApparentHydration
        case .brightnessRadiance: confidenceBrightnessRadiance
        case .rednessInflammation: confidenceRedness
        case .poreVisibility: confidencePoreVisibility
        case .toneUniformity: confidenceToneUniformity
        case .underEyeQuality: confidenceUnderEyeQuality
        case .wrinkleDepth: confidenceWrinkleDepth
        case .elasticityProxy: confidenceElasticity
        case .overallSkinHealth: confidenceLevel
        }
    }

    func setConfidenceForMetric(_ metric: SkinMetricType, level: String) {
        switch metric {
        case .textureEvenness: confidenceTextureEvenness = level
        case .apparentHydration: confidenceApparentHydration = level
        case .brightnessRadiance: confidenceBrightnessRadiance = level
        case .rednessInflammation: confidenceRedness = level
        case .poreVisibility: confidencePoreVisibility = level
        case .toneUniformity: confidenceToneUniformity = level
        case .underEyeQuality: confidenceUnderEyeQuality = level
        case .wrinkleDepth: confidenceWrinkleDepth = level
        case .elasticityProxy: confidenceElasticity = level
        case .overallSkinHealth: confidenceLevel = level
        }
    }

    func regionScores(for region: String) -> RegionScores {
        switch region {
        case "Forehead":
            return RegionScores(
                textureEvennessScore: foreheadTexture, apparentHydrationScore: foreheadHydration,
                brightnessRadianceScore: foreheadBrightness, rednessScore: foreheadRedness,
                poreVisibilityScore: foreheadPores, toneUniformityScore: foreheadTone,
                wrinkleDepthScore: foreheadWrinkles, elasticityProxyScore: foreheadElasticity,
                itaAngle: 0, aStarMean: foreheadMeanA, bStarMean: foreheadMeanB,
                laplacianVariance: foreheadLaplacianVar, saturationVariance: foreheadSatVar,
                hfEnergy: foreheadHFEnergy, gaborFilterEnergy: foreheadGaborEnergy, meanL: foreheadMeanL
            )
        case "Left Cheek":
            return RegionScores(
                textureEvennessScore: leftCheekTexture, apparentHydrationScore: leftCheekHydration,
                brightnessRadianceScore: leftCheekBrightness, rednessScore: leftCheekRedness,
                poreVisibilityScore: leftCheekPores, toneUniformityScore: leftCheekTone,
                wrinkleDepthScore: leftCheekWrinkles, elasticityProxyScore: leftCheekElasticity,
                itaAngle: 0, aStarMean: leftCheekMeanA, bStarMean: leftCheekMeanB,
                laplacianVariance: leftCheekLaplacianVar, saturationVariance: leftCheekSatVar,
                hfEnergy: leftCheekHFEnergy, gaborFilterEnergy: leftCheekGaborEnergy, meanL: leftCheekMeanL
            )
        case "Right Cheek":
            return RegionScores(
                textureEvennessScore: rightCheekTexture, apparentHydrationScore: rightCheekHydration,
                brightnessRadianceScore: rightCheekBrightness, rednessScore: rightCheekRedness,
                poreVisibilityScore: rightCheekPores, toneUniformityScore: rightCheekTone,
                wrinkleDepthScore: rightCheekWrinkles, elasticityProxyScore: rightCheekElasticity,
                itaAngle: 0, aStarMean: rightCheekMeanA, bStarMean: rightCheekMeanB,
                laplacianVariance: rightCheekLaplacianVar, saturationVariance: rightCheekSatVar,
                hfEnergy: rightCheekHFEnergy, gaborFilterEnergy: rightCheekGaborEnergy, meanL: rightCheekMeanL
            )
        case "Chin":
            return RegionScores(
                textureEvennessScore: chinTexture, apparentHydrationScore: chinHydration,
                brightnessRadianceScore: chinBrightness, rednessScore: chinRedness,
                poreVisibilityScore: chinPores, toneUniformityScore: chinTone,
                wrinkleDepthScore: chinWrinkles, elasticityProxyScore: chinElasticity,
                itaAngle: 0, aStarMean: chinMeanA, bStarMean: chinMeanB,
                laplacianVariance: chinLaplacianVar, saturationVariance: chinSatVar,
                hfEnergy: chinHFEnergy, gaborFilterEnergy: chinGaborEnergy, meanL: chinMeanL
            )
        case "Under-Eyes":
            return RegionScores(
                textureEvennessScore: underEyeTexture, apparentHydrationScore: underEyeHydration,
                brightnessRadianceScore: underEyeBrightness, rednessScore: underEyeRedness,
                poreVisibilityScore: underEyePores, toneUniformityScore: underEyeTone,
                underEyeQualityScore: underEyeQuality, wrinkleDepthScore: underEyeWrinkles,
                elasticityProxyScore: underEyeElasticity,
                itaAngle: 0, aStarMean: underEyeMeanA, bStarMean: underEyeMeanB,
                laplacianVariance: underEyeLaplacianVar, saturationVariance: underEyeSatVar,
                hfEnergy: underEyeHFEnergy, gaborFilterEnergy: underEyeGaborEnergy, meanL: underEyeMeanL
            )
        case "Nose":
            return RegionScores(
                textureEvennessScore: noseTexture, apparentHydrationScore: noseHydration,
                brightnessRadianceScore: noseBrightness, rednessScore: noseRedness,
                poreVisibilityScore: nosePores, toneUniformityScore: noseTone,
                wrinkleDepthScore: noseWrinkles, elasticityProxyScore: noseElasticity,
                itaAngle: 0, aStarMean: noseMeanA, bStarMean: noseMeanB,
                laplacianVariance: noseLaplacianVar, saturationVariance: noseSatVar,
                hfEnergy: noseHFEnergy, gaborFilterEnergy: noseGaborEnergy, meanL: noseMeanL
            )
        default:
            return RegionScores()
        }
    }

    func storeRegionScores(_ scores: RegionScores, for region: String) {
        switch region {
        case "Forehead":
            foreheadTexture = scores.textureEvennessScore
            foreheadHydration = scores.apparentHydrationScore
            foreheadBrightness = scores.brightnessRadianceScore
            foreheadRedness = scores.rednessScore
            foreheadPores = scores.poreVisibilityScore
            foreheadTone = scores.toneUniformityScore
            foreheadWrinkles = scores.wrinkleDepthScore
            foreheadElasticity = scores.elasticityProxyScore
            foreheadMeanL = scores.meanL
            foreheadMeanA = scores.aStarMean
            foreheadMeanB = scores.bStarMean
            foreheadLaplacianVar = scores.laplacianVariance
            foreheadSatVar = scores.saturationVariance
            foreheadHFEnergy = scores.hfEnergy
            foreheadGaborEnergy = scores.gaborFilterEnergy
        case "Left Cheek":
            leftCheekTexture = scores.textureEvennessScore
            leftCheekHydration = scores.apparentHydrationScore
            leftCheekBrightness = scores.brightnessRadianceScore
            leftCheekRedness = scores.rednessScore
            leftCheekPores = scores.poreVisibilityScore
            leftCheekTone = scores.toneUniformityScore
            leftCheekWrinkles = scores.wrinkleDepthScore
            leftCheekElasticity = scores.elasticityProxyScore
            leftCheekMeanL = scores.meanL
            leftCheekMeanA = scores.aStarMean
            leftCheekMeanB = scores.bStarMean
            leftCheekLaplacianVar = scores.laplacianVariance
            leftCheekSatVar = scores.saturationVariance
            leftCheekHFEnergy = scores.hfEnergy
            leftCheekGaborEnergy = scores.gaborFilterEnergy
        case "Right Cheek":
            rightCheekTexture = scores.textureEvennessScore
            rightCheekHydration = scores.apparentHydrationScore
            rightCheekBrightness = scores.brightnessRadianceScore
            rightCheekRedness = scores.rednessScore
            rightCheekPores = scores.poreVisibilityScore
            rightCheekTone = scores.toneUniformityScore
            rightCheekWrinkles = scores.wrinkleDepthScore
            rightCheekElasticity = scores.elasticityProxyScore
            rightCheekMeanL = scores.meanL
            rightCheekMeanA = scores.aStarMean
            rightCheekMeanB = scores.bStarMean
            rightCheekLaplacianVar = scores.laplacianVariance
            rightCheekSatVar = scores.saturationVariance
            rightCheekHFEnergy = scores.hfEnergy
            rightCheekGaborEnergy = scores.gaborFilterEnergy
        case "Chin":
            chinTexture = scores.textureEvennessScore
            chinHydration = scores.apparentHydrationScore
            chinBrightness = scores.brightnessRadianceScore
            chinRedness = scores.rednessScore
            chinPores = scores.poreVisibilityScore
            chinTone = scores.toneUniformityScore
            chinWrinkles = scores.wrinkleDepthScore
            chinElasticity = scores.elasticityProxyScore
            chinMeanL = scores.meanL
            chinMeanA = scores.aStarMean
            chinMeanB = scores.bStarMean
            chinLaplacianVar = scores.laplacianVariance
            chinSatVar = scores.saturationVariance
            chinHFEnergy = scores.hfEnergy
            chinGaborEnergy = scores.gaborFilterEnergy
        case "Under-Eyes":
            underEyeTexture = scores.textureEvennessScore
            underEyeHydration = scores.apparentHydrationScore
            underEyeBrightness = scores.brightnessRadianceScore
            underEyeRedness = scores.rednessScore
            underEyePores = scores.poreVisibilityScore
            underEyeTone = scores.toneUniformityScore
            underEyeQuality = scores.underEyeQualityScore
            underEyeWrinkles = scores.wrinkleDepthScore
            underEyeElasticity = scores.elasticityProxyScore
            underEyeMeanL = scores.meanL
            underEyeMeanA = scores.aStarMean
            underEyeMeanB = scores.bStarMean
            underEyeLaplacianVar = scores.laplacianVariance
            underEyeSatVar = scores.saturationVariance
            underEyeHFEnergy = scores.hfEnergy
            underEyeGaborEnergy = scores.gaborFilterEnergy
        case "Nose":
            noseTexture = scores.textureEvennessScore
            noseHydration = scores.apparentHydrationScore
            noseBrightness = scores.brightnessRadianceScore
            noseRedness = scores.rednessScore
            nosePores = scores.poreVisibilityScore
            noseTone = scores.toneUniformityScore
            noseWrinkles = scores.wrinkleDepthScore
            noseElasticity = scores.elasticityProxyScore
            noseMeanL = scores.meanL
            noseMeanA = scores.aStarMean
            noseMeanB = scores.bStarMean
            noseLaplacianVar = scores.laplacianVariance
            noseSatVar = scores.saturationVariance
            noseHFEnergy = scores.hfEnergy
            noseGaborEnergy = scores.gaborFilterEnergy
        default:
            break
        }
    }
}
