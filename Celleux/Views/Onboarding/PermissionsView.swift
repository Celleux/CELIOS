import SwiftUI

struct PermissionsView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    @State private var appeared: Bool = false
    @State private var hapticTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("Almost there")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(CelleuxColors.textPrimary)

                Text("Enable features for the best experience")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(CelleuxColors.textSecondary)
            }
            .staggeredAppear(appeared: appeared, delay: 0)

            Spacer()
                .frame(height: 40)

            VStack(spacing: 16) {
                permissionCard(
                    icon: "applewatch",
                    title: "Apple Watch & Health",
                    description: "Track sleep, HRV, and recovery to power your Longevity Score",
                    isEnabled: viewModel.healthConnected,
                    delay: 0.05
                ) {
                    hapticTrigger += 1
                    Task {
                        await viewModel.requestHealthPermission()
                    }
                }

                permissionCard(
                    icon: "bell.badge",
                    title: "Notifications",
                    description: "Gentle reminders for your optimal supplement timing",
                    isEnabled: viewModel.notificationsEnabled,
                    delay: 0.1
                ) {
                    hapticTrigger += 1
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }

                permissionCard(
                    icon: "camera",
                    title: "Camera",
                    description: "Your photos never leave your device — all analysis is on-device",
                    isEnabled: viewModel.cameraEnabled,
                    delay: 0.15
                ) {
                    hapticTrigger += 1
                    Task {
                        await viewModel.requestCameraPermission()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()

            VStack(spacing: 14) {
                Button {
                    onContinue()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(0.3)
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(GlassButtonStyle())
                .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)

                Button {
                    onContinue()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
            .staggeredAppear(appeared: appeared, delay: 0.25)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .task {
            await viewModel.checkExistingPermissions()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
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
            HStack(spacing: 16) {
                GlowingAccentBadge(icon, color: isEnabled ? CelleuxColors.warmGold : CelleuxColors.silver, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
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
