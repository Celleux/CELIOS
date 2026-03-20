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
    var laplacianVariance: Double
    var saturationVariance: Double
    var photoPath: String?

    init(date: Date = Date(), overallScore: Int = 0, brightnessScore: Double = 0, rednessScore: Double = 0, textureScore: Double = 0, hydrationScore: Double = 0, itaAngle: Double = 0, aStarMean: Double = 0, laplacianVariance: Double = 0, saturationVariance: Double = 0, photoPath: String? = nil) {
        self.date = date
        self.overallScore = overallScore
        self.brightnessScore = brightnessScore
        self.rednessScore = rednessScore
        self.textureScore = textureScore
        self.hydrationScore = hydrationScore
        self.itaAngle = itaAngle
        self.aStarMean = aStarMean
        self.laplacianVariance = laplacianVariance
        self.saturationVariance = saturationVariance
        self.photoPath = photoPath
    }
}
