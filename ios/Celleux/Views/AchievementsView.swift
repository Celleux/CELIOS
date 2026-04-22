import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<AchievementRecord> { $0.unlockedAt != nil }) private var unlockedRecords: [AchievementRecord]
    @Query private var allRecords: [AchievementRecord]
    @State private var appeared: Bool = false
    @State private var engine = AchievementEngine.shared

    private var unlockedIds: Set<String> {
        Set(unlockedRecords.map { $0.identifier })
    }

    private var totalPoints: Int {
        AchievementDefinition.allCases
            .filter { unlockedIds.contains($0.rawValue) }
            .reduce(0) { $0 + $1.points }
    }

    private var maxPoints: Int {
        AchievementDefinition.allCases.reduce(0) { $0 + $1.points }
    }

    private func unlockDate(for def: AchievementDefinition) -> Date? {
        unlockedRecords.first { $0.identifier == def.rawValue }?.unlockedAt
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 28) {
                pointsHeader
                
                ForEach(AchievementCategory.allCases, id: \.rawValue) { category in
                    categorySection(category)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .background(CelleuxMeshBackground())
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }

    private var pointsHeader: some View {
        GlassCard(depth: .elevated, showShimmer: true) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    CelleuxColors.warmGold.opacity(0.15),
                                    CelleuxColors.warmGold.opacity(0.03),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 90, height: 90)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CelleuxColors.roseGold, CelleuxColors.warmGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.breathe, isActive: appeared)
                }

                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(totalPoints)")
                            .font(.system(size: 42, weight: .ultraLight))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .contentTransition(.numericText())
                        Text("/ \(maxPoints)")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    Text("TOTAL POINTS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(CelleuxColors.warmGold)
                        .tracking(1.5)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(CelleuxColors.silver.opacity(0.1))
                            .frame(height: 6)

                        Capsule()
                            .fill(CelleuxColors.goldGradient)
                            .frame(width: max(0, geo.size.width * Double(totalPoints) / Double(max(1, maxPoints))), height: 6)
                            .shadow(color: CelleuxColors.warmGold.opacity(0.4), radius: 4)
                            .animation(CelleuxSpring.luxury, value: totalPoints)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(unlockedRecords.count) of \(AchievementDefinition.allCases.count) unlocked")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CelleuxColors.textLabel)
                    Spacer()
                    Text("\(Int(Double(unlockedRecords.count) / Double(AchievementDefinition.allCases.count) * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CelleuxColors.warmGold)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .staggeredAppear(appeared: appeared, delay: 0.05)
    }

    private func categorySection(_ category: AchievementCategory) -> some View {
        let definitions = AchievementDefinition.definitions(for: category)
        let delay = Double(AchievementCategory.allCases.firstIndex(of: category) ?? 0) * 0.06 + 0.12

        return VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CelleuxColors.warmGold)
                Text(category.rawValue.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CelleuxColors.sectionLabel)
                    .tracking(1.5)
                Spacer()
                let unlocked = definitions.filter { unlockedIds.contains($0.rawValue) }.count
                Text("\(unlocked)/\(definitions.count)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(CelleuxColors.textLabel)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(definitions) { def in
                    let isUnlocked = unlockedIds.contains(def.rawValue)
                    achievementCard(def: def, unlocked: isUnlocked)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: delay)
    }

    private func achievementCard(def: AchievementDefinition, unlocked: Bool) -> some View {
        VStack(spacing: 12) {
            if unlocked {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [CelleuxColors.warmGold.opacity(0.15), CelleuxColors.warmGold.opacity(0.03)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 28
                            )
                        )
                        .frame(width: 52, height: 52)
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    CelleuxColors.warmGold.opacity(0.6),
                                    CelleuxP3.champagne.opacity(0.3),
                                    CelleuxColors.roseGold.opacity(0.5),
                                    CelleuxColors.warmGold.opacity(0.6)
                                ],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: def.icon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CelleuxColors.roseGold, CelleuxColors.warmGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: CelleuxColors.warmGold.opacity(0.2), radius: 8, x: 0, y: 4)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "F2F0ED"), Color(hex: "E8E6E3")],
                                center: .init(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: 28
                            )
                        )
                        .frame(width: 52, height: 52)
                    Circle()
                        .stroke(CelleuxColors.silverBorder.opacity(0.2), lineWidth: 0.5)
                        .frame(width: 52, height: 52)
                    Image(systemName: def.icon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(CelleuxColors.silverGradient)
                        .opacity(0.35)
                }
            }

            VStack(spacing: 4) {
                Text(def.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(unlocked ? CelleuxColors.textPrimary : CelleuxColors.textLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                Text(def.subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(CelleuxColors.textLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 24)
            }

            if unlocked {
                if let date = unlockDate(for: def) {
                    Text(date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(CelleuxColors.warmGold)
                }
            } else {
                let prog = engine.progress(for: def, modelContext: modelContext)
                VStack(spacing: 3) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(CelleuxColors.silver.opacity(0.12))
                                .frame(height: 4)
                            Capsule()
                                .fill(CelleuxColors.silverGradient)
                                .frame(width: max(0, geo.size.width * prog), height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text("\(Int(prog * 100))%")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(CelleuxColors.textLabel)
                }
            }

            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                Text("\(def.points) pts")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(unlocked ? CelleuxColors.warmGold : CelleuxColors.silver.opacity(0.5))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    unlocked
                        ? AnyShapeStyle(
                            AngularGradient(
                                colors: [
                                    CelleuxColors.warmGold.opacity(0.5),
                                    CelleuxP3.champagne.opacity(0.3),
                                    Color.white.opacity(0.7),
                                    CelleuxColors.roseGold.opacity(0.4),
                                    CelleuxColors.warmGold.opacity(0.5)
                                ],
                                center: .center
                            )
                        )
                        : AnyShapeStyle(CelleuxColors.glassEdgeHighlight),
                    lineWidth: unlocked ? 1.5 : 1
                )
        )
        .celleuxDepthShadow()
    }
}
