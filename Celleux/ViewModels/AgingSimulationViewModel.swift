import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

@Observable
final class AgingSimulationViewModel {
    var selectedYears: Int = 5
    var isProcessing: Bool = false
    var currentRateImage: UIImage?
    var withRoutineImage: UIImage?
    var currentRateScores: ProjectedScores?
    var withRoutineScores: ProjectedScores?

    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private var sourceImage: UIImage?
    private var baseMetrics: SkinScanResult?

    let yearOptions: [Int] = [5, 10, 20]

    func configure(result: SkinScanResult, capturedImage: UIImage?) {
        baseMetrics = result
        sourceImage = capturedImage
        generateSimulation()
    }

    func selectYears(_ years: Int) {
        guard years != selectedYears else { return }
        selectedYears = years
        generateSimulation()
    }

    func generateSimulation() {
        guard let result = baseMetrics else { return }
        isProcessing = true

        let currentScores = projectScores(result: result, years: selectedYears, withRoutine: false)
        let routineScores = projectScores(result: result, years: selectedYears, withRoutine: true)
        currentRateScores = currentScores
        withRoutineScores = routineScores

        if let source = sourceImage {
            Task {
                let currentImg = await applyAgingFilters(to: source, intensity: currentScores.agingIntensity)
                let routineImg = await applyAgingFilters(to: source, intensity: routineScores.agingIntensity)
                currentRateImage = currentImg
                withRoutineImage = routineImg
                isProcessing = false
            }
        } else {
            isProcessing = false
        }
    }

    private func projectScores(result: SkinScanResult, years: Int, withRoutine: Bool) -> ProjectedScores {
        let yearFactor = Double(years)
        let currentOverall = Double(result.overallScore)

        let wrinkleScore = Double(result.metrics.first { $0.name == "Wrinkle Depth" }?.score ?? 70)
        let elasticityScore = Double(result.metrics.first { $0.name == "Elasticity" }?.score ?? 70)
        let hydrationScore = Double(result.metrics.first { $0.name == "Apparent Hydration" }?.score ?? 70)
        let textureScore = Double(result.metrics.first { $0.name == "Texture Evenness" }?.score ?? 70)
        let radianceScore = Double(result.metrics.first { $0.name == "Brightness" }?.score ?? 70)

        if withRoutine {
            let improvementPerYear = 1.2
            let decayPerYear = 0.3
            let netPerYear = improvementPerYear - decayPerYear

            let projectedOverall = min(98, currentOverall + netPerYear * yearFactor * (1.0 - yearFactor * 0.01))
            let projectedWrinkle = min(98, wrinkleScore + netPerYear * yearFactor * 0.8)
            let projectedElasticity = min(98, elasticityScore + netPerYear * yearFactor * 0.7)
            let projectedHydration = min(98, hydrationScore + netPerYear * yearFactor * 1.0)
            let projectedTexture = min(98, textureScore + netPerYear * yearFactor * 0.9)
            let projectedRadiance = min(98, radianceScore + netPerYear * yearFactor * 0.6)

            let agingIntensity = max(0.05, 0.15 * (yearFactor / 20.0) * (1.0 - currentOverall / 200.0))

            return ProjectedScores(
                overall: Int(projectedOverall.rounded()),
                wrinkle: Int(projectedWrinkle.rounded()),
                elasticity: Int(projectedElasticity.rounded()),
                hydration: Int(projectedHydration.rounded()),
                texture: Int(projectedTexture.rounded()),
                radiance: Int(projectedRadiance.rounded()),
                agingIntensity: agingIntensity
            )
        } else {
            let baseDecay = (100.0 - currentOverall) / 100.0
            let decayPerYear = 1.8 + baseDecay * 2.0

            let projectedOverall = max(15, currentOverall - decayPerYear * yearFactor)
            let projectedWrinkle = max(10, wrinkleScore - decayPerYear * yearFactor * 1.3)
            let projectedElasticity = max(10, elasticityScore - decayPerYear * yearFactor * 1.2)
            let projectedHydration = max(15, hydrationScore - decayPerYear * yearFactor * 0.9)
            let projectedTexture = max(12, textureScore - decayPerYear * yearFactor * 1.1)
            let projectedRadiance = max(15, radianceScore - decayPerYear * yearFactor * 0.8)

            let agingIntensity = min(1.0, 0.3 * (yearFactor / 10.0) * (1.0 + baseDecay))

            return ProjectedScores(
                overall: Int(projectedOverall.rounded()),
                wrinkle: Int(projectedWrinkle.rounded()),
                elasticity: Int(projectedElasticity.rounded()),
                hydration: Int(projectedHydration.rounded()),
                texture: Int(projectedTexture.rounded()),
                radiance: Int(projectedRadiance.rounded()),
                agingIntensity: agingIntensity
            )
        }
    }

    private func applyAgingFilters(to image: UIImage, intensity: Double) async -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        var ciImage = CIImage(cgImage: cgImage)

        let gaussianBlur = CIFilter.gaussianBlur()
        gaussianBlur.inputImage = ciImage
        gaussianBlur.radius = Float(intensity * 3.0)
        if let output = gaussianBlur.outputImage {
            ciImage = output.cropped(to: CIImage(cgImage: cgImage).extent)
        }

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = ciImage
        colorControls.saturation = Float(max(0.5, 1.0 - intensity * 0.5))
        colorControls.contrast = Float(1.0 + intensity * 0.15)
        colorControls.brightness = Float(-intensity * 0.04)
        if let output = colorControls.outputImage {
            ciImage = output
        }

        let noiseReduction = CIFilter.noiseReduction()
        noiseReduction.inputImage = ciImage
        noiseReduction.noiseLevel = Float(intensity * 0.03)
        noiseReduction.sharpness = Float(0.4 + intensity * 0.4)
        if let output = noiseReduction.outputImage {
            ciImage = output
        }

        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = ciImage
        sharpen.sharpness = Float(intensity * 0.6)
        sharpen.radius = Float(1.0 + intensity * 2.0)
        if let output = sharpen.outputImage {
            ciImage = output
        }

        let warmth = CIFilter.temperatureAndTint()
        warmth.inputImage = ciImage
        warmth.neutral = CIVector(x: 6500 + CGFloat(intensity * 400), y: 0)
        if let output = warmth.outputImage {
            ciImage = output
        }

        let extent = ciImage.extent
        guard let cgResult = context.createCGImage(ciImage, from: extent) else { return image }
        return UIImage(cgImage: cgResult, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct ProjectedScores {
    let overall: Int
    let wrinkle: Int
    let elasticity: Int
    let hydration: Int
    let texture: Int
    let radiance: Int
    let agingIntensity: Double
}
