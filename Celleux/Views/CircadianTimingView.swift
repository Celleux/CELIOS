import SwiftUI
import SwiftData

struct CircadianTimingView: View {
    @State private var viewModel = CircadianTimingViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var appeared: Bool = false
    @State private var toggleTrigger: Bool = false
    @State private var showSettings: Bool = false
    @State private var completionCelebration: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    timelineSection
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
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            GlassCard(depth: .elevated) {
                VStack(spacing: 14) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CelleuxColors.warmGold)
                            Text("YOUR PROTOCOL FOR TODAY")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.55))
                                .tracking(1.5)
                        }
                        Spacer()
                        Text("\(viewModel.completedCount) of \(viewModel.totalCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(CelleuxColors.warmGold)
                            .contentTransition(.numericText())
                    }

                    progressBar
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(CelleuxColors.silver.opacity(0.08))
                    .frame(height: 5)

                Capsule()
                    .fill(CelleuxColors.goldGradient)
                    .frame(
                        width: geo.size.width * CGFloat(viewModel.completedCount) / CGFloat(max(viewModel.totalCount, 1)),
                        height: 5
                    )
                    .shadow(color: CelleuxColors.warmGold.opacity(0.5), radius: 6)
            }
        }
        .frame(height: 5)
    }

    private var timelineSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.scheduleItems.enumerated()), id: \.element.id) { index, item in
                timelineRow(item: item, isLast: index == viewModel.scheduleItems.count - 1, delay: Double(index) * 0.06 + 0.08)
            }
        }
    }

    private func timelineRow(item: ScheduleItem, isLast: Bool, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(
                            item.isCompleted
                                ? RadialGradient(colors: [CelleuxColors.warmGold.opacity(0.3), CelleuxColors.warmGold.opacity(0.05)], center: .center, startRadius: 0, endRadius: 10)
                                : RadialGradient(colors: [CelleuxColors.silver.opacity(0.15), CelleuxColors.silver.opacity(0.03)], center: .center, startRadius: 0, endRadius: 10)
                        )
                        .frame(width: 18, height: 18)

                    Circle()
                        .fill(item.isCompleted ? Color(red: 0.79, green: 0.66, blue: 0.43) : CelleuxColors.silver)
                        .frame(width: 10, height: 10)
                }
                .shadow(color: item.isCompleted ? Color(red: 0.79, green: 0.66, blue: 0.43).opacity(0.3) : .clear, radius: 4)

                if !isLast {
                    Rectangle()
                        .fill(Color(red: 0.78, green: 0.78, blue: 0.82).opacity(0.4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 18)

            VStack(spacing: 0) {
                Text(item.timeString)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.5))
                    .tracking(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 1)

                scheduleCard(item: item)
                    .padding(.top, 8)
                    .padding(.bottom, isLast ? 0 : 20)
            }
        }
        .staggeredAppear(appeared: appeared, delay: delay)
    }

    private func scheduleCard(item: ScheduleItem) -> some View {
        let borderColor: LinearGradient = item.isActive
            ? LinearGradient(colors: [CelleuxColors.warmGold.opacity(0.6), CelleuxColors.warmGold.opacity(0.2), CelleuxColors.warmGold.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            : CelleuxColors.chromeBorder

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(item.isCompleted ? CelleuxColors.textLabel : CelleuxColors.textPrimary)
                    .strikethrough(item.isCompleted, color: CelleuxColors.textLabel)

                Spacer()

                if item.isMissed && !item.isCompleted {
                    Text("Missed")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "E8A838"))
                        .tracking(0.5)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(item.supplements, id: \.self) { supplement in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.79, green: 0.66, blue: 0.43).opacity(0.6))
                            .frame(width: 6, height: 6)
                        Text(supplement)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(item.isCompleted ? CelleuxColors.textLabel : CelleuxColors.textPrimary)
                    }
                }
            }

            Text(item.rationale)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(CelleuxColors.textLabel)
                .lineSpacing(3)

            PremiumDivider()

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
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: toggleTrigger)
            .sensoryFeedback(.success, trigger: completionCelebration)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    item.isActive ? AnyShapeStyle(borderColor) : AnyShapeStyle(CelleuxColors.glassEdgeHighlight),
                    lineWidth: item.isActive ? 1.5 : 1
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 30, x: 0, y: 15)
        .opacity(item.isCompleted ? 0.8 : 1)
    }

    private var scienceSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Timing Science")

            VStack(spacing: 10) {
                ForEach(viewModel.scienceCards) { card in
                    scienceCardView(card)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.32)
    }

    private func scienceCardView(_ card: TimingScienceCard) -> some View {
        let isExpanded = viewModel.expandedScienceCards.contains(card.id.uuidString)

        return CompactGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
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

    private var settingsSheet: some View {
        NavigationStack {
            @Bindable var vm = viewModel
            List {
                Section {
                    DatePicker("Wake Time", selection: $viewModel.wakeTime, displayedComponents: .hourAndMinute)
                        .tint(CelleuxColors.warmGold)
                        .listRowBackground(Color.white.opacity(0.55))

                    DatePicker("Workout Time", selection: $viewModel.workoutTime, displayedComponents: .hourAndMinute)
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
                    Text("Receive reminders at each supplement time.")
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
