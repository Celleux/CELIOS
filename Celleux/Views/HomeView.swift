import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    var switchTab: (AppTab) -> Void
    @State private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared: Bool = false
    @State private var scoreAnimated: Bool = false
    @State private var ringGlow: Bool = false
    @State private var protocolToggleTrigger: Bool = false
    @State private var countdownText: String? = nil
    @State private var showLongevityScore: Bool = false
    @State private var showMoodCheckIn: Bool = false
    @State private var breathingShadow: Bool = false
    @State private var overdueGlow: Bool = false
    @State private var selectedFactor: LongevityFactor? = nil
    @State private var achievementCelebration: Bool = false
    @State private var showChallengeDetail: Bool = false
    @Query(filter: #Predicate<SkinTransformationChallenge> { $0.isActive == true }) private var activeChallenges: [SkinTransformationChallenge]
    @Namespace private var heroAnimation

    var body: some View {
        NavigationStack {
            ZStack {
                CelleuxMeshBackground()

                CelleuxParticleView()
                    .opacity(0.6)

                ScrollView {
                    VStack(spacing: 32) {
                        if viewModel.isRefreshing {
                            GoldRefreshSpinner()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)
                                .transition(.opacity.combined(with: .scale(scale: 0.6)))
                        }

                        greetingSection
                        if viewModel.hasData {
                            skinScoreHeroCard
                        } else {
                            emptyScoreCard
                        }
                        longevityCompositeCard
                        todaysProtocolCard
                        healthSnapshotSection
                        quickActionsRow
                        weeklyTrendCard
                        streakAchievementSection
                        challengeCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await viewModel.refreshAll(modelContext: modelContext)
                }
                .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: viewModel.refreshTrigger)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Celleux")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(CelleuxColors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        ChromeToolbarButton(icon: "bell")
                    }
                }
            }
            .navigationDestination(isPresented: $showChallengeDetail) {
                ChallengeDetailView()
            }
            .navigationDestination(isPresented: $showLongevityScore) {
                SkinLongevityScoreView()
                    .navigationTransition(.zoom(sourceID: "scoreHero", in: heroAnimation))
            }
            .sheet(isPresented: $showMoodCheckIn) {
                MoodCheckInSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(32)
                    .presentationContentInteraction(.scrolls)
            }
            .sheet(item: $selectedFactor) { factor in
                LongevityFactorDetailSheet(
                    factor: factor,
                    score: viewModel.scoreForFactor(factor),
                    detail: viewModel.detailForFactor(factor),
                    hasData: viewModel.factorHasData(factor),
                    history: viewModel.historicalScoresForFactor(factor)
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(32)
                .presentationContentInteraction(.scrolls)
            }
            .onAppear {
                viewModel.loadData(modelContext: modelContext)
                startCountdownTimer()
                withAnimation(.spring(duration: 0.8, bounce: 0.15)) {
                    appeared = true
                }
                withAnimation(.easeOut(duration: 1.6).delay(0.3)) {
                    viewModel.animateScore()
                    scoreAnimated = true
                }
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(1.0)) {
                    ringGlow = true
                    breathingShadow = true
                }
                if viewModel.isScanOverdue || viewModel.lastScanDate == nil {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.5)) {
                        overdueGlow = true
                    }
                }
                if viewModel.newAchievementUnlocked {
                    achievementCelebration = true
                    viewModel.newAchievementUnlocked = false
                }
            }
        }
    }

    // MARK: - 1. Hero Section with Narrative Insight Pill

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(viewModel.greeting), \(viewModel.userName)")
                        .font(CelleuxType.title1)
                        .tracking(CelleuxType.title1Tracking)
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text(viewModel.dateString)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(1.5)
                        .textCase(.uppercase)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "E8A838"), Color(hex: "D4903C")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("UV \(viewModel.uvIndex) · \(viewModel.uvLabel)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.95))
                )
                .overlay(
                    Capsule()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }

            narrativeInsightPill
        }
        .padding(.top, 4)
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    private var narrativeInsightPill: some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.narrativeInsight.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CelleuxColors.warmGold)

            Text(viewModel.narrativeInsight.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CelleuxColors.textSecondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : CelleuxColors.glassEdgeHighlight, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - 2. Skin Score Card

    private var emptyScoreCard: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 18) {
                ZStack {
                    LuxuryBezelRing(progress: 0, size: 120, lineWidth: 8, glowing: $ringGlow)
                    Image(systemName: "viewfinder")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(CelleuxColors.silver)
                        .symbolEffect(.variableColor.iterative.reversing, options: .repeating, isActive: appeared)
                }

                Text("Complete your first scan to see your score")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(CelleuxColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    switchTab(.scan)
                } label: {
                    Text("Take Your First Scan")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(GlassButtonStyle(style: .primary))
                .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: false)
            }
            .frame(maxWidth: .infinity)
        }
        .staggeredAppear(appeared: appeared, delay: 0.06)
    }

    private var skinScoreHeroCard: some View {
        Button { showLongevityScore = true } label: {
            VStack(spacing: 0) {
                VStack(spacing: 22) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(CelleuxColors.warmGold)
                            Text("SKIN LONGEVITY SCORE")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(CelleuxColors.textLabel)
                                .tracking(1.5)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    ZStack {
                        LuxuryBezelRing(
                            progress: viewModel.skinScore / 100,
                            size: 172,
                            lineWidth: 10,
                            glowing: $ringGlow
                        )

                        VStack(spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(Int(viewModel.skinScore))")
                                    .font(.system(size: 52, weight: .ultraLight, design: .rounded))
                                    .foregroundStyle(CelleuxColors.textPrimary)
                                    .contentTransition(.numericText())

                                Text("/100")
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }

                            Text("Skin Longevity")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(CelleuxColors.textLabel)
                                .tracking(0.8)
                                .textCase(.uppercase)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 8) {
                        if !viewModel.lastScanRelativeString.isEmpty {
                            Text(viewModel.lastScanRelativeString)
                                .font(CelleuxType.caption)
                                .foregroundStyle(CelleuxColors.textLabel)
                        }

                        if viewModel.scoreTrend != 0 && viewModel.scanCount >= 3 {
                            HStack(spacing: 10) {
                                PulsingDot(color: CelleuxColors.warmGold)

                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.scoreTrend > 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(viewModel.scoreTrend > 0 ? CelleuxColors.warmGold : Color(hex: "E53935"))
                                        .symbolEffect(.wiggle.up, value: scoreAnimated)
                                    Text(String(format: "%+.0f from last scan", viewModel.scoreTrend))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(viewModel.scoreTrend > 0 ? CelleuxColors.warmGold : Color(hex: "E53935"))
                                        .contentTransition(.numericText())
                                }

                                Spacer()

                                Text(viewModel.scoreTrend > 0 ? "Improving" : "Needs attention")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                        }

                        if viewModel.isScanOverdue {
                            Button {
                                switchTab(.scan)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "viewfinder")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Scan Now")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(CelleuxColors.warmGold)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(GlassButtonStyle(style: .primary))
                            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: overdueGlow)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(24)
                .background(heroCardBackground)
            }
            .shimmer()
        }
        .matchedTransitionSource(id: "scoreHero", in: heroAnimation)
        .buttonStyle(PressableButtonStyle())
        .shadow(
            color: viewModel.isScanOverdue
                ? CelleuxColors.warmGold.opacity(overdueGlow ? 0.25 : 0.08)
                : CelleuxColors.goldGlow.opacity(breathingShadow ? 0.12 : 0.06),
            radius: viewModel.isScanOverdue
                ? (overdueGlow ? 35 : 18)
                : (breathingShadow ? 30 : 15),
            x: 0, y: 10
        )
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: showLongevityScore)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Skin longevity score")
        .accessibilityValue("\(Int(viewModel.skinScore)) out of 100\(viewModel.scoreTrend != 0 ? ", trend \(viewModel.scoreTrend > 0 ? "improving" : "declining")" : "")")
        .accessibilityHint("Opens detailed longevity score view")
        .accessibilityAddTraits(.isButton)
        .staggeredAppear(appeared: appeared, delay: 0.06)
    }

    private var heroCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.92))
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : CelleuxColors.glassEdgeHighlight, lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.03), radius: 30, x: 0, y: 15)
    }

    // MARK: - 3. Longevity Composite Card

    private var longevityCompositeCard: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                        Text("LONGEVITY FACTORS")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .tracking(1.5)
                    }
                    Spacer()
                }

                VStack(spacing: 2) {
                    ForEach(LongevityFactor.allCases) { factor in
                        let hasData = viewModel.factorHasData(factor)
                        Button {
                            selectedFactor = factor
                        } label: {
                            longevityFactorRow(factor: factor, hasData: hasData)
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.selection, trigger: selectedFactor)
                    }
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.10)
    }

    private func longevityFactorRow(factor: LongevityFactor, hasData: Bool) -> some View {
        let score = viewModel.scoreForFactor(factor)
        let detail = viewModel.detailForFactor(factor)

        return HStack(spacing: 14) {
            let _ = 0 // accessibility applied at end
            ChromeIconBadge(factor.icon, size: 36, gradient: hasData ? CelleuxColors.iconGoldGradient : CelleuxColors.iconBlueGradient)
                .opacity(hasData ? 1.0 : 0.45)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(factor.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(hasData ? CelleuxColors.textPrimary : CelleuxColors.textLabel)

                    Text("\(Int(factor.weight * 100))%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.white.opacity(0.6))
                        )
                }

                if hasData {
                    Text(detail)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .lineLimit(1)
                } else if factor.requiresWatch {
                    Text("Connect Apple Watch")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CelleuxColors.warmGold.opacity(0.7))
                } else {
                    Text("No data yet")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }

            Spacer()

            if hasData {
                MiniFactorRing(progress: score / 100, size: 34)

                Text("\(Int(score))")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .contentTransition(.numericText())
                    .frame(width: 30, alignment: .trailing)
            } else {
                Text("\u{2014}")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .frame(width: 30, alignment: .trailing)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(CelleuxColors.textLabel)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(factor.title)")
        .accessibilityValue(hasData ? "\(Int(score)) out of 100, \(detail)" : "No data available")
        .accessibilityHint("Shows \(factor.title) details")
    }

    // MARK: - 4. Today's Protocol

    private var todaysProtocolCard: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.warmGold)
                        Text("TODAY'S PROTOCOL")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .tracking(1.5)
                    }
                    Spacer()
                    Text("\(viewModel.completedCount) of \(viewModel.totalCount)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .contentTransition(.numericText())
                }

                protocolProgressBar

                if let countdown = countdownText {
                    protocolCountdownPill(countdown)
                }

                VStack(spacing: 0) {
                    ForEach(Array(viewModel.protocolItems.enumerated()), id: \.element.id) { index, item in
                        protocolRow(item: item, isLast: index == viewModel.protocolItems.count - 1)
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.protocolCompletionTrigger)
        .staggeredAppear(appeared: appeared, delay: 0.14)
    }

    private func protocolCountdownPill(_ text: String) -> some View {
        HStack(spacing: 8) {
            PulsingDot(color: CelleuxColors.warmGold)

            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CelleuxColors.warmGold)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(CelleuxColors.warmGold.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(CelleuxColors.warmGold.opacity(0.15), lineWidth: 1)
        )
    }

    private var protocolProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CelleuxColors.silver.opacity(0.08))
                    .frame(height: 5)

                Capsule()
                    .fill(CelleuxColors.goldGradient)
                    .frame(width: geo.size.width * CGFloat(viewModel.completedCount) / CGFloat(max(viewModel.totalCount, 1)), height: 5)
                    .shadow(color: CelleuxColors.warmGold.opacity(0.5), radius: 6, x: 0, y: 0)
                    .animation(CelleuxSpring.luxury, value: viewModel.completedCount)
            }
        }
        .frame(height: 5)
    }

    private func protocolRow(item: ProtocolItem, isLast: Bool) -> some View {
        let isNextDose = viewModel.nextDoseItem?.id == item.id

        return HStack(spacing: 14) {
            VStack(spacing: 0) {
                Button {
                    withAnimation(CelleuxSpring.snappy) {
                        viewModel.toggleProtocolItem(item, modelContext: modelContext)
                        protocolToggleTrigger.toggle()
                        if item.isCompleted == false {
                            viewModel.protocolCompletionTrigger.toggle()
                        }
                    }
                    updateCountdown()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                item.isCompleted ?
                                RadialGradient(colors: [Color.white, CelleuxP3.warmCream], center: .center, startRadius: 0, endRadius: 22) :
                                RadialGradient(colors: [CelleuxP3.warmCream, CelleuxP3.goldMist.opacity(0.5)], center: .center, startRadius: 0, endRadius: 22)
                            )
                            .frame(width: 44, height: 44)
                        Circle()
                            .stroke(
                                item.isCompleted ?
                                AngularGradient(colors: [CelleuxColors.warmGold.opacity(0.7), CelleuxColors.warmGold.opacity(0.25), CelleuxColors.warmGold.opacity(0.6)], center: .center) :
                                isNextDose ?
                                AngularGradient(colors: [CelleuxColors.warmGold.opacity(0.5), CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.4)], center: .center) :
                                AngularGradient(colors: [Color.white.opacity(0.8), CelleuxColors.silverBorder.opacity(0.25), Color.white.opacity(0.6)], center: .center),
                                lineWidth: item.isCompleted ? 1.5 : 1
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: item.isCompleted ? "checkmark" : item.icon)
                            .font(.system(size: item.isCompleted ? 14 : 16, weight: item.isCompleted ? .bold : .light))
                            .foregroundStyle(item.isCompleted ? CelleuxColors.warmGold : CelleuxColors.silver)
                            .symbolEffect(.bounce, value: protocolToggleTrigger)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .shadow(color: item.isCompleted ? CelleuxColors.warmGold.opacity(0.25) : .black.opacity(0.03), radius: 8, x: 0, y: 3)
                }
                .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: protocolToggleTrigger)

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.12), CelleuxColors.silver.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1.5, height: 22)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.period)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(0.8)
                        .textCase(.uppercase)

                    if isNextDose && !item.isCompleted {
                        Text("NEXT")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(CelleuxColors.warmGold.opacity(0.12))
                            )
                    }
                }

                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(item.isCompleted ? CelleuxColors.textLabel : CelleuxColors.textPrimary)
                    .strikethrough(item.isCompleted, color: CelleuxColors.textLabel)

                Text(item.time)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .lineSpacing(4)
            }
            .padding(.bottom, isLast ? 0 : 12)

            Spacer()
        }
    }

    private func startCountdownTimer() {
        updateCountdown()
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                updateCountdown()
            }
        }
    }

    private func updateCountdown() {
        withAnimation(.easeInOut(duration: 0.3)) {
            countdownText = viewModel.nextDoseCountdownString
        }
    }

    private var quickActionsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(1.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    quickActionChip(title: "Scan Skin", icon: "faceid", color: CelleuxColors.warmGold) {
                        switchTab(.scan)
                    }
                    quickActionChip(title: "Log Mood", icon: "face.smiling", color: CelleuxColors.warmGold) {
                        showMoodCheckIn = true
                    }
                    quickActionChip(title: "View Trends", icon: "chart.line.uptrend.xyaxis", color: CelleuxP3.coolSilver) {
                        switchTab(.insights)
                    }
                    quickActionChip(title: "Ritual", icon: "leaf.fill", color: CelleuxColors.roseGold) {
                        switchTab(.ritual)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
        .staggeredAppear(appeared: appeared, delay: 0.20)
    }

    @State private var chipFlashId: String? = nil

    private func quickActionChip(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            chipFlashId = title
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                chipFlashId = nil
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.06))
                        .frame(width: 56, height: 56)
                        .offset(y: 4)
                        .blur(radius: 6)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.95))
                        .frame(width: 56, height: 56)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : CelleuxColors.iconHighlightGradient, lineWidth: 1.5)
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(CelleuxColors.iconGoldGradient)
                }

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CelleuxColors.textSecondary)
            }
            .frame(width: 84)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : CelleuxColors.glassEdgeHighlight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: chipFlashId)
        .accessibilityLabel(title)
    }

    // MARK: - 5. Health Snapshot

    private var healthSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HEALTH SNAPSHOT")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(1.5)

            if viewModel.hasHealthSnapshotData {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if let sleep = viewModel.sleepValueString {
                            healthSnapshotCard(
                                icon: "moon.fill",
                                title: "Sleep",
                                value: sleep,
                                detail: viewModel.sleepDetailString,
                                sparkline: viewModel.sleepSparkline
                            )
                        }
                        if let hrv = viewModel.hrvValueString {
                            healthSnapshotCard(
                                icon: "heart.text.square",
                                title: "HRV",
                                value: hrv,
                                detail: viewModel.hrvDetailString,
                                sparkline: viewModel.hrvSparkline
                            )
                        }
                        if let hydration = viewModel.hydrationValueString {
                            healthSnapshotCard(
                                icon: "drop.fill",
                                title: "Hydration",
                                value: hydration,
                                detail: viewModel.hydrationDetailString,
                                sparkline: viewModel.hydrationSparkline
                            )
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
            } else {
                healthSnapshotEmptyState
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.18)
    }

    private func healthSnapshotCard(icon: String, title: String, value: String, detail: String?, sparkline: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CelleuxColors.warmGold)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .tracking(1.0)
            }

            Text(value)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(CelleuxColors.textPrimary)
                .contentTransition(.numericText())

            if let detail {
                Text(detail)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .lineLimit(1)
            }

            if sparkline.count >= 2 {
                miniSparkline(data: sparkline)
                    .frame(height: 28)
            }
        }
        .frame(width: 150)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : CelleuxColors.glassEdgeHighlight, lineWidth: 1)
        )
        .celleuxDepthShadow()
    }

    private func miniSparkline(data: [Double]) -> some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Day", index),
                    y: .value("Score", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(CelleuxColors.warmGold.opacity(0.8))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...100)
    }

    private var healthSnapshotEmptyState: some View {
        HStack(spacing: 14) {
            Image(systemName: "applewatch")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(CelleuxColors.silver)

            VStack(alignment: .leading, spacing: 3) {
                Text("Connect Apple Watch")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CelleuxColors.textPrimary)
                Text("For deeper sleep, HRV & hydration insights")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : CelleuxColors.glassEdgeHighlight, lineWidth: 1)
        )
        .celleuxDepthShadow()
    }

    // MARK: - 6. Weekly Trend (Swift Charts)

    private var weeklyTrendCard: some View {
        GlassCard(depth: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.dataGold)
                        Text("YOUR SKIN THIS WEEK")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .tracking(1.5)
                    }
                    Spacer()
                    Button {
                        switchTab(.insights)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }

                weeklySwiftChart
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.selectedWeeklyScore?.id)
        .staggeredAppear(appeared: appeared, delay: 0.26)
    }

    @ViewBuilder
    private var weeklySwiftChart: some View {
        let scores = viewModel.weeklyScores
        if scores.count >= 2 {
            let minY = max(0, (scores.map(\.score).min() ?? 50) - 10)
            let maxY = min(100, (scores.map(\.score).max() ?? 80) + 10)

            Chart {
                ForEach(scores) { score in
                    AreaMark(
                        x: .value("Day", score.date),
                        y: .value("Score", score.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                CelleuxColors.warmGold.opacity(0.3),
                                CelleuxColors.warmGold.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Day", score.date),
                        y: .value("Score", score.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    PointMark(
                        x: .value("Day", score.date),
                        y: .value("Score", score.score)
                    )
                    .foregroundStyle(viewModel.selectedWeeklyScore?.id == score.id ? CelleuxColors.warmGold : CelleuxColors.warmGold.opacity(0.6))
                    .symbolSize(viewModel.selectedWeeklyScore?.id == score.id ? 60 : 20)
                    .annotation(position: .top, spacing: 6) {
                        if viewModel.selectedWeeklyScore?.id == score.id {
                            VStack(spacing: 2) {
                                Text("\(Int(score.score))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(CelleuxColors.textPrimary)
                                Text(score.day)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.95))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(CelleuxColors.warmGold.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .chartYScale(domain: minY...maxY)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 10))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(CelleuxColors.textLabel)
                    AxisGridLine()
                        .foregroundStyle(CelleuxColors.silver.opacity(0.1))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let date: Date = proxy.value(atX: location.x) else { return }
                            let closest = scores.min(by: {
                                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                            })
                            withAnimation(CelleuxSpring.snappy) {
                                if viewModel.selectedWeeklyScore?.id == closest?.id {
                                    viewModel.selectedWeeklyScore = nil
                                } else {
                                    viewModel.selectedWeeklyScore = closest
                                }
                            }
                        }
                }
            }
            .frame(height: 160)

            if scores.count < 7 {
                Text("\(scores.count) of 7 days tracked")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .frame(maxWidth: .infinity)
            }
        } else if scores.count == 1 {
            VStack(spacing: 8) {
                Text("\(Int(scores[0].score))")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(CelleuxColors.textPrimary)
                Text("Complete more scans to see trends")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            Text("Complete more scans to see trends")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        }
    }

    @ViewBuilder
    private var streakAchievementSection: some View {
        VStack(spacing: 16) {
            if viewModel.streakDays > 0 {
                streakCard
            }
            achievementCard
            nextAchievementCard
        }
        .sensoryFeedback(.success, trigger: achievementCelebration)
        .staggeredAppear(appeared: appeared, delay: 0.32)
    }

    private var streakCard: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.03)], center: .center, startRadius: 0, endRadius: 30))
                            .frame(width: 56, height: 56)
                        Circle()
                            .stroke(AngularGradient(colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.45)], center: .center), lineWidth: 1)
                            .frame(width: 56, height: 56)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(LinearGradient(colors: [CelleuxColors.roseGold, CelleuxColors.warmGold], startPoint: .top, endPoint: .bottom))
                            .symbolEffect(.breathe, isActive: appeared)
                    }
                    .shadow(color: CelleuxColors.warmGold.opacity(0.2), radius: 10, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(viewModel.streakDays)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(CelleuxColors.goldGradient)
                                .contentTransition(.numericText())
                            Text("day streak")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(CelleuxColors.textPrimary)
                        }
                        Text("Consistency is the real anti-aging secret")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .lineSpacing(4)
                    }
                    Spacer()
                }

                streakMilestoneBar
            }
        }
    }

    private var streakMilestoneBar: some View {
        let milestone = viewModel.streakMilestone
        return VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CelleuxColors.silver.opacity(0.1))
                        .frame(height: 6)

                    Capsule()
                        .fill(CelleuxColors.goldGradient)
                        .frame(width: geo.size.width * milestone.progress, height: 6)
                        .shadow(color: CelleuxColors.warmGold.opacity(0.4), radius: 4, x: 0, y: 0)
                        .animation(CelleuxSpring.luxury, value: milestone.progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(milestone.daysRemaining) days to \(milestone.next)-day milestone")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
                Spacer()
                Text("\(Int(milestone.progress * 100))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CelleuxColors.warmGold)
                    .contentTransition(.numericText())
            }
        }
    }

    @ViewBuilder
    private var achievementCard: some View {
        if let achievement = viewModel.latestAchievement {
            ZStack {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [CelleuxColors.warmGold.opacity(0.12), CelleuxColors.warmGold.opacity(0.02)], center: .center, startRadius: 0, endRadius: 26))
                            .frame(width: 50, height: 50)
                        Circle()
                            .stroke(AngularGradient(colors: [CelleuxColors.warmGold.opacity(0.5), CelleuxColors.warmGold.opacity(0.15), CelleuxColors.roseGold.opacity(0.4)], center: .center), lineWidth: 1)
                            .frame(width: 50, height: 50)
                        Image(systemName: achievement.icon)
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(LinearGradient(colors: [CelleuxColors.roseGold, CelleuxColors.warmGold], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .symbolEffect(.bounce, value: achievementCelebration)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("LATEST ACHIEVEMENT")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .tracking(0.8)
                            .textCase(.uppercase)
                        Text(achievement.title)
                            .font(.system(size: 18, weight: .medium))
                            .tracking(0.3)
                            .foregroundStyle(CelleuxColors.textPrimary)
                        Text(achievement.subtitle)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : CelleuxColors.glassEdgeHighlight, lineWidth: 1)
                )
                .celleuxDepthShadow()

                if achievementCelebration {
                    CelebrationParticleBurst(isActive: achievementCelebration)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    @ViewBuilder
    private var nextAchievementCard: some View {
        if let next = viewModel.nextAchievement {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(CelleuxColors.silver.opacity(0.06))
                        .frame(width: 46, height: 46)
                    Circle()
                        .stroke(CelleuxColors.silver.opacity(0.15), lineWidth: 1)
                        .frame(width: 46, height: 46)

                    Circle()
                        .trim(from: 0, to: next.progress)
                        .stroke(
                            LinearGradient(colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.warmGold], startPoint: .topLeading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 46, height: 46)
                        .rotationEffect(.degrees(-90))
                        .animation(CelleuxSpring.luxury, value: next.progress)

                    Image(systemName: next.icon)
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(CelleuxColors.silver.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("NEXT ACHIEVEMENT")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .tracking(0.8)

                    Text(next.title)
                        .font(.system(size: 15, weight: .medium))
                        .tracking(0.3)
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text(next.subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(Int(next.progress * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CelleuxColors.warmGold)
                    .contentTransition(.numericText())
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : CelleuxColors.glassEdgeHighlight, lineWidth: 1)
            )
            .celleuxDepthShadow()
        }
    }

    // MARK: - Challenge Card

    @ViewBuilder
    private var challengeCard: some View {
        if let challenge = activeChallenges.first {
            Button {
                showChallengeDetail = true
            } label: {
                GlassCard {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(CelleuxColors.silver.opacity(0.12), lineWidth: 5)
                                .frame(width: 64, height: 64)

                            Circle()
                                .trim(from: 0, to: challenge.progress)
                                .stroke(
                                    AngularGradient(
                                        colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.roseGold, CelleuxColors.warmGold],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                )
                                .frame(width: 64, height: 64)
                                .rotationEffect(.degrees(-90))
                                .animation(CelleuxSpring.luxury, value: challenge.progress)

                            VStack(spacing: 0) {
                                Text("\(challenge.currentDay)")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(CelleuxColors.textPrimary)
                                    .contentTransition(.numericText())
                                Text("/90")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("90-DAY CHALLENGE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(CelleuxColors.warmGold)
                                .tracking(0.8)

                            Text("\(challenge.checkedInDayCount) check-ins \u{2022} \(Int(challenge.progress * 100))% complete")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CelleuxColors.textPrimary)

                            let target = challenge.currentMilestoneTarget
                            let daysTo = max(0, target - challenge.daysSinceStart)
                            Text("\(daysTo) days to \(target)-day milestone")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.silver)
                    }
                }
            }
            .buttonStyle(.plain)
            .staggeredAppear(appeared: appeared, delay: 0.38)
        } else {
            Button {
                showChallengeDetail = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [CelleuxColors.warmGold.opacity(0.1), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 28
                                )
                            )
                            .frame(width: 50, height: 50)
                        Image(systemName: "trophy")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("90-DAY TRANSFORMATION")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .tracking(0.8)
                        Text("Start your skin transformation journey")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CelleuxColors.silver)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.88))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : CelleuxColors.glassEdgeHighlight, lineWidth: 1)
                )
                .celleuxDepthShadow()
            }
            .buttonStyle(.plain)
            .staggeredAppear(appeared: appeared, delay: 0.38)
        }
    }
}

// MARK: - Mini Factor Ring

struct MiniFactorRing: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(CelleuxColors.silver.opacity(0.15), lineWidth: 3)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [CelleuxColors.warmGold.opacity(0.8), CelleuxColors.warmGold],
                        startPoint: .topLeading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Factor Detail Sheet

struct LongevityFactorDetailSheet: View {
    let factor: LongevityFactor
    let score: Double
    let detail: String
    let hasData: Bool
    let history: [(date: Date, score: Double)]

    @State private var ringGlow: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    if !history.isEmpty {
                        trendSection
                    }
                    impactSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(factor.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    ringGlow = true
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                LuxuryBezelRing(
                    progress: hasData ? score / 100 : 0,
                    size: 120,
                    lineWidth: 8,
                    glowing: $ringGlow
                )

                if hasData {
                    Text("\(Int(score))")
                        .font(.system(size: 36, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .contentTransition(.numericText())
                } else {
                    Text("\u{2014}")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }

            Text(detail)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CelleuxColors.textSecondary)

            HStack(spacing: 4) {
                Text("Weight:")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
                Text("\(Int(factor.weight * 100))% of composite")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CelleuxColors.warmGold)
            }
        }
        .frame(maxWidth: .infinity)
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-DAY TREND")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(1.5)

            Chart {
                ForEach(Array(history.enumerated()), id: \.offset) { index, entry in
                    LineMark(
                        x: .value("Day", entry.date),
                        y: .value("Score", entry.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(CelleuxColors.warmGold)

                    PointMark(
                        x: .value("Day", entry.date),
                        y: .value("Score", entry.score)
                    )
                    .foregroundStyle(CelleuxColors.warmGold)
                    .symbolSize(24)
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 10))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(CelleuxColors.textLabel)
                    AxisGridLine()
                        .foregroundStyle(CelleuxColors.silver.opacity(0.15))
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .staggeredAppear(appeared: appeared, delay: 0.08)
    }

    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW IT AFFECTS YOUR SKIN")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(CelleuxColors.textLabel)
                .tracking(1.5)

            Text(factor.skinImpact)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(CelleuxColors.textSecondary)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .staggeredAppear(appeared: appeared, delay: 0.14)
    }
}

// MARK: - Mood Check-In Sheet

struct MoodCheckInSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var valenceValue: Double = 0.0
    @State private var selectedLabels: Set<MoodLabelOption> = []
    @State private var selectedAssociations: Set<MoodAssociationOption> = []
    @State private var note: String = ""
    @State private var hapticTrigger: Int = 0
    @State private var isSaving: Bool = false
    @State private var saveTrigger: Bool = false

    private let healthService = HealthKitService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    valenceSection
                    labelsSection
                    associationsSection
                    noteSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .sensoryFeedback(.selection, trigger: hapticTrigger)
            .sensoryFeedback(.success, trigger: saveTrigger)
            .navigationTitle("State of Mind")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(CelleuxColors.textLabel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveStateOfMind()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(CelleuxColors.warmGold)
                    .disabled(isSaving)
                }
            }
        }
    }

    private var valenceSection: some View {
        VStack(spacing: 16) {
            Text("How are you feeling?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(CelleuxColors.textPrimary)

            Text(valenceLabel)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(valenceColor)
                .contentTransition(.numericText())

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "E53935").opacity(0.3),
                                CelleuxP3.warmCream,
                                CelleuxColors.warmGold.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 8)

                Slider(value: $valenceValue, in: -1.0...1.0, step: 0.05)
                    .tint(.clear)
                    .onChange(of: valenceValue) { _, _ in
                        hapticTrigger += 1
                    }
            }

            HStack {
                Text("Very Unpleasant")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
                Spacer()
                Text("Very Pleasant")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
    }

    private var valenceLabel: String {
        if valenceValue < -0.71 { return "Very Unpleasant" }
        if valenceValue < -0.43 { return "Unpleasant" }
        if valenceValue < -0.14 { return "Slightly Unpleasant" }
        if valenceValue < 0.14 { return "Neutral" }
        if valenceValue < 0.43 { return "Slightly Pleasant" }
        if valenceValue < 0.71 { return "Pleasant" }
        return "Very Pleasant"
    }

    private var valenceColor: Color {
        if valenceValue < -0.3 { return Color(hex: "E53935") }
        if valenceValue < 0.3 { return CelleuxColors.textSecondary }
        return CelleuxColors.warmGold
    }

    private var labelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT BEST DESCRIBES THIS FEELING?")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(CelleuxColors.textPrimary.opacity(0.55))
                .tracking(1.2)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                ForEach(MoodLabelOption.allCases) { label in
                    Button {
                        if selectedLabels.contains(label) {
                            selectedLabels.remove(label)
                        } else {
                            selectedLabels.insert(label)
                        }
                        hapticTrigger += 1
                    } label: {
                        Text(label.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(selectedLabels.contains(label) ? CelleuxColors.warmGold : CelleuxColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedLabels.contains(label) ? CelleuxColors.warmGold.opacity(0.12) : Color.white.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectedLabels.contains(label) ? CelleuxColors.warmGold.opacity(0.5) : Color.white.opacity(0.8), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var associationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT'S THIS RELATED TO?")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(CelleuxColors.textPrimary.opacity(0.55))
                .tracking(1.2)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(MoodAssociationOption.allCases) { assoc in
                    Button {
                        if selectedAssociations.contains(assoc) {
                            selectedAssociations.remove(assoc)
                        } else {
                            selectedAssociations.insert(assoc)
                        }
                        hapticTrigger += 1
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: assoc.icon)
                                .font(.system(size: 10))
                            Text(assoc.displayName)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(selectedAssociations.contains(assoc) ? CelleuxColors.warmGold : CelleuxColors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedAssociations.contains(assoc) ? CelleuxColors.warmGold.opacity(0.12) : Color.white.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selectedAssociations.contains(assoc) ? CelleuxColors.warmGold.opacity(0.5) : Color.white.opacity(0.8), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var noteSection: some View {
        TextField("Optional note...", text: $note, axis: .vertical)
            .lineLimit(2...4)
            .font(.system(size: 14))
            .foregroundStyle(CelleuxColors.textPrimary)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
    }

    private func saveStateOfMind() {
        isSaving = true
        let hkLabels = selectedLabels.map(\.hkLabel)
        let hkAssociations = selectedAssociations.map(\.hkAssociation)

        Task {
            _ = await healthService.saveStateOfMind(
                valence: valenceValue,
                kind: .momentaryEmotion,
                labels: hkLabels,
                associations: hkAssociations
            )

            let moodString: String
            if valenceValue > 0.3 { moodString = "Great" }
            else if valenceValue > 0 { moodString = "Good" }
            else if valenceValue > -0.3 { moodString = "Okay" }
            else { moodString = "Low" }

            let checkIn = DailyCheckIn(
                date: Date(),
                mood: moodString,
                energy: "",
                note: note,
                adherence: true
            )
            modelContext.insert(checkIn)
            try? modelContext.save()

            saveTrigger.toggle()
            isSaving = false
            dismiss()
        }
    }
}

import HealthKit

nonisolated enum MoodLabelOption: String, CaseIterable, Identifiable, Hashable, Sendable {
    case stressed, anxious, worried, drained
    case calm, content, peaceful, happy
    case grateful, joyful, excited, confident

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var hkLabel: HKStateOfMind.Label {
        switch self {
        case .stressed: .stressed
        case .anxious: .anxious
        case .worried: .worried
        case .drained: .drained
        case .calm: .calm
        case .content: .content
        case .peaceful: .peaceful
        case .happy: .happy
        case .grateful: .grateful
        case .joyful: .joyful
        case .excited: .excited
        case .confident: .confident
        }
    }
}

nonisolated enum MoodAssociationOption: String, CaseIterable, Identifiable, Hashable, Sendable {
    case health, fitness, work, weather, selfCare

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .selfCare: "Self-Care"
        default: rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .health: "heart.fill"
        case .fitness: "figure.run"
        case .work: "briefcase.fill"
        case .weather: "cloud.sun.fill"
        case .selfCare: "sparkles"
        }
    }

    var hkAssociation: HKStateOfMind.Association {
        switch self {
        case .health: .health
        case .fitness: .fitness
        case .work: .work
        case .weather: .weather
        case .selfCare: .selfCare
        }
    }
}

struct ChromeToolbarButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String

    private static let chromeBorder = AngularGradient(
        colors: [CelleuxP3.warmCream.opacity(0.6), CelleuxP3.coolSilver.opacity(0.25), Color.white.opacity(0.5)],
        center: .center
    )

    private static let darkChromeBorder = AngularGradient(
        colors: [Color.white.opacity(0.12), CelleuxColors.warmGold.opacity(0.15), Color.white.opacity(0.08)],
        center: .center
    )

    var body: some View {
        ZStack {
            Circle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.95))
                .frame(width: 44, height: 44)
            Circle()
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : CelleuxColors.iconHighlightGradient, lineWidth: 1)
                .frame(width: 44, height: 44)
            Circle()
                .stroke(colorScheme == .dark ? Self.darkChromeBorder : Self.chromeBorder, lineWidth: 0.5)
                .frame(width: 44, height: 44)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.9) : CelleuxColors.textPrimary)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 3)
    }
}
