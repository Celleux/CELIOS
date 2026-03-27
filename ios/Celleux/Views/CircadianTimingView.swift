import SwiftUI
import SwiftData

struct CircadianTimingView: View {
    @State private var viewModel = CircadianTimingViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var appeared: Bool = false
    @State private var toggleTrigger: Bool = false
    @State private var showSettings: Bool = false
    @State private var completionCelebration: Int = 0
    @State private var clockAnimated: Bool = false
    @State private var swipeOffsets: [String: CGFloat] = [:]
    @State private var milestoneCelebration: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 28) {
                    watchPromptBanner
                    clockHeroSection
                    streakSection
                    breathingTimerSection
                    countdownBanner
                    emptyRitualPrompt
                    doseCardsSection
                    scienceSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .background(CelleuxMeshBackground())
            .navigationTitle("Daily Ritual")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        ChromeToolbarButton(icon: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
            .task {
                await viewModel.loadSchedule(modelContext: modelContext)
                withAnimation(CelleuxSpring.luxury) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                    clockAnimated = true
                }
            }
            .onChange(of: viewModel.isMilestoneStreak) { _, newValue in
                if newValue {
                    withAnimation(CelleuxSpring.bouncy) {
                        milestoneCelebration = true
                    }
                    viewModel.isMilestoneStreak = false
                }
            }
        }
    }

    // MARK: - Watch Prompt Banner

    @ViewBuilder
    private var watchPromptBanner: some View {
        if !viewModel.hasWatchSleepData && !viewModel.isLoading {
            CompactGlassCard(cornerRadius: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [CelleuxColors.silverLight.opacity(0.2), CelleuxColors.silverLight.opacity(0.05)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: "applewatch")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(CelleuxColors.silverGradient)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connect Apple Watch")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)
                        Text("For personalized timing based on your sleep schedule")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
            .staggeredAppear(appeared: appeared, delay: 0)
        }
    }

    // MARK: - Clock Hero

    private var clockHeroSection: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                        Text("YOUR PROTOCOL")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(CelleuxColors.sectionLabel)
                            .tracking(1.5)
                    }
                    Spacer()

                    if viewModel.weeklyAdherencePercent > 0 {
                        HStack(spacing: 4) {
                            Text("\(viewModel.weeklyAdherencePercent)%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(CelleuxColors.warmGold)
                                .contentTransition(.numericText())
                            Text("this week")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    } else {
                        Text("\(viewModel.completedCount) of \(viewModel.totalCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .contentTransition(.numericText())
                    }
                }

                ZStack {
                    circadianClockFace
                        .frame(width: 200, height: 200)
                }
                .frame(maxWidth: .infinity)

                completionProgressBar

                if viewModel.isWeekendMode {
                    statusPill(icon: "moon.zzz.fill", text: "Weekend mode active — timings shifted later", color: CelleuxColors.warmGold)
                }

                if viewModel.workoutDetectedToday {
                    statusPill(icon: "figure.run", text: "Workout detected — post-workout dose adjusted", color: Color(.displayP3, red: 0.3, green: 0.7, blue: 0.4))
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    private func statusPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CelleuxColors.textSecondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(color.opacity(0.08))
        )
    }

    private var circadianClockFace: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            CelleuxColors.silverLight.opacity(0.3),
                            CelleuxColors.silverLight.opacity(0.15),
                            CelleuxColors.silverLight.opacity(0.3)
                        ],
                        center: .center
                    ),
                    lineWidth: 3
                )

            Circle()
                .stroke(Color(.displayP3, red: 0.93, green: 0.91, blue: 0.89), lineWidth: 12)

            Circle()
                .trim(from: 0, to: clockAnimated ? viewModel.currentTimeProgress : 0)
                .stroke(
                    AngularGradient(
                        colors: [
                            CelleuxColors.warmGold.opacity(0.4),
                            CelleuxColors.warmGold,
                            CelleuxColors.champagneGold
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: CelleuxColors.goldGlow.opacity(0.6), radius: 8)

            ForEach(viewModel.doseWindowSegments(), id: \.category) { segment in
                doseMarker(segment: segment)
            }

            currentTimeIndicator

            VStack(spacing: 4) {
                Text("\(viewModel.completedCount)")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .contentTransition(.numericText())
                Text("of \(viewModel.totalCount) doses")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
        }
    }

    private func doseMarker(segment: (start: Double, end: Double, category: String)) -> some View {
        let angle = segment.start * 360 - 90
        let isCompleted = viewModel.scheduleItems.first(where: { $0.category == segment.category })?.isCompleted ?? false

        return Circle()
            .fill(
                isCompleted
                    ? AnyShapeStyle(CelleuxColors.goldGradient)
                    : AnyShapeStyle(CelleuxColors.silverLight.opacity(0.6))
            )
            .frame(width: 10, height: 10)
            .shadow(color: isCompleted ? CelleuxColors.goldGlow : .clear, radius: 4)
            .offset(y: -88)
            .rotationEffect(.degrees(angle))
    }

    private var currentTimeIndicator: some View {
        let angle = viewModel.currentTimeProgress * 360 - 90

        return Circle()
            .fill(CelleuxColors.warmGold)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
            )
            .shadow(color: CelleuxColors.warmGold.opacity(0.6), radius: 6)
            .offset(y: -88)
            .rotationEffect(.degrees(angle))
    }

    private var completionProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CelleuxColors.silver.opacity(0.08))
                    .frame(height: 5)

                Capsule()
                    .fill(CelleuxColors.goldGradient)
                    .frame(
                        width: geo.size.width * viewModel.completionProgress,
                        height: 5
                    )
                    .shadow(color: CelleuxColors.warmGold.opacity(0.5), radius: 6)
                    .animation(CelleuxSpring.luxury, value: viewModel.completionProgress)
            }
        }
        .frame(height: 5)
    }

    // MARK: - Streak Section

    @ViewBuilder
    private var streakSection: some View {
        if viewModel.streakDays > 0 {
            let milestone = StreakMilestone.current(for: viewModel.streakDays)

            ZStack {
                GlassCard(depth: .elevated) {
                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(RadialGradient(colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.03)], center: .center, startRadius: 0, endRadius: 26))
                                    .frame(width: 50, height: 50)
                                Circle()
                                    .stroke(AngularGradient(colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.45)], center: .center), lineWidth: 1)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(LinearGradient(colors: [CelleuxColors.roseGold, CelleuxColors.warmGold], startPoint: .top, endPoint: .bottom))
                                    .symbolEffect(.breathe, isActive: appeared)
                            }
                            .shadow(color: CelleuxColors.warmGold.opacity(0.2), radius: 8, x: 0, y: 4)
                            .scaleEffect(milestoneCelebration ? 1.15 : 1.0)
                            .animation(CelleuxSpring.bouncy, value: milestoneCelebration)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(viewModel.streakDays)")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(CelleuxColors.goldGradient)
                                        .contentTransition(.numericText())
                                    Text("day streak")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(CelleuxColors.textPrimary)
                                }
                                Text("Consistency is the real anti-aging secret")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                            Spacer()
                        }

                        VStack(spacing: 6) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(CelleuxColors.silver.opacity(0.1))
                                        .frame(height: 5)

                                    Capsule()
                                        .fill(CelleuxColors.goldGradient)
                                        .frame(width: geo.size.width * milestone.progress, height: 5)
                                        .shadow(color: CelleuxColors.warmGold.opacity(0.4), radius: 4)
                                        .animation(CelleuxSpring.luxury, value: milestone.progress)
                                }
                            }
                            .frame(height: 5)

                            HStack {
                                Text("\(milestone.daysRemaining) days to \(milestone.next)-day milestone")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                                Spacer()
                                Text("\(Int(milestone.progress * 100))%")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(CelleuxColors.warmGold)
                                    .contentTransition(.numericText())
                            }
                        }
                    }
                }

                if milestoneCelebration {
                    CelebrationParticleBurst(isActive: milestoneCelebration)
                        .allowsHitTesting(false)
                }
            }
            .sensoryFeedback(.success, trigger: milestoneCelebration)
            .staggeredAppear(appeared: appeared, delay: 0.04)
        }
    }

    // MARK: - Breathing Timer

    @ViewBuilder
    private var breathingTimerSection: some View {
        if viewModel.breathingTimerActive {
            BreathingTimerView(
                countdown: viewModel.breathingCountdown,
                onTick: {
                    viewModel.tickBreathingCountdown()
                },
                onComplete: {
                    if let category = viewModel.breathingTimerCategory,
                       let item = viewModel.scheduleItems.first(where: { $0.category == category && !$0.isCompleted }) {
                        viewModel.toggleCompletion(item: item, modelContext: modelContext)
                        toggleTrigger.toggle()
                        completionCelebration += 1
                    }
                    withAnimation(CelleuxSpring.snappy) {
                        viewModel.stopBreathingTimer()
                    }
                },
                onDismiss: {
                    withAnimation(CelleuxSpring.snappy) {
                        viewModel.stopBreathingTimer()
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
        }
    }

    // MARK: - Countdown Banner

    @ViewBuilder
    private var countdownBanner: some View {
        if let countdown = viewModel.nextDoseCountdown, let nextDose = viewModel.nextDoseItem {
            CompactGlassCard(cornerRadius: 18) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.03)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 40, height: 40)
                        Image(systemName: "timer")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next: \(nextDose.label)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)
                        Text(countdown)
                            .font(.system(size: 22, weight: .thin))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    Text(nextDose.timeString)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
            .staggeredAppear(appeared: appeared, delay: 0.06)
        }
    }

    // MARK: - Empty Ritual Prompt

    @ViewBuilder
    private var emptyRitualPrompt: some View {
        if viewModel.completedCount == 0 && !viewModel.isLoading && !viewModel.breathingTimerActive {
            CompactGlassCard(cornerRadius: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(CelleuxColors.warmGold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start your ritual")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)
                        Text("Complete a dose to build momentum today")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    Spacer()
                }
            }
            .staggeredAppear(appeared: appeared, delay: 0.08)
        }
    }

    // MARK: - Dose Cards

    private var doseCardsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today's Doses")

            ForEach(Array(viewModel.scheduleItems.enumerated()), id: \.element.id) { index, item in
                doseCard(item: item, delay: Double(index) * 0.06 + 0.12)
            }
        }
    }

    private func doseCard(item: ScheduleItem, delay: Double) -> some View {
        let offset = swipeOffsets[item.category] ?? 0
        let swipeThreshold: CGFloat = 100
        let swipeProgress = min(1, abs(offset) / swipeThreshold)

        return ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.displayP3, red: 0.3, green: 0.72, blue: 0.4).opacity(swipeProgress * 0.2),
                            Color(.displayP3, red: 0.3, green: 0.72, blue: 0.4).opacity(swipeProgress * 0.1)
                        ],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .trailing) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color(.displayP3, red: 0.3, green: 0.72, blue: 0.4))
                        .opacity(swipeProgress)
                        .scaleEffect(0.5 + swipeProgress * 0.5)
                        .padding(.trailing, 20)
                }

            doseCardContent(item: item)
                .offset(x: offset)
                .gesture(
                    item.isCompleted ? nil :
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let translation = value.translation.width
                            if translation < 0 {
                                swipeOffsets[item.category] = translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -swipeThreshold {
                                withAnimation(CelleuxSpring.snappy) {
                                    swipeOffsets[item.category] = 0
                                }
                                viewModel.toggleCompletion(item: item, modelContext: modelContext)
                                toggleTrigger.toggle()
                                completionCelebration += 1
                            } else {
                                withAnimation(CelleuxSpring.snappy) {
                                    swipeOffsets[item.category] = 0
                                }
                            }
                        }
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .staggeredAppear(appeared: appeared, delay: delay)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: toggleTrigger)
        .sensoryFeedback(.success, trigger: completionCelebration)
    }

    private func doseCardContent(item: ScheduleItem) -> some View {
        let borderGradient: LinearGradient = item.isActive
            ? LinearGradient(colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.warmGold.opacity(0.2), CelleuxColors.warmGold.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            : CelleuxColors.chromeBorder

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            item.isCompleted
                                ? RadialGradient(colors: [CelleuxColors.warmGold.opacity(0.2), CelleuxColors.warmGold.opacity(0.05)], center: .center, startRadius: 0, endRadius: 22)
                                : RadialGradient(colors: [Color.white.opacity(0.9), Color(hex: "F5F0E8")], center: .init(x: 0.35, y: 0.35), startRadius: 0, endRadius: 22)
                        )
                        .frame(width: 44, height: 44)

                    Circle()
                        .stroke(
                            item.isCompleted ? CelleuxColors.goldChromeBorder : CelleuxColors.glassEdgeHighlight,
                            lineWidth: 1
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            item.isCompleted
                                ? AnyShapeStyle(CelleuxColors.warmGold)
                                : AnyShapeStyle(CelleuxColors.iconGoldGradient)
                        )
                }
                .shadow(color: item.isCompleted ? CelleuxColors.goldGlow : .black.opacity(0.04), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.label)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(item.isCompleted ? CelleuxColors.textLabel : CelleuxColors.textPrimary)
                            .strikethrough(item.isCompleted, color: CelleuxColors.textLabel)

                        Spacer()

                        if item.isMissed && !item.isCompleted {
                            Text("MISSED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color(hex: "E8A838"))
                                .tracking(0.8)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "E8A838").opacity(0.1))
                                )
                        } else if item.isActive {
                            PulsingDot(color: CelleuxColors.warmGold)
                        }
                    }

                    Text(item.timeString)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(item.isCompleted ? CelleuxColors.warmGold : CelleuxColors.textLabel)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(item.supplements, id: \.self) { supplement in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(CelleuxColors.warmGold.opacity(0.6))
                            .frame(width: 5, height: 5)
                        Text(supplement)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(item.isCompleted ? CelleuxColors.textLabel : CelleuxColors.textSecondary)
                    }
                }
            }

            Text(item.rationale)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(CelleuxColors.textLabel)
                .lineSpacing(3)

            PremiumDivider()

            HStack {
                Button {
                    viewModel.toggleCompletion(item: item, modelContext: modelContext)
                    toggleTrigger.toggle()
                    if !item.isCompleted {
                        completionCelebration += 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    item.isCompleted
                                        ? RadialGradient(colors: [Color.white, Color(hex: "FBF8F2")], center: .center, startRadius: 0, endRadius: 12)
                                        : RadialGradient(colors: [Color(hex: "F6F4F1"), Color(hex: "EDEAE6")], center: .center, startRadius: 0, endRadius: 12)
                                )
                                .frame(width: 24, height: 24)

                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    item.isCompleted
                                        ? CelleuxColors.goldChromeBorder
                                        : LinearGradient(colors: [CelleuxColors.silverBorder.opacity(0.4), Color.white.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: item.isCompleted ? 1.5 : 1
                                )
                                .frame(width: 24, height: 24)

                            if item.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(CelleuxColors.warmGold)
                                    .symbolEffect(.bounce, value: toggleTrigger)
                            }
                        }
                        .shadow(color: item.isCompleted ? CelleuxColors.warmGold.opacity(0.25) : .clear, radius: 4, x: 0, y: 2)

                        Text(item.isCompleted ? "Completed" : "Mark as done")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(item.isCompleted ? CelleuxColors.warmGold : CelleuxColors.textSecondary)
                    }
                }

                Spacer()

                if item.isActive && !item.isCompleted && !viewModel.breathingTimerActive {
                    Button {
                        withAnimation(CelleuxSpring.luxury) {
                            viewModel.startBreathingTimer(for: item.category)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "wind")
                                .font(.system(size: 10, weight: .medium))
                            Text("Start Ritual")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(CelleuxColors.warmGold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(CelleuxColors.warmGold.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(CelleuxColors.warmGold.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                } else if !item.isCompleted {
                    Text("Swipe left to complete")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel.opacity(0.6))
                        .tracking(0.3)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    item.isActive ? AnyShapeStyle(borderGradient) : AnyShapeStyle(CelleuxColors.glassEdgeHighlight),
                    lineWidth: item.isActive ? 1.5 : 1
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 30, x: 0, y: 15)
        .opacity(item.isCompleted ? 0.8 : 1)
    }

    // MARK: - Science

    private var scienceSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Timing Science")

            VStack(spacing: 10) {
                ForEach(viewModel.scienceCards) { card in
                    scienceCardView(card)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.36)
    }

    private func scienceCardView(_ card: TimingScienceCard) -> some View {
        let isExpanded = viewModel.expandedScienceCards.contains(card.id.uuidString)

        return CompactGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(CelleuxSpring.snappy) {
                        if isExpanded {
                            viewModel.expandedScienceCards.remove(card.id.uuidString)
                        } else {
                            viewModel.expandedScienceCards.insert(card.id.uuidString)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: card.icon)
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(CelleuxColors.silverGradient)
                            .frame(width: 24)

                        Text(card.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(CelleuxColors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }

                if isExpanded {
                    PremiumDivider()
                        .padding(.vertical, 10)

                    Text(card.explanation)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .lineSpacing(4)
                }
            }
        }
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Wake Time", selection: $viewModel.wakeTime, displayedComponents: .hourAndMinute)
                        .tint(CelleuxColors.warmGold)
                        .listRowBackground(Color.white.opacity(0.55))

                    DatePicker("Sleep Time", selection: $viewModel.sleepTime, displayedComponents: .hourAndMinute)
                        .tint(CelleuxColors.warmGold)
                        .listRowBackground(Color.white.opacity(0.55))

                    Toggle("Auto-adjust from HealthKit", isOn: $viewModel.autoAdjust)
                        .tint(CelleuxColors.warmGold)
                        .listRowBackground(Color.white.opacity(0.55))
                } header: {
                    Text("Schedule")
                        .foregroundStyle(CelleuxColors.textPrimary.opacity(0.55))
                } footer: {
                    Text("When auto-adjust is on, your schedule updates based on real sleep data from Apple Watch.")
                        .foregroundStyle(CelleuxColors.textPrimary.opacity(0.45))
                }

                Section {
                    Toggle("Weekend Mode", isOn: Binding(
                        get: { viewModel.weekendModeEnabled },
                        set: { _ in viewModel.toggleWeekendMode() }
                    ))
                    .tint(CelleuxColors.warmGold)
                    .listRowBackground(Color.white.opacity(0.55))

                    if viewModel.weekendModeEnabled {
                        Stepper("Shift: +\(viewModel.weekendExtraMinutes) min", value: $viewModel.weekendExtraMinutes, in: 15...120, step: 15)
                            .listRowBackground(Color.white.opacity(0.55))
                            .onChange(of: viewModel.weekendExtraMinutes) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "weekendExtraMinutes")
                            }
                    }
                } header: {
                    Text("Weekend")
                        .foregroundStyle(CelleuxColors.textPrimary.opacity(0.55))
                } footer: {
                    Text("Automatically shift all timings later on Saturdays and Sundays.")
                        .foregroundStyle(CelleuxColors.textPrimary.opacity(0.45))
                }

                Section {
                    Button {
                        viewModel.scheduleNotifications()
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(CelleuxColors.warmGold)
                            Text("Enable Reminders")
                                .foregroundStyle(CelleuxColors.warmGold)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.55))
                } header: {
                    Text("Notifications")
                        .foregroundStyle(CelleuxColors.textPrimary.opacity(0.55))
                } footer: {
                    Text("Receive reminders at each supplement time, with a gentle follow-up 30 minutes later if not taken.")
                        .foregroundStyle(CelleuxColors.textPrimary.opacity(0.45))
                }
            }
            .scrollContentBackground(.hidden)
            .foregroundStyle(CelleuxColors.textPrimary)
            .navigationTitle("Timing Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.regenerateSchedule()
                        showSettings = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(CelleuxColors.warmGold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
        .presentationBackground {
            ZStack {
                Color.white.opacity(0.82)
                Color(red: 0.97, green: 0.96, blue: 0.94).opacity(0.5)
            }
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
        }
        .presentationCornerRadius(32)
    }
}
