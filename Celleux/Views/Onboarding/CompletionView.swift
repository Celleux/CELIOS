import SwiftUI

struct CompletionView: View {
    let onFinish: () -> Void
    @State private var appeared: Bool = false
    @State private var celebrationActive: Bool = false
    @State private var ringGlow: Bool = false
    @State private var hapticFired: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [CelleuxColors.warmGold.opacity(0.06), CelleuxColors.warmGold.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1 : 0)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                CelleuxColors.silverLight.opacity(0.4),
                                CelleuxColors.warmGold.opacity(0.3),
                                Color.white.opacity(0.6),
                                CelleuxColors.champagneGold.opacity(0.35),
                                CelleuxColors.silverLight.opacity(0.4)
                            ],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: CelleuxColors.goldGlow.opacity(ringGlow ? 0.4 : 0.1), radius: ringGlow ? 20 : 8, x: 0, y: 0)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color(hex: "F5F0E8")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(CelleuxColors.goldChromeBorder, lineWidth: 1.5)
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(CelleuxColors.goldSilverGradient)
                }
                .shadow(color: CelleuxColors.goldGlow, radius: 24, x: 0, y: 8)
                .scaleEffect(appeared ? 1.0 : 0.3)

                CelebrationParticleBurst(isActive: celebrationActive)
            }
            .animation(CelleuxSpring.bouncy, value: appeared)

            Spacer()
                .frame(height: CelleuxSpacing.xxl)

            VStack(spacing: CelleuxSpacing.md) {
                Text("You're Ready")
                    .font(.system(size: 32, weight: .light))
                    .tracking(1)
                    .foregroundStyle(CelleuxColors.textPrimary)

                Text("Your first scan will establish\nyour personal baseline")
                    .font(CelleuxType.body)
                    .foregroundStyle(CelleuxColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(CelleuxType.bodyLineSpacing)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(CelleuxSpring.luxury.delay(0.3), value: appeared)

            Spacer()
            Spacer()

            Button {
                onFinish()
            } label: {
                HStack(spacing: 10) {
                    Text("Take Your First Scan")
                        .font(.system(size: 17, weight: .medium))
                        .tracking(0.5)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(CelleuxColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .buttonStyle(Premium3DButtonStyle())
            .padding(.horizontal, CelleuxSpacing.lg)
            .padding(.bottom, 56)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1.0 : 0.92)
            .animation(CelleuxSpring.luxury.delay(0.5), value: appeared)
        }
        .sensoryFeedback(.success, trigger: hapticFired)
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation(CelleuxSpring.bouncy) {
                    appeared = true
                }
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                    celebrationActive = true
                }
                hapticFired = true
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    ringGlow = true
                }
            }
        }
    }
}
