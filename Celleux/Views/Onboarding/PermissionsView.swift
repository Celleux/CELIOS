import SwiftUI

struct PermissionsView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    @State private var appeared: Bool = false
    @State private var hapticTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: CelleuxSpacing.sm) {
                Text("Enable Your Intelligence")
                    .font(.system(size: 28, weight: .light))
                    .tracking(0.5)
                    .foregroundStyle(CelleuxColors.textPrimary)

                Text("Power up your skin analysis engine")
                    .font(CelleuxType.body)
                    .foregroundStyle(CelleuxColors.textSecondary)
            }
            .staggeredAppear(appeared: appeared, delay: 0)

            Spacer()
                .frame(height: CelleuxSpacing.xl)

            VStack(spacing: CelleuxSpacing.md) {
                permissionCard(
                    icon: "faceid",
                    title: "Face Scan Engine",
                    description: "ARKit-powered skin analysis with 10 precision metrics",
                    isEnabled: viewModel.cameraEnabled,
                    delay: 0.05
                ) {
                    hapticTrigger += 1
                    Task {
                        await viewModel.requestCameraPermission()
                    }
                }

                permissionCard(
                    icon: "heart.fill",
                    title: "Body Intelligence",
                    description: "Sleep, HRV, and recovery data power your Longevity Score",
                    isEnabled: viewModel.healthConnected,
                    delay: 0.1
                ) {
                    hapticTrigger += 1
                    Task {
                        await viewModel.requestHealthPermission()
                    }
                }

                permissionCard(
                    icon: "bell.badge.fill",
                    title: "Smart Reminders",
                    description: "Circadian-timed notifications for optimal supplement timing",
                    isEnabled: viewModel.notificationsEnabled,
                    delay: 0.15
                ) {
                    hapticTrigger += 1
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }
            }
            .padding(.horizontal, CelleuxSpacing.lg)

            Spacer()
            Spacer()

            VStack(spacing: 14) {
                Button {
                    hapticTrigger += 1
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(Premium3DButtonStyle())
                .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)

                Button {
                    onContinue()
                } label: {
                    Text("Skip for now")
                        .font(CelleuxType.caption)
                        .tracking(CelleuxType.captionTracking)
                        .foregroundStyle(CelleuxColors.silver)
                }
            }
            .staggeredAppear(appeared: appeared, delay: 0.25)
            .padding(.horizontal, CelleuxSpacing.lg)
            .padding(.bottom, 40)
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .task {
            await viewModel.checkExistingPermissions()
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
        }
    }

    private func permissionCard(
        icon: String,
        title: String,
        description: String,
        isEnabled: Bool,
        delay: Double,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: CelleuxSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 48, height: 48)

                    Circle()
                        .stroke(
                            isEnabled ? CelleuxColors.goldChromeBorder : CelleuxColors.chromeBorder,
                            lineWidth: 1
                        )
                        .frame(width: 48, height: 48)

                    if isEnabled {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .symbolEffect(.bounce, value: isEnabled)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(CelleuxColors.silver)
                    }
                }
                .shadow(color: isEnabled ? CelleuxColors.goldGlow.opacity(0.3) : .black.opacity(0.04), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(CelleuxColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isEnabled
                                ? LinearGradient(colors: [Color(hex: "E8DCC8"), Color(hex: "D4C4A0"), Color(hex: "C9A96E")], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(hex: "E8E6E3"), Color(hex: "DDD9D5")], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 50, height: 30)

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isEnabled
                                ? LinearGradient(colors: [Color(hex: "C9A96E").opacity(0.5), Color.white.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.white.opacity(0.5), CelleuxColors.silverBorder.opacity(0.2)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 0.5
                        )
                        .frame(width: 50, height: 30)

                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: isEnabled ? 10 : -10)
                }
            }
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.9), Color.white.opacity(0.55), Color.white.opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 20)
                        .fill(CelleuxColors.glassHighlight)
                        .padding(1)
                        .mask(
                            VStack {
                                Rectangle().frame(height: 30)
                                Spacer()
                            }
                        )

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isEnabled ?
                            CelleuxColors.goldChromeBorder :
                            CelleuxColors.chromeBorder,
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: isEnabled ? CelleuxColors.goldGlow.opacity(0.15) : .black.opacity(0.04), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 0.5)
        }
        .buttonStyle(PressableButtonStyle())
        .staggeredAppear(appeared: appeared, delay: delay)
    }
}
