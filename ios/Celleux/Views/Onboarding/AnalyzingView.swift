import SwiftUI

struct AnalyzingView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var appeared: Bool = false
    @State private var activeStep: Int = -1
    @State private var ringProgress: CGFloat = 0
    @State private var ringRotation: Double = 0
    @State private var percentValue: Int = 0
    @State private var hapticTrigger: Int = 0
    @State private var completed: Bool = false

    private let steps: [(label: String, icon: String)] = [
        ("Analyzing skin profile", "faceid"),
        ("Mapping your concerns", "sparkles.rectangle.stack.fill"),
        ("Calibrating longevity baseline", "waveform.path.ecg"),
        ("Syncing circadian model", "sunrise.fill"),
        ("Building your plan", "leaf.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ringSection
                .staggeredAppear(appeared: appeared, delay: 0)

            Spacer().frame(height: CelleuxSpacing.xl)

            VStack(spacing: 10) {
                Text("Preparing your\npersonal intelligence")
                    .font(.system(size: 26, weight: .light))
                    .tracking(0.5)
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("This takes just a moment")
                    .font(CelleuxType.body)
                    .foregroundStyle(CelleuxColors.textSecondary)
            }
            .staggeredAppear(appeared: appeared, delay: 0.1)

            Spacer().frame(height: CelleuxSpacing.xl)

            VStack(spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                    stepRow(index: idx, label: step.label, icon: step.icon)
                }
            }
            .padding(.horizontal, CelleuxSpacing.lg)
            .staggeredAppear(appeared: appeared, delay: 0.2)

            Spacer()
            Spacer()
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            runAnalysis()
        }
    }

    private var ringSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [CelleuxColors.warmGold.opacity(0.06), CelleuxColors.warmGold.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)

            Circle()
                .stroke(CelleuxColors.silver.opacity(0.12), lineWidth: 4)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "E8DCC8"),
                            Color(hex: "C9A96E"),
                            Color(hex: "D4C4A0"),
                            Color(hex: "E8DCC8")
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .shadow(color: CelleuxColors.goldGlow, radius: 10)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "E8DCC8").opacity(0.3),
                            Color.white.opacity(0.5),
                            Color(hex: "C9A96E").opacity(0.2),
                            Color(hex: "E8DCC8").opacity(0.3)
                        ],
                        center: .center
                    ),
                    lineWidth: 0.8
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(ringRotation))

            VStack(spacing: 4) {
                Text("\(percentValue)%")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText(countsDown: false))

                Text("COMPLETE")
                    .font(CelleuxType.label)
                    .tracking(CelleuxType.labelTracking)
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
    }

    private func stepRow(index: Int, label: String, icon: String) -> some View {
        let isActive = activeStep >= index
        let isDone = activeStep > index || (completed && activeStep >= index)

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? CelleuxColors.warmGold.opacity(0.15) : CelleuxColors.silver.opacity(0.1))
                    .frame(width: 28, height: 28)

                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .transition(.scale.combined(with: .opacity))
                } else if isActive {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(CelleuxColors.warmGold, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 14, height: 14)
                        .rotationEffect(.degrees(ringRotation * 3))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(CelleuxColors.silver.opacity(0.6))
                }
            }

            Text(label)
                .font(.system(size: 15, weight: isActive ? .medium : .regular))
                .foregroundStyle(isActive ? CelleuxColors.textPrimary : CelleuxColors.textSecondary.opacity(0.7))

            Spacer()
        }
        .opacity(activeStep >= index - 1 ? 1 : 0.35)
        .animation(CelleuxSpring.snappy, value: activeStep)
    }

    private func runAnalysis() {
        Task {
            try? await Task.sleep(for: .milliseconds(400))

            for step in 0..<steps.count {
                withAnimation(CelleuxSpring.snappy) {
                    activeStep = step
                }
                hapticTrigger += 1

                let targetProgress = CGFloat(step + 1) / CGFloat(steps.count)
                let durationMs: Int = [900, 1100, 1200, 900, 1300][step]

                withAnimation(.easeInOut(duration: Double(durationMs) / 1000.0)) {
                    ringProgress = targetProgress
                }

                let startPct = (step * 100) / steps.count
                let endPct = ((step + 1) * 100) / steps.count
                await animatePercent(from: startPct, to: endPct, durationMs: durationMs)

                try? await Task.sleep(for: .milliseconds(150))
            }

            withAnimation(CelleuxSpring.snappy) {
                completed = true
                activeStep = steps.count
            }
            try? await Task.sleep(for: .milliseconds(600))
            onContinue()
        }
    }

    private func animatePercent(from: Int, to: Int, durationMs: Int) async {
        let steps = max(1, to - from)
        let interval = max(20, durationMs / steps)
        for value in from...to {
            withAnimation(.linear(duration: 0.05)) {
                percentValue = value
            }
            try? await Task.sleep(for: .milliseconds(interval))
        }
    }
}
