import SwiftData
import Foundation

@Model
final class SkinScanRecord {
    var date: Date
    var overallScore: Int
    var brightnessScore: Double
    var rednessScore: Double
    var textureScore: Double
    var hydrationScore: Double
    var itaAngle: Double
    var aStarMean: Double
    var bStarMean: Double
    var laplacianVariance: Double
    var saturationVariance: Double
    var photoPath: String?

    var foreheadBrightness: Double
    var foreheadRedness: Double
    var foreheadTexture: Double
    var foreheadHydration: Double

    var leftCheekBrightness: Double
    var leftCheekRedness: Double
    var leftCheekTexture: Double
    var leftCheekHydration: Double

    var rightCheekBrightness: Double
    var rightCheekRedness: Double
    var rightCheekTexture: Double
    var rightCheekHydration: Double

    var chinBrightness: Double
    var chinRedness: Double
    var chinTexture: Double
    var chinHydration: Double

    var underEyeBrightness: Double
    var underEyeRedness: Double
    var underEyeTexture: Double
    var underEyeHydration: Double

    var noseBrightness: Double
    var noseRedness: Double
    var noseTexture: Double
    var noseHydration: Double

    init(date: Date = Date(), overallScore: Int = 0, brightnessScore: Double = 0, rednessScore: Double = 0, textureScore: Double = 0, hydrationScore: Double = 0, itaAngle: Double = 0, aStarMean: Double = 0, bStarMean: Double = 0, laplacianVariance: Double = 0, saturationVariance: Double = 0, photoPath: String? = nil, foreheadBrightness: Double = 0, foreheadRedness: Double = 0, foreheadTexture: Double = 0, foreheadHydration: Double = 0, leftCheekBrightness: Double = 0, leftCheekRedness: Double = 0, leftCheekTexture: Double = 0, leftCheekHydration: Double = 0, rightCheekBrightness: Double = 0, rightCheekRedness: Double = 0, rightCheekTexture: Double = 0, rightCheekHydration: Double = 0, chinBrightness: Double = 0, chinRedness: Double = 0, chinTexture: Double = 0, chinHydration: Double = 0, underEyeBrightness: Double = 0, underEyeRedness: Double = 0, underEyeTexture: Double = 0, underEyeHydration: Double = 0, noseBrightness: Double = 0, noseRedness: Double = 0, noseTexture: Double = 0, noseHydration: Double = 0) {
        self.date = date
        self.overallScore = overallScore
        self.brightnessScore = brightnessScore
        self.rednessScore = rednessScore
        self.textureScore = textureScore
        self.hydrationScore = hydrationScore
        self.itaAngle = itaAngle
        self.aStarMean = aStarMean
        self.bStarMean = bStarMean
        self.laplacianVariance = laplacianVariance
        self.saturationVariance = saturationVariance
        self.photoPath = photoPath
        self.foreheadBrightness = foreheadBrightness
        self.foreheadRedness = foreheadRedness
        self.foreheadTexture = foreheadTexture
        self.foreheadHydration = foreheadHydration
        self.leftCheekBrightness = leftCheekBrightness
        self.leftCheekRedness = leftCheekRedness
        self.leftCheekTexture = leftCheekTexture
        self.leftCheekHydration = leftCheekHydration
        self.rightCheekBrightness = rightCheekBrightness
        self.rightCheekRedness = rightCheekRedness
        self.rightCheekTexture = rightCheekTexture
        self.rightCheekHydration = rightCheekHydration
        self.chinBrightness = chinBrightness
        self.chinRedness = chinRedness
        self.chinTexture = chinTexture
        self.chinHydration = chinHydration
        self.underEyeBrightness = underEyeBrightness
        self.underEyeRedness = underEyeRedness
        self.underEyeTexture = underEyeTexture
        self.underEyeHydration = underEyeHydration
        self.noseBrightness = noseBrightness
        self.noseRedness = noseRedness
        self.noseTexture = noseTexture
        self.noseHydration = noseHydration
    }

    func regionScores(for region: String) -> RegionScores {
        switch region {
        case "Forehead":
            return RegionScores(brightnessScore: foreheadBrightness, rednessScore: foreheadRedness, textureScore: foreheadTexture, hydrationScore: foreheadHydration)
        case "Left Cheek":
            return RegionScores(brightnessScore: leftCheekBrightness, rednessScore: leftCheekRedness, textureScore: leftCheekTexture, hydrationScore: leftCheekHydration)
        case "Right Cheek":
            return RegionScores(brightnessScore: rightCheekBrightness, rednessScore: rightCheekRedness, textureScore: rightCheekTexture, hydrationScore: rightCheekHydration)
        case "Chin":
            return RegionScores(brightnessScore: chinBrightness, rednessScore: chinRedness, textureScore: chinTexture, hydrationScore: chinHydration)
        case "Under-Eyes":
            return RegionScores(brightnessScore: underEyeBrightness, rednessScore: underEyeRedness, textureScore: underEyeTexture, hydrationScore: underEyeHydration)
        case "Nose":
            return RegionScores(brightnessScore: noseBrightness, rednessScore: noseRedness, textureScore: noseTexture, hydrationScore: noseHydration)
        default:
            return RegionScores()
        }
    }
}
