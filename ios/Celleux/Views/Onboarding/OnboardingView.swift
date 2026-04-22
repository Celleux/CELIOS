import SwiftUI

struct OnboardingView: View {
    @Environment(\.completeOnboarding) private var completeOnboarding
    @State private var viewModel = OnboardingViewModel()
    @Namespace private var dotNamespace

    var body: some View {
        ZStack {
            CelleuxMeshBackground()

            currentPageView
                .id(viewModel.currentPage)
                .transition(.blurReplace)

            VStack {
                if viewModel.currentPage.showProgress {
                    progressBar
                        .padding(.top, 8)
                }

                if viewModel.currentPage.showSkip {
                    HStack {
                        Spacer()
                        Button {
                            navigateForward()
                        } label: {
                            Text("Skip")
                                .font(CelleuxType.caption)
                                .tracking(CelleuxType.captionTracking)
                                .foregroundStyle(CelleuxColors.silver)
                                .padding(.horizontal, CelleuxSpacing.md)
                                .padding(.vertical, CelleuxSpacing.sm)
                        }
                    }
                    .padding(.horizontal, CelleuxSpacing.md)
                }

                Spacer()

                if viewModel.currentPage.showDots {
                    pageIndicator
                        .padding(.bottom, 120)
                }
            }

            if viewModel.currentPage.isCarousel {
                VStack {
                    Spacer()
                    Button {
                        navigateForward()
                    } label: {
                        Text("Continue")
                            .font(.system(size: 16, weight: .medium))
                            .tracking(0.3)
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .padding(.horizontal, CelleuxSpacing.lg)
                    .padding(.bottom, 40)
                }
            }
        }
        .animation(CelleuxSpring.luxury, value: viewModel.currentPage)
        .fullScreenCover(isPresented: $viewModel.showQRScanner) {
            QRScanView(
                isPresented: $viewModel.showQRScanner,
                scanSuccess: $viewModel.qrScanSuccess,
                onSuccess: {
                    viewModel.goToPersonalization()
                }
            )
        }
    }

    @ViewBuilder
    private var currentPageView: some View {
        switch viewModel.currentPage {
        case .welcome:
            WelcomeView(
                showQRScanner: $viewModel.showQRScanner,
                onBegin: {
                    navigateForward()
                }
            )
        case .skinTracking:
            ValuePropSkinTrackingView()
        case .longevityScore:
            ValuePropLongevityScoreView()
        case .smartTiming:
            ValuePropSmartTimingView()
        case .socialProof:
            SocialProofView {
                navigateForward()
            }
        case .personalization:
            PersonalizationView(viewModel: viewModel) {
                navigateForward()
            }
        case .referralSource:
            ReferralSourceView(viewModel: viewModel) {
                navigateForward()
            }
        case .analyzing:
            AnalyzingView(viewModel: viewModel) {
                navigateForward()
            }
        case .projectedResults:
            ProjectedResultsView(viewModel: viewModel) {
                navigateForward()
            }
        case .permissions:
            PermissionsView(viewModel: viewModel) {
                navigateForward()
            }
        case .completion:
            CompletionView {
                completeOnboarding()
            }
        }
    }

    private func navigateForward() {
        viewModel.nextPage()
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(CelleuxColors.silver.opacity(0.12))
                    .frame(height: 2)

                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.champagneGold.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * viewModel.progressFraction, height: 2)
                    .animation(CelleuxSpring.luxury, value: viewModel.progressFraction)
            }
        }
        .frame(height: 2)
        .padding(.horizontal, CelleuxSpacing.lg)
    }

    private var pageIndicator: some View {
        HStack(spacing: CelleuxSpacing.sm) {
            ForEach(0..<OnboardingPage.dotCount, id: \.self) { index in
                let isActive = index == viewModel.currentPage.dotIndex

                Capsule()
                    .fill(isActive ? CelleuxColors.warmGold : CelleuxColors.silver.opacity(0.25))
                    .frame(width: isActive ? 24 : 8, height: 8)
                    .animation(CelleuxSpring.snappy, value: viewModel.currentPage)
            }
        }
    }
}
