import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var previousTab: AppTab = .home
    @State private var tabBounce: Bool = false
    @State private var rippleTab: AppTab? = nil
    @State private var ripplePhase: CGFloat = 0
    @State private var contentAppeared: Bool = false
    @State private var longPressTab: AppTab? = nil
    @Namespace private var tabNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            CelleuxMeshBackground()

            Group {
                switch selectedTab {
                case .home:
                    HomeView(switchTab: { selectedTab = $0 })
                case .scan:
                    ScanView()
                case .ritual:
                    CircadianTimingView()
                case .insights:
                    InsightsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.blurReplace)
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 12)
            .animation(CelleuxSpring.luxury.delay(0.05), value: contentAppeared)

            floatingTabBar
        }
        .ignoresSafeArea(.keyboard)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.6), trigger: longPressTab)
        .onChange(of: selectedTab) { _, _ in
            contentAppeared = false
            Task {
                try? await Task.sleep(for: .milliseconds(50))
                contentAppeared = true
            }
        }
        .onAppear { contentAppeared = true }
    }

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabItem(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(tabBarBackground)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func tabItem(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            guard selectedTab != tab else { return }
            previousTab = selectedTab
            rippleTab = tab
            ripplePhase = 0
            withAnimation(CelleuxSpring.snappy) {
                selectedTab = tab
            }
            withAnimation(.easeOut(duration: 0.55)) {
                ripplePhase = 1
            }
            tabBounce.toggle()
            Task {
                try? await Task.sleep(for: .milliseconds(650))
                rippleTab = nil
                ripplePhase = 0
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(CelleuxColors.warmGold.opacity(0.10))
                            .frame(width: 44, height: 44)
                            .matchedGeometryEffect(id: "tabPill", in: tabNamespace)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }

                    if rippleTab == tab {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        CelleuxColors.warmGold.opacity(0.18 * (1.0 - ripplePhase)),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 22 + ripplePhase * 20
                                )
                            )
                            .frame(width: 44 + ripplePhase * 16, height: 44 + ripplePhase * 16)
                            .transition(.opacity)
                            .allowsHitTesting(false)
                    }

                    Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .medium : .light))
                        .foregroundStyle(
                            isSelected
                                ? AnyShapeStyle(CelleuxColors.textPrimary)
                                : AnyShapeStyle(CelleuxColors.silverDark)
                        )
                        .symbolEffect(.bounce, value: tabBounce)
                        .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                        .animation(CelleuxSpring.bouncy, value: isSelected)
                }
                .frame(height: 36)

                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    CelleuxColors.warmGold.opacity(0.7),
                                    CelleuxColors.champagneGold
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 20, height: 2)
                        .shadow(color: CelleuxColors.goldGlow, radius: 4, x: 0, y: 1)
                        .matchedGeometryEffect(id: "tabUnderline", in: tabNamespace)
                        .transition(.opacity.combined(with: .scale(scale: 0.5)))
                }

                Text(tab.label.uppercased())
                    .font(.system(size: 8, weight: isSelected ? .semibold : .regular))
                    .tracking(CelleuxType.labelTracking)
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(CelleuxColors.warmGold)
                            : AnyShapeStyle(CelleuxColors.silverDark.opacity(0.7))
                    )
                    .animation(CelleuxSpring.snappy, value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(tab.quickActions, id: \.label) { action in
                Button {
                    if selectedTab != tab {
                        withAnimation(CelleuxSpring.snappy) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    Label(action.label, systemImage: action.icon)
                }
            }
        }
    }

    private var tabBarBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.95))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    AngularGradient(
                        colors: [
                            CelleuxColors.silverLight.opacity(0.6),
                            CelleuxColors.warmGold.opacity(0.45),
                            Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.8),
                            CelleuxColors.silverBorder.opacity(0.5),
                            CelleuxColors.champagneGold.opacity(0.35),
                            Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.7),
                            CelleuxColors.silverLight.opacity(0.6)
                        ],
                        center: .center
                    ),
                    lineWidth: 1.5
                )
        }
        .celleuxDepthShadow()
    }
}

nonisolated struct TabQuickAction {
    let label: String
    let icon: String
}

nonisolated enum AppTab: String, Hashable, CaseIterable {
    case home, scan, ritual, insights, profile

    var icon: String {
        switch self {
        case .home: "house"
        case .scan: "viewfinder"
        case .ritual: "leaf"
        case .insights: "chart.line.uptrend.xyaxis"
        case .profile: "person"
        }
    }

    var activeIcon: String {
        switch self {
        case .home: "house.fill"
        case .scan: "viewfinder"
        case .ritual: "leaf.fill"
        case .insights: "chart.line.uptrend.xyaxis"
        case .profile: "person.fill"
        }
    }

    var label: String {
        switch self {
        case .home: "Home"
        case .scan: "Scan"
        case .ritual: "Ritual"
        case .insights: "Insights"
        case .profile: "Profile"
        }
    }

    var quickActions: [TabQuickAction] {
        switch self {
        case .home:
            [
                TabQuickAction(label: "Today's Score", icon: "star.fill"),
                TabQuickAction(label: "Weekly Snapshot", icon: "calendar")
            ]
        case .scan:
            [
                TabQuickAction(label: "Quick Scan", icon: "camera.fill"),
                TabQuickAction(label: "Scan History", icon: "clock.arrow.circlepath")
            ]
        case .ritual:
            [
                TabQuickAction(label: "Start Ritual", icon: "play.fill"),
                TabQuickAction(label: "View Schedule", icon: "clock")
            ]
        case .insights:
            [
                TabQuickAction(label: "Skin Trends", icon: "chart.line.uptrend.xyaxis"),
                TabQuickAction(label: "Correlations", icon: "arrow.triangle.branch")
            ]
        case .profile:
            [
                TabQuickAction(label: "Settings", icon: "gearshape"),
                TabQuickAction(label: "Achievements", icon: "trophy.fill")
            ]
        }
    }
}
