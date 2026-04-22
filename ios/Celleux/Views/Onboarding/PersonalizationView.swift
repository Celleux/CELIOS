import SwiftUI
import SwiftData

struct PersonalizationView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var appeared: Bool = false
    @State private var hapticTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: CelleuxSpacing.lg) {
                    VStack(spacing: CelleuxSpacing.sm) {
                        Text("Let's personalize")
                            .font(.system(size: 30, weight: .light))
                            .tracking(0.5)
                            .foregroundStyle(CelleuxColors.textPrimary)

                        Text("Help us tailor your experience")
                            .font(CelleuxType.body)
                            .foregroundStyle(CelleuxColors.textSecondary)
                    }
                    .staggeredAppear(appeared: appeared, delay: 0)
                    .padding(.top, CelleuxSpacing.md)

                    nameSection
                        .staggeredAppear(appeared: appeared, delay: 0.05)

                    ageSection
                        .staggeredAppear(appeared: appeared, delay: 0.1)

                    goalsSection
                        .staggeredAppear(appeared: appeared, delay: 0.15)

                    concernsSection
                        .staggeredAppear(appeared: appeared, delay: 0.2)

                    genderSection
                        .staggeredAppear(appeared: appeared, delay: 0.25)

                    skinTypeSection
                        .staggeredAppear(appeared: appeared, delay: 0.3)

                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, CelleuxSpacing.lg)
            }
            .scrollIndicators(.hidden)

            VStack {
                Button {
                    viewModel.saveProfile(modelContext: modelContext)
                    hapticTrigger += 1
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(0.3)
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(Premium3DButtonStyle())
                .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)
                .opacity(canContinue ? 1.0 : 0.5)
                .disabled(!canContinue)
            }
            .padding(.horizontal, CelleuxSpacing.lg)
            .padding(.bottom, CelleuxSpacing.md)
            .padding(.top, CelleuxSpacing.sm)
            .background(
                LinearGradient(
                    colors: [CelleuxColors.background.opacity(0), CelleuxColors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                .allowsHitTesting(false),
                alignment: .top
            )
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .onAppear {
            withAnimation(CelleuxSpring.luxury) {
                appeared = true
            }
        }
    }

    private var canContinue: Bool {
        !viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty
        && viewModel.selectedAgeRange != nil
        && !viewModel.selectedGoals.isEmpty
    }

    private var nameSection: some View {
        GlassCard(cornerRadius: 20, depth: .subtle) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("YOUR NAME")

                TextField("First name", text: $viewModel.name)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(CelleuxColors.textPrimary)
                    .padding(CelleuxSpacing.md)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.7))
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial)
                                )

                            RoundedRectangle(cornerRadius: 14)
                                .stroke(CelleuxColors.goldChromeBorder, lineWidth: 1)
                        }
                    )
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
            }
        }
    }

    private var ageSection: some View {
        GlassCard(cornerRadius: 20, depth: .subtle) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("AGE RANGE")

                FlowLayout(spacing: 10) {
                    ForEach(viewModel.ageRanges, id: \.self) { range in
                        PillButton(
                            title: range,
                            isSelected: viewModel.selectedAgeRange == range
                        ) {
                            withAnimation(CelleuxSpring.snappy) {
                                viewModel.selectedAgeRange = range
                            }
                            hapticTrigger += 1
                        }
                    }
                }
            }
        }
    }

    private var goalsSection: some View {
        GlassCard(cornerRadius: 20, depth: .subtle) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("PRIMARY GOALS")

                FlowLayout(spacing: 10) {
                    ForEach(viewModel.goals, id: \.self) { goal in
                        PillButton(
                            title: goal,
                            isSelected: viewModel.selectedGoals.contains(goal)
                        ) {
                            withAnimation(CelleuxSpring.snappy) {
                                viewModel.toggleGoal(goal)
                            }
                            hapticTrigger += 1
                        }
                    }
                }
            }
        }
    }

    private var concernsSection: some View {
        GlassCard(cornerRadius: 20, depth: .subtle) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("SKIN CONCERNS")

                FlowLayout(spacing: 10) {
                    ForEach(viewModel.concerns, id: \.self) { concern in
                        PillButton(
                            title: concern,
                            isSelected: viewModel.selectedConcerns.contains(concern)
                        ) {
                            withAnimation(CelleuxSpring.snappy) {
                                viewModel.toggleConcern(concern)
                            }
                            hapticTrigger += 1
                        }
                    }
                }
            }
        }
    }

    private var genderSection: some View {
        GlassCard(cornerRadius: 20, depth: .subtle) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionLabel("GENDER")
                    Text("optional")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                }

                FlowLayout(spacing: 10) {
                    ForEach(viewModel.genders, id: \.self) { gender in
                        PillButton(
                            title: gender,
                            isSelected: viewModel.selectedGender == gender
                        ) {
                            withAnimation(CelleuxSpring.snappy) {
                                viewModel.selectedGender = gender
                            }
                            hapticTrigger += 1
                        }
                    }
                }
            }
        }
    }

    private var skinTypeSection: some View {
        GlassCard(cornerRadius: 20, depth: .subtle) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionLabel("SKIN TYPE")
                    Text("optional")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(CelleuxColors.textLabel)
                }

                FlowLayout(spacing: 10) {
                    ForEach(FitzpatrickType.allCases) { type in
                        PillButton(
                            title: "\(type.rawValue) · \(type.label)",
                            isSelected: viewModel.selectedSkinType == type
                        ) {
                            withAnimation(CelleuxSpring.snappy) {
                                viewModel.selectedSkinType = type
                            }
                            hapticTrigger += 1
                        }
                    }
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(CelleuxType.label)
            .foregroundStyle(CelleuxColors.textLabel)
            .tracking(CelleuxType.labelTracking)
    }
}

struct PillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? CelleuxColors.textPrimary : CelleuxColors.textPrimary.opacity(0.8))
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.95), Color(hex: "F5F0E8")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )

                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "E8DCC8").opacity(0.9), Color(hex: "C9A96E").opacity(0.5), Color(hex: "D4C4A0").opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.6))
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                )

                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.8), CelleuxColors.silverBorder.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }
                )
                .shadow(color: isSelected ? CelleuxColors.goldGlow.opacity(0.3) : .black.opacity(0.03), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
