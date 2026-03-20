import SwiftUI

struct WelcomeView: View {
    @Binding var showQRScanner: Bool
    let onLearnMore: () -> Void
    @State private var appeared: Bool = false
    @State private var logoScale: CGFloat = 0.8
    @State private var particles: [FloatingParticle] = []
    @State private var ringRotation: Double = 0

    var body: some View {
        ZStack {
            CelleuxMeshBackground()

            particleField
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
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
                            .scaleEffect(appeared ? 1.0 : 0.5)

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
                        .scaleEffect(logoScale)
                    }

                    Text("Celleux")
                        .font(.system(size: 44, weight: .thin))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .tracking(8)

                    Text("YOUR LONGEVITY COMPANION")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .tracking(1.5)
                }
                .staggeredAppear(appeared: appeared, delay: 0.1)

                Spacer()
                Spacer()

                VStack(spacing: 14) {
                    Button {
                        showQRScanner = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 18, weight: .light))
                            Text("I have AeonDerm")
                                .font(.system(size: 16, weight: .semibold))
                                .tracking(0.3)
                        }
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: showQRScanner)

                    Button {
                        onLearnMore()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Learn more")
                                .font(.system(size: 15, weight: .medium))
                                .tracking(0.3)
                        }
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(OutlineGlassButtonStyle())
                }
                .staggeredAppear(appeared: appeared, delay: 0.4)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            generateParticles()
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                appeared = true
                logoScale = 1.0
            }
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
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
                    .phaseAnimator([false, true]) { content, phase in
                        content
                            .offset(
                                x: phase ? CGFloat(idx % 2 == 0 ? 25 : -25) : 0,
                                y: phase ? CGFloat(idx % 3 == 0 ? -35 : 30) : 0
                            )
                            .opacity(phase ? particle.opacity * 1.5 : particle.opacity * 0.5)
                    } animation: { _ in
                        .easeInOut(duration: particle.speed)
                    }
            }
        }
        .allowsHitTesting(false)
    }
}

struct FloatingParticle {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let speed: Double
    let isViolet: Bool
}
