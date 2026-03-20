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
    var photoPath: String?

    var lightingAmbientIntensity: Double
    var lightingColorTemperature: Double
    var lightingCorrectionApplied: Bool

    var foreheadTexture: Double
    var foreheadHydration: Double
    var foreheadBrightness: Double
    var foreheadRedness: Double
    var foreheadPores: Double
    var foreheadTone: Double
    var foreheadWrinkles: Double

    var leftCheekTexture: Double
    var leftCheekHydration: Double
    var leftCheekBrightness: Double
    var leftCheekRedness: Double
    var leftCheekPores: Double
    var leftCheekTone: Double

    var rightCheekTexture: Double
    var rightCheekHydration: Double
    var rightCheekBrightness: Double
    var rightCheekRedness: Double
    var rightCheekPores: Double
    var rightCheekTone: Double

    var chinTexture: Double
    var chinHydration: Double
    var chinBrightness: Double
    var chinRedness: Double

    var underEyeBrightness: Double
    var underEyeRedness: Double
    var underEyeTexture: Double
    var underEyeHydration: Double
    var underEyeQuality: Double

    var noseTexture: Double
    var noseHydration: Double
    var noseBrightness: Double
    var noseRedness: Double
    var nosePores: Double

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
        photoPath: String? = nil,
        lightingAmbientIntensity: Double = 0,
        lightingColorTemperature: Double = 0,
        lightingCorrectionApplied: Bool = false,
        foreheadTexture: Double = 0, foreheadHydration: Double = 0, foreheadBrightness: Double = 0, foreheadRedness: Double = 0, foreheadPores: Double = 0, foreheadTone: Double = 0, foreheadWrinkles: Double = 0,
        leftCheekTexture: Double = 0, leftCheekHydration: Double = 0, leftCheekBrightness: Double = 0, leftCheekRedness: Double = 0, leftCheekPores: Double = 0, leftCheekTone: Double = 0,
        rightCheekTexture: Double = 0, rightCheekHydration: Double = 0, rightCheekBrightness: Double = 0, rightCheekRedness: Double = 0, rightCheekPores: Double = 0, rightCheekTone: Double = 0,
        chinTexture: Double = 0, chinHydration: Double = 0, chinBrightness: Double = 0, chinRedness: Double = 0,
        underEyeBrightness: Double = 0, underEyeRedness: Double = 0, underEyeTexture: Double = 0, underEyeHydration: Double = 0, underEyeQuality: Double = 0,
        noseTexture: Double = 0, noseHydration: Double = 0, noseBrightness: Double = 0, noseRedness: Double = 0, nosePores: Double = 0
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
        self.photoPath = photoPath
        self.lightingAmbientIntensity = lightingAmbientIntensity
        self.lightingColorTemperature = lightingColorTemperature
        self.lightingCorrectionApplied = lightingCorrectionApplied
        self.foreheadTexture = foreheadTexture
        self.foreheadHydration = foreheadHydration
        self.foreheadBrightness = foreheadBrightness
        self.foreheadRedness = foreheadRedness
        self.foreheadPores = foreheadPores
        self.foreheadTone = foreheadTone
        self.foreheadWrinkles = foreheadWrinkles
        self.leftCheekTexture = leftCheekTexture
        self.leftCheekHydration = leftCheekHydration
        self.leftCheekBrightness = leftCheekBrightness
        self.leftCheekRedness = leftCheekRedness
        self.leftCheekPores = leftCheekPores
        self.leftCheekTone = leftCheekTone
        self.rightCheekTexture = rightCheekTexture
        self.rightCheekHydration = rightCheekHydration
        self.rightCheekBrightness = rightCheekBrightness
        self.rightCheekRedness = rightCheekRedness
        self.rightCheekPores = rightCheekPores
        self.rightCheekTone = rightCheekTone
        self.chinTexture = chinTexture
        self.chinHydration = chinHydration
        self.chinBrightness = chinBrightness
        self.chinRedness = chinRedness
        self.underEyeBrightness = underEyeBrightness
        self.underEyeRedness = underEyeRedness
        self.underEyeTexture = underEyeTexture
        self.underEyeHydration = underEyeHydration
        self.underEyeQuality = underEyeQuality
        self.noseTexture = noseTexture
        self.noseHydration = noseHydration
        self.noseBrightness = noseBrightness
        self.noseRedness = noseRedness
        self.nosePores = nosePores
    }

    var brightnessScore: Double { brightnessRadianceScore }
    var textureScore: Double { textureEvennessScore }
    var hydrationScore: Double { apparentHydrationScore }

    func regionScores(for region: String) -> RegionScores {
        switch region {
        case "Forehead":
            return RegionScores(
                textureEvennessScore: foreheadTexture, apparentHydrationScore: foreheadHydration,
                brightnessRadianceScore: foreheadBrightness, rednessScore: foreheadRedness,
                poreVisibilityScore: foreheadPores, toneUniformityScore: foreheadTone,
                wrinkleDepthScore: foreheadWrinkles
            )
        case "Left Cheek":
            return RegionScores(
                textureEvennessScore: leftCheekTexture, apparentHydrationScore: leftCheekHydration,
                brightnessRadianceScore: leftCheekBrightness, rednessScore: leftCheekRedness,
                poreVisibilityScore: leftCheekPores, toneUniformityScore: leftCheekTone
            )
        case "Right Cheek":
            return RegionScores(
                textureEvennessScore: rightCheekTexture, apparentHydrationScore: rightCheekHydration,
                brightnessRadianceScore: rightCheekBrightness, rednessScore: rightCheekRedness,
                poreVisibilityScore: rightCheekPores, toneUniformityScore: rightCheekTone
            )
        case "Chin":
            return RegionScores(
                textureEvennessScore: chinTexture, apparentHydrationScore: chinHydration,
                brightnessRadianceScore: chinBrightness, rednessScore: chinRedness
            )
        case "Under-Eyes":
            return RegionScores(
                textureEvennessScore: underEyeTexture, apparentHydrationScore: underEyeHydration,
                brightnessRadianceScore: underEyeBrightness, rednessScore: underEyeRedness,
                underEyeQualityScore: underEyeQuality
            )
        case "Nose":
            return RegionScores(
                textureEvennessScore: noseTexture, apparentHydrationScore: noseHydration,
                brightnessRadianceScore: noseBrightness, rednessScore: noseRedness,
                poreVisibilityScore: nosePores
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
        case "Left Cheek":
            leftCheekTexture = scores.textureEvennessScore
            leftCheekHydration = scores.apparentHydrationScore
            leftCheekBrightness = scores.brightnessRadianceScore
            leftCheekRedness = scores.rednessScore
            leftCheekPores = scores.poreVisibilityScore
            leftCheekTone = scores.toneUniformityScore
        case "Right Cheek":
            rightCheekTexture = scores.textureEvennessScore
            rightCheekHydration = scores.apparentHydrationScore
            rightCheekBrightness = scores.brightnessRadianceScore
            rightCheekRedness = scores.rednessScore
            rightCheekPores = scores.poreVisibilityScore
            rightCheekTone = scores.toneUniformityScore
        case "Chin":
            chinTexture = scores.textureEvennessScore
            chinHydration = scores.apparentHydrationScore
            chinBrightness = scores.brightnessRadianceScore
            chinRedness = scores.rednessScore
        case "Under-Eyes":
            underEyeTexture = scores.textureEvennessScore
            underEyeHydration = scores.apparentHydrationScore
            underEyeBrightness = scores.brightnessRadianceScore
            underEyeRedness = scores.rednessScore
            underEyeQuality = scores.underEyeQualityScore
        case "Nose":
            noseTexture = scores.textureEvennessScore
            noseHydration = scores.apparentHydrationScore
            noseBrightness = scores.brightnessRadianceScore
            noseRedness = scores.rednessScore
            nosePores = scores.poreVisibilityScore
        default:
            break
        }
    }
}
