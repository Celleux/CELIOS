import SwiftUI

struct OnboardingView: View {
    @Environment(\.completeOnboarding) private var completeOnboarding
    @State private var viewModel = OnboardingViewModel()
    @State private var transitionDirection: Edge = .trailing

    var body: some View {
        ZStack {
            CelleuxMeshBackground()

            currentPageView
                .id(viewModel.currentPage)
                .transition(.asymmetric(
                    insertion: .move(edge: transitionDirection).combined(with: .opacity),
                    removal: .move(edge: transitionDirection == .trailing ? .leading : .trailing).combined(with: .opacity)
                ))

            if viewModel.currentPage.showDots {
                VStack {
                    Spacer()
                    pageIndicator
                        .padding(.bottom, 120)
                }
            }

            if viewModel.currentPage.showSkip && viewModel.currentPage != .welcome {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            navigateForward()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    Spacer()
                }
            }

            if viewModel.currentPage.isCarousel {
                VStack {
                    Spacer()
                    Button {
                        navigateForward()
                    } label: {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .tracking(0.3)
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.currentPage)
        .fullScreenCover(isPresented: $viewModel.showQRScanner) {
            QRScanView(
                isPresented: $viewModel.showQRScanner,
                scanSuccess: $viewModel.qrScanSuccess,
                onSuccess: {
                    transitionDirection = .trailing
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
                onLearnMore: {
                    navigateForward()
                }
            )
        case .skinTracking:
            ValuePropSkinTrackingView()
        case .longevityScore:
            ValuePropLongevityScoreView()
        case .smartTiming:
            ValuePropSmartTimingView()
        case .personalization:
            PersonalizationView(viewModel: viewModel) {
                navigateForward()
            }
        case .permissions:
            PermissionsView(viewModel: viewModel) {
                completeOnboarding()
            }
        }
    }

    private func navigateForward() {
        transitionDirection = .trailing
        viewModel.nextPage()
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<OnboardingPage.dotCount, id: \.self) { index in
                Capsule()
                    .fill(
                        index == viewModel.currentPage.dotIndex
                            ? CelleuxColors.warmGold
                            : CelleuxColors.silver.opacity(0.25)
                    )
                    .frame(
                        width: index == viewModel.currentPage.dotIndex ? 24 : 8,
                        height: 8
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.currentPage)
            }
        }
    }
}
