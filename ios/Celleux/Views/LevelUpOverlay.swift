import SwiftUI

struct LevelUpOverlay: View {
    let level: CelleuxLevel
    let onDismiss: () -> Void

    @State private var appeared: Bool = false
    @State private var ringSpin: Double = 0
    @State private var burstActive: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.55 : 0)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    CelleuxColors.warmGold,
                                    CelleuxColors.roseGold,
                                    CelleuxColors.champagneGold,
                                    CelleuxColors.warmGold
                                ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(ringSpin))

                    VStack(spacing: 2) {
                        Text("LEVEL")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .tracking(2.0)
                        Text("\(level.level)")
                            .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                            .foregroundStyle(CelleuxColors.goldGradient)
                    }

                    if burstActive {
                        CelebrationParticleBurst(isActive: burstActive)
                            .allowsHitTesting(false)
                    }
                }

                VStack(spacing: 6) {
                    Text("Level Up")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(level.title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(CelleuxColors.warmGold)
                        .textCase(.uppercase)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Continue")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(CelleuxColors.goldGradient))
                }
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringSpin = 360
            }
            burstActive = true
        }
    }
}
