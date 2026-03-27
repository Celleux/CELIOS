import SwiftUI
import ARKit
import SceneKit

struct ARFaceTrackingView: UIViewRepresentable {
    let isScanning: Bool
    let scanProgress: Double
    let heatMapMode: HeatMapMode
    let showHeatMap: Bool
    let regionScores: [String: RegionScores]
    var onFaceDetected: ((Bool) -> Void)?
    var onFrameCaptured: ((CVPixelBuffer) -> Void)?
    var onElasticityComputed: ((Double) -> Void)?
    var onAllCapturesFailed: (() -> Void)?
    var onLightingUpdated: ((LightingConditions) -> Void)?

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.delegate = context.coordinator
        sceneView.session.delegate = context.coordinator
        sceneView.automaticallyUpdatesLighting = true
        sceneView.rendersContinuously = true
        sceneView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.10, alpha: 1.0)
        sceneView.antialiasingMode = .multisampling4X

        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        config.maximumNumberOfTrackedFaces = 1
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        context.coordinator.sceneView = sceneView

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.isScanning = isScanning
        context.coordinator.scanProgress = scanProgress
        context.coordinator.heatMapMode = heatMapMode
        context.coordinator.showHeatMap = showHeatMap
        context.coordinator.regionScores = regionScores
        context.coordinator.onFaceDetected = onFaceDetected
        context.coordinator.onFrameCaptured = onFrameCaptured
        context.coordinator.onElasticityComputed = onElasticityComputed
        context.coordinator.onAllCapturesFailed = onAllCapturesFailed
        context.coordinator.onLightingUpdated = onLightingUpdated
        context.coordinator.updateMeshAppearance()
    }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        weak var sceneView: ARSCNView?
        var isScanning: Bool = false
        var scanProgress: Double = 0
        var heatMapMode: HeatMapMode = .all
        var showHeatMap: Bool = false
        var regionScores: [String: RegionScores] = [:]
        var onFaceDetected: ((Bool) -> Void)?
        var onFrameCaptured: ((CVPixelBuffer) -> Void)?
        var onElasticityComputed: ((Double) -> Void)?
        var onAllCapturesFailed: (() -> Void)?
        var onLightingUpdated: ((LightingConditions) -> Void)?

        private var faceNode: SCNNode?
        private var blendShapeSamples: [(timestamp: TimeInterval, jawOpen: Double, cheekPuff: Double, mouthSmileL: Double, mouthSmileR: Double)] = []
        private var elasticityPhase: ElasticityPhase = .idle
        private var elasticityScore: Double = 0

        enum ElasticityPhase {
            case idle
            case sampling
            case computed
        }
        private var faceGeometry: ARSCNFaceGeometry?
        private var heatMapNode: SCNNode?
        private var scanBeamNode: SCNNode?
        private var gridLinesNode: SCNNode?
        private var meshRevealNode: SCNNode?
        private var landmarkDots: [SCNNode] = []
        private var orbitParticles: [SCNNode] = []
        private var hasCapturedFrame: Bool = false
        private var captureRetryCount: Int = 0
        private var lastUpdateTime: TimeInterval = 0
        private var lastLightingUpdate: TimeInterval = 0
        private var latestLightingConditions: LightingConditions?

        private let captureThresholds: [Double] = [0.8, 0.85, 0.9, 0.95]

        private let whiteGold = UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: 1.0)
        private let brightGold = UIColor(red: 0.85, green: 0.75, blue: 0.50, alpha: 1.0)
        private let silver = UIColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1.0)
        private let champagne = UIColor(red: 0.95, green: 0.90, blue: 0.78, alpha: 1.0)
        private let warmWhite = UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1.0)

        nonisolated func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard anchor is ARFaceAnchor,
                  let device = MTLCreateSystemDefaultDevice(),
                  let geometry = ARSCNFaceGeometry(device: device) else { return nil }

            geometry.firstMaterial?.fillMode = .lines
            geometry.firstMaterial?.diffuse.contents = UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: 0.0)
            geometry.firstMaterial?.emission.contents = UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: 0.0)
            geometry.firstMaterial?.isDoubleSided = true
            geometry.firstMaterial?.lightingModel = .constant

            let node = SCNNode(geometry: geometry)

            Task { @MainActor in
                self.faceNode = node
                self.faceGeometry = geometry
                self.addFuturisticMeshOverlay(to: node, device: device)
                self.addScanBeam(to: node)
                self.addOrbitParticles(to: node)
                self.onFaceDetected?(true)
            }

            return node
        }

        nonisolated func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }

            faceGeometry.update(from: faceAnchor.geometry)

            let blendShapes = faceAnchor.blendShapes
            let jawOpen = blendShapes[.jawOpen]?.doubleValue ?? 0
            let cheekPuff = blendShapes[.cheekPuff]?.doubleValue ?? 0
            let smileL = blendShapes[.mouthSmileLeft]?.doubleValue ?? 0
            let smileR = blendShapes[.mouthSmileRight]?.doubleValue ?? 0
            let time = CACurrentMediaTime()

            Task { @MainActor in
                self.sampleBlendShapes(timestamp: time, jawOpen: jawOpen, cheekPuff: cheekPuff, smileL: smileL, smileR: smileR)
                self.updateHeatMapGeometry(faceAnchor: faceAnchor, node: node)
                self.updateMeshReveal(faceAnchor: faceAnchor, node: node)
            }
        }

        nonisolated func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            guard anchor is ARFaceAnchor else { return }
            Task { @MainActor in
                self.faceNode = nil
                self.faceGeometry = nil
                self.heatMapNode = nil
                self.meshRevealNode = nil
                self.onFaceDetected?(false)
            }
        }

        nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let lightEstimate = frame.lightEstimate
            let ambientIntensity = lightEstimate?.ambientIntensity ?? 1000
            let colorTemperature = lightEstimate?.ambientColorTemperature ?? 6500

            Task { @MainActor in
                let now = CACurrentMediaTime()
                if now - self.lastLightingUpdate > 0.5 {
                    self.lastLightingUpdate = now
                    let conditions = LightingConditions(
                        ambientIntensity: Double(ambientIntensity),
                        colorTemperature: Double(colorTemperature),
                        correctionApplied: false
                    )
                    self.latestLightingConditions = conditions
                    self.onLightingUpdated?(conditions)
                }

                guard self.isScanning else { return }
                guard self.captureRetryCount < self.captureThresholds.count else {
                    if !self.hasCapturedFrame {
                        self.hasCapturedFrame = true
                        self.onAllCapturesFailed?()
                    }
                    return
                }

                if self.scanProgress >= self.captureThresholds[self.captureRetryCount] {
                    self.captureRetryCount += 1
                    self.onFrameCaptured?(frame.capturedImage)
                }
            }
        }

        func updateMeshAppearance() {
            guard let geometry = faceGeometry else { return }

            if isScanning || showHeatMap {
                let revealProgress = min(1.0, scanProgress * 1.2)
                let baseAlpha = showHeatMap ? 0.0 : min(1.0, 0.2 + revealProgress * 0.5)
                let meshColor = UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: baseAlpha)
                geometry.firstMaterial?.diffuse.contents = meshColor
                geometry.firstMaterial?.emission.contents = UIColor(red: 0.95, green: 0.90, blue: 0.78, alpha: baseAlpha * 0.6)

                for (index, dot) in landmarkDots.enumerated() {
                    dot.isHidden = scanProgress < Double(index) * 0.06
                }

                scanBeamNode?.isHidden = !isScanning
                if isScanning && scanBeamNode?.action(forKey: "sweep") == nil {
                    startScanBeamAnimation()
                }
                if !isScanning {
                    scanBeamNode?.removeAction(forKey: "sweep")
                }

                gridLinesNode?.isHidden = !showHeatMap
                heatMapNode?.isHidden = !showHeatMap

                for particle in orbitParticles {
                    particle.isHidden = false
                }
            } else {
                geometry.firstMaterial?.diffuse.contents = UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: 0.0)
                geometry.firstMaterial?.emission.contents = UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: 0.0)

                for dot in landmarkDots {
                    dot.isHidden = true
                }
                scanBeamNode?.isHidden = true
                scanBeamNode?.removeAction(forKey: "sweep")
                gridLinesNode?.isHidden = true
                heatMapNode?.isHidden = true
                meshRevealNode?.removeFromParentNode()
                meshRevealNode = nil
                hasCapturedFrame = false
                captureRetryCount = 0
                blendShapeSamples.removeAll()
                elasticityPhase = .idle
                elasticityScore = 0

                for particle in orbitParticles {
                    particle.isHidden = true
                }
            }
        }

        private func sampleBlendShapes(timestamp: TimeInterval, jawOpen: Double, cheekPuff: Double, smileL: Double, smileR: Double) {
            guard isScanning, elasticityPhase != .computed else { return }

            if elasticityPhase == .idle && scanProgress > 0.1 {
                elasticityPhase = .sampling
            }

            guard elasticityPhase == .sampling else { return }

            blendShapeSamples.append((timestamp: timestamp, jawOpen: jawOpen, cheekPuff: cheekPuff, mouthSmileL: smileL, mouthSmileR: smileR))

            if blendShapeSamples.count >= 30 && scanProgress > 0.6 {
                elasticityScore = computeElasticityFromSamples()
                elasticityPhase = .computed
                onElasticityComputed?(elasticityScore)
            }
        }

        private func computeElasticityFromSamples() -> Double {
            guard blendShapeSamples.count >= 10 else { return 75 }

            var smileSymmetryValues: [Double] = []
            var jawVariability: [Double] = []
            var cheekResponsiveness: [Double] = []

            for sample in blendShapeSamples {
                let symmetry = 1.0 - abs(sample.mouthSmileL - sample.mouthSmileR)
                smileSymmetryValues.append(symmetry)
                jawVariability.append(sample.jawOpen)
                cheekResponsiveness.append(sample.cheekPuff)
            }

            let avgSymmetry = smileSymmetryValues.reduce(0, +) / Double(smileSymmetryValues.count)

            let jawMean = jawVariability.reduce(0, +) / Double(jawVariability.count)
            let jawRange = (jawVariability.max() ?? 0) - (jawVariability.min() ?? 0)

            let cheekMean = cheekResponsiveness.reduce(0, +) / Double(cheekResponsiveness.count)

            var recoverySpeed: Double = 0.5
            for i in 1..<blendShapeSamples.count {
                let prev = blendShapeSamples[i - 1]
                let curr = blendShapeSamples[i]
                let dt = curr.timestamp - prev.timestamp
                guard dt > 0 else { continue }
                let jawDelta = abs(curr.jawOpen - prev.jawOpen) / dt
                recoverySpeed = max(recoverySpeed, min(1.0, jawDelta / 5.0))
            }

            let symmetryComponent = avgSymmetry * 30.0
            let rangeComponent = min(1.0, jawRange / 0.3) * 25.0
            let recoveryComponent = recoverySpeed * 25.0
            let baselineComponent = min(1.0, (cheekMean + jawMean) / 0.2) * 20.0

            let rawScore = symmetryComponent + rangeComponent + recoveryComponent + baselineComponent
            return max(25, min(98, rawScore))
        }

        private func addFuturisticMeshOverlay(to node: SCNNode, device: MTLDevice) {
            let dotPositions: [(Int, UIColor, String)] = [
                (9, UIColor(red: 0.95, green: 0.90, blue: 0.70, alpha: 1.0), "forehead"),
                (24, UIColor(red: 0.95, green: 0.90, blue: 0.70, alpha: 1.0), "forehead2"),
                (1117, UIColor(red: 0.85, green: 0.80, blue: 0.65, alpha: 1.0), "leftCheek"),
                (1247, UIColor(red: 0.85, green: 0.80, blue: 0.65, alpha: 1.0), "rightCheek"),
                (1061, UIColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1.0), "leftEye"),
                (1064, UIColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1.0), "rightEye"),
                (462, UIColor(red: 0.98, green: 0.92, blue: 0.75, alpha: 1.0), "nose"),
                (376, UIColor(red: 0.88, green: 0.82, blue: 0.62, alpha: 1.0), "chin"),
                (661, UIColor(red: 0.78, green: 0.80, blue: 0.85, alpha: 1.0), "jawLeft"),
                (888, UIColor(red: 0.78, green: 0.80, blue: 0.85, alpha: 1.0), "jawRight"),
                (822, UIColor(red: 0.92, green: 0.86, blue: 0.68, alpha: 1.0), "temple"),
                (1047, UIColor(red: 0.92, green: 0.86, blue: 0.68, alpha: 1.0), "temple2"),
            ]

            guard let faceGeometry = faceGeometry else { return }
            let vertices = faceGeometry.vertices()

            for (index, color, _) in dotPositions {
                guard index < vertices.count else { continue }

                let coreGlow = SCNSphere(radius: 0.002)
                coreGlow.firstMaterial?.diffuse.contents = UIColor.white
                coreGlow.firstMaterial?.emission.contents = color
                coreGlow.firstMaterial?.lightingModel = .constant
                let coreNode = SCNNode(geometry: coreGlow)
                let pos = vertices[index]
                coreNode.position = SCNVector3(pos.x, pos.y, pos.z)
                coreNode.isHidden = true

                let haloSphere = SCNSphere(radius: 0.005)
                haloSphere.firstMaterial?.diffuse.contents = color.withAlphaComponent(0.15)
                haloSphere.firstMaterial?.emission.contents = color.withAlphaComponent(0.10)
                haloSphere.firstMaterial?.lightingModel = .constant
                haloSphere.firstMaterial?.isDoubleSided = true
                let haloNode = SCNNode(geometry: haloSphere)
                coreNode.addChildNode(haloNode)

                let outerRing = SCNTorus(ringRadius: 0.007, pipeRadius: 0.0005)
                outerRing.firstMaterial?.diffuse.contents = color.withAlphaComponent(0.30)
                outerRing.firstMaterial?.emission.contents = color.withAlphaComponent(0.20)
                outerRing.firstMaterial?.lightingModel = .constant
                let ringNode = SCNNode(geometry: outerRing)
                coreNode.addChildNode(ringNode)

                let pulse = SCNAction.sequence([
                    SCNAction.scale(to: 1.3, duration: 0.8),
                    SCNAction.scale(to: 0.85, duration: 0.8)
                ])
                coreNode.runAction(SCNAction.repeatForever(pulse))

                let ringRotate = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: 3.0)
                ringNode.runAction(SCNAction.repeatForever(ringRotate))

                node.addChildNode(coreNode)
                landmarkDots.append(coreNode)
            }
        }

        private func addOrbitParticles(to node: SCNNode) {
            let goldTones: [UIColor] = [
                UIColor(red: 0.95, green: 0.90, blue: 0.70, alpha: 0.6),
                UIColor(red: 0.88, green: 0.82, blue: 0.62, alpha: 0.5),
                UIColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 0.5),
                UIColor(red: 0.98, green: 0.95, blue: 0.82, alpha: 0.6),
                UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: 0.5),
                UIColor(red: 0.85, green: 0.75, blue: 0.50, alpha: 0.5),
                UIColor(red: 0.78, green: 0.80, blue: 0.85, alpha: 0.4),
                UIColor(red: 0.95, green: 0.92, blue: 0.82, alpha: 0.5),
            ]

            for i in 0..<8 {
                let particleSphere = SCNSphere(radius: 0.0012)
                let particleColor = goldTones[i]
                particleSphere.firstMaterial?.diffuse.contents = particleColor
                particleSphere.firstMaterial?.emission.contents = particleColor
                particleSphere.firstMaterial?.lightingModel = .constant

                let particleNode = SCNNode(geometry: particleSphere)
                particleNode.isHidden = true

                let angle = Double(i) * (.pi * 2.0 / 8.0)
                let radius: Float = 0.08
                particleNode.position = SCNVector3(
                    cos(Float(angle)) * radius,
                    sin(Float(angle)) * radius * 0.6,
                    0.02
                )

                let orbit = SCNAction.customAction(duration: 4.0 + Double(i) * 0.3) { actionNode, elapsed in
                    let t = Float(elapsed) / Float(4.0 + Float(i) * 0.3)
                    let a = Float(angle) + t * Float.pi * 2
                    let r: Float = 0.08 + sin(t * Float.pi * 4) * 0.015
                    actionNode.position = SCNVector3(
                        cos(a) * r,
                        sin(a) * r * 0.6,
                        0.02 + sin(t * Float.pi * 6) * 0.008
                    )
                }
                particleNode.runAction(SCNAction.repeatForever(orbit))

                node.addChildNode(particleNode)
                orbitParticles.append(particleNode)
            }
        }

        private func addScanBeam(to node: SCNNode) {
            let beamPlane = SCNPlane(width: 0.003, height: 0.18)
            let beamMaterial = SCNMaterial()
            beamMaterial.diffuse.contents = UIColor(red: 0.95, green: 0.90, blue: 0.70, alpha: 0.2)
            beamMaterial.emission.contents = UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: 0.7)
            beamMaterial.lightingModel = .constant
            beamMaterial.isDoubleSided = true
            beamMaterial.transparent.contents = UIColor(white: 1.0, alpha: 0.8)
            beamPlane.materials = [beamMaterial]

            let beamNode = SCNNode(geometry: beamPlane)
            beamNode.position = SCNVector3(-0.08, 0, 0.015)
            beamNode.isHidden = true
            node.addChildNode(beamNode)

            let trailPlane = SCNPlane(width: 0.04, height: 0.18)
            let trailMaterial = SCNMaterial()
            trailMaterial.diffuse.contents = UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: 0.04)
            trailMaterial.emission.contents = UIColor(red: 0.95, green: 0.90, blue: 0.78, alpha: 0.08)
            trailMaterial.lightingModel = .constant
            trailMaterial.isDoubleSided = true
            trailPlane.materials = [trailMaterial]

            let trailNode = SCNNode(geometry: trailPlane)
            trailNode.position = SCNVector3(-0.015, 0, -0.001)
            beamNode.addChildNode(trailNode)

            let glowPlane = SCNPlane(width: 0.008, height: 0.18)
            let glowMaterial = SCNMaterial()
            glowMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.3)
            glowMaterial.emission.contents = UIColor(red: 0.98, green: 0.95, blue: 0.85, alpha: 0.5)
            glowMaterial.lightingModel = .constant
            glowMaterial.isDoubleSided = true
            glowPlane.materials = [glowMaterial]

            let glowNode = SCNNode(geometry: glowPlane)
            glowNode.position = SCNVector3(0, 0, 0.001)
            beamNode.addChildNode(glowNode)

            self.scanBeamNode = beamNode
        }

        private func startScanBeamAnimation() {
            guard let beam = scanBeamNode else { return }
            let moveRight = SCNAction.move(to: SCNVector3(0.08, 0, 0.015), duration: 3.0)
            moveRight.timingMode = .easeInEaseOut
            let moveLeft = SCNAction.move(to: SCNVector3(-0.08, 0, 0.015), duration: 0.2)
            moveLeft.timingMode = .easeIn
            let sequence = SCNAction.sequence([moveRight, moveLeft])
            beam.runAction(SCNAction.repeatForever(sequence), forKey: "sweep")
        }

        private func updateMeshReveal(faceAnchor: ARFaceAnchor, node: SCNNode) {
            guard isScanning, scanProgress > 0.05 else { return }

            meshRevealNode?.removeFromParentNode()

            let vertices = faceAnchor.geometry.vertices
            let triangleIndices = faceAnchor.geometry.triangleIndices
            let vertexCount = vertices.count

            let revealX = Float(-0.08 + scanProgress * 0.16)

            var colorData = Data(capacity: vertexCount * MemoryLayout<SIMD4<Float>>.stride)

            for i in 0..<vertexCount {
                let pos = vertices[i]
                let distFromBeam = pos.x - revealX
                var alpha: Float = 0

                if distFromBeam < 0 {
                    alpha = min(0.55, 0.55 * min(1.0, abs(distFromBeam) * 8))
                    let edgeFade = max(0, 1.0 - abs(distFromBeam) * 3)
                    alpha += edgeFade * 0.3
                } else if distFromBeam < 0.01 {
                    alpha = 0.85 * (1.0 - distFromBeam / 0.01)
                }

                let goldR: Float = 0.91
                let goldG: Float = 0.84
                let goldB: Float = 0.67

                let edgeGlow = max(0, 1.0 - abs(distFromBeam) * 15)
                let r = goldR + edgeGlow * 0.09
                let g = goldG + edgeGlow * 0.11
                let b = goldB + edgeGlow * 0.18

                var rgba = SIMD4<Float>(r, g, b, alpha)
                colorData.append(contentsOf: withUnsafeBytes(of: &rgba) { Data($0) })
            }

            let positionSource = SCNGeometrySource(
                data: Data(bytes: vertices, count: vertexCount * MemoryLayout<SIMD3<Float>>.stride),
                semantic: .vertex,
                vectorCount: vertexCount,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD3<Float>>.stride
            )

            let colorSource = SCNGeometrySource(
                data: colorData,
                semantic: .color,
                vectorCount: vertexCount,
                usesFloatComponents: true,
                componentsPerVector: 4,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD4<Float>>.stride
            )

            let indexData = Data(bytes: triangleIndices, count: triangleIndices.count * MemoryLayout<Int16>.stride)
            let element = SCNGeometryElement(
                data: indexData,
                primitiveType: .triangles,
                primitiveCount: triangleIndices.count / 3,
                bytesPerIndex: MemoryLayout<Int16>.size
            )

            let revealGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [element])
            let material = SCNMaterial()
            material.lightingModel = .constant
            material.isDoubleSided = true
            material.diffuse.contents = UIColor.white
            material.fillMode = .lines
            material.blendMode = .add
            revealGeometry.materials = [material]

            let newRevealNode = SCNNode(geometry: revealGeometry)
            newRevealNode.position = SCNVector3(0, 0, 0.0008)
            node.addChildNode(newRevealNode)
            self.meshRevealNode = newRevealNode
        }

        private func updateHeatMapGeometry(faceAnchor: ARFaceAnchor, node: SCNNode) {
            guard showHeatMap else { return }

            heatMapNode?.removeFromParentNode()

            let vertices = faceAnchor.geometry.vertices
            let triangleIndices = faceAnchor.geometry.triangleIndices
            let vertexCount = vertices.count

            var colorData = Data(capacity: vertexCount * MemoryLayout<SIMD4<Float>>.stride)

            for i in 0..<vertexCount {
                let pos = vertices[i]
                let color = heatMapColorForVertex(position: pos, mode: heatMapMode)
                var rgba = color
                colorData.append(contentsOf: withUnsafeBytes(of: &rgba) { Data($0) })
            }

            let positionSource = SCNGeometrySource(
                data: Data(bytes: vertices, count: vertexCount * MemoryLayout<SIMD3<Float>>.stride),
                semantic: .vertex,
                vectorCount: vertexCount,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD3<Float>>.stride
            )

            let colorSource = SCNGeometrySource(
                data: colorData,
                semantic: .color,
                vectorCount: vertexCount,
                usesFloatComponents: true,
                componentsPerVector: 4,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD4<Float>>.stride
            )

            let indexData = Data(bytes: triangleIndices, count: triangleIndices.count * MemoryLayout<Int16>.stride)
            let element = SCNGeometryElement(
                data: indexData,
                primitiveType: .triangles,
                primitiveCount: triangleIndices.count / 3,
                bytesPerIndex: MemoryLayout<Int16>.size
            )

            let heatGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [element])
            let material = SCNMaterial()
            material.lightingModel = .constant
            material.isDoubleSided = true
            material.diffuse.contents = UIColor.white
            material.blendMode = .add
            heatGeometry.materials = [material]

            let newHeatNode = SCNNode(geometry: heatGeometry)
            newHeatNode.position = SCNVector3(0, 0, 0.001)
            node.addChildNode(newHeatNode)
            self.heatMapNode = newHeatNode
        }

        private func classifyRegion(position: SIMD3<Float>) -> (primary: String, secondary: String?, blendFactor: Float) {
            let x = position.x
            let y = position.y

            if y > 0.03 && abs(x) < 0.05 {
                return ("Forehead", nil, 0)
            }

            if abs(x) > 0.015 && abs(x) < 0.045 && y > -0.005 && y < 0.025 {
                return ("Under-Eyes", nil, 0)
            }

            if abs(x) > 0.005 && abs(x) < 0.025 && y > -0.025 && y < 0.015 {
                let distFromNoseCenter = abs(x) / 0.025
                if distFromNoseCenter < 0.6 {
                    return ("Nose", nil, 0)
                }
                let cheekName = x < 0 ? "Left Cheek" : "Right Cheek"
                return ("Nose", cheekName, Float(distFromNoseCenter - 0.6) / 0.4)
            }

            if x < -0.025 && y < 0.03 && y > -0.03 {
                return ("Left Cheek", nil, 0)
            }
            if x > 0.025 && y < 0.03 && y > -0.03 {
                return ("Right Cheek", nil, 0)
            }

            if y < -0.03 && abs(x) < 0.04 {
                return ("Chin", nil, 0)
            }

            if y > 0.01 {
                return ("Forehead", nil, 0)
            }
            if y < -0.02 {
                return ("Chin", nil, 0)
            }

            let cheekName = x < 0 ? "Left Cheek" : "Right Cheek"
            return (cheekName, nil, 0)
        }

        private func scoreForRegionAndMode(_ regionName: String, mode: HeatMapMode) -> Float {
            guard let scores = regionScores[regionName] else { return 0.5 }

            switch mode {
            case .all:
                let avg = (scores.brightnessScore + scores.rednessScore + scores.textureScore + scores.hydrationScore) / 4.0
                return Float(max(0, min(1, avg / 100.0)))
            case .redness:
                return Float(max(0, min(1, scores.rednessScore / 100.0)))
            case .texture:
                return Float(max(0, min(1, scores.textureScore / 100.0)))
            case .hydration:
                return Float(max(0, min(1, scores.hydrationScore / 100.0)))
            case .tone:
                return Float(max(0, min(1, scores.toneUniformityScore / 100.0)))
            }
        }

        private func heatMapColorForVertex(position: SIMD3<Float>, mode: HeatMapMode) -> SIMD4<Float> {
            guard !regionScores.isEmpty else {
                return SIMD4<Float>(0, 0, 0, 0)
            }

            let classification = classifyRegion(position: position)
            let primaryScore = scoreForRegionAndMode(classification.primary, mode: mode)

            var finalScore: Float
            if let secondary = classification.secondary {
                let secondaryScore = scoreForRegionAndMode(secondary, mode: mode)
                finalScore = primaryScore * (1 - classification.blendFactor) + secondaryScore * classification.blendFactor
            } else {
                finalScore = primaryScore
            }

            let invertedScore = 1.0 - finalScore

            let goldR: Float = 0.91
            let goldG: Float = 0.84
            let goldB: Float = 0.67
            let warmRedR: Float = 0.95
            let warmRedG: Float = 0.55
            let warmRedB: Float = 0.40

            let r = goldR * finalScore + warmRedR * invertedScore
            let g = goldG * finalScore + warmRedG * invertedScore
            let b = goldB * finalScore + warmRedB * invertedScore

            let intensity = max(0.15, invertedScore * 0.6)

            let time = Float(CACurrentMediaTime())
            let pulse = (sin(time * 2.0 + position.x * 20 + position.y * 15) * 0.1 + 1.0)
            let a = intensity * pulse

            return SIMD4<Float>(r, g, b, a)
        }
    }
}

extension ARSCNFaceGeometry {
    func vertices() -> [SIMD3<Float>] {
        let source = self.sources(for: .vertex).first!
        let count = source.vectorCount
        let stride = source.dataStride
        let offset = source.dataOffset
        let data = source.data

        var result: [SIMD3<Float>] = []
        result.reserveCapacity(count)

        data.withUnsafeBytes { rawBuffer in
            for i in 0..<count {
                let byteOffset = offset + i * stride
                let ptr = rawBuffer.baseAddress!.advanced(by: byteOffset)
                    .assumingMemoryBound(to: Float.self)
                result.append(SIMD3<Float>(ptr[0], ptr[1], ptr[2]))
            }
        }

        return result
    }
}
