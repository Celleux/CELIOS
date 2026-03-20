import SwiftUI

struct WelcomeView: View {
    @Binding var showQRScanner: Bool
    let onBegin: () -> Void
    @State private var phase: WelcomePhase = .hidden
    @State private var particles: [FloatingParticle] = []
    @State private var ringRotation: Double = 0
    @State private var dividerTrim: CGFloat = 0

    var body: some View {
        ZStack {
            CelleuxMeshBackground()

            particleField
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                logoSection

                Spacer()
                    .frame(height: CelleuxSpacing.xl)

                titleSection

                Spacer()
                    .frame(height: CelleuxSpacing.lg)

                goldDivider

                Spacer()

                buttonsSection

                Spacer()
                    .frame(height: 56)
            }
        }
        .onAppear {
            generateParticles()
            startRotation()
            startPhaseSequence()
        }
    }

    private var logoSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [CelleuxColors.warmGold.opacity(0.06), CelleuxColors.warmGold.opacity(0.0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(phase.logoVisible ? 1.0 : 0.5)
                .opacity(phase.logoVisible ? 1 : 0)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "E8DCC8").opacity(0.4),
                            Color(hex: "C9A96E").opacity(0.15),
                            Color.white.opacity(0.3),
                            Color(hex: "D4C4A0").opacity(0.1),
                            Color(hex: "E8DCC8").opacity(0.35)
                        ],
                        center: .center
                    ),
                    lineWidth: 0.5
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(ringRotation))

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "C9A96E").opacity(0.2),
                            Color.white.opacity(0.1),
                            Color(hex: "D4C4A0").opacity(0.15),
                            Color(hex: "C9A96E").opacity(0.18)
                        ],
                        center: .center
                    ),
                    lineWidth: 0.5
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-ringRotation * 0.7))

            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color(hex: "F5F0E8")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(hex: "E8DCC8").opacity(0.7),
                                    Color(hex: "C9A96E").opacity(0.3),
                                    Color.white.opacity(0.5),
                                    Color(hex: "D4C4A0").opacity(0.25),
                                    Color(hex: "E8DCC8").opacity(0.6)
                                ],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 100, height: 100)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: 98, height: 98)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(CelleuxColors.goldSilverGradient)
                }
                .shadow(color: CelleuxColors.goldGlow, radius: 20, x: 0, y: 8)
            }
            .scaleEffect(phase.logoVisible ? 1.0 : 0.8)
        }
        .opacity(phase.logoVisible ? 1 : 0)
        .animation(CelleuxSpring.luxury, value: phase)
    }

    private var titleSection: some View {
        VStack(spacing: CelleuxSpacing.sm) {
            Text("CELLEUX")
                .font(CelleuxType.display)
                .tracking(8)
                .foregroundStyle(CelleuxColors.warmGold)

            Text("Your Skin's Daily Intelligence")
                .font(CelleuxType.title1)
                .tracking(CelleuxType.title1Tracking)
                .foregroundStyle(CelleuxColors.silver)
                .multilineTextAlignment(.center)
        }
        .opacity(phase.textVisible ? 1 : 0)
        .offset(y: phase.textVisible ? 0 : 15)
        .animation(CelleuxSpring.luxury.delay(0.2), value: phase)
    }

    private var goldDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        CelleuxColors.warmGold.opacity(0.0),
                        CelleuxColors.warmGold.opacity(0.6),
                        CelleuxColors.champagneGold.opacity(0.8),
                        CelleuxColors.warmGold.opacity(0.6),
                        CelleuxColors.warmGold.opacity(0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 180, height: 1)
            .mask(
                Rectangle()
                    .frame(width: 180)
                    .offset(x: -90 + 180 * dividerTrim)
                    .frame(width: 180, alignment: .leading)
                    .clipped()
            )
            .opacity(phase.lineVisible ? 1 : 0)
    }

    private var buttonsSection: some View {
        VStack(spacing: 14) {
            Button {
                onBegin()
            } label: {
                Text("Begin")
                    .font(.system(size: 17, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
            .buttonStyle(Premium3DButtonStyle())
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.8), trigger: phase)

            Button {
                showQRScanner = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 16, weight: .light))
                    Text("I have AeonDerm")
                        .font(.system(size: 15, weight: .regular))
                        .tracking(0.3)
                }
                .foregroundStyle(CelleuxColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(OutlineGlassButtonStyle())
        }
        .padding(.horizontal, CelleuxSpacing.lg)
        .opacity(phase.buttonVisible ? 1 : 0)
        .scaleEffect(phase.buttonVisible ? 1.0 : 0.92)
        .animation(CelleuxSpring.luxury.delay(0.6), value: phase)
    }

    private func startPhaseSequence() {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(CelleuxSpring.luxury) {
                phase = .logoIn
            }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(CelleuxSpring.luxury) {
                phase = .textIn
            }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.8)) {
                phase = .lineIn
                dividerTrim = 1.0
            }
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(CelleuxSpring.luxury) {
                phase = .complete
            }
        }
    }

    private func startRotation() {
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }

    private func generateParticles() {
        particles = (0..<18).map { _ in
            FloatingParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 3...12),
                opacity: Double.random(in: 0.03...0.10),
                speed: Double.random(in: 8...20),
                isViolet: Bool.random()
            )
        }
    }

    private var particleField: some View {
        GeometryReader { geo in
            ForEach(Array(particles.enumerated()), id: \.offset) { idx, particle in
                Circle()
                    .fill(
                        particle.isViolet
                            ? CelleuxColors.warmGold.opacity(particle.opacity)
                            : CelleuxColors.silver.opacity(particle.opacity)
                    )
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: particle.size * 0.4)
                    .position(
                        x: particle.x * geo.size.width,
                        y: particle.y * geo.size.height
                    )
                    .phaseAnimator([false, true]) { content, animPhase in
                        content
                            .offset(
                                x: animPhase ? CGFloat(idx % 2 == 0 ? 25 : -25) : 0,
                                y: animPhase ? CGFloat(idx % 3 == 0 ? -35 : 30) : 0
                            )
                            .opacity(animPhase ? particle.opacity * 1.5 : particle.opacity * 0.5)
                    } animation: { _ in
                        .easeInOut(duration: particle.speed)
                    }
            }
        }
        .allowsHitTesting(false)
    }
}

private enum WelcomePhase: Int {
    case hidden
    case logoIn
    case textIn
    case lineIn
    case complete

    var logoVisible: Bool { rawValue >= WelcomePhase.logoIn.rawValue }
    var textVisible: Bool { rawValue >= WelcomePhase.textIn.rawValue }
    var lineVisible: Bool { rawValue >= WelcomePhase.lineIn.rawValue }
    var buttonVisible: Bool { rawValue >= WelcomePhase.complete.rawValue }
}

struct FloatingParticle {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let speed: Double
    let isViolet: Bool
}
