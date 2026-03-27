import SwiftUI

nonisolated enum BreathingPhase: CaseIterable, Sendable {
    case inhale
    case exhale

    var label: String {
        switch self {
        case .inhale: "Inhale"
        case .exhale: "Exhale"
        }
    }

    var icon: String {
        switch self {
        case .inhale: "wind"
        case .exhale: "leaf"
        }
    }
}

struct BreathingTimerView: View {
    let countdown: Int
    let onTick: () -> Void
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @State private var phase: BreathingPhase = .inhale
    @State private var ringScale: CGFloat = 0.85
    @State private var phaseOpacity: Double = 1.0
    @State private var hapticTrigger: Int = 0
    @State private var completionHaptic: Int = 0
    @State private var timerActive: Bool = true

    private let ringSize: CGFloat = 160

    var body: some View {
        GlassCard(depth: .floating) {
            VStack(spacing: 20) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                        Text("MINDFUL APPLICATION")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(CelleuxColors.sectionLabel)
                            .tracking(1.5)
                    }
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.6)))
                    }
                }

                ZStack {
                    Circle()
                        .stroke(CelleuxColors.silver.opacity(0.15), lineWidth: 8)
                        .frame(width: ringSize, height: ringSize)

                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    CelleuxColors.warmGold.opacity(0.3),
                                    CelleuxColors.warmGold,
                                    CelleuxColors.champagneGold,
                                    CelleuxColors.warmGold.opacity(0.3)
                                ],
                                center: .center
                            ),
                            lineWidth: 8
                        )
                        .frame(width: ringSize, height: ringSize)
                        .scaleEffect(ringScale)
                        .shadow(color: CelleuxColors.goldGlow.opacity(Double(ringScale - 0.85) * 4), radius: 16)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    CelleuxColors.warmGold.opacity(0.08),
                                    CelleuxColors.warmGold.opacity(0.02),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: ringSize - 20, height: ringSize - 20)
                        .scaleEffect(ringScale)

                    VStack(spacing: 6) {
                        Image(systemName: phase.icon)
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .opacity(phaseOpacity)

                        Text(phase.label)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .opacity(phaseOpacity)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(CelleuxColors.silver.opacity(0.1), lineWidth: 3)
                            .frame(width: 52, height: 52)

                        Circle()
                            .trim(from: 0, to: max(0, Double(countdown) / 30.0))
                            .stroke(CelleuxColors.goldGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 52, height: 52)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: countdown)

                        Text("\(countdown)")
                            .font(.system(size: 18, weight: .thin))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText(countsDown: true))
                    }

                    Text("Hold during application")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hapticTrigger)
        .sensoryFeedback(.success, trigger: completionHaptic)
        .onAppear { startBreathingCycle() }
        .task { await runCountdown() }
    }

    private func startBreathingCycle() {
        breatheIn()
    }

    private func breatheIn() {
        guard timerActive else { return }
        withAnimation(.easeInOut(duration: 0.2)) { phaseOpacity = 0.3 }
        withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
            phase = .inhale
            phaseOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 4.0)) {
            ringScale = 1.05
        }
        hapticTrigger += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            breatheOut()
        }
    }

    private func breatheOut() {
        guard timerActive else { return }
        withAnimation(.easeInOut(duration: 0.2)) { phaseOpacity = 0.3 }
        withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
            phase = .exhale
            phaseOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 4.0)) {
            ringScale = 0.85
        }
        hapticTrigger += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            breatheIn()
        }
    }

    private func runCountdown() async {
        while timerActive && countdown > 0 {
            try? await Task.sleep(for: .seconds(1))
            guard timerActive else { return }
            onTick()
            if countdown <= 1 {
                timerActive = false
                completionHaptic += 1
                try? await Task.sleep(for: .milliseconds(500))
                onComplete()
                return
            }
        }
    }
}
