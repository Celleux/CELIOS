import SwiftUI
import ARKit
import SceneKit

struct ARFaceTrackingView: UIViewRepresentable {
    let isScanning: Bool
    let scanProgress: Double
    let heatMapMode: HeatMapMode
    let showHeatMap: Bool
    var onFaceDetected: ((Bool) -> Void)?
    var onFrameCaptured: ((CVPixelBuffer) -> Void)?

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
        context.coordinator.onFaceDetected = onFaceDetected
        context.coordinator.onFrameCaptured = onFrameCaptured
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
        var onFaceDetected: ((Bool) -> Void)?
        var onFrameCaptured: ((CVPixelBuffer) -> Void)?

        private var faceNode: SCNNode?
        private var faceGeometry: ARSCNFaceGeometry?
        private var heatMapNode: SCNNode?
        private var scanBeamNode: SCNNode?
        private var gridLinesNode: SCNNode?
        private var meshRevealNode: SCNNode?
        private var landmarkDots: [SCNNode] = []
        private var orbitParticles: [SCNNode] = []
        private var hasCapturedFrame: Bool = false
        private var lastUpdateTime: TimeInterval = 0

        private let whiteGold = UIColor(red: 0.91, green: 0.84, blue: 0.67, alpha: 1.0)
        private let brightGold = UIColor(red: 0.85, green: 0.75, blue: 0.50, alpha: 1.0)
        private let silver = UIColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1.0)
        private let champagne = UIColor(red: 0.95, green: 0.90, blue: 0.78, alpha: 1.0)
        private let warmWhite = UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1.0)

        nonisolated func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard anchor is ARFaceAnchor,
                  let device = (renderer as? ARSCNView)?.device,
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

            Task { @MainActor in
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
            Task { @MainActor in
                if self.isScanning && self.scanProgress > 0.8 && !self.hasCapturedFrame {
                    self.hasCapturedFrame = true
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

                for particle in orbitParticles {
                    particle.isHidden = true
                }
            }
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

        private func heatMapColorForVertex(position: SIMD3<Float>, mode: HeatMapMode) -> SIMD4<Float> {
            let x = position.x
            let y = position.y

            var rednessIntensity: Float = 0
            var textureIntensity: Float = 0
            var darkSpotIntensity: Float = 0
            var dehydrationIntensity: Float = 0

            let cheekZone = abs(x) > 0.025 && y < 0.02 && y > -0.04
            if cheekZone {
                rednessIntensity = max(0, 1.0 - abs(x - 0.04) * 8) * 0.7
            }

            let foreheadZone = y > 0.03 && abs(x) < 0.05
            if foreheadZone {
                textureIntensity = max(0, (y - 0.03) * 12) * 0.6
            }

            let underEyeZone = abs(x) > 0.015 && abs(x) < 0.045 && y > -0.005 && y < 0.02
            if underEyeZone {
                darkSpotIntensity = max(0, 1.0 - abs(y - 0.01) * 30) * 0.5
            }

            let jawZone = y < -0.03 && abs(x) < 0.06
            if jawZone {
                dehydrationIntensity = max(0, (-0.03 - y) * 8) * 0.5
            }

            let noseSide = abs(x) > 0.005 && abs(x) < 0.02 && y > -0.025 && y < 0.01
            if noseSide {
                textureIntensity = max(textureIntensity, 0.4)
            }

            let chinZone = y < -0.04 && abs(x) < 0.03
            if chinZone {
                rednessIntensity = max(rednessIntensity, 0.3)
            }

            var r: Float = 0
            var g: Float = 0
            var b: Float = 0
            var a: Float = 0

            switch mode {
            case .all:
                r = rednessIntensity * 0.95 + textureIntensity * 0.88 + darkSpotIntensity * 0.82 + dehydrationIntensity * 0.78
                g = rednessIntensity * 0.55 + textureIntensity * 0.82 + darkSpotIntensity * 0.80 + dehydrationIntensity * 0.80
                b = rednessIntensity * 0.40 + textureIntensity * 0.62 + darkSpotIntensity * 0.85 + dehydrationIntensity * 0.85
                a = max(rednessIntensity, max(textureIntensity, max(darkSpotIntensity, dehydrationIntensity))) * 0.45
            case .redness:
                r = rednessIntensity * 0.95
                g = rednessIntensity * 0.60
                b = rednessIntensity * 0.45
                a = rednessIntensity * 0.55
            case .texture:
                r = textureIntensity * 0.92
                g = textureIntensity * 0.85
                b = textureIntensity * 0.62
                a = textureIntensity * 0.55
            case .darkSpots:
                r = darkSpotIntensity * 0.82
                g = darkSpotIntensity * 0.80
                b = darkSpotIntensity * 0.88
                a = darkSpotIntensity * 0.55
            case .dehydration:
                r = dehydrationIntensity * 0.78
                g = dehydrationIntensity * 0.80
                b = dehydrationIntensity * 0.88
                a = dehydrationIntensity * 0.55
            }

            let time = Float(CACurrentMediaTime())
            let pulse = (sin(time * 2.0 + x * 20 + y * 15) * 0.15 + 1.0)
            a *= pulse

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
