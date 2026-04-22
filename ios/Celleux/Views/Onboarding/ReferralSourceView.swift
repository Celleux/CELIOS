import SwiftUI

struct ReferralSourceView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    @State private var appeared: Bool = false
    @State private var hapticTrigger: Int = 0

    private let sources: [(id: String, label: String, icon: String)] = [
        ("tiktok", "TikTok", "play.rectangle.fill"),
        ("instagram", "Instagram", "camera.fill"),
        ("youtube", "YouTube", "play.tv.fill"),
        ("appstore", "App Store", "apple.logo"),
        ("friend", "Friend or family", "person.2.fill"),
        ("podcast", "Podcast", "waveform"),
        ("news", "News or article", "newspaper.fill"),
        ("other", "Other", "ellipsis.circle.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: CelleuxSpacing.lg) {
                    VStack(spacing: CelleuxSpacing.sm) {
                        Text("Where did you\nhear about us?")
                            .font(.system(size: 30, weight: .light))
                            .tracking(0.5)
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)

                        Text("Helps us reach more people like you")
                            .font(CelleuxType.body)
                            .foregroundStyle(CelleuxColors.textSecondary)
                    }
                    .staggeredAppear(appeared: appeared, delay: 0)
                    .padding(.top, CelleuxSpacing.xxl)

                    VStack(spacing: 10) {
                        ForEach(Array(sources.enumerated()), id: \.offset) { idx, source in
                            sourceRow(source)
                                .staggeredAppear(appeared: appeared, delay: 0.08 + Double(idx) * 0.04)
                        }
                    }
                    .padding(.horizontal, CelleuxSpacing.lg)

                    Spacer().frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)

            Button {
                hapticTrigger += 1
                onContinue()
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(Premium3DButtonStyle())
            .opacity(viewModel.referralSource != nil ? 1.0 : 0.5)
            .disabled(viewModel.referralSource == nil)
            .padding(.horizontal, CelleuxSpacing.lg)
            .padding(.bottom, 40)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)
        }
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
        }
    }

    private func sourceRow(_ source: (id: String, label: String, icon: String)) -> some View {
        let isSelected = viewModel.referralSource == source.id
        return Button {
            withAnimation(CelleuxSpring.snappy) {
                viewModel.referralSource = source.id
            }
            hapticTrigger += 1
        } label: {
            HStack(spacing: CelleuxSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(colors: [Color.white.opacity(0.95), Color(hex: "F5F0E8")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 40, height: 40)

                    Circle()
                        .stroke(isSelected ? CelleuxColors.goldChromeBorder : CelleuxColors.chromeBorder, lineWidth: 1)
                        .frame(width: 40, height: 40)

                    Image(systemName: source.icon)
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(isSelected ? CelleuxColors.goldSilverGradient : CelleuxColors.silverGradient)
                }

                Text(source.label)
                    .font(.system(size: 16, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(CelleuxColors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .symbolEffect(.bounce, value: isSelected)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.85) : Color.white.opacity(0.55))
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? CelleuxColors.goldChromeBorder : CelleuxColors.chromeBorder, lineWidth: isSelected ? 1.5 : 1)
                }
            )
            .shadow(color: isSelected ? CelleuxColors.goldGlow.opacity(0.2) : .black.opacity(0.03), radius: isSelected ? 10 : 4, x: 0, y: isSelected ? 5 : 2)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
