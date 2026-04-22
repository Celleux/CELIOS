import SwiftUI
import SwiftData
import Charts

struct ChallengeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<SkinTransformationChallenge> { $0.isActive == true }) private var activeChallenges: [SkinTransformationChallenge]
    @Query(sort: \SkinTransformationChallenge.startDate, order: .reverse) private var allChallenges: [SkinTransformationChallenge]
    @Query(sort: \SkinScanRecord.date, order: .reverse) private var allScans: [SkinScanRecord]
    @State private var appeared: Bool = false
    @State private var ringGlow: Bool = false
    @State private var showRestartAlert: Bool = false
    @State private var showAbandonAlert: Bool = false

    private var challenge: SkinTransformationChallenge? { activeChallenges.first ?? allChallenges.first }
    private var hasActiveChallenge: Bool { activeChallenges.first != nil }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 28) {
                if let challenge, (challenge.isActive || challenge.isCompleted) {
                    heroProgressRing(challenge)
                    milestoneTimeline(challenge)
                    checkInCalendar(challenge)
                    if challenge.daysSinceStart >= 7, !allScans.isEmpty {
                        beforeAfterSection(challenge)
                        metricBreakdown(challenge)
                    }
                    if challengeScores(challenge).count >= 2 {
                        trendChart(challenge)
                    }
                    actionButtons(challenge)
                } else {
                    startChallengeCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .background(CelleuxMeshBackground())
        .navigationTitle("90-Day Challenge")
        .navigationBarTitleDisplayMode(.large)
        .alert("Restart Challenge?", isPresented: $showRestartAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Restart", role: .destructive) { restartChallenge() }
        } message: {
            Text("This will start a new 90-day challenge. Your previous challenge data will be kept.")
        }
        .alert("Abandon Challenge?", isPresented: $showAbandonAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Abandon", role: .destructive) { abandonChallenge() }
        } message: {
            Text("You can start a new challenge anytime after abandoning.")
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                ringGlow = true
            }
        }
    }

    // MARK: - Hero Progress Ring

    private func heroProgressRing(_ challenge: SkinTransformationChallenge) -> some View {
        GlassCard(depth: .elevated, showShimmer: challenge.isCompleted) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(CelleuxColors.silver.opacity(0.12), lineWidth: 10)
                        .frame(width: 160, height: 160)

                    Circle()
                        .trim(from: 0, to: challenge.progress)
                        .stroke(
                            AngularGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.roseGold, CelleuxColors.warmGold],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: CelleuxColors.warmGold.opacity(ringGlow ? 0.4 : 0.15), radius: ringGlow ? 12 : 6)
                        .animation(CelleuxSpring.luxury, value: challenge.progress)

                    VStack(spacing: 4) {
                        Text("DAY")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .tracking(1.5)

                        Text("\(challenge.currentDay)")
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText())

                        Text("of 90")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }

                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("\(challenge.checkedInDayCount)")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText())
                        Text("CHECK-INS")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .tracking(1)
                    }

                    Rectangle()
                        .fill(CelleuxColors.silver.opacity(0.15))
                        .frame(width: 1, height: 28)

                    VStack(spacing: 2) {
                        Text("\(Int(challenge.progress * 100))%")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .contentTransition(.numericText())
                        Text("COMPLETE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .tracking(1)
                    }

                    Rectangle()
                        .fill(CelleuxColors.silver.opacity(0.15))
                        .frame(width: 1, height: 28)

                    VStack(spacing: 2) {
                        Text("\(challenge.daysRemaining)")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText())
                        Text("REMAINING")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .tracking(1)
                    }
                }

                if challenge.isCompleted {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                        Text("CHALLENGE COMPLETE")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(1.5)
                    }
                    .foregroundStyle(CelleuxColors.warmGold)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    // MARK: - Milestone Timeline

    private func milestoneTimeline(_ challenge: SkinTransformationChallenge) -> some View {
        let milestones = buildMilestones(challenge)

        return GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(CelleuxColors.warmGold)
                    Text("MILESTONES")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.sectionLabel)
                        .tracking(1.5)
                }
                .padding(.bottom, 20)

                ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                    HStack(spacing: 16) {
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(milestone.isReached ? CelleuxColors.warmGold : CelleuxColors.silver.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                if milestone.isReached {
                                    Circle()
                                        .stroke(CelleuxColors.warmGold.opacity(0.3), lineWidth: 1)
                                        .frame(width: 32, height: 32)
                                }

                                Image(systemName: milestone.icon)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(milestone.isReached ? .white : CelleuxColors.silver.opacity(0.5))
                            }

                            if index < milestones.count - 1 {
                                Rectangle()
                                    .fill(
                                        milestones[index + 1].isReached
                                            ? CelleuxColors.warmGold.opacity(0.5)
                                            : CelleuxColors.silver.opacity(0.12)
                                    )
                                    .frame(width: 2, height: 28)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(milestone.title)
                                .font(.system(size: 15, weight: milestone.isReached ? .semibold : .medium))
                                .foregroundStyle(milestone.isReached ? CelleuxColors.textPrimary : CelleuxColors.textLabel)

                            if let date = milestone.reachedDate {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(CelleuxColors.warmGold)
                            } else {
                                let daysToGo = max(0, milestone.day - challenge.daysSinceStart)
                                Text("\(daysToGo) days away")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(CelleuxColors.textLabel)
                            }
                        }

                        Spacer()

                        if milestone.isReached {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(CelleuxColors.warmGold)
                        }
                    }
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.08)
    }

    // MARK: - Check-In Calendar

    private func checkInCalendar(_ challenge: SkinTransformationChallenge) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days: [Date] = (0..<30).compactMap { offset in
            calendar.date(byAdding: .day, value: -29 + offset, to: today)
        }

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(CelleuxColors.warmGold)
                    Text("LAST 30 DAYS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.sectionLabel)
                        .tracking(1.5)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(days, id: \.self) { day in
                        let isActive = day >= calendar.startOfDay(for: challenge.startDate)
                        let checked = challenge.isCheckedIn(on: day)
                        let isToday = calendar.isDateInToday(day)

                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    checked ? CelleuxColors.warmGold.opacity(0.18) :
                                    isToday ? CelleuxColors.silver.opacity(0.08) :
                                    Color.clear
                                )
                                .frame(height: 32)

                            if checked {
                                Circle()
                                    .fill(CelleuxColors.warmGold)
                                    .frame(width: 8, height: 8)
                            } else if isActive && day <= today {
                                Circle()
                                    .fill(CelleuxColors.silver.opacity(0.2))
                                    .frame(width: 6, height: 6)
                            }

                            if isToday {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(CelleuxColors.warmGold.opacity(0.4), lineWidth: 1)
                                    .frame(height: 32)
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(CelleuxColors.warmGold)
                            .frame(width: 6, height: 6)
                        Text("Checked in")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(CelleuxColors.silver.opacity(0.2))
                            .frame(width: 6, height: 6)
                        Text("Missed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.16)
    }

    // MARK: - Before/After

    private func beforeAfterSection(_ challenge: SkinTransformationChallenge) -> some View {
        let latestScore = allScans.first.map { $0.overallScore } ?? 0
        let delta = latestScore - challenge.baselineScore

        return GlassCard {
            VStack(spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12))
                        .foregroundStyle(CelleuxColors.warmGold)
                    Text("BEFORE & AFTER")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.sectionLabel)
                        .tracking(1.5)
                }

                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("START")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .tracking(1)
                        Text("\(challenge.baselineScore)")
                            .font(.system(size: 42, weight: .ultraLight))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText())
                        Text(challenge.startDate.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 6) {
                        Image(systemName: delta >= 0 ? "arrow.right" : "arrow.right")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(CelleuxColors.warmGold)

                        HStack(spacing: 2) {
                            Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                            Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(delta >= 0 ? CelleuxColors.warmGold : CelleuxColors.silver)
                    }
                    .frame(width: 60)

                    VStack(spacing: 6) {
                        Text("NOW")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .tracking(1)
                        Text("\(latestScore)")
                            .font(.system(size: 42, weight: .ultraLight))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText())
                        Text("Today")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.24)
    }

    // MARK: - Metric Breakdown

    private func metricBreakdown(_ challenge: SkinTransformationChallenge) -> some View {
        let latest = allScans.first

        let metrics: [(String, Double, Double)] = [
            ("Texture", challenge.baselineTexture, latest?.textureEvennessScore ?? 0),
            ("Hydration", challenge.baselineHydration, latest?.apparentHydrationScore ?? 0),
            ("Radiance", challenge.baselineRadiance, latest?.brightnessRadianceScore ?? 0),
            ("Tone", challenge.baselineTone, latest?.toneUniformityScore ?? 0),
            ("Under-Eye", challenge.baselineUnderEye, latest?.underEyeQualityScore ?? 0),
            ("Elasticity", challenge.baselineElasticity, latest?.elasticityProxyScore ?? 0),
        ]

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(CelleuxColors.warmGold)
                    Text("METRIC CHANGES")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.sectionLabel)
                        .tracking(1.5)
                }

                ForEach(metrics, id: \.0) { name, baseline, current in
                    let delta = current - baseline
                    HStack(spacing: 12) {
                        Text(name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .frame(width: 80, alignment: .leading)

                        Text("\(Int(baseline))")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(CelleuxColors.textLabel)
                            .frame(width: 30, alignment: .trailing)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(CelleuxColors.silver)

                        Text("\(Int(current))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .frame(width: 30, alignment: .trailing)

                        Spacer()

                        HStack(spacing: 2) {
                            Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 9, weight: .bold))
                            Text(delta >= 0 ? "+\(Int(delta))" : "\(Int(delta))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(delta >= 0 ? CelleuxColors.warmGold : CelleuxColors.silver)
                    }

                    if name != "Elasticity" {
                        PremiumDivider()
                    }
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.28)
    }

    // MARK: - Trend Chart

    private func trendChart(_ challenge: SkinTransformationChallenge) -> some View {
        let scores = challengeScores(challenge)

        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12))
                        .foregroundStyle(CelleuxColors.warmGold)
                    Text("SCORE JOURNEY")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.sectionLabel)
                        .tracking(1.5)
                }

                Chart(scores, id: \.date) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Score", entry.score)
                    )
                    .foregroundStyle(CelleuxColors.warmGold)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Score", entry.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.system(size: 9))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(CelleuxColors.silver.opacity(0.15))
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }
                }
                .frame(height: 180)
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.32)
    }

    // MARK: - Action Buttons

    private func actionButtons(_ challenge: SkinTransformationChallenge) -> some View {
        VStack(spacing: 12) {
            if challenge.isCompleted {
                Button {
                    showRestartAlert = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Start New Challenge")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(CelleuxColors.goldGradient)
                    )
                    .celleuxDepthShadow()
                }
            } else if challenge.isActive {
                Button {
                    showAbandonAlert = true
                } label: {
                    Text("Abandon Challenge")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(CelleuxColors.silver.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(CelleuxColors.silver.opacity(0.15), lineWidth: 1)
                        )
                }

                Button {
                    showRestartAlert = true
                } label: {
                    Text("Restart Challenge")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.36)
    }

    // MARK: - Start Card

    private var startChallengeCard: some View {
        GlassCard(depth: .elevated, showShimmer: true) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CelleuxColors.roseGold, CelleuxColors.warmGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.breathe, isActive: appeared)
                }

                VStack(spacing: 8) {
                    Text("90-Day Skin Transformation")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Commit to 90 days of consistent skincare. Track your progress, hit milestones, and see your transformation.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(CelleuxColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Button {
                    startNewChallenge()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13))
                        Text("Begin Challenge")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(CelleuxColors.goldGradient)
                    )
                    .celleuxDepthShadow()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    // MARK: - Helpers

    private func buildMilestones(_ challenge: SkinTransformationChallenge) -> [ChallengeMilestone] {
        [
            ChallengeMilestone(id: 0, day: 7, title: "First Week", icon: "7.circle.fill", reachedDate: challenge.milestone7Date),
            ChallengeMilestone(id: 1, day: 14, title: "Two Weeks", icon: "bolt.fill", reachedDate: challenge.milestone14Date),
            ChallengeMilestone(id: 2, day: 30, title: "One Month", icon: "moon.fill", reachedDate: challenge.milestone30Date),
            ChallengeMilestone(id: 3, day: 60, title: "Two Months", icon: "flame.fill", reachedDate: challenge.milestone60Date),
            ChallengeMilestone(id: 4, day: 90, title: "Challenge Complete", icon: "crown.fill", reachedDate: challenge.milestone90Date),
        ]
    }

    private func challengeScores(_ challenge: SkinTransformationChallenge) -> [(date: Date, score: Double)] {
        let startDay = Calendar.current.startOfDay(for: challenge.startDate)
        return allScans
            .filter { $0.date >= startDay }
            .sorted { $0.date < $1.date }
            .map { (date: $0.date, score: Double($0.overallScore)) }
    }

    private func startNewChallenge() {
        let latestScan = allScans.first
        let challenge = SkinTransformationChallenge(
            startDate: Date(),
            baselineScore: latestScan?.overallScore ?? 0,
            baselineTexture: latestScan?.textureEvennessScore ?? 0,
            baselineHydration: latestScan?.apparentHydrationScore ?? 0,
            baselineRadiance: latestScan?.brightnessRadianceScore ?? 0,
            baselineTone: latestScan?.toneUniformityScore ?? 0,
            baselineUnderEye: latestScan?.underEyeQualityScore ?? 0,
            baselineElasticity: latestScan?.elasticityProxyScore ?? 0
        )
        modelContext.insert(challenge)
        try? modelContext.save()
    }

    private func restartChallenge() {
        if let current = activeChallenges.first {
            current.abandon()
        }
        startNewChallenge()
    }

    private func abandonChallenge() {
        if let current = activeChallenges.first {
            current.abandon()
            try? modelContext.save()
        }
    }
}
