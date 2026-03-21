import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    var switchTab: (AppTab) -> Void
    @State private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var appeared: Bool = false
    @State private var scoreAnimated: Bool = false
    @State private var ringGlow: Bool = false
    @State private var protocolToggleTrigger: Bool = false
    @State private var selectedDay: Int? = nil
    @State private var showLongevityScore: Bool = false
    @State private var showMoodCheckIn: Bool = false
    @State private var breathingShadow: Bool = false
    @State private var overdueGlow: Bool = false
    @State private var selectedFactor: LongevityFactor? = nil
    @Namespace private var heroAnimation

    var body: some View {
        NavigationStack {
            ZStack {
                CelleuxMeshBackground()

                CelleuxParticleView()
                    .opacity(0.6)

                ScrollView {
                    VStack(spacing: 32) {
                        greetingSection
                        if viewModel.hasData {
                            skinScoreHeroCard
                        } else {
                            emptyScoreCard
                        }
                        longevityCompositeCard
                        todaysProtocolCard
                        quickActionsRow
                        if !viewModel.weeklyScores.isEmpty {
                            weeklySnapshotCard
                        }
                        if viewModel.streakDays > 0 {
                            streakCard
                        }
                        achievementCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    viewModel.loadData(modelContext: modelContext)
                }
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
            .navigationDestination(isPresented: $showLongevityScore) {
                SkinLongevityScoreView()
                    .navigationTransition(.zoom(sourceID: "scoreHero", in: heroAnimation))
            }
            .sheet(isPresented: $showMoodCheckIn) {
                MoodCheckInSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground {
                        ZStack {
                            Color.white.opacity(0.82)
                            Color(red: 0.97, green: 0.96, blue: 0.94).opacity(0.5)
                        }
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea()
                    }
                    .presentationCornerRadius(32)
                    .presentationContentInteraction(.scrolls)
            }
            .sheet(item: $selectedFactor) { factor in
                FactorDetailSheet(
                    factor: factor,
                    score: viewModel.scoreForFactor(factor),
                    detail: viewModel.detailForFactor(factor),
                    hasData: viewModel.factorHasData(factor),
                    history: viewModel.historicalScoresForFactor(factor)
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground {
                    ZStack {
                        Color.white.opacity(0.82)
                        Color(red: 0.97, green: 0.96, blue: 0.94).opacity(0.5)
                    }
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                }
                .presentationCornerRadius(32)
                .presentationContentInteraction(.scrolls)
            }
            .onAppear {
                viewModel.loadData(modelContext: modelContext)
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
                        .fill(Color.white.opacity(0.95))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
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
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CelleuxColors.glassEdgeHighlight, lineWidth: 1)
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
        .staggeredAppear(appeared: appeared, delay: 0.06)
    }

    private var heroCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.92))
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CelleuxColors.glassEdgeHighlight, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 30, x: 0, y: 15)
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
    }

    // MARK: - Existing Sections (unchanged)

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

                VStack(spacing: 0) {
                    ForEach(Array(viewModel.protocolItems.enumerated()), id: \.element.id) { index, item in
                        protocolRow(item: item, isLast: index == viewModel.protocolItems.count - 1)
                    }
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.14)
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
            }
        }
        .frame(height: 5)
    }

    private func protocolRow(item: ProtocolItem, isLast: Bool) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Button {
                    viewModel.toggleProtocolItem(item, modelContext: modelContext)
                    protocolToggleTrigger.toggle()
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
                Text(item.period)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .tracking(0.8)
                    .textCase(.uppercase)

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
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 56, height: 56)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.0)],
                                startPoint: .topLeading,
                                endPoint: .center
                            ),
                            lineWidth: 1.5
                        )
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
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CelleuxColors.glassEdgeHighlight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: chipFlashId)
    }

    private var weeklySnapshotCard: some View {
        Button { switchTab(.insights) } label: {
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
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    weeklyChart
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.3), trigger: false)
        .staggeredAppear(appeared: appeared, delay: 0.26)
    }

    private var weeklyChart: some View {
        let scores = viewModel.weeklyScores
        guard scores.count >= 2 else {
            return AnyView(
                Text("Complete more scans to see trends")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            )
        }
        let minScore = (scores.map(\.score).min() ?? 70) - 5
        let maxScore = (scores.map(\.score).max() ?? 80) + 5
        let range = maxScore - minScore

        return AnyView(
            GeometryReader { geo in
                let width = geo.size.width
                let height: CGFloat = 120
                let stepX = width / CGFloat(scores.count - 1)

                ZStack(alignment: .bottomLeading) {
                    Path { path in
                        for (index, score) in scores.enumerated() {
                            let x = stepX * CGFloat(index)
                            let y = height - ((score.score - minScore) / range * height)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                let prev = scores[index - 1]
                                let prevX = stepX * CGFloat(index - 1)
                                let prevY = height - ((prev.score - minScore) / range * height)
                                path.addCurve(
                                    to: CGPoint(x: x, y: y),
                                    control1: CGPoint(x: prevX + stepX * 0.4, y: prevY),
                                    control2: CGPoint(x: x - stepX * 0.4, y: y)
                                )
                            }
                        }
                    }
                    .trim(from: 0, to: scoreAnimated ? 1 : 0)
                    .stroke(
                        LinearGradient(colors: [CelleuxP3.coolSilver, CelleuxColors.warmGold], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                    ForEach(Array(scores.enumerated()), id: \.element.id) { index, score in
                        let x = stepX * CGFloat(index)
                        let y = height - ((score.score - minScore) / range * height)
                        ZStack {
                            Circle().fill(Color.white).frame(width: 10, height: 10)
                            Circle().fill(CelleuxColors.warmGold.opacity(0.7)).frame(width: 5, height: 5)
                        }
                        .position(x: x, y: y)
                        .opacity(scoreAnimated ? 1 : 0)
                    }

                    ForEach(Array(scores.enumerated()), id: \.element.id) { index, score in
                        let x = stepX * CGFloat(index)
                        Text(score.day)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .position(x: x, y: height + 16)
                    }
                }
            }
            .frame(height: 145)
        )
    }

    private var streakCard: some View {
        CompactGlassCard(cornerRadius: 24) {
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
        }
        .staggeredAppear(appeared: appeared, delay: 0.32)
    }

    @ViewBuilder
    private var achievementCard: some View {
        if let achievement = viewModel.latestAchievement {
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
                        .symbolEffect(.bounce, value: appeared)
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
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CelleuxColors.glassEdgeHighlight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.03), radius: 30, x: 0, y: 15)
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

struct FactorDetailSheet: View {
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
    let icon: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 44, height: 44)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: 44, height: 44)
            Circle().stroke(
                AngularGradient(colors: [CelleuxP3.warmCream.opacity(0.6), CelleuxP3.coolSilver.opacity(0.25), Color.white.opacity(0.5)], center: .center),
                lineWidth: 0.5
            ).frame(width: 44, height: 44)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20))
        }
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}
