import SwiftUI

// MARK: - Page 1: Real Skin Analysis

struct ValuePropSkinTrackingView: View {
    @State private var appeared: Bool = false
    @State private var gridPulse: Bool = false
    @State private var scanLine: CGFloat = -100

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color(hex: "F5F0E8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 280)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(CelleuxColors.goldChromeBorder, lineWidth: 1.5)
                    )
                    .celleuxDepthShadow()

                scanGridOverlay
                    .clipShape(RoundedRectangle(cornerRadius: 28))

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [CelleuxColors.warmGold.opacity(0), CelleuxColors.warmGold.opacity(0.2), CelleuxColors.warmGold.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 3)
                    .blur(radius: 2)
                    .offset(y: scanLine)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .allowsHitTesting(false)

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(CelleuxColors.warmGold.opacity(0.06))
                            .frame(width: 80, height: 80)
                            .scaleEffect(gridPulse ? 1.3 : 1.0)
                            .opacity(gridPulse ? 0.2 : 0.6)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.9), Color(hex: "F5F0E8")],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 56, height: 56)

                        Circle()
                            .stroke(CelleuxColors.goldChromeBorder, lineWidth: 1)
                            .frame(width: 56, height: 56)

                        Image(systemName: "faceid")
                            .font(.system(size: 26, weight: .thin))
                            .foregroundStyle(CelleuxColors.goldSilverGradient)
                    }
                    .shadow(color: CelleuxColors.goldGlow.opacity(0.3), radius: 10, x: 0, y: 4)

                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(CelleuxColors.warmGold.opacity(0.15 + Double(i) * 0.1))
                                .frame(width: 40, height: 6)
                        }
                    }

                    Text("10 METRICS")
                        .font(CelleuxType.label)
                        .foregroundStyle(CelleuxColors.warmGold.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(CelleuxType.labelTracking)
                }
            }
            .padding(.horizontal, CelleuxSpacing.xl)
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: CelleuxSpacing.xxl)

            VStack(spacing: 14) {
                Text("Real Skin Analysis")
                    .font(.system(size: 28, weight: .light))
                    .tracking(0.5)
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("10 metrics. Zero guesswork.\nPowered by ARKit + Computer Vision.")
                    .font(CelleuxType.body)
                    .foregroundStyle(CelleuxColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(CelleuxType.bodyLineSpacing)
                    .padding(.horizontal, CelleuxSpacing.sm)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.horizontal, CelleuxSpacing.xl)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                gridPulse = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                scanLine = 100
            }
        }
    }

    private var scanGridOverlay: some View {
        Canvas { context, size in
            let spacing: CGFloat = 24
            let cols = Int(size.width / spacing)
            let rows = Int(size.height / spacing)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxDist = hypot(center.x, center.y)

            for row in 0...rows {
                for col in 0...cols {
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    let distance = hypot(x - center.x, y - center.y)
                    let opacity = max(0, 0.15 - (distance / maxDist) * 0.12)
                    let dot = Path(ellipseIn: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3))
                    context.fill(dot, with: .color(CelleuxColors.warmGold.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Page 2: Your Body's Story

struct ValuePropLongevityScoreView: View {
    @State private var appeared: Bool = false
    @State private var ringProgress: CGFloat = 0
    @State private var scoreValue: Int = 0
    @State private var glowPhase: Bool = false

    private let healthIcons: [(icon: String, angle: Double)] = [
        ("heart.fill", 30),
        ("bed.double.fill", 90),
        ("waveform.path.ecg", 150),
        ("drop.fill", 210),
        ("figure.walk", 270),
        ("moon.fill", 330)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [CelleuxColors.warmGold.opacity(0.04), CelleuxColors.warmGold.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [CelleuxColors.silver.opacity(0.1), CelleuxColors.silver.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        AngularGradient(
                            colors: [Color(hex: "D4C4A0"), Color(hex: "C9A96E"), Color(hex: "B8A078"), Color(hex: "D4A574")],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: CelleuxColors.goldGlow, radius: glowPhase ? 16 : 8, x: 0, y: 0)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color(hex: "F5F0E8").opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)

                Circle()
                    .stroke(CelleuxColors.goldChromeBorder, lineWidth: 0.5)
                    .frame(width: 160, height: 160)

                VStack(spacing: 4) {
                    Text("\(scoreValue)")
                        .font(CelleuxType.metric)
                        .tracking(CelleuxType.metricTracking)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .animatedNumber()

                    Text("LONGEVITY")
                        .font(CelleuxType.label)
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(CelleuxType.labelTracking)
                }

                ForEach(Array(healthIcons.enumerated()), id: \.offset) { idx, item in
                    Image(systemName: item.icon)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(CelleuxColors.warmGold.opacity(0.4))
                        .offset(y: -128)
                        .rotationEffect(.degrees(item.angle))
                        .opacity(appeared ? 1 : 0)
                        .animation(CelleuxSpring.luxury.delay(0.3 + Double(idx) * 0.08), value: appeared)
                }
            }
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: CelleuxSpacing.xxl)

            VStack(spacing: 14) {
                Text("Your Body's Story")
                    .font(.system(size: 28, weight: .light))
                    .tracking(0.5)
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Sleep, HRV, stress, hydration \u{2014}\nall connected to your skin.")
                    .font(CelleuxType.body)
                    .foregroundStyle(CelleuxColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(CelleuxType.bodyLineSpacing)
                    .padding(.horizontal, CelleuxSpacing.sm)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(CelleuxSpring.luxury.delay(0.15), value: appeared)
            .padding(.horizontal, CelleuxSpacing.xl)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 2.0).delay(0.3)) {
                ringProgress = 0.82
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
            animateScore()
        }
    }

    private func animateScore() {
        let target = 82
        let duration: Double = 1.8
        let steps = 30
        let interval = duration / Double(steps)

        for step in 0...steps {
            let delay = 0.3 + interval * Double(step)
            let value = Int(Double(target) * (Double(step) / Double(steps)))
            Task {
                try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
                withAnimation(.snappy) {
                    scoreValue = value
                }
            }
        }
    }
}

// MARK: - Page 3: Intelligent Timing

struct ValuePropSmartTimingView: View {
    @State private var appeared: Bool = false
    @State private var activeDose: Int = -1

    private let doses: [(time: String, label: String, icon: String)] = [
        ("7:00 AM", "Morning Dose", "sunrise.fill"),
        ("2:00 PM", "Midday Boost", "sun.max.fill"),
        ("9:00 PM", "Night Repair", "moon.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                ForEach(Array(doses.enumerated()), id: \.offset) { idx, dose in
                    HStack(spacing: CelleuxSpacing.md) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        idx <= activeDose
                                            ? LinearGradient(colors: [Color.white.opacity(0.95), Color(hex: "F5F0E8")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [Color(hex: "F0EDE8"), Color(hex: "E6E3DE")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 52, height: 52)

                                Circle()
                                    .stroke(
                                        idx <= activeDose
                                            ? LinearGradient(colors: [Color(hex: "E8DCC8").opacity(0.8), Color(hex: "C9A96E").opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [Color.white.opacity(0.8), CelleuxColors.silverBorder.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 1
                                    )
                                    .frame(width: 52, height: 52)

                                Image(systemName: dose.icon)
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(idx <= activeDose ? CelleuxColors.goldSilverGradient : CelleuxColors.silverGradient)
                            }
                            .shadow(color: idx <= activeDose ? CelleuxColors.goldGlow.opacity(0.4) : .black.opacity(0.03), radius: 8, x: 0, y: 4)

                            if idx < doses.count - 1 {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(
                                        idx < activeDose
                                            ? CelleuxColors.warmGold.opacity(0.25)
                                            : CelleuxColors.silverBorder.opacity(0.2)
                                    )
                                    .frame(width: 2, height: 24)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(dose.time)
                                .font(CelleuxType.caption)
                                .tracking(CelleuxType.captionTracking)
                                .foregroundStyle(idx <= activeDose ? CelleuxColors.warmGold : CelleuxColors.textLabel)

                            Text(dose.label)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(CelleuxColors.textPrimary)

                            if idx <= activeDose {
                                Text("Optimized for your rhythm")
                                    .font(CelleuxType.caption)
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                        }

                        Spacer()

                        if idx <= activeDose {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(CelleuxColors.warmGold.opacity(0.7))
                                .symbolEffect(.bounce, value: activeDose)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(CelleuxSpacing.lg)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.92), Color.white.opacity(0.6), Color.white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 24)
                        .fill(CelleuxColors.glassHighlight)
                        .padding(1)
                        .mask(
                            VStack {
                                Rectangle().frame(height: 40)
                                Spacer()
                            }
                        )

                    RoundedRectangle(cornerRadius: 24)
                        .stroke(CelleuxColors.goldChromeBorder, lineWidth: 1.5)

                    RoundedRectangle(cornerRadius: 22.5)
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                        .padding(1.5)
                }
            )
            .celleuxDepthShadow()
            .padding(.horizontal, CelleuxSpacing.xl)
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: CelleuxSpacing.xxl)

            VStack(spacing: 14) {
                Text("Intelligent Timing")
                    .font(.system(size: 28, weight: .light))
                    .tracking(0.5)
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your supplements, timed to\nyour circadian rhythm.")
                    .font(CelleuxType.body)
                    .foregroundStyle(CelleuxColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(CelleuxType.bodyLineSpacing)
                    .padding(.horizontal, CelleuxSpacing.sm)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(CelleuxSpring.luxury.delay(0.15), value: appeared)
            .padding(.horizontal, CelleuxSpacing.xl)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
            animateDoses()
        }
    }

    private func animateDoses() {
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(CelleuxSpring.snappy) {
                activeDose = 0
            }
            try? await Task.sleep(for: .milliseconds(800))
            withAnimation(CelleuxSpring.snappy) {
                activeDose = 1
            }
            try? await Task.sleep(for: .milliseconds(800))
            withAnimation(CelleuxSpring.snappy) {
                activeDose = 2
            }
        }
    }
}
