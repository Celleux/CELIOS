import SwiftUI

struct ScanGridOverlayView: View {
    let progress: Double
    let isActive: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                drawHexagonalGrid(context: context, size: size, time: time)
                if isActive {
                    drawScanBeamEffect(context: context, size: size, time: time)
                    drawCornerBrackets(context: context, size: size, time: time)
                    drawCircuitLines(context: context, size: size, time: time)
                    drawDataStreams(context: context, size: size, time: time)
                    drawFloatingReadouts(context: context, size: size, time: time)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawHexagonalGrid(context: GraphicsContext, size: CGSize, time: Double) {
        let hexRadius: CGFloat = 18
        let hexWidth = hexRadius * 2
        let hexHeight = hexRadius * sqrt(3)
        let cols = Int(size.width / (hexWidth * 0.75)) + 2
        let rows = Int(size.height / hexHeight) + 2
        let centerX = size.width / 2
        let centerY = size.height / 2
        let maxDist = hypot(centerX, centerY)
        let breathe = sin(time * 0.8) * 0.02 + 1.0

        let goldColor = Color(hex: "E8D6A8")
        let silverColor = Color(hex: "C0C8D4")

        for row in 0...rows {
            for col in 0...cols {
                let xOffset = CGFloat(col) * hexWidth * 0.75
                let yOffset = CGFloat(row) * hexHeight + (col % 2 == 1 ? hexHeight / 2 : 0)
                let dx = xOffset - centerX
                let dy = yOffset - centerY
                let dist = hypot(dx, dy)
                let normalizedDist = dist / maxDist

                let wavePhase = sin(time * 1.2 + normalizedDist * 6.0)
                let baseOpacity = max(0, 0.25 - normalizedDist * 0.22)
                let activeBoost = isActive ? 0.15 * max(0, wavePhase) : 0.0
                let opacity = (baseOpacity + activeBoost) * breathe

                if opacity < 0.01 { continue }

                let lineColor = normalizedDist < 0.4 ? goldColor : silverColor

                var hexPath = Path()
                for i in 0..<6 {
                    let angle = CGFloat(i) * .pi / 3 - .pi / 6
                    let hx = xOffset + cos(angle) * hexRadius * 0.85
                    let hy = yOffset + sin(angle) * hexRadius * 0.85
                    if i == 0 {
                        hexPath.move(to: CGPoint(x: hx, y: hy))
                    } else {
                        hexPath.addLine(to: CGPoint(x: hx, y: hy))
                    }
                }
                hexPath.closeSubpath()
                context.stroke(hexPath, with: .color(lineColor.opacity(opacity * 0.4)), lineWidth: 0.5)

                let dotSize: CGFloat = isActive ? 2.0 : 1.5
                let glowTime = sin(time * 2.0 + Double(row) * 0.3 + Double(col) * 0.2)
                let dotGlow = isActive ? max(0, glowTime) * 0.4 : 0

                let dot = Path(ellipseIn: CGRect(
                    x: xOffset - dotSize / 2,
                    y: yOffset - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                ))
                context.fill(dot, with: .color(goldColor.opacity((opacity + dotGlow) * 0.8)))
            }
        }
    }

    private func drawScanBeamEffect(context: GraphicsContext, size: CGSize, time: Double) {
        let cycleTime = time.truncatingRemainder(dividingBy: 3.5) / 3.5
        let x = cycleTime * size.width

        let gold = Color(hex: "E8D6A8")
        let lineWidth: CGFloat = 60

        var stops: [Gradient.Stop] = []
        stops.append(.init(color: gold.opacity(0), location: 0))
        stops.append(.init(color: gold.opacity(0.02), location: 0.2))
        stops.append(.init(color: gold.opacity(0.08), location: 0.4))
        stops.append(.init(color: Color(hex: "FFF8E8").opacity(0.30), location: 0.5))
        stops.append(.init(color: gold.opacity(0.08), location: 0.6))
        stops.append(.init(color: gold.opacity(0.02), location: 0.8))
        stops.append(.init(color: gold.opacity(0), location: 1))

        let rect = CGRect(x: x - lineWidth / 2, y: 0, width: lineWidth, height: size.height)
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(stops: stops),
                startPoint: CGPoint(x: rect.minX, y: 0),
                endPoint: CGPoint(x: rect.maxX, y: 0)
            )
        )

        var centerLine = Path()
        centerLine.move(to: CGPoint(x: x, y: 0))
        centerLine.addLine(to: CGPoint(x: x, y: size.height))
        context.stroke(centerLine, with: .color(Color(hex: "E8D6A8").opacity(0.7)), lineWidth: 1.0)

        var brightCore = Path()
        brightCore.move(to: CGPoint(x: x, y: 0))
        brightCore.addLine(to: CGPoint(x: x, y: size.height))
        context.stroke(brightCore, with: .color(Color.white.opacity(0.4)), lineWidth: 0.5)
    }

    private func drawCornerBrackets(context: GraphicsContext, size: CGSize, time: Double) {
        let inset: CGFloat = 14
        let length: CGFloat = 36
        let pulse = sin(time * 1.5) * 0.15 + 0.85
        let gold = Color(hex: "E8D6A8").opacity(pulse)
        let lineWidth: CGFloat = 2.0

        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: inset, y: inset + length), CGPoint(x: inset, y: inset), CGPoint(x: inset + length, y: inset)),
            (CGPoint(x: size.width - inset - length, y: inset), CGPoint(x: size.width - inset, y: inset), CGPoint(x: size.width - inset, y: inset + length)),
            (CGPoint(x: inset, y: size.height - inset - length), CGPoint(x: inset, y: size.height - inset), CGPoint(x: inset + length, y: size.height - inset)),
            (CGPoint(x: size.width - inset - length, y: size.height - inset), CGPoint(x: size.width - inset, y: size.height - inset), CGPoint(x: size.width - inset, y: size.height - inset - length)),
        ]

        for (start, corner, end) in corners {
            var path = Path()
            path.move(to: start)
            path.addLine(to: corner)
            path.addLine(to: end)
            context.stroke(path, with: .color(gold), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            let dotRect = CGRect(x: corner.x - 3, y: corner.y - 3, width: 6, height: 6)
            context.fill(Path(ellipseIn: dotRect), with: .color(Color(hex: "E8D6A8").opacity(0.5)))
        }
    }

    private func drawCircuitLines(context: GraphicsContext, size: CGSize, time: Double) {
        let gold = Color(hex: "D4C4A0")
        let pulse = sin(time * 2.0)

        let circuits: [(start: CGPoint, mid: CGPoint, end: CGPoint)] = [
            (CGPoint(x: 14, y: size.height * 0.3), CGPoint(x: 40, y: size.height * 0.3), CGPoint(x: 40, y: size.height * 0.2)),
            (CGPoint(x: size.width - 14, y: size.height * 0.7), CGPoint(x: size.width - 40, y: size.height * 0.7), CGPoint(x: size.width - 40, y: size.height * 0.8)),
            (CGPoint(x: 14, y: size.height * 0.6), CGPoint(x: 30, y: size.height * 0.6), CGPoint(x: 30, y: size.height * 0.55)),
            (CGPoint(x: size.width - 14, y: size.height * 0.4), CGPoint(x: size.width - 30, y: size.height * 0.4), CGPoint(x: size.width - 30, y: size.height * 0.35)),
        ]

        for (index, circuit) in circuits.enumerated() {
            let phaseShift = sin(time * 1.5 + Double(index) * 1.2)
            let opacity = max(0, phaseShift) * 0.3

            var path = Path()
            path.move(to: circuit.start)
            path.addLine(to: circuit.mid)
            path.addLine(to: circuit.end)
            context.stroke(path, with: .color(gold.opacity(opacity)), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))

            if pulse > 0 {
                let dotRect = CGRect(x: circuit.end.x - 2, y: circuit.end.y - 2, width: 4, height: 4)
                context.fill(Path(ellipseIn: dotRect), with: .color(gold.opacity(opacity * 1.5)))
            }
        }
    }

    private func drawDataStreams(context: GraphicsContext, size: CGSize, time: Double) {
        let streamCount = 6
        let gold = Color(hex: "E8D6A8")

        for i in 0..<streamCount {
            let baseX = size.width * CGFloat(i + 1) / CGFloat(streamCount + 1)
            let speed = 1.5 + Double(i) * 0.3
            let offset = time.truncatingRemainder(dividingBy: speed) / speed

            for j in 0..<3 {
                let segY = (offset + Double(j) * 0.33).truncatingRemainder(dividingBy: 1.0) * Double(size.height)
                let segLength: CGFloat = 8
                let segOpacity = progress > Double(i) * 0.15 ? 0.15 : 0.03

                var seg = Path()
                seg.move(to: CGPoint(x: baseX, y: segY))
                seg.addLine(to: CGPoint(x: baseX, y: segY + segLength))
                context.stroke(seg, with: .color(gold.opacity(segOpacity)), lineWidth: 0.6)
            }
        }
    }

    private func drawFloatingReadouts(context: GraphicsContext, size: CGSize, time: Double) {
        let readouts: [(String, CGPoint, Double)] = [
            ("DERMIS SCAN", CGPoint(x: 0.12, y: 0.18), 0.0),
            ("λ 380-780nm", CGPoint(x: 0.72, y: 0.15), 0.1),
            ("COLLAGEN MAP", CGPoint(x: 0.10, y: 0.45), 0.2),
            ("MELANIN IDX", CGPoint(x: 0.70, y: 0.50), 0.3),
            ("HYDRATION %", CGPoint(x: 0.08, y: 0.72), 0.4),
            ("ELASTIN LVL", CGPoint(x: 0.72, y: 0.78), 0.5),
            (String(format: "%.1f%%", progress * 100), CGPoint(x: 0.50, y: 0.92), 0.0),
        ]

        for (index, readout) in readouts.enumerated() {
            let showThreshold = progress > readout.2
            let flickerCycle = sin(time * 2.2 + Double(index) * 1.5)
            guard showThreshold && flickerCycle > -0.3 else { continue }

            let position = CGPoint(x: readout.1.x * size.width, y: readout.1.y * size.height)
            let opacity = min(1.0, max(0, flickerCycle * 0.3 + 0.7)) * 0.7

            let text = Text(readout.0)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: "E8D6A8").opacity(opacity))

            context.draw(context.resolve(text), at: position, anchor: .leading)
        }
    }
}
