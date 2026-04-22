import SwiftUI

struct SocialProofView: View {
    let onContinue: () -> Void
    @State private var appeared: Bool = false
    @State private var starBounce: Bool = false
    @State private var hapticTrigger: Int = 0

    private let testimonials: [(name: String, handle: String, quote: String, stars: Int)] = [
        ("Sophia R.", "34, NYC", "My skin score jumped 18 points in three weeks. I finally understand what my skin actually needs.", 5),
        ("Marcus T.", "41, LA", "The circadian timing changed everything. My supplements finally work with my body, not against it.", 5),
        ("Elena K.", "29, London", "It's like having a dermatologist in my pocket. Every scan reveals something new.", 5)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: CelleuxSpacing.lg) {
                    ratingHeader
                        .padding(.top, CelleuxSpacing.xxl)
                        .staggeredAppear(appeared: appeared, delay: 0)

                    VStack(spacing: 14) {
                        Text("Trusted by skincare\nenthusiasts worldwide")
                            .font(.system(size: 26, weight: .light))
                            .tracking(0.5)
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        Text("Join 120,000+ people using Celleux to decode their skin.")
                            .font(CelleuxType.body)
                            .foregroundStyle(CelleuxColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, CelleuxSpacing.md)
                    }
                    .staggeredAppear(appeared: appeared, delay: 0.08)

                    VStack(spacing: CelleuxSpacing.md) {
                        ForEach(Array(testimonials.enumerated()), id: \.offset) { idx, item in
                            testimonialCard(item)
                                .staggeredAppear(appeared: appeared, delay: 0.14 + Double(idx) * 0.07)
                        }
                    }
                    .padding(.horizontal, CelleuxSpacing.lg)

                    metricsRow
                        .padding(.horizontal, CelleuxSpacing.lg)
                        .staggeredAppear(appeared: appeared, delay: 0.4)

                    Spacer().frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)

            continueButton
                .padding(.horizontal, CelleuxSpacing.lg)
                .padding(.bottom, 40)
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.spring(duration: 0.6, bounce: 0.5)) {
                    starBounce = true
                }
            }
        }
    }

    private var ratingHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(CelleuxColors.goldSilverGradient)
                        .shadow(color: CelleuxColors.goldGlow, radius: 6, x: 0, y: 2)
                        .scaleEffect(starBounce ? 1.0 : 0.6)
                        .opacity(starBounce ? 1 : 0)
                        .animation(CelleuxSpring.bouncy.delay(Double(i) * 0.08), value: starBounce)
                }
            }

            HStack(spacing: 8) {
                Text("4.9")
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(CelleuxColors.textPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("App Store")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(CelleuxColors.textLabel)
                        .textCase(.uppercase)

                    Text("12,483 ratings")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(CelleuxColors.textSecondary)
                }
            }
        }
    }

    private func testimonialCard(_ item: (name: String, handle: String, quote: String, stars: Int)) -> some View {
        GlassCard(cornerRadius: 22, depth: .subtle) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 3) {
                    ForEach(0..<item.stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                    }
                    Spacer()
                }

                Text("\u{201C}\(item.quote)\u{201D}")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Circle()
                        .fill(CelleuxColors.goldSilverGradient)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(item.name.prefix(1)))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textPrimary)

                        Text(item.handle)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    Spacer()
                }
            }
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 0) {
            metric(value: "120K+", label: "Users")
            Divider().frame(height: 32).overlay(CelleuxColors.silverBorder.opacity(0.3))
            metric(value: "2.8M", label: "Scans")
            Divider().frame(height: 32).overlay(CelleuxColors.silverBorder.opacity(0.3))
            metric(value: "94%", label: "See results")
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CelleuxColors.goldChromeBorder, lineWidth: 1)
        )
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(CelleuxColors.textPrimary)

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(CelleuxColors.textLabel)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var continueButton: some View {
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
        .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)
    }
}
