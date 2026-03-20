import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var previousTab: AppTab = .home
    @State private var tabBounce: Bool = false
    @State private var rippleTab: AppTab? = nil
    @State private var ripplePhase: CGFloat = 0
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

            floatingTabBar
        }
        .ignoresSafeArea(.keyboard)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button {
                    guard selectedTab != tab else { return }
                    previousTab = selectedTab
                    rippleTab = tab
                    ripplePhase = 0
                    withAnimation(.smooth(duration: 0.3)) {
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
                    VStack(spacing: 4) {
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(Color(red: 0.79, green: 0.66, blue: 0.43).opacity(0.12))
                                    .frame(width: 48, height: 48)
                                    .matchedGeometryEffect(id: "tabPill", in: tabNamespace)
                                    .transition(.opacity)
                            }

                            if rippleTab == tab {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                CelleuxColors.warmGold.opacity(0.2 * (1.0 - ripplePhase)),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 24 + ripplePhase * 20
                                        )
                                    )
                                    .frame(width: 48 + ripplePhase * 16, height: 48 + ripplePhase * 16)
                                    .transition(.opacity)
                                    .allowsHitTesting(false)
                            }

                            Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                                .font(.system(size: 18, weight: isSelected ? .medium : .light))
                                .foregroundStyle(
                                    isSelected ?
                                    AnyShapeStyle(Color(red: 0.12, green: 0.12, blue: 0.18)) :
                                    AnyShapeStyle(Color(red: 0.70, green: 0.72, blue: 0.75))
                                )
                                .symbolEffect(.bounce, value: tabBounce)
                                .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                                .scaleEffect(isSelected ? 1.08 : 1.0)
                                .animation(.spring(duration: 0.35, bounce: 0.35), value: isSelected)
                        }
                        .frame(height: 38)

                        Text(tab.label)
                            .font(.system(size: 9.5, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(
                                isSelected ?
                                AnyShapeStyle(Color(red: 0.12, green: 0.12, blue: 0.18)) :
                                AnyShapeStyle(Color(red: 0.70, green: 0.72, blue: 0.75))
                            )
                            .animation(.easeOut(duration: 0.2), value: isSelected)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(tabBarBackground)
        .padding(.horizontal, 24)
        .padding(.bottom, 4)
    }

    private var tabBarBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.95))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CelleuxColors.glassEdgeHighlight, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: -5)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
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
}
