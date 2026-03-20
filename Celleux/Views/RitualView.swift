import SwiftUI

struct RitualView: View {
    @State private var appeared: Bool = false
    @State private var morningChecked: Bool = true
    @State private var middayChecked: Bool = false
    @State private var nightChecked: Bool = false
    @State private var checkHaptic: Int = 0
    @State private var moodHaptic: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    streakBanner
                    supplementSection
                    journalSection
                    moodSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(CelleuxMeshBackground())
            .navigationTitle("Daily Ritual")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 38, height: 38)
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.8), Color.white.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 38, height: 38)
                            Circle()
                                .stroke(CelleuxColors.goldChromeBorder, lineWidth: 0.5)
                                .frame(width: 38, height: 38)
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(CelleuxColors.warmGold)
                        }
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
        }
    }

    private var streakBanner: some View {
        GlassCard(depth: .elevated) {
            HStack(spacing: 16) {
                GlowingAccentBadge("flame.fill", color: CelleuxColors.roseGold, size: 58)

                VStack(alignment: .leading, spacing: 5) {
                    Text("14-Day Streak")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .contentTransition(.numericText())

                    Text("You're building real momentum. Keep it up.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(CelleuxColors.textSecondary)
                }

                Spacer()
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    private var supplementSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Supplement Log")

            VStack(spacing: 10) {
                ritualRow(
                    icon: "sunrise",
                    title: "Morning Elixir",
                    subtitle: "1 scoop · 8oz water · before breakfast",
                    time: "7:12 AM",
                    isChecked: $morningChecked
                )

                ritualRow(
                    icon: "sun.max",
                    title: "Midday Boost",
                    subtitle: "1 capsule · with lunch",
                    time: "Not yet",
                    isChecked: $middayChecked
                )

                ritualRow(
                    icon: "moon",
                    title: "Night Repair",
                    subtitle: "2 capsules · before bed",
                    time: "Not yet",
                    isChecked: $nightChecked
                )
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.08)
    }

    private func ritualRow(icon: String, title: String, subtitle: String, time: String, isChecked: Binding<Bool>) -> some View {
        GlassCard(cornerRadius: 20) {
            HStack(spacing: 14) {
                Button {
                    isChecked.wrappedValue.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                isChecked.wrappedValue ?
                                RadialGradient(
                                    colors: [CelleuxColors.warmGold.opacity(0.8), CelleuxColors.warmGold],
                                    center: .init(x: 0.35, y: 0.35),
                                    startRadius: 0,
                                    endRadius: 16
                                ) :
                                RadialGradient(
                                    colors: [Color.white.opacity(0.7), Color(hex: "F0EDE9")],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 16
                                )
                            )
                            .frame(width: 32, height: 32)

                        Circle()
                            .stroke(
                                isChecked.wrappedValue ?
                                LinearGradient(colors: [Color.white.opacity(0.5), CelleuxColors.warmGold.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color.white.opacity(0.8), CelleuxColors.silverBorder.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                            .frame(width: 32, height: 32)

                        if isChecked.wrappedValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .shadow(color: isChecked.wrappedValue ? CelleuxColors.goldGlow.opacity(0.4) : .black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
                .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: isChecked.wrappedValue)
                .sensoryFeedback(.success, trigger: checkHaptic)

                ChromeIconBadge(icon, size: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isChecked.wrappedValue ? CelleuxColors.textLabel : CelleuxColors.textPrimary)
                        .strikethrough(isChecked.wrappedValue, color: CelleuxColors.textLabel)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                }

                Spacer()

                Text(time)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isChecked.wrappedValue ? CelleuxColors.warmGold : CelleuxColors.textLabel)
            }
        }
    }

    private var journalSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Micro-Journal", action: "View All")

            Button {} label: {
                GlassCard(cornerRadius: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            ChromeIconBadge("pencil.line", size: 30)

                            Text("How's your skin feeling today?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CelleuxColors.textPrimary)
                        }

                        PremiumDivider()

                        Text("Tap to add a quick note about your skin, energy, or anything you notice...")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel.opacity(0.7))
                            .lineSpacing(4)
                    }
                }
            }
            .buttonStyle(PressableButtonStyle())
        }
        .staggeredAppear(appeared: appeared, delay: 0.16)
    }

    private var moodSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Energy & Mood Check-In")

            GlassCard(cornerRadius: 20) {
                VStack(spacing: 18) {
                    HStack(spacing: 0) {
                        ForEach(moodOptions, id: \.label) { option in
                            Button {
                                moodHaptic += 1
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [Color.white.opacity(0.9), Color(hex: "F5F0E8")],
                                                    center: .init(x: 0.35, y: 0.35),
                                                    startRadius: 0,
                                                    endRadius: 24
                                                )
                                            )
                                            .frame(width: 46, height: 46)

                                        Circle()
                                            .stroke(CelleuxColors.goldChromeBorder, lineWidth: 0.5)
                                            .frame(width: 46, height: 46)

                                        Text(option.emoji)
                                            .font(.system(size: 22))
                                    }
                                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                                    Text(option.label)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(CelleuxColors.textLabel)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: moodHaptic)
                        }
                    }

                    Text("How are you feeling right now?")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.24)
    }

    private var moodOptions: [(emoji: String, label: String)] {
        [
            ("😴", "Low"),
            ("😐", "Okay"),
            ("🙂", "Good"),
            ("😊", "Great"),
            ("✨", "Amazing")
        ]
    }
}
