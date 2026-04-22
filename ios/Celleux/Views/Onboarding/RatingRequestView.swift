import SwiftUI
import StoreKit

struct RatingRequestView: View {
    let onContinue: () -> Void

    @Environment(\.requestReview) private var requestReview
    @State private var appeared: Bool = false
    @State private var filledStars: Int = 0
    @State private var showQuote: Bool = false
    @State private var hapticTrigger: Int = 0
    @State private var reviewRequested: Bool = false

    private let reviews: [(name: String, location: String, quote: String)] = [
        ("Isabella M.", "Milan", "Celleux is the only skin app that actually felt personal. My skin has never looked better."),
        ("Daniel K.", "Zurich", "I've tried them all. This is the first one that treats skin like biology, not marketing."),
        ("Amara O.", "Paris", "Three weeks in and my dermatologist noticed. That's never happened before.")
    ]

    @State private var currentReview: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: CelleuxSpacing.lg) {
                    header
                        .padding(.top, CelleuxSpacing.xxl)
                        .staggeredAppear(appeared: appeared, delay: 0)

                    starsCard
                        .padding(.horizontal, CelleuxSpacing.lg)
                        .staggeredAppear(appeared: appeared, delay: 0.15)

                    reviewCarousel
                        .padding(.horizontal, CelleuxSpacing.lg)
                        .staggeredAppear(appeared: appeared, delay: 0.25)

                    trustBadges
                        .padding(.horizontal, CelleuxSpacing.lg)
                        .staggeredAppear(appeared: appeared, delay: 0.35)

                    Spacer().frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)

            continueButton
                .padding(.horizontal, CelleuxSpacing.lg)
                .padding(.bottom, 40)
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: hapticTrigger)
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
            animateStars()
            rotateReviews()
        }
    }

    private var header: some View {
        VStack(spacing: CelleuxSpacing.sm) {
            Text("HELP US GROW")
                .font(CelleuxType.label)
                .tracking(CelleuxType.labelTracking)
                .foregroundStyle(CelleuxColors.warmGold.opacity(0.85))

            Text("Give us a rating on\nthe App Store")
                .font(.system(size: 28, weight: .light))
                .tracking(0.5)
                .foregroundStyle(CelleuxColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Celleux is built by a small team obsessed\nwith skin longevity. Your rating helps us\nreach more people like you.")
                .font(CelleuxType.body)
                .foregroundStyle(CelleuxColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CelleuxType.bodyLineSpacing)
                .padding(.horizontal, CelleuxSpacing.md)
                .padding(.top, 4)
        }
    }

    private var starsCard: some View {
        GlassCard(cornerRadius: 24, depth: .elevated) {
            VStack(spacing: 18) {
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < filledStars ? "star.fill" : "star")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(i < filledStars ? AnyShapeStyle(CelleuxColors.goldSilverGradient) : AnyShapeStyle(CelleuxColors.silver.opacity(0.3)))
                            .shadow(color: i < filledStars ? CelleuxColors.goldGlow : .clear, radius: 8, x: 0, y: 2)
                            .scaleEffect(i < filledStars ? 1.0 : 0.85)
                            .animation(CelleuxSpring.bouncy.delay(Double(i) * 0.08), value: filledStars)
                    }
                }
                .padding(.top, 4)

                VStack(spacing: 6) {
                    Text("Rate Celleux")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text("It takes less than 5 seconds\nand means the world to us")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(CelleuxColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }

    private var reviewCarousel: some View {
        let review = reviews[currentReview]
        return GlassCard(cornerRadius: 22, depth: .subtle) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                    }
                    Spacer()
                }

                Text("\u{201C}\(review.quote)\u{201D}")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(currentReview)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                HStack(spacing: 8) {
                    Circle()
                        .fill(CelleuxColors.goldSilverGradient)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(review.name.prefix(1)))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(review.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textPrimary)

                        Text(review.location)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    Spacer()
                }
            }
        }
    }

    private var trustBadges: some View {
        HStack(spacing: 0) {
            badge(icon: "lock.shield.fill", label: "Privacy first")
            Divider().frame(height: 32).overlay(CelleuxColors.silverBorder.opacity(0.3))
            badge(icon: "sparkles", label: "Editor's pick")
            Divider().frame(height: 32).overlay(CelleuxColors.silverBorder.opacity(0.3))
            badge(icon: "checkmark.seal.fill", label: "Derm-reviewed")
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CelleuxColors.goldChromeBorder, lineWidth: 1)
        )
    }

    private func badge(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(CelleuxColors.iconGoldGradient)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(CelleuxColors.textLabel)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }

    private var continueButton: some View {
        VStack(spacing: 12) {
            Button {
                hapticTrigger += 1
                if !reviewRequested {
                    reviewRequested = true
                    requestReview()
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    onContinue()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Rate Celleux")
                        .font(.system(size: 17, weight: .medium))
                        .tracking(0.5)
                }
                .foregroundStyle(CelleuxColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .buttonStyle(Premium3DButtonStyle())

            Button {
                hapticTrigger += 1
                onContinue()
            } label: {
                Text("Maybe later")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(CelleuxColors.textLabel)
                    .padding(.vertical, 8)
            }
        }
    }

    private func animateStars() {
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            for i in 1...5 {
                withAnimation(CelleuxSpring.bouncy) {
                    filledStars = i
                }
                hapticTrigger += 1
                try? await Task.sleep(for: .milliseconds(120))
            }
            withAnimation(CelleuxSpring.luxury) {
                showQuote = true
            }
        }
    }

    private func rotateReviews() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentReview = (currentReview + 1) % reviews.count
                }
            }
        }
    }
}
