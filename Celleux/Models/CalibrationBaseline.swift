import SwiftData
import Foundation

@Model
final class CalibrationBaseline {
    var createdAt: Date
    var updatedAt: Date
    var scanCount: Int

    var foreheadMeanL: Double
    var foreheadMeanA: Double
    var foreheadMeanB: Double
    var foreheadTextureVariance: Double
    var foreheadSaturationVariance: Double

    var leftCheekMeanL: Double
    var leftCheekMeanA: Double
    var leftCheekMeanB: Double
    var leftCheekTextureVariance: Double
    var leftCheekSaturationVariance: Double

    var rightCheekMeanL: Double
    var rightCheekMeanA: Double
    var rightCheekMeanB: Double
    var rightCheekTextureVariance: Double
    var rightCheekSaturationVariance: Double

    var chinMeanL: Double
    var chinMeanA: Double
    var chinMeanB: Double
    var chinTextureVariance: Double
    var chinSaturationVariance: Double

    var underEyeMeanL: Double
    var underEyeMeanA: Double
    var underEyeMeanB: Double
    var underEyeTextureVariance: Double
    var underEyeSaturationVariance: Double

    var noseMeanL: Double
    var noseMeanA: Double
    var noseMeanB: Double
    var noseTextureVariance: Double
    var noseSaturationVariance: Double

    var baselineTextureEvenness: Double
    var baselineApparentHydration: Double
    var baselineBrightnessRadiance: Double
    var baselineRedness: Double
    var baselinePoreVisibility: Double
    var baselineToneUniformity: Double
    var baselineUnderEyeQuality: Double
    var baselineWrinkleDepth: Double
    var baselineElasticity: Double
    var baselineOverall: Double

    init(
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        scanCount: Int = 0,
        foreheadMeanL: Double = 0, foreheadMeanA: Double = 0, foreheadMeanB: Double = 0, foreheadTextureVariance: Double = 0, foreheadSaturationVariance: Double = 0,
        leftCheekMeanL: Double = 0, leftCheekMeanA: Double = 0, leftCheekMeanB: Double = 0, leftCheekTextureVariance: Double = 0, leftCheekSaturationVariance: Double = 0,
        rightCheekMeanL: Double = 0, rightCheekMeanA: Double = 0, rightCheekMeanB: Double = 0, rightCheekTextureVariance: Double = 0, rightCheekSaturationVariance: Double = 0,
        chinMeanL: Double = 0, chinMeanA: Double = 0, chinMeanB: Double = 0, chinTextureVariance: Double = 0, chinSaturationVariance: Double = 0,
        underEyeMeanL: Double = 0, underEyeMeanA: Double = 0, underEyeMeanB: Double = 0, underEyeTextureVariance: Double = 0, underEyeSaturationVariance: Double = 0,
        noseMeanL: Double = 0, noseMeanA: Double = 0, noseMeanB: Double = 0, noseTextureVariance: Double = 0, noseSaturationVariance: Double = 0,
        baselineTextureEvenness: Double = 0, baselineApparentHydration: Double = 0, baselineBrightnessRadiance: Double = 0, baselineRedness: Double = 0,
        baselinePoreVisibility: Double = 0, baselineToneUniformity: Double = 0, baselineUnderEyeQuality: Double = 0, baselineWrinkleDepth: Double = 0,
        baselineElasticity: Double = 0, baselineOverall: Double = 0
    ) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.scanCount = scanCount
        self.foreheadMeanL = foreheadMeanL
        self.foreheadMeanA = foreheadMeanA
        self.foreheadMeanB = foreheadMeanB
        self.foreheadTextureVariance = foreheadTextureVariance
        self.foreheadSaturationVariance = foreheadSaturationVariance
        self.leftCheekMeanL = leftCheekMeanL
        self.leftCheekMeanA = leftCheekMeanA
        self.leftCheekMeanB = leftCheekMeanB
        self.leftCheekTextureVariance = leftCheekTextureVariance
        self.leftCheekSaturationVariance = leftCheekSaturationVariance
        self.rightCheekMeanL = rightCheekMeanL
        self.rightCheekMeanA = rightCheekMeanA
        self.rightCheekMeanB = rightCheekMeanB
        self.rightCheekTextureVariance = rightCheekTextureVariance
        self.rightCheekSaturationVariance = rightCheekSaturationVariance
        self.chinMeanL = chinMeanL
        self.chinMeanA = chinMeanA
        self.chinMeanB = chinMeanB
        self.chinTextureVariance = chinTextureVariance
        self.chinSaturationVariance = chinSaturationVariance
        self.underEyeMeanL = underEyeMeanL
        self.underEyeMeanA = underEyeMeanA
        self.underEyeMeanB = underEyeMeanB
        self.underEyeTextureVariance = underEyeTextureVariance
        self.underEyeSaturationVariance = underEyeSaturationVariance
        self.noseMeanL = noseMeanL
        self.noseMeanA = noseMeanA
        self.noseMeanB = noseMeanB
        self.noseTextureVariance = noseTextureVariance
        self.noseSaturationVariance = noseSaturationVariance
        self.baselineTextureEvenness = baselineTextureEvenness
        self.baselineApparentHydration = baselineApparentHydration
        self.baselineBrightnessRadiance = baselineBrightnessRadiance
        self.baselineRedness = baselineRedness
        self.baselinePoreVisibility = baselinePoreVisibility
        self.baselineToneUniformity = baselineToneUniformity
        self.baselineUnderEyeQuality = baselineUnderEyeQuality
        self.baselineWrinkleDepth = baselineWrinkleDepth
        self.baselineElasticity = baselineElasticity
        self.baselineOverall = baselineOverall
    }

    func regionMeans(for region: String) -> (meanL: Double, meanA: Double, meanB: Double, textureVar: Double, satVar: Double) {
        switch region {
        case "Forehead": (foreheadMeanL, foreheadMeanA, foreheadMeanB, foreheadTextureVariance, foreheadSaturationVariance)
        case "Left Cheek": (leftCheekMeanL, leftCheekMeanA, leftCheekMeanB, leftCheekTextureVariance, leftCheekSaturationVariance)
        case "Right Cheek": (rightCheekMeanL, rightCheekMeanA, rightCheekMeanB, rightCheekTextureVariance, rightCheekSaturationVariance)
        case "Chin": (chinMeanL, chinMeanA, chinMeanB, chinTextureVariance, chinSaturationVariance)
        case "Under-Eyes": (underEyeMeanL, underEyeMeanA, underEyeMeanB, underEyeTextureVariance, underEyeSaturationVariance)
        case "Nose": (noseMeanL, noseMeanA, noseMeanB, noseTextureVariance, noseSaturationVariance)
        default: (0, 0, 0, 0, 0)
        }
    }

    func setRegionMeans(for region: String, meanL: Double, meanA: Double, meanB: Double, textureVar: Double, satVar: Double) {
        switch region {
        case "Forehead":
            foreheadMeanL = meanL; foreheadMeanA = meanA; foreheadMeanB = meanB
            foreheadTextureVariance = textureVar; foreheadSaturationVariance = satVar
        case "Left Cheek":
            leftCheekMeanL = meanL; leftCheekMeanA = meanA; leftCheekMeanB = meanB
            leftCheekTextureVariance = textureVar; leftCheekSaturationVariance = satVar
        case "Right Cheek":
            rightCheekMeanL = meanL; rightCheekMeanA = meanA; rightCheekMeanB = meanB
            rightCheekTextureVariance = textureVar; rightCheekSaturationVariance = satVar
        case "Chin":
            chinMeanL = meanL; chinMeanA = meanA; chinMeanB = meanB
            chinTextureVariance = textureVar; chinSaturationVariance = satVar
        case "Under-Eyes":
            underEyeMeanL = meanL; underEyeMeanA = meanA; underEyeMeanB = meanB
            underEyeTextureVariance = textureVar; underEyeSaturationVariance = satVar
        case "Nose":
            noseMeanL = meanL; noseMeanA = meanA; noseMeanB = meanB
            noseTextureVariance = textureVar; noseSaturationVariance = satVar
        default:
            break
        }
    }

    func baselineScore(for metric: SkinMetricType) -> Double {
        switch metric {
        case .textureEvenness: baselineTextureEvenness
        case .apparentHydration: baselineApparentHydration
        case .brightnessRadiance: baselineBrightnessRadiance
        case .rednessInflammation: baselineRedness
        case .poreVisibility: baselinePoreVisibility
        case .toneUniformity: baselineToneUniformity
        case .underEyeQuality: baselineUnderEyeQuality
        case .wrinkleDepth: baselineWrinkleDepth
        case .elasticityProxy: baselineElasticity
        case .overallSkinHealth: baselineOverall
        }
    }
}
