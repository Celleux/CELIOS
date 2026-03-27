import SwiftUI

struct AgingSimulationView: View {
    let result: SkinScanResult
    let capturedImage: UIImage?
    let onDismiss: () -> Void

    @State private var viewModel = AgingSimulationViewModel()
    @State private var sliderPosition: CGFloat = 0.5
    @State private var appeared: Bool = false
    @State private var scoresAppeared: Bool = false
    @State private var yearSelectionTrigger: Int = 0
    @State private var shareImage: UIImage?
    @State private var showShareSheet: Bool = false
    @State private var isGeneratingShare: Bool = false

    var body: some View {
        ZStack {
            Color(.displayP3, red: 0.06, green: 0.06, blue: 0.10)
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [CelleuxColors.warmGold.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .offset(y: -100)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 8)

                if viewModel.isProcessing {
                    Spacer()
                    processingIndicator
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            if capturedImage != nil {
                                faceComparisonSlider
                                    .padding(.top, 12)
                            } else {
                                placeholderFaceView
                                    .padding(.top, 12)
                            }

                            yearSelector

                            projectedScoreCards

                            shareButton

                            disclaimerText
                                .padding(.bottom, 32)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(image: image)
            }
        }
        .sensoryFeedback(.selection, trigger: yearSelectionTrigger)
        .onAppear {
            viewModel.configure(result: result, capturedImage: capturedImage)
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation(CelleuxSpring.luxury) {
                    scoresAppeared = true
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("AGING SIMULATION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CelleuxColors.warmGold)
                    .tracking(2)

                Text("Predict Your Skin\u{2019}s Future")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            Spacer()

            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Processing

    private var processingIndicator: some View {
        VStack(spacing: 16) {
            AnalyzingBrainView(isActive: true)

            Text("Generating Simulation...")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CelleuxColors.warmGold)

            Text("Applying aging trajectory models")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))
        }
    }

    // MARK: - Face Comparison Slider

    private var faceComparisonSlider: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height: CGFloat = 380

            ZStack {
                if let currentImg = viewModel.currentRateImage {
                    Image(uiImage: currentImg)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                        .allowsHitTesting(false)
                }

                if let routineImg = viewModel.withRoutineImage {
                    Image(uiImage: routineImg)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                        .allowsHitTesting(false)
                        .clipShape(SliderClipShape(position: sliderPosition))
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [CelleuxColors.warmGold.opacity(0.8), CelleuxColors.champagneGold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: height)
                    .position(x: width * sliderPosition, y: height / 2)
                    .shadow(color: CelleuxColors.goldGlow, radius: 8, x: 0, y: 0)

                sliderHandle(width: width, height: height)

                scenarioLabels
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 10)

                yearBadge
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 10)
            }
            .frame(height: height)
            .clipShape(.rect(cornerRadius: 20))
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.96)
            .animation(CelleuxSpring.luxury, value: appeared)
        }
        .frame(height: 380)
    }

    private func sliderHandle(width: CGFloat, height: CGFloat) -> some View {
        Circle()
            .fill(Color(.displayP3, red: 0.12, green: 0.12, blue: 0.16))
            .frame(width: 40, height: 40)
            .overlay(
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                CelleuxColors.warmGold.opacity(0.8),
                                Color.white.opacity(0.6),
                                CelleuxColors.warmGold.opacity(0.5),
                                Color.white.opacity(0.7),
                                CelleuxColors.warmGold.opacity(0.8)
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
            )
            .overlay(
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 8, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(CelleuxColors.warmGold)
            )
            .position(x: width * sliderPosition, y: height / 2)
            .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newPos = value.location.x / width
                        sliderPosition = max(0.05, min(0.95, newPos))
                    }
            )
    }

    private var scenarioLabels: some View {
        HStack {
            Text("AT CURRENT RATE")
                .font(.system(size: 8, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color(hex: "E8A838").opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.5)))

            Spacer()

            Text("WITH CELLEUX")
                .font(.system(size: 8, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color(hex: "4CAF50").opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.5)))
        }
        .padding(.horizontal, 8)
    }

    private var yearBadge: some View {
        HStack {
            Spacer()
            Text("+\(viewModel.selectedYears) YEARS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(CelleuxColors.warmGold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.55))
                        .background(.ultraThinMaterial.opacity(0.2))
                )
                .clipShape(Capsule())
            Spacer()
        }
    }

    // MARK: - Placeholder Face

    private var placeholderFaceView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.displayP3, red: 0.08, green: 0.08, blue: 0.12))
                .frame(height: 300)

            VStack(spacing: 16) {
                Image(systemName: "face.dashed")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(CelleuxColors.warmGold.opacity(0.5))

                Text("Score-Based Projection")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.7))

                Text("Face photo unavailable.\nProjections below are based on your metric scores.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(CelleuxSpring.luxury, value: appeared)
    }

    // MARK: - Year Selector

    private var yearSelector: some View {
        HStack(spacing: 10) {
            ForEach(Array(viewModel.yearOptions.enumerated()), id: \.element) { index, years in
                let isSelected = viewModel.selectedYears == years
                Button {
                    yearSelectionTrigger += 1
                    withAnimation(CelleuxSpring.snappy) {
                        viewModel.selectYears(years)
                    }
                } label: {
                    Text("\(years)Y")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(isSelected ? CelleuxColors.warmGold : Color.white.opacity(0.4))
                        .frame(width: 64, height: 36)
                        .background(
                            Capsule()
                                .fill(isSelected ? CelleuxColors.warmGold.opacity(0.15) : Color.white.opacity(0.05))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? CelleuxColors.warmGold.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(duration: 0.5, bounce: 0.2).delay(Double(index) * 0.08), value: appeared)
            }
        }
    }

    // MARK: - Projected Score Cards

    private var projectedScoreCards: some View {
        HStack(spacing: 12) {
            if let currentScores = viewModel.currentRateScores {
                scenarioCard(
                    title: "AT CURRENT RATE",
                    titleColor: Color(hex: "E8A838"),
                    scores: currentScores,
                    isRoutine: false
                )
            }

            if let routineScores = viewModel.withRoutineScores {
                scenarioCard(
                    title: "WITH CELLEUX",
                    titleColor: Color(hex: "4CAF50"),
                    scores: routineScores,
                    isRoutine: true
                )
            }
        }
        .opacity(scoresAppeared ? 1 : 0)
        .offset(y: scoresAppeared ? 0 : 16)
    }

    private func scenarioCard(title: String, titleColor: Color, scores: ProjectedScores, isRoutine: Bool) -> some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(titleColor)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 4)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: scoresAppeared ? Double(scores.overall) / 100.0 : 0)
                    .stroke(
                        LinearGradient(
                            colors: isRoutine
                                ? [Color(hex: "4CAF50"), Color(hex: "66BB6A")]
                                : [Color(hex: "E8A838"), Color(hex: "D4A574")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.2).delay(0.3), value: scoresAppeared)

                Text("\(scores.overall)")
                    .font(.system(size: 20, weight: .thin))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .contentTransition(.numericText())
            }

            VStack(spacing: 6) {
                miniMetricRow(label: "Wrinkles", score: scores.wrinkle, color: titleColor)
                miniMetricRow(label: "Elasticity", score: scores.elasticity, color: titleColor)
                miniMetricRow(label: "Hydration", score: scores.hydration, color: titleColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(titleColor.opacity(0.15), lineWidth: 0.5)
        )
    }

    private func miniMetricRow(label: String, score: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))

                Spacer()

                Text("\(score)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 3)

                    Capsule()
                        .fill(color.opacity(0.7))
                        .frame(width: scoresAppeared ? geo.size.width * CGFloat(score) / 100.0 : 0, height: 3)
                        .animation(.easeOut(duration: 0.8).delay(0.5), value: scoresAppeared)
                }
            }
            .frame(height: 3)
        }
    }

    // MARK: - Share

    private var shareButton: some View {
        Button {
            generateShareImage()
        } label: {
            HStack(spacing: 10) {
                if isGeneratingShare {
                    ProgressView()
                        .tint(Color(.displayP3, red: 0.06, green: 0.06, blue: 0.10))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .medium))
                }
                Text("Share Simulation")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color(.displayP3, red: 0.06, green: 0.06, blue: 0.10))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [CelleuxColors.warmGold, CelleuxColors.champagneGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: CelleuxColors.goldGlow, radius: 12, x: 0, y: 4)
        }
        .disabled(isGeneratingShare)
        .opacity(scoresAppeared ? 1 : 0)
        .animation(CelleuxSpring.luxury.delay(0.3), value: scoresAppeared)
    }

    // MARK: - Disclaimer

    private var disclaimerText: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.3))

            Text("Simulation only. Not a medical prediction.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .opacity(scoresAppeared ? 1 : 0)
    }

    // MARK: - Share Generation

    private func generateShareImage() {
        isGeneratingShare = true
        let exportView = AgingSimulationExportCard(
            selectedYears: viewModel.selectedYears,
            currentScores: viewModel.currentRateScores,
            routineScores: viewModel.withRoutineScores,
            currentOverall: result.overallScore
        )
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            shareImage = uiImage
            showShareSheet = true
        }
        isGeneratingShare = false
    }
}

// MARK: - Export Card

struct AgingSimulationExportCard: View {
    let selectedYears: Int
    let currentScores: ProjectedScores?
    let routineScores: ProjectedScores?
    let currentOverall: Int

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("CELLEUX")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(4)
                    .foregroundStyle(Color(hex: "C9A96E"))
                Spacer()
                Text("AGING SIMULATION")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Color(hex: "999999"))
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "C9A96E").opacity(0.1), Color(hex: "C9A96E").opacity(0.5), Color(hex: "C9A96E").opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: 16) {
                exportScenarioColumn(
                    title: "AT CURRENT RATE",
                    titleColor: Color(hex: "E8A838"),
                    score: currentScores?.overall ?? 0
                )

                VStack(spacing: 4) {
                    Text("+\(selectedYears)Y")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "C9A96E"))

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color(hex: "999999"))
                }

                exportScenarioColumn(
                    title: "WITH CELLEUX",
                    titleColor: Color(hex: "4CAF50"),
                    score: routineScores?.overall ?? 0
                )
            }

            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 8, weight: .medium))
                Text("Simulation only. Not a medical prediction.")
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundStyle(Color(hex: "AAAAAA"))
            .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Text("Tracked with Celleux")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(hex: "AAAAAA"))
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color(hex: "C9A96E").opacity(0.5))
                    Text("On-Device")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color(hex: "AAAAAA"))
                }
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "E8DCC8").opacity(0.6), Color(hex: "C9A96E").opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func exportScenarioColumn(title: String, titleColor: Color, score: Int) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .tracking(1)
                .foregroundStyle(titleColor)

            ZStack {
                Circle()
                    .stroke(Color(hex: "EEEEEE"), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: Double(score) / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: [titleColor.opacity(0.8), titleColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(.system(size: 22, weight: .thin))
                    .foregroundStyle(Color(hex: "1A1A26"))
            }
        }
    }
}
