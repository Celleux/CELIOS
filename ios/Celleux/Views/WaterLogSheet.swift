import SwiftUI

struct WaterLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onLogged: () -> Void = {}

    @State private var selectedAmount: Double = 250
    @State private var hapticTrigger: Int = 0
    @State private var saveTrigger: Bool = false
    @State private var isSaving: Bool = false

    private let presets: [(label: String, icon: String, ml: Double)] = [
        ("Sip", "cup.and.saucer.fill", 100),
        ("Glass", "drop.fill", 250),
        ("Bottle", "waterbottle.fill", 500),
        ("Large", "waterbottle.fill", 750),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text("\(Int(selectedAmount)) mL")
                        .font(.system(size: 44, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .contentTransition(.numericText())
                    Text("Tap a preset or use the slider")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
                .padding(.top, 10)

                HStack(spacing: 10) {
                    ForEach(presets, id: \.label) { preset in
                        Button {
                            withAnimation(CelleuxSpring.snappy) {
                                selectedAmount = preset.ml
                            }
                            hapticTrigger += 1
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundStyle(selectedAmount == preset.ml ? CelleuxColors.warmGold : CelleuxColors.silver)
                                Text(preset.label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(selectedAmount == preset.ml ? CelleuxColors.textPrimary : CelleuxColors.textLabel)
                                Text("\(Int(preset.ml))mL")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(selectedAmount == preset.ml ? CelleuxColors.warmGold.opacity(0.12) : Color.white.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(selectedAmount == preset.ml ? CelleuxColors.warmGold.opacity(0.4) : Color.white.opacity(0.7), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }

                Slider(value: $selectedAmount, in: 50...1000, step: 25)
                    .tint(CelleuxColors.warmGold)
                    .onChange(of: selectedAmount) { _, _ in hapticTrigger += 1 }

                Button {
                    logWater()
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView().tint(CelleuxColors.warmGold)
                        } else {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Log \(Int(selectedAmount)) mL")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .foregroundStyle(CelleuxColors.warmGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(CelleuxColors.warmGold.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(CelleuxColors.warmGold.opacity(0.35), lineWidth: 1)
                    )
                }
                .disabled(isSaving)
                .sensoryFeedback(.success, trigger: saveTrigger)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
            .sensoryFeedback(.selection, trigger: hapticTrigger)
            .navigationTitle("Log Hydration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
        }
    }

    private func logWater() {
        isSaving = true
        Task {
            _ = await HealthKitService.shared.logWater(milliliters: selectedAmount)
            GamificationEngine.shared.award(.waterLogged)
            saveTrigger.toggle()
            onLogged()
            isSaving = false
            try? await Task.sleep(for: .milliseconds(300))
            dismiss()
        }
    }
}
