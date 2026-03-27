import SwiftUI

struct GoldSkeletonCard: View {
    let style: SkeletonStyle

    enum SkeletonStyle {
        case scoreHero
        case metricRow
        case healthSnapshot
        case protocolCard
        case chartCard
        case compact
    }

    var body: some View {
        Group {
            switch style {
            case .scoreHero:
                scoreHeroSkeleton
            case .metricRow:
                metricRowSkeleton
            case .healthSnapshot:
                healthSnapshotSkeleton
            case .protocolCard:
                protocolCardSkeleton
            case .chartCard:
                chartCardSkeleton
            case .compact:
                compactSkeleton
            }
        }
        .skeletonShimmer()
    }

    private var scoreHeroSkeleton: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 22) {
                HStack {
                    skeletonPill(width: 160, height: 14)
                    Spacer()
                    skeletonPill(width: 12, height: 12)
                }

                Circle()
                    .fill(skeletonFill)
                    .frame(width: 172, height: 172)

                VStack(spacing: 8) {
                    skeletonPill(width: 100, height: 12)
                    skeletonPill(width: 140, height: 14)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var metricRowSkeleton: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(skeletonFill)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                skeletonPill(width: 100, height: 14)
                skeletonPill(width: 60, height: 11)
            }

            Spacer()

            Circle()
                .fill(skeletonFill)
                .frame(width: 34, height: 34)

            skeletonPill(width: 30, height: 16)

            skeletonPill(width: 8, height: 12)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }

    private var healthSnapshotSkeleton: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    skeletonPill(width: 60, height: 11)
                    skeletonPill(width: 50, height: 28)
                    skeletonPill(width: 80, height: 11)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(skeletonFill)
                        .frame(height: 28)
                }
                .frame(width: 150)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.85))
                )
            }
        }
    }

    private var protocolCardSkeleton: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    skeletonPill(width: 130, height: 12)
                    Spacer()
                    skeletonPill(width: 40, height: 12)
                }

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(skeletonFill)
                    .frame(height: 5)

                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in
                        HStack(spacing: 14) {
                            Circle()
                                .fill(skeletonFill)
                                .frame(width: 44, height: 44)

                            VStack(alignment: .leading, spacing: 4) {
                                skeletonPill(width: 60, height: 11)
                                skeletonPill(width: 140, height: 15)
                                skeletonPill(width: 80, height: 12)
                            }

                            Spacer()
                        }
                        .padding(.bottom, i < 2 ? 12 : 0)
                    }
                }
            }
        }
    }

    private var chartCardSkeleton: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    skeletonPill(width: 150, height: 12)
                    Spacer()
                    skeletonPill(width: 12, height: 12)
                }

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(skeletonFill)
                    .frame(height: 160)
            }
        }
    }

    private var compactSkeleton: some View {
        CompactGlassCard {
            HStack(spacing: 12) {
                Circle()
                    .fill(skeletonFill)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    skeletonPill(width: 100, height: 14)
                    skeletonPill(width: 140, height: 11)
                }

                Spacer()
            }
        }
    }

    private func skeletonPill(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(skeletonFill)
            .frame(width: width, height: height)
    }

    private var skeletonFill: Color {
        Color(.displayP3, red: 0.88, green: 0.86, blue: 0.82).opacity(0.4)
    }
}

struct LoadingTransitionModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isLoading ? 0 : 1)
            .animation(.easeInOut(duration: 0.35), value: isLoading)
    }
}

extension View {
    func loadingTransition(isLoading: Bool) -> some View {
        modifier(LoadingTransitionModifier(isLoading: isLoading))
    }
}
