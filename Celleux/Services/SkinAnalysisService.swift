import UIKit
import CoreImage
import Vision
import Accelerate

nonisolated class SkinAnalysisService: Sendable {

    func analyze(pixelBuffer: CVPixelBuffer, blendShapeElasticity: Double? = nil, lightingConditions: LightingConditions? = nil) async -> SkinAnalysisData? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        let namedRegions = await detectNamedFaceRegions(in: cgImage)

        guard !namedRegions.isEmpty else {
            return analyzeFullImage(cgImage: cgImage, context: context, blendShapeElasticity: blendShapeElasticity, lightingConditions: lightingConditions)
        }

        let adaptationMatrix = lightingConditions.flatMap { computeBradfordAdaptationMatrix(colorTemperature: $0.colorTemperature) }
        let correctionApplied = adaptationMatrix != nil

        var regionData: [String: RegionScores] = [:]
        var allITA: [Double] = []
        var allRedness: [Double] = []
        var allTexture: [Double] = []
        var allSaturationVar: [Double] = []
        var allBStar: [Double] = []
        var allMeanL: [Double] = []
        var allHFEnergy: [Double] = []
        var allGaborEnergy: [Double] = []
        var regionMeanLMap: [String: Double] = [:]

        for (name, rect) in namedRegions {
            guard let cropped = cgImage.cropping(to: rect),
                  let metrics = computeRegionMetrics(cgImage: cropped, context: context, adaptationMatrix: adaptationMatrix) else { continue }

            let tScore = mapTextureToScore(metrics.texture)
            let hScore = mapHydrationToScore(metrics.saturationVariance)
            let bScore = mapITAToScore(metrics.ita)
            let rScore = mapRednessToScore(metrics.redness)
            let pScore = mapPoreVisibilityToScore(metrics.highFreqLaplacianEnergy)
            let wScore = mapWrinkleDepthToScore(metrics.gaborEnergy)

            regionData[name] = RegionScores(
                textureEvennessScore: tScore,
                apparentHydrationScore: hScore,
                brightnessRadianceScore: bScore,
                rednessScore: rScore,
                poreVisibilityScore: pScore,
                wrinkleDepthScore: wScore,
                itaAngle: metrics.ita,
                aStarMean: metrics.redness,
                bStarMean: metrics.bStar,
                laplacianVariance: metrics.texture,
                saturationVariance: metrics.saturationVariance,
                hfEnergy: metrics.highFreqLaplacianEnergy,
                gaborFilterEnergy: metrics.gaborEnergy,
                meanL: metrics.meanL
            )

            allITA.append(metrics.ita)
            allRedness.append(metrics.redness)
            allTexture.append(metrics.texture)
            allSaturationVar.append(metrics.saturationVariance)
            allBStar.append(metrics.bStar)
            allMeanL.append(metrics.meanL)
            allHFEnergy.append(metrics.highFreqLaplacianEnergy)
            allGaborEnergy.append(metrics.gaborEnergy)
            regionMeanLMap[name] = metrics.meanL
        }

        guard !allITA.isEmpty else {
            return nil
        }

        let count = Double(allITA.count)
        let avgITA = allITA.reduce(0, +) / count
        let avgRedness = allRedness.reduce(0, +) / count
        let avgTexture = allTexture.reduce(0, +) / count
        let avgSatVar = allSaturationVar.reduce(0, +) / count
        let avgBStar = allBStar.reduce(0, +) / count
        let avgHFEnergy = allHFEnergy.reduce(0, +) / count
        let avgGaborEnergy = allGaborEnergy.reduce(0, +) / count

        let lStarMean = allMeanL.reduce(0, +) / count
        let lStarStdDev = sqrt(allMeanL.reduce(0) { $0 + ($1 - lStarMean) * ($1 - lStarMean) } / count)
        let toneUniformityScore = mapToneUniformityToScore(lStarStdDev)

        let underEyeLStar = regionMeanLMap["Under-Eyes"]
        let leftCheekL = regionMeanLMap["Left Cheek"]
        let rightCheekL = regionMeanLMap["Right Cheek"]
        var underEyeQualityScore: Double = 0
        var computedUnderEyeDeltaL: Double = 0
        if let eyeL = underEyeLStar {
            let cheekL: Double
            if let lL = leftCheekL, let rL = rightCheekL {
                cheekL = (lL + rL) / 2.0
            } else if let lL = leftCheekL {
                cheekL = lL
            } else if let rL = rightCheekL {
                cheekL = rL
            } else {
                cheekL = eyeL
            }
            computedUnderEyeDeltaL = abs(eyeL - cheekL)
            underEyeQualityScore = mapUnderEyeQualityToScore(computedUnderEyeDeltaL)
        }

        for (name, var scores) in regionData {
            scores.toneUniformityScore = toneUniformityScore
            if name == "Under-Eyes" {
                scores.underEyeQualityScore = underEyeQualityScore
            }
            regionData[name] = scores
        }

        let textureEvennessScore = mapTextureToScore(avgTexture)
        let apparentHydrationScore = mapHydrationToScore(avgSatVar)
        let brightnessRadianceScore = mapITAToScore(avgITA)
        let rednessScore = mapRednessToScore(avgRedness)
        let poreVisibilityScore = mapPoreVisibilityToScore(avgHFEnergy)
        let wrinkleDepthScore = mapWrinkleDepthToScore(avgGaborEnergy)
        let elasticityProxyScore = blendShapeElasticity ?? 0

        var data = SkinAnalysisData(
            textureEvennessScore: textureEvennessScore,
            apparentHydrationScore: apparentHydrationScore,
            brightnessRadianceScore: brightnessRadianceScore,
            rednessScore: rednessScore,
            poreVisibilityScore: poreVisibilityScore,
            toneUniformityScore: toneUniformityScore,
            underEyeQualityScore: underEyeQualityScore,
            wrinkleDepthScore: wrinkleDepthScore,
            elasticityProxyScore: elasticityProxyScore,
            itaAngle: avgITA,
            aStarMean: avgRedness,
            bStarMean: avgBStar,
            laplacianVariance: avgTexture,
            saturationVariance: avgSatVar,
            poreHFEnergy: avgHFEnergy,
            gaborEnergy: avgGaborEnergy,
            toneStdDev: lStarStdDev,
            underEyeDeltaL: computedUnderEyeDeltaL,
            elasticityRecoverySpeed: blendShapeElasticity ?? 0,
            regionData: regionData
        )

        data.overallScore = SkinAnalysisData.computeOverall(from: data)

        if let lc = lightingConditions {
            data.lightingConditions = LightingConditions(
                ambientIntensity: lc.ambientIntensity,
                colorTemperature: lc.colorTemperature,
                correctionApplied: correctionApplied
            )
        }

        return data
    }

    private func analyzeFullImage(cgImage: CGImage, context: CIContext, blendShapeElasticity: Double? = nil, lightingConditions: LightingConditions? = nil) -> SkinAnalysisData? {
        let w = cgImage.width
        let h = cgImage.height
        let centerRect = CGRect(
            x: CGFloat(w) * 0.25,
            y: CGFloat(h) * 0.25,
            width: CGFloat(w) * 0.5,
            height: CGFloat(h) * 0.5
        )
        let adaptationMatrix = lightingConditions.flatMap { computeBradfordAdaptationMatrix(colorTemperature: $0.colorTemperature) }
        guard let cropped = cgImage.cropping(to: centerRect),
              let metrics = computeRegionMetrics(cgImage: cropped, context: context, adaptationMatrix: adaptationMatrix) else {
            return nil
        }

        let textureEvennessScore = mapTextureToScore(metrics.texture)
        let apparentHydrationScore = mapHydrationToScore(metrics.saturationVariance)
        let brightnessRadianceScore = mapITAToScore(metrics.ita)
        let rednessScore = mapRednessToScore(metrics.redness)
        let poreVisibilityScore = mapPoreVisibilityToScore(metrics.highFreqLaplacianEnergy)
        let toneUniformityScore = mapToneUniformityToScore(0)
        let wrinkleDepthScore = mapWrinkleDepthToScore(metrics.gaborEnergy)

        let scores = RegionScores(
            textureEvennessScore: textureEvennessScore,
            apparentHydrationScore: apparentHydrationScore,
            brightnessRadianceScore: brightnessRadianceScore,
            rednessScore: rednessScore,
            poreVisibilityScore: poreVisibilityScore,
            wrinkleDepthScore: wrinkleDepthScore,
            itaAngle: metrics.ita,
            aStarMean: metrics.redness,
            bStarMean: metrics.bStar,
            laplacianVariance: metrics.texture,
            saturationVariance: metrics.saturationVariance,
            hfEnergy: metrics.highFreqLaplacianEnergy,
            gaborFilterEnergy: metrics.gaborEnergy,
            meanL: metrics.meanL
        )

        let regionData: [String: RegionScores] = [
            "Forehead": scores,
            "Left Cheek": scores,
            "Right Cheek": scores,
            "Chin": scores,
            "Under-Eyes": scores,
            "Nose": scores
        ]

        var data = SkinAnalysisData(
            textureEvennessScore: textureEvennessScore,
            apparentHydrationScore: apparentHydrationScore,
            brightnessRadianceScore: brightnessRadianceScore,
            rednessScore: rednessScore,
            poreVisibilityScore: poreVisibilityScore,
            toneUniformityScore: toneUniformityScore,
            wrinkleDepthScore: wrinkleDepthScore,
            elasticityProxyScore: blendShapeElasticity ?? 0,
            itaAngle: metrics.ita,
            aStarMean: metrics.redness,
            bStarMean: metrics.bStar,
            laplacianVariance: metrics.texture,
            saturationVariance: metrics.saturationVariance,
            poreHFEnergy: metrics.highFreqLaplacianEnergy,
            gaborEnergy: metrics.gaborEnergy,
            toneStdDev: 0,
            underEyeDeltaL: 0,
            elasticityRecoverySpeed: blendShapeElasticity ?? 0,
            regionData: regionData
        )

        data.overallScore = SkinAnalysisData.computeOverall(from: data)

        if let lc = lightingConditions {
            let correctionApplied = adaptationMatrix != nil
            data.lightingConditions = LightingConditions(
                ambientIntensity: lc.ambientIntensity,
                colorTemperature: lc.colorTemperature,
                correctionApplied: correctionApplied
            )
        }

        return data
    }

    private func detectNamedFaceRegions(in cgImage: CGImage) async -> [(String, CGRect)] {
        await withCheckedContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, _ in
                guard let observations = request.results as? [VNFaceObservation],
                      let face = observations.first else {
                    continuation.resume(returning: [])
                    return
                }

                let w = CGFloat(cgImage.width)
                let h = CGFloat(cgImage.height)
                let faceBox = face.boundingBox

                let faceRect = CGRect(
                    x: faceBox.origin.x * w,
                    y: faceBox.origin.y * h,
                    width: faceBox.width * w,
                    height: faceBox.height * h
                )

                var regions: [(String, CGRect)] = []
                let imageBounds = CGRect(x: 0, y: 0, width: w, height: h)

                let foreheadRect = CGRect(
                    x: faceRect.midX - faceRect.width * 0.2,
                    y: faceRect.maxY - faceRect.height * 0.15,
                    width: faceRect.width * 0.4,
                    height: faceRect.height * 0.12
                ).intersection(imageBounds)

                let leftCheek = CGRect(
                    x: faceRect.minX + faceRect.width * 0.05,
                    y: faceRect.midY - faceRect.height * 0.1,
                    width: faceRect.width * 0.2,
                    height: faceRect.height * 0.2
                ).intersection(imageBounds)

                let rightCheek = CGRect(
                    x: faceRect.maxX - faceRect.width * 0.25,
                    y: faceRect.midY - faceRect.height * 0.1,
                    width: faceRect.width * 0.2,
                    height: faceRect.height * 0.2
                ).intersection(imageBounds)

                let chin = CGRect(
                    x: faceRect.midX - faceRect.width * 0.15,
                    y: faceRect.minY,
                    width: faceRect.width * 0.3,
                    height: faceRect.height * 0.12
                ).intersection(imageBounds)

                let underEye = CGRect(
                    x: faceRect.midX - faceRect.width * 0.25,
                    y: faceRect.midY + faceRect.height * 0.05,
                    width: faceRect.width * 0.5,
                    height: faceRect.height * 0.08
                ).intersection(imageBounds)

                let nose = CGRect(
                    x: faceRect.midX - faceRect.width * 0.1,
                    y: faceRect.midY - faceRect.height * 0.15,
                    width: faceRect.width * 0.2,
                    height: faceRect.height * 0.2
                ).intersection(imageBounds)

                let namedRects: [(String, CGRect)] = [
                    ("Forehead", foreheadRect),
                    ("Left Cheek", leftCheek),
                    ("Right Cheek", rightCheek),
                    ("Chin", chin),
                    ("Under-Eyes", underEye),
                    ("Nose", nose)
                ]

                for (name, r) in namedRects {
                    if r.width > 5 && r.height > 5 {
                        regions.append((name, r))
                    }
                }

                continuation.resume(returning: regions)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    private nonisolated struct InternalRegionMetrics: Sendable {
        let ita: Double
        let redness: Double
        let bStar: Double
        let texture: Double
        let saturationVariance: Double
        let meanL: Double
        let highFreqLaplacianEnergy: Double
        let gaborEnergy: Double
    }

    private func computeRegionMetrics(cgImage: CGImage, context: CIContext, adaptationMatrix: [[Double]]? = nil) -> InternalRegionMetrics? {
        let width = cgImage.width
        let height = cgImage.height
        let totalPixels = width * height

        guard totalPixels > 0,
              let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else {
            return nil
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        var lStarSum: Double = 0
        var aStarSum: Double = 0
        var bStarSum: Double = 0
        var satValues: [Double] = []
        var sampleCount = 0

        let step = max(1, totalPixels / 2000)

        for i in stride(from: 0, to: totalPixels, by: step) {
            let row = i / width
            let col = i % width
            let offset = row * bytesPerRow + col * bytesPerPixel

            guard offset + 2 < CFDataGetLength(data) else { continue }

            var r = Double(ptr[offset]) / 255.0
            var g = Double(ptr[offset + 1]) / 255.0
            var b = Double(ptr[offset + 2]) / 255.0

            if let matrix = adaptationMatrix {
                (r, g, b) = applyBradfordCorrection(r: r, g: g, b: b, matrix: matrix)
            }

            let lab = rgbToLab(r: r, g: g, b: b)
            lStarSum += lab.l
            aStarSum += lab.a
            bStarSum += lab.b_

            let maxC = max(r, max(g, b))
            let minC = min(r, min(g, b))
            let sat = maxC > 0 ? (maxC - minC) / maxC : 0
            satValues.append(sat)

            sampleCount += 1
        }

        guard sampleCount > 0 else {
            return nil
        }

        let meanL = lStarSum / Double(sampleCount)
        let meanA = aStarSum / Double(sampleCount)
        let meanB = bStarSum / Double(sampleCount)
        let ita = atan2(meanL - 50, meanB) * (180.0 / .pi)

        let meanSat = satValues.reduce(0, +) / Double(satValues.count)
        let satVar = satValues.reduce(0) { $0 + ($1 - meanSat) * ($1 - meanSat) } / Double(satValues.count)

        let dataLength = CFDataGetLength(data)
        let textureVar = computeTextureVariance(ptr: ptr, width: width, height: height, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, dataLength: dataLength)
        let hfEnergy = computeHighFreqLaplacianEnergy(ptr: ptr, width: width, height: height, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, dataLength: dataLength)
        let gabor = computeGaborFilterEnergy(ptr: ptr, width: width, height: height, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, dataLength: dataLength)

        return InternalRegionMetrics(
            ita: ita,
            redness: meanA,
            bStar: meanB,
            texture: textureVar,
            saturationVariance: satVar,
            meanL: meanL,
            highFreqLaplacianEnergy: hfEnergy,
            gaborEnergy: gabor
        )
    }

    private func computeTextureVariance(ptr: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int, bytesPerPixel: Int, dataLength: Int) -> Double {
        var laplacianValues: [Double] = []
        let step = max(1, min(width, height) / 50)

        for y in stride(from: 1, to: height - 1, by: step) {
            for x in stride(from: 1, to: width - 1, by: step) {
                let center = grayAt(ptr, x: x, y: y, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let top = grayAt(ptr, x: x, y: y - 1, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let bottom = grayAt(ptr, x: x, y: y + 1, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let left = grayAt(ptr, x: x - 1, y: y, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let right = grayAt(ptr, x: x + 1, y: y, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)

                guard center >= 0 && top >= 0 && bottom >= 0 && left >= 0 && right >= 0 else { continue }

                let lap = top + bottom + left + right - 4.0 * center
                laplacianValues.append(lap)
            }
        }

        guard !laplacianValues.isEmpty else { return 300 }

        let mean = laplacianValues.reduce(0, +) / Double(laplacianValues.count)
        let variance = laplacianValues.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(laplacianValues.count)
        return variance
    }

    private func grayAt(_ ptr: UnsafePointer<UInt8>, x: Int, y: Int, bytesPerRow: Int, bpp: Int, dataLength: Int) -> Double {
        let offset = y * bytesPerRow + x * bpp
        guard offset + 2 < dataLength else { return -1 }
        let r = Double(ptr[offset])
        let g = Double(ptr[offset + 1])
        let b = Double(ptr[offset + 2])
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    private func rgbToLab(r: Double, g: Double, b: Double) -> (l: Double, a: Double, b_: Double) {
        func linearize(_ c: Double) -> Double {
            c > 0.04045 ? pow((c + 0.055) / 1.055, 2.4) : c / 12.92
        }

        let rl = linearize(r)
        let gl = linearize(g)
        let bl = linearize(b)

        var x = (rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375) / 0.95047
        var y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750
        var z = (rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041) / 1.08883

        func f(_ t: Double) -> Double {
            t > 0.008856 ? pow(t, 1.0/3.0) : (7.787 * t + 16.0 / 116.0)
        }

        x = f(x); y = f(y); z = f(z)

        let l = 116.0 * y - 16.0
        let a = 500.0 * (x - y)
        let bVal = 200.0 * (y - z)

        return (l, a, bVal)
    }

    private func mapITAToScore(_ ita: Double) -> Double {
        if ita > 55 { return min(98, 85 + (ita - 55) * 0.4) }
        if ita > 28 { return 60 + (ita - 28) * (25.0 / 27.0) }
        if ita > 10 { return 40 + (ita - 10) * (20.0 / 18.0) }
        return max(25, 25 + ita * (15.0 / 10.0))
    }

    private func mapRednessToScore(_ aStar: Double) -> Double {
        if aStar < 8 { return min(98, 90 + (8 - aStar)) }
        if aStar < 12 { return 80 + (12 - aStar) * 2.5 }
        if aStar < 18 { return 60 + (18 - aStar) * (20.0 / 6.0) }
        return max(25, 60 - (aStar - 18) * 3.0)
    }

    private func mapTextureToScore(_ variance: Double) -> Double {
        if variance < 100 { return min(98, 90 + (100 - variance) * 0.08) }
        if variance < 300 { return 70 + (300 - variance) * (20.0 / 200.0) }
        if variance < 600 { return 50 + (600 - variance) * (20.0 / 300.0) }
        return max(25, 50 - (variance - 600) * 0.05)
    }

    private func mapHydrationToScore(_ satVariance: Double) -> Double {
        if satVariance < 0.005 { return min(98, 90 + (0.005 - satVariance) * 1000) }
        if satVariance < 0.015 { return 70 + (0.015 - satVariance) * (20.0 / 0.01) }
        if satVariance < 0.04 { return 50 + (0.04 - satVariance) * (20.0 / 0.025) }
        return max(25, 50 - (satVariance - 0.04) * 500)
    }

    private func mapPoreVisibilityToScore(_ hfEnergy: Double) -> Double {
        if hfEnergy < 50 { return min(98, 92 + (50 - hfEnergy) * 0.12) }
        if hfEnergy < 150 { return 75 + (150 - hfEnergy) * (17.0 / 100.0) }
        if hfEnergy < 400 { return 50 + (400 - hfEnergy) * (25.0 / 250.0) }
        return max(25, 50 - (hfEnergy - 400) * 0.05)
    }

    private func mapToneUniformityToScore(_ lStarStdDev: Double) -> Double {
        if lStarStdDev < 2 { return min(98, 92 + (2 - lStarStdDev) * 3) }
        if lStarStdDev < 5 { return 75 + (5 - lStarStdDev) * (17.0 / 3.0) }
        if lStarStdDev < 10 { return 55 + (10 - lStarStdDev) * (20.0 / 5.0) }
        return max(25, 55 - (lStarStdDev - 10) * 2)
    }

    private func mapUnderEyeQualityToScore(_ deltaL: Double) -> Double {
        if deltaL < 2 { return min(98, 92 + (2 - deltaL) * 3) }
        if deltaL < 5 { return 78 + (5 - deltaL) * (14.0 / 3.0) }
        if deltaL < 10 { return 55 + (10 - deltaL) * (23.0 / 5.0) }
        return max(25, 55 - (deltaL - 10) * 2.5)
    }

    private func mapWrinkleDepthToScore(_ gaborEnergy: Double) -> Double {
        if gaborEnergy < 30 { return min(98, 90 + (30 - gaborEnergy) * 0.27) }
        if gaborEnergy < 100 { return 72 + (100 - gaborEnergy) * (18.0 / 70.0) }
        if gaborEnergy < 300 { return 50 + (300 - gaborEnergy) * (22.0 / 200.0) }
        return max(25, 50 - (gaborEnergy - 300) * 0.06)
    }

    private func computeGaborFilterEnergy(ptr: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int, bytesPerPixel: Int, dataLength: Int) -> Double {
        var totalEnergy: Double = 0
        var sampleCount = 0

        let orientations: [(kx: Double, ky: Double)] = [
            (1.0, 0.0),
            (0.0, 1.0),
            (0.707, 0.707),
            (-0.707, 0.707)
        ]

        let frequency = 0.15
        let sigma = 3.0
        let kernelRadius = 4
        let step = max(1, min(width, height) / 40)

        for y in stride(from: kernelRadius, to: height - kernelRadius, by: step) {
            for x in stride(from: kernelRadius, to: width - kernelRadius, by: step) {
                var maxResponse: Double = 0

                for orient in orientations {
                    var response: Double = 0

                    for ky in -kernelRadius...kernelRadius {
                        for kx in -kernelRadius...kernelRadius {
                            let gray = grayAt(ptr, x: x + kx, y: y + ky, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                            guard gray >= 0 else { continue }

                            let xPrime = Double(kx) * orient.kx + Double(ky) * orient.ky
                            let dist2 = Double(kx * kx + ky * ky)
                            let gaussian = exp(-dist2 / (2.0 * sigma * sigma))
                            let sinusoidal = cos(2.0 * .pi * frequency * xPrime)
                            let kernel = gaussian * sinusoidal

                            response += gray * kernel
                        }
                    }

                    maxResponse = max(maxResponse, response * response)
                }

                totalEnergy += maxResponse
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return 100 }
        return totalEnergy / Double(sampleCount)
    }

    private nonisolated func colorTemperatureToXYZ(kelvin: Double) -> (x: Double, y: Double, z: Double) {
        let t = kelvin
        let x: Double
        if t >= 1667 && t <= 4000 {
            x = -0.2661239e9 / (t * t * t) - 0.2343589e6 / (t * t) + 0.8776956e3 / t + 0.179910
        } else {
            x = -3.0258469e9 / (t * t * t) + 2.1070379e6 / (t * t) + 0.2226347e3 / t + 0.240390
        }

        let y: Double
        if t >= 1667 && t <= 2222 {
            y = -1.1063814 * x * x * x - 1.34811020 * x * x + 2.18555832 * x - 0.20219683
        } else if t <= 4000 {
            y = -0.9549476 * x * x * x - 1.37418593 * x * x + 2.09137015 * x - 0.16748867
        } else {
            y = 3.0817580 * x * x * x - 5.87338670 * x * x + 3.75112997 * x - 0.37001483
        }

        guard y > 0 else { return (0.9505, 1.0, 1.0890) }
        let bigY = 1.0
        let bigX = (bigY / y) * x
        let bigZ = (bigY / y) * (1.0 - x - y)
        return (bigX, bigY, bigZ)
    }

    private nonisolated func computeBradfordAdaptationMatrix(colorTemperature: Double) -> [[Double]]? {
        guard abs(colorTemperature - 6500) > 1000 else { return nil }

        let source = colorTemperatureToXYZ(kelvin: colorTemperature)
        let dest = colorTemperatureToXYZ(kelvin: 6500)

        let bradfordM: [[Double]] = [
            [0.8951,  0.2664, -0.1614],
            [-0.7502, 1.7135,  0.0367],
            [0.0389, -0.0685,  1.0296]
        ]

        let bradfordMInv: [[Double]] = [
            [0.9869929, -0.1470543,  0.1599627],
            [0.4323053,  0.5183603,  0.0492912],
            [-0.0085287, 0.0400428,  0.9684867]
        ]

        let srcLMS = multiplyMatVec(bradfordM, vec: [source.x, source.y, source.z])
        let dstLMS = multiplyMatVec(bradfordM, vec: [dest.x, dest.y, dest.z])

        guard srcLMS[0] != 0, srcLMS[1] != 0, srcLMS[2] != 0 else { return nil }

        let scale: [[Double]] = [
            [dstLMS[0] / srcLMS[0], 0, 0],
            [0, dstLMS[1] / srcLMS[1], 0],
            [0, 0, dstLMS[2] / srcLMS[2]]
        ]

        let temp = multiplyMat(scale, b: bradfordM)
        let result = multiplyMat(bradfordMInv, b: temp)
        return result
    }

    private nonisolated func multiplyMatVec(_ mat: [[Double]], vec: [Double]) -> [Double] {
        var result = [Double](repeating: 0, count: 3)
        for i in 0..<3 {
            for j in 0..<3 {
                result[i] += mat[i][j] * vec[j]
            }
        }
        return result
    }

    private nonisolated func multiplyMat(_ a: [[Double]], b: [[Double]]) -> [[Double]] {
        var result = [[Double]](repeating: [Double](repeating: 0, count: 3), count: 3)
        for i in 0..<3 {
            for j in 0..<3 {
                for k in 0..<3 {
                    result[i][j] += a[i][k] * b[k][j]
                }
            }
        }
        return result
    }

    private nonisolated func applyBradfordCorrection(r: Double, g: Double, b: Double, matrix: [[Double]]) -> (Double, Double, Double) {
        func linearize(_ c: Double) -> Double {
            c > 0.04045 ? pow((c + 0.055) / 1.055, 2.4) : c / 12.92
        }
        func delinearize(_ c: Double) -> Double {
            c > 0.0031308 ? 1.055 * pow(c, 1.0 / 2.4) - 0.055 : 12.92 * c
        }

        let rl = linearize(r)
        let gl = linearize(g)
        let bl = linearize(b)

        let toXYZ: [[Double]] = [
            [0.4124564, 0.3575761, 0.1804375],
            [0.2126729, 0.7151522, 0.0721750],
            [0.0193339, 0.1191920, 0.9503041]
        ]
        let fromXYZ: [[Double]] = [
            [3.2404542, -1.5371385, -0.4985314],
            [-0.9692660, 1.8760108,  0.0415560],
            [0.0556434, -0.2040259,  1.0572252]
        ]

        let xyz = multiplyMatVec(toXYZ, vec: [rl, gl, bl])
        let adaptedXYZ = multiplyMatVec(matrix, vec: xyz)
        let rgb = multiplyMatVec(fromXYZ, vec: adaptedXYZ)

        let cr = max(0, min(1, delinearize(max(0, rgb[0]))))
        let cg = max(0, min(1, delinearize(max(0, rgb[1]))))
        let cb = max(0, min(1, delinearize(max(0, rgb[2]))))

        return (cr, cg, cb)
    }

    private func computeHighFreqLaplacianEnergy(ptr: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int, bytesPerPixel: Int, dataLength: Int) -> Double {
        var highFreqValues: [Double] = []
        let step = max(1, min(width, height) / 80)

        for y in stride(from: 2, to: height - 2, by: step) {
            for x in stride(from: 2, to: width - 2, by: step) {
                let center = grayAt(ptr, x: x, y: y, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let top = grayAt(ptr, x: x, y: y - 1, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let bottom = grayAt(ptr, x: x, y: y + 1, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let left = grayAt(ptr, x: x - 1, y: y, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let right = grayAt(ptr, x: x + 1, y: y, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let topLeft = grayAt(ptr, x: x - 1, y: y - 1, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let topRight = grayAt(ptr, x: x + 1, y: y - 1, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let bottomLeft = grayAt(ptr, x: x - 1, y: y + 1, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)
                let bottomRight = grayAt(ptr, x: x + 1, y: y + 1, bytesPerRow: bytesPerRow, bpp: bytesPerPixel, dataLength: dataLength)

                guard center >= 0 && top >= 0 && bottom >= 0 && left >= 0 && right >= 0 &&
                      topLeft >= 0 && topRight >= 0 && bottomLeft >= 0 && bottomRight >= 0 else { continue }

                let laplacian = -1 * topLeft + -1 * top + -1 * topRight +
                                -1 * left + 8 * center + -1 * right +
                                -1 * bottomLeft + -1 * bottom + -1 * bottomRight

                highFreqValues.append(laplacian * laplacian)
            }
        }

        guard !highFreqValues.isEmpty else { return 200 }
        return highFreqValues.reduce(0, +) / Double(highFreqValues.count)
    }
}
