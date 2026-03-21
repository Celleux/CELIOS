import SwiftUI

struct AchievementUnlockOverlay: View {
    let achievement: AchievementDefinition
    let onDismiss: () -> Void
    @State private var appeared: Bool = false
    @State private var iconBounce: Bool = false
    @State private var particleBurst: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.55 : 0)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(appeared ? 1 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    CelleuxColors.warmGold.opacity(0.2),
                                    CelleuxColors.warmGold.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(appeared ? 1 : 0.5)

                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(
                                    AngularGradient(
                                        colors: [
                                            CelleuxColors.warmGold.opacity(0.7),
                                            CelleuxP3.champagne.opacity(0.5),
                                            Color.white.opacity(0.9),
                                            CelleuxColors.roseGold.opacity(0.6),
                                            CelleuxColors.warmGold.opacity(0.7)
                                        ],
                                        center: .center
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: CelleuxColors.warmGold.opacity(0.4), radius: 20, x: 0, y: 8)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CelleuxColors.roseGold, CelleuxColors.warmGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: iconBounce)

                    CelebrationParticleBurst(isActive: particleBurst)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 10) {
                    Text("ACHIEVEMENT UNLOCKED")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .tracking(2)

                    Text(achievement.title)
                        .font(CelleuxType.title1)
                        .tracking(CelleuxType.title1Tracking)
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text(achievement.subtitle)
                        .font(CelleuxType.body)
                        .foregroundStyle(CelleuxColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(CelleuxType.bodyLineSpacing)

                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(achievement.points) pts")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(CelleuxColors.warmGold)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)
            }
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
        }
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            withAnimation(CelleuxSpring.bouncy) {
                appeared = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                iconBounce.toggle()
                particleBurst = true
            }
        }
    }
}
