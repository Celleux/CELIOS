import UIKit
import CoreImage
import Vision

nonisolated class SkinAnalysisService: Sendable {

    func analyze(pixelBuffer: CVPixelBuffer) async -> SkinAnalysisData? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        let namedRegions = await detectNamedFaceRegions(in: cgImage)

        guard !namedRegions.isEmpty else {
            return analyzeFullImage(cgImage: cgImage, context: context)
        }

        var regionData: [String: RegionScores] = [:]
        var allBrightness: [Double] = []
        var allRedness: [Double] = []
        var allTexture: [Double] = []
        var allSaturationVar: [Double] = []
        var allBStar: [Double] = []

        for (name, rect) in namedRegions {
            guard let cropped = cgImage.cropping(to: rect),
                  let metrics = computeRegionMetrics(cgImage: cropped, context: context) else { continue }

            let bScore = mapITAToScore(metrics.brightness)
            let rScore = mapRednessToScore(metrics.redness)
            let tScore = mapTextureToScore(metrics.texture)
            let hScore = mapHydrationToScore(metrics.saturationVariance)

            regionData[name] = RegionScores(
                brightnessScore: bScore,
                rednessScore: rScore,
                textureScore: tScore,
                hydrationScore: hScore,
                itaAngle: metrics.brightness,
                aStarMean: metrics.redness,
                bStarMean: metrics.bStar,
                laplacianVariance: metrics.texture,
                saturationVariance: metrics.saturationVariance
            )

            allBrightness.append(metrics.brightness)
            allRedness.append(metrics.redness)
            allTexture.append(metrics.texture)
            allSaturationVar.append(metrics.saturationVariance)
            allBStar.append(metrics.bStar)
        }

        guard !allBrightness.isEmpty else {
            return nil
        }

        let avgBrightness = allBrightness.reduce(0, +) / Double(allBrightness.count)
        let avgRedness = allRedness.reduce(0, +) / Double(allRedness.count)
        let avgTexture = allTexture.reduce(0, +) / Double(allTexture.count)
        let avgSatVar = allSaturationVar.reduce(0, +) / Double(allSaturationVar.count)
        let avgBStar = allBStar.reduce(0, +) / Double(allBStar.count)

        let brightnessScore = mapITAToScore(avgBrightness)
        let rednessScore = mapRednessToScore(avgRedness)
        let textureScore = mapTextureToScore(avgTexture)
        let hydrationScore = mapHydrationToScore(avgSatVar)

        let overall = brightnessScore * 0.25 + rednessScore * 0.20 + textureScore * 0.30 + hydrationScore * 0.25

        return SkinAnalysisData(
            brightnessScore: brightnessScore,
            rednessScore: rednessScore,
            textureScore: textureScore,
            hydrationScore: hydrationScore,
            overallScore: overall,
            itaAngle: avgBrightness,
            aStarMean: avgRedness,
            bStarMean: avgBStar,
            laplacianVariance: avgTexture,
            saturationVariance: avgSatVar,
            regionData: regionData
        )
    }

    private func analyzeFullImage(cgImage: CGImage, context: CIContext) -> SkinAnalysisData? {
        let w = cgImage.width
        let h = cgImage.height
        let centerRect = CGRect(
            x: CGFloat(w) * 0.25,
            y: CGFloat(h) * 0.25,
            width: CGFloat(w) * 0.5,
            height: CGFloat(h) * 0.5
        )
        guard let cropped = cgImage.cropping(to: centerRect),
              let metrics = computeRegionMetrics(cgImage: cropped, context: context) else {
            return nil
        }

        let brightnessScore = mapITAToScore(metrics.brightness)
        let rednessScore = mapRednessToScore(metrics.redness)
        let textureScore = mapTextureToScore(metrics.texture)
        let hydrationScore = mapHydrationToScore(metrics.saturationVariance)
        let overall = brightnessScore * 0.25 + rednessScore * 0.20 + textureScore * 0.30 + hydrationScore * 0.25

        let scores = RegionScores(
            brightnessScore: brightnessScore,
            rednessScore: rednessScore,
            textureScore: textureScore,
            hydrationScore: hydrationScore,
            itaAngle: metrics.brightness,
            aStarMean: metrics.redness,
            bStarMean: metrics.bStar,
            laplacianVariance: metrics.texture,
            saturationVariance: metrics.saturationVariance
        )

        let regionData: [String: RegionScores] = [
            "Forehead": scores,
            "Left Cheek": scores,
            "Right Cheek": scores,
            "Chin": scores,
            "Under-Eyes": scores,
            "Nose": scores
        ]

        return SkinAnalysisData(
            brightnessScore: brightnessScore,
            rednessScore: rednessScore,
            textureScore: textureScore,
            hydrationScore: hydrationScore,
            overallScore: overall,
            itaAngle: metrics.brightness,
            aStarMean: metrics.redness,
            bStarMean: metrics.bStar,
            laplacianVariance: metrics.texture,
            saturationVariance: metrics.saturationVariance,
            regionData: regionData
        )
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
        let brightness: Double
        let redness: Double
        let bStar: Double
        let texture: Double
        let saturationVariance: Double
    }

    private func computeRegionMetrics(cgImage: CGImage, context: CIContext) -> InternalRegionMetrics? {
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

            let r = Double(ptr[offset]) / 255.0
            let g = Double(ptr[offset + 1]) / 255.0
            let b = Double(ptr[offset + 2]) / 255.0

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

        let textureVar = computeTextureVariance(ptr: ptr, width: width, height: height, bytesPerRow: bytesPerRow, bytesPerPixel: bytesPerPixel, dataLength: CFDataGetLength(data))

        return InternalRegionMetrics(
            brightness: ita,
            redness: meanA,
            bStar: meanB,
            texture: textureVar,
            saturationVariance: satVar
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
}
