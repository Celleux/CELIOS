import SwiftUI

enum CelleuxP3 {
    static let pureWhite = Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0)
    static let warmCream = Color(.displayP3, red: 0.96, green: 0.95, blue: 0.93)
    static let goldMist = Color(.displayP3, red: 0.88, green: 0.86, blue: 0.82)
    static let coolSilver = Color(.displayP3, red: 0.82, green: 0.81, blue: 0.83)
    static let champagne = Color(.displayP3, red: 0.92, green: 0.89, blue: 0.84)
    static let darkSilver = Color(.displayP3, red: 0.70, green: 0.70, blue: 0.72)

    static let chartGold = Color(.displayP3, red: 0.85, green: 0.82, blue: 0.75)
    static let chartSilver = Color(.displayP3, red: 0.78, green: 0.78, blue: 0.80)
    static let chartChampagne = Color(.displayP3, red: 0.92, green: 0.89, blue: 0.84)
    static let chartDarkSilver = Color(.displayP3, red: 0.70, green: 0.70, blue: 0.72)
}

enum CelleuxColors {
    static let background = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let cardSurface = Color.white.opacity(0.92)
    static let depthLayer = Color(red: 0.98, green: 0.98, blue: 0.98)

    static let accent = Color(.displayP3, red: 0.42, green: 0.247, blue: 0.627)
    static let accentLight = Color(.displayP3, red: 0.608, green: 0.435, blue: 0.816)

    static let silverLight = Color(.displayP3, red: 0.816, green: 0.847, blue: 0.878)
    static let silver = Color(.displayP3, red: 0.69, green: 0.722, blue: 0.757)
    static let silverBorder = Color(.displayP3, red: 0.753, green: 0.784, blue: 0.816)
    static let silverDark = Color(.displayP3, red: 0.627, green: 0.659, blue: 0.69)

    static let warmGold = Color(.displayP3, red: 0.788, green: 0.663, blue: 0.431)
    static let champagneGold = Color(.displayP3, red: 0.788, green: 0.663, blue: 0.431)
    static let roseGold = Color(.displayP3, red: 0.831, green: 0.647, blue: 0.455)

    static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.15)
    static let textSecondary = Color(red: 0.10, green: 0.10, blue: 0.15).opacity(0.65)
    static let textTertiary = Color(red: 0.10, green: 0.10, blue: 0.15).opacity(0.45)
    static let textLabel = Color(red: 0.10, green: 0.10, blue: 0.15).opacity(0.45)
    static let sectionLabel = Color(red: 0.10, green: 0.10, blue: 0.15).opacity(0.40)

    static let glassBackground = Color.white.opacity(0.92)
    static let glassBorder = Color.white.opacity(0.8)

    static let silverGradient = LinearGradient(
        colors: [Color(.displayP3, red: 0.816, green: 0.847, blue: 0.878), Color(.displayP3, red: 0.627, green: 0.659, blue: 0.69)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [Color(.displayP3, red: 0.831, green: 0.769, blue: 0.627), Color(.displayP3, red: 0.788, green: 0.663, blue: 0.431), Color(.displayP3, red: 0.722, green: 0.588, blue: 0.416)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let roseGoldGradient = LinearGradient(
        colors: [Color(.displayP3, red: 0.925, green: 0.773, blue: 0.643), Color(.displayP3, red: 0.831, green: 0.647, blue: 0.455), Color(.displayP3, red: 0.722, green: 0.541, blue: 0.353)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let chromeGradient = LinearGradient(
        colors: [Color(.displayP3, red: 0.941, green: 0.957, blue: 0.973), Color(.displayP3, red: 0.753, green: 0.784, blue: 0.816), Color(.displayP3, red: 0.878, green: 0.902, blue: 0.925), Color(.displayP3, red: 0.69, green: 0.722, blue: 0.757)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldSilverGradient = LinearGradient(
        colors: [Color(.displayP3, red: 0.831, green: 0.769, blue: 0.627), Color(.displayP3, red: 0.788, green: 0.663, blue: 0.431), Color(.displayP3, red: 0.722, green: 0.753, blue: 0.784), Color(.displayP3, red: 0.816, green: 0.784, blue: 0.722)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassHighlight = LinearGradient(
        colors: [Color.white.opacity(0.95), Color.white.opacity(0.0)],
        startPoint: .top,
        endPoint: .center
    )

    static let premiumSheen = LinearGradient(
        colors: [Color.white.opacity(0.0), Color.white.opacity(0.3), Color.white.opacity(0.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGlow = Color(.displayP3, red: 0.788, green: 0.663, blue: 0.431).opacity(0.3)
    static let roseGoldGlow = Color(.displayP3, red: 0.831, green: 0.647, blue: 0.455).opacity(0.3)
    static let silverGlow = Color(.displayP3, red: 0.69, green: 0.722, blue: 0.757).opacity(0.25)

    static let chromeBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.95),
            CelleuxP3.coolSilver.opacity(0.5),
            Color.white.opacity(0.7),
            CelleuxP3.darkSilver.opacity(0.4),
            Color.white.opacity(0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldChromeBorder = LinearGradient(
        colors: [
            CelleuxP3.warmCream.opacity(0.9),
            CelleuxColors.warmGold.opacity(0.5),
            Color.white.opacity(0.7),
            CelleuxP3.champagne.opacity(0.4),
            CelleuxP3.warmCream.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let innerGlow = LinearGradient(
        colors: [Color.white.opacity(0.6), Color.white.opacity(0.0), Color.white.opacity(0.15)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let glassEdgeHighlight = LinearGradient(
        colors: [
            Color.white.opacity(0.9),
            Color.white.opacity(0.3),
            Color(red: 0.78, green: 0.78, blue: 0.80).opacity(0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dataViolet = Color(.displayP3, red: 0.42, green: 0.247, blue: 0.627).opacity(0.5)
    static let dataVioletGradient = LinearGradient(
        colors: [Color(.displayP3, red: 0.608, green: 0.435, blue: 0.816).opacity(0.5), Color(.displayP3, red: 0.42, green: 0.247, blue: 0.627).opacity(0.5)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let iconGoldGradient = LinearGradient(
        colors: [
            Color(red: 0.79, green: 0.66, blue: 0.43),
            Color(red: 0.65, green: 0.55, blue: 0.38)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let iconBlueGradient = LinearGradient(
        colors: [
            Color(red: 0.42, green: 0.72, blue: 0.88),
            Color(red: 0.29, green: 0.61, blue: 0.78)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let iconLavenderGradient = LinearGradient(
        colors: [
            Color(red: 0.61, green: 0.56, blue: 0.77),
            Color(red: 0.48, green: 0.44, blue: 0.66)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let iconAmberGradient = LinearGradient(
        colors: [
            Color(red: 0.92, green: 0.75, blue: 0.35),
            Color(red: 0.79, green: 0.60, blue: 0.30)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .displayP3,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct CelleuxMeshBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.96, blue: 0.94)
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.92, green: 0.88, blue: 0.80).opacity(0.3),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -50)
                .allowsHitTesting(false)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.85, green: 0.86, blue: 0.90).opacity(0.2),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 100, y: 200)
                .allowsHitTesting(false)
        }
    }
}

struct CelleuxParticleView: View {
    @State private var particles: [AmbientParticle] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for particle in particles {
                    let x = particle.startX * size.width + sin(time * particle.horizontalSpeed + particle.phase) * particle.amplitude
                    let elapsed = time.truncatingRemainder(dividingBy: particle.lifetime)
                    let normalizedY = elapsed / particle.lifetime
                    let y = size.height * (1.0 - normalizedY)
                    let fadeIn = min(1.0, normalizedY * 5.0)
                    let fadeOut = min(1.0, (1.0 - normalizedY) * 3.0)
                    let opacity = particle.opacity * fadeIn * fadeOut

                    let rect = CGRect(x: x - particle.size / 2, y: y - particle.size / 2, width: particle.size, height: particle.size)
                    let dot = Path(ellipseIn: rect)
                    context.fill(dot, with: .color(particle.color.opacity(opacity)))
                    context.addFilter(.blur(radius: 1.5))
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { generateParticles() }
    }

    private func generateParticles() {
        particles = (0..<14).map { _ in
            AmbientParticle(
                startX: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 2...4),
                opacity: Double.random(in: 0.08...0.22),
                horizontalSpeed: Double.random(in: 0.3...0.8),
                phase: Double.random(in: 0...(.pi * 2)),
                amplitude: CGFloat.random(in: 15...40),
                lifetime: Double.random(in: 12...25),
                color: Bool.random() ? CelleuxP3.pureWhite : CelleuxP3.champagne
            )
        }
    }
}

struct AmbientParticle {
    let startX: CGFloat
    let size: CGFloat
    let opacity: Double
    let horizontalSpeed: Double
    let phase: Double
    let amplitude: CGFloat
    let lifetime: Double
    let color: Color
}

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let depth: GlassDepth
    let content: Content

    init(cornerRadius: CGFloat = 24, depth: GlassDepth = .standard, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.depth = depth
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(CelleuxColors.glassEdgeHighlight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.03), radius: 30, x: 0, y: 15)
    }
}

nonisolated enum GlassDepth {
    case subtle
    case standard
    case elevated
    case floating

    var shadowOpacity: Double {
        switch self {
        case .subtle: 0.05
        case .standard: 0.07
        case .elevated: 0.10
        case .floating: 0.14
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .subtle: 10
        case .standard: 18
        case .elevated: 28
        case .floating: 36
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .subtle: 5
        case .standard: 9
        case .elevated: 14
        case .floating: 18
        }
    }
}

struct CompactGlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(CelleuxColors.glassEdgeHighlight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.03), radius: 24, x: 0, y: 12)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct GlassButtonStyle: ButtonStyle {
    let style: GlassButtonVariant

    init(style: GlassButtonVariant = .primary) {
        self.style = style
    }

    init(color: Color = CelleuxColors.warmGold, glowColor: Color = CelleuxColors.goldGlow) {
        self.style = .primary
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.95))

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: configuration.isPressed ? style.activeBorderColors : style.borderColors,
                                center: .center
                            ),
                            lineWidth: configuration.isPressed ? 2 : 1.5
                        )
                }
            )
            .shadow(color: style.glowColor.opacity(configuration.isPressed ? 0.25 : 0.12), radius: configuration.isPressed ? 6 : 14, x: 0, y: configuration.isPressed ? 2 : 6)
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

nonisolated enum GlassButtonVariant {
    case primary
    case secondary

    var borderColors: [Color] {
        switch self {
        case .primary:
            [
                Color(hex: "E8DCC8").opacity(0.85),
                Color(hex: "C9A96E").opacity(0.45),
                Color.white.opacity(0.7),
                Color(hex: "D4C4A0").opacity(0.35),
                Color(hex: "C9A96E").opacity(0.3),
                Color.white.opacity(0.6),
                Color(hex: "E8DCC8").opacity(0.8)
            ]
        case .secondary:
            [
                Color.white.opacity(0.8),
                Color(hex: "C0C8D0").opacity(0.35),
                Color.white.opacity(0.6),
                Color(hex: "B0B8C1").opacity(0.3),
                Color.white.opacity(0.7),
                Color(hex: "C0C8D0").opacity(0.25),
                Color.white.opacity(0.75)
            ]
        }
    }

    var activeBorderColors: [Color] {
        switch self {
        case .primary:
            [
                Color(hex: "C9A96E").opacity(0.9),
                Color(hex: "D4B078").opacity(0.7),
                Color.white.opacity(0.5),
                Color(hex: "C9A96E").opacity(0.6),
                Color(hex: "D4C4A0").opacity(0.8),
                Color.white.opacity(0.4),
                Color(hex: "C9A96E").opacity(0.85)
            ]
        case .secondary:
            [
                Color(hex: "C0C8D0").opacity(0.6),
                Color.white.opacity(0.5),
                Color(hex: "B0B8C1").opacity(0.4),
                Color.white.opacity(0.6),
                Color(hex: "C0C8D0").opacity(0.5)
            ]
        }
    }

    var glowColor: Color {
        switch self {
        case .primary: Color(hex: "C9A96E")
        case .secondary: Color(hex: "B0B8C1")
        }
    }
}

struct Premium3DButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.5))
                        .offset(y: configuration.isPressed ? 1 : 3)
                        .blur(radius: 0.5)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.95))

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    CelleuxColors.warmGold.opacity(0.6),
                                    CelleuxP3.coolSilver.opacity(0.45),
                                    Color.white.opacity(0.85),
                                    CelleuxP3.champagne.opacity(0.5),
                                    CelleuxP3.coolSilver.opacity(0.35),
                                    Color.white.opacity(0.9),
                                    CelleuxColors.warmGold.opacity(0.45),
                                    Color.white.opacity(0.95)
                                ],
                                center: .center
                            ),
                            lineWidth: configuration.isPressed ? 2.5 : 2
                        )
                }
            )
            .shadow(color: CelleuxColors.warmGold.opacity(configuration.isPressed ? 0.15 : 0.2), radius: configuration.isPressed ? 4 : 16, x: 0, y: configuration.isPressed ? 1 : 6)
            .shadow(color: Color.black.opacity(0.08), radius: configuration.isPressed ? 2 : 6, x: 0, y: configuration.isPressed ? 1 : 3)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct OutlineGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.92))

                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(CelleuxColors.glassEdgeHighlight, lineWidth: 1)
                }
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct LuxuryBezelRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    @Binding var glowing: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color(red: 0.78, green: 0.78, blue: 0.82).opacity(0.5),
                            Color.white.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size + lineWidth + 8, height: size + lineWidth + 8)

            Circle()
                .stroke(Color(red: 0.93, green: 0.91, blue: 0.89), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.72, blue: 0.45),
                            Color(red: 0.78, green: 0.66, blue: 0.43)
                        ],
                        startPoint: .topLeading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: CelleuxColors.goldGlow.opacity(glowing ? 0.6 : 0.2), radius: glowing ? 18 : 8)

            Circle()
                .trim(from: 0.05, to: 0.25)
                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                .frame(width: size + 4, height: size + 4)
                .blur(radius: 0.5)
                .rotationEffect(.degrees(-80))
        }
    }
}

struct ChromeRingView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    @Binding var glowing: Bool

    var body: some View {
        LuxuryBezelRing(progress: progress, size: size, lineWidth: lineWidth, glowing: $glowing)
    }
}

struct MetricDisplay: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(CelleuxColors.iconGoldGradient)
            }
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)

            Text(value)
                .font(.system(size: 26, weight: .thin))
                .foregroundStyle(CelleuxColors.textPrimary)
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(CelleuxColors.sectionLabel)
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var action: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.55))
                .textCase(.uppercase)
                .tracking(1.5)

            Spacer()

            if let action {
                Button(action) {}
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CelleuxColors.warmGold)
            }
        }
    }
}

struct PulsingDot: View {
    @State private var isAnimating: Bool = false
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 16, height: 16)
                .scaleEffect(isAnimating ? 1.5 : 1.0)
                .opacity(isAnimating ? 0 : 0.6)

            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 300)
                .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onAppear {
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct SkeletonShimmerEffect: ViewModifier {
    @State private var startPoint: UnitPoint = UnitPoint(x: -0.3, y: -0.3)

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.25), .clear],
                    startPoint: startPoint,
                    endPoint: UnitPoint(x: startPoint.x + 0.6, y: startPoint.y + 0.6)
                )
                .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    startPoint = UnitPoint(x: 1.3, y: 1.3)
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }

    func skeletonShimmer() -> some View {
        modifier(SkeletonShimmerEffect())
    }

    func staggeredAppear(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .scaleEffect(appeared ? 1 : 0.97)
            .animation(.spring(duration: 0.5, bounce: 0.2).delay(delay), value: appeared)
    }

    func premiumCardStyle(depth: GlassDepth = .standard) -> some View {
        self
            .rotation3DEffect(.degrees(0.5), axis: (x: 1, y: 0, z: 0), perspective: 0.8)
    }

    func breathingShadow(color: Color = CelleuxColors.goldGlow, isActive: Bool) -> some View {
        self
            .shadow(color: color.opacity(isActive ? 0.12 : 0.06), radius: isActive ? 30 : 15, x: 0, y: 10)
    }
}

struct ChromeIconBadge: View {
    let systemName: String
    let size: CGFloat
    let gradientStyle: LinearGradient

    init(_ systemName: String, size: CGFloat = 42, gradient: LinearGradient? = nil) {
        self.systemName = systemName
        self.size = size
        self.gradientStyle = gradient ?? CelleuxColors.iconGoldGradient
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: size, height: size)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.0)],
                        startPoint: .topLeading,
                        endPoint: .center
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(gradientStyle)
        }
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

struct PremiumDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.78, green: 0.78, blue: 0.80).opacity(0.02),
                        Color(red: 0.78, green: 0.78, blue: 0.80).opacity(0.25),
                        Color.white.opacity(0.3),
                        Color(red: 0.78, green: 0.78, blue: 0.80).opacity(0.25),
                        Color(red: 0.78, green: 0.78, blue: 0.80).opacity(0.02)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

struct GlowingAccentBadge: View {
    let systemName: String
    let color: Color
    let size: CGFloat

    init(_ systemName: String, color: Color = CelleuxColors.warmGold, size: CGFloat = 48) {
        self.systemName = systemName
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: size, height: size)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.0)],
                        startPoint: .topLeading,
                        endPoint: .center
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.9), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .shadow(color: color.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

struct FlashOverlayView: View {
    let isActive: Bool
    @State private var opacity: Double = 0

    var body: some View {
        Color.white
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeIn(duration: 0.08)) {
                        opacity = 0.35
                    }
                    withAnimation(.easeOut(duration: 0.35).delay(0.08)) {
                        opacity = 0
                    }
                }
            }
    }
}

nonisolated enum ScanCelebrationPhase: CaseIterable {
    case idle
    case burst
    case settle

    var scale: Double {
        switch self {
        case .idle: 1.0
        case .burst: 1.12
        case .settle: 1.0
        }
    }

    var opacity: Double {
        switch self {
        case .idle: 0.0
        case .burst: 1.0
        case .settle: 0.0
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .idle: 0
        case .burst: 24
        case .settle: 8
        }
    }
}

struct ScoreCelebrationKeyframes {
    var verticalOffset: Double = 0
    var scale: Double = 1.0
    var glowOpacity: Double = 0
}

struct AnalyzingBrainView: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            CelleuxColors.warmGold.opacity(0.3),
                            CelleuxColors.warmGold.opacity(0.05),
                            CelleuxColors.warmGold.opacity(0.2)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 80, height: 80)
                .phaseAnimator([false, true], trigger: isActive) { content, phase in
                    content
                        .scaleEffect(phase ? 1.06 : 0.96)
                        .rotationEffect(.degrees(phase ? 8 : -8))
                } animation: { _ in
                    .easeInOut(duration: 1.8)
                }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [CelleuxColors.warmGold.opacity(0.08), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .phaseAnimator([false, true], trigger: isActive) { content, phase in
                    content
                        .scaleEffect(phase ? 1.2 : 0.9)
                        .opacity(phase ? 0.8 : 0.3)
                } animation: { _ in
                    .easeInOut(duration: 2.2)
                }

            Image(systemName: "brain.head.profile")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(CelleuxColors.warmGold)
                .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isActive)
        }
    }
}

struct CelebrationParticleBurst: View {
    let isActive: Bool
    @State private var particles: [BurstParticle] = []

    var body: some View {
        ZStack {
            ForEach(Array(particles.enumerated()), id: \.offset) { _, particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: isActive ? particle.endX : 0, y: isActive ? particle.endY : 0)
                    .opacity(isActive ? 0 : particle.opacity)
                    .blur(radius: 1)
            }
        }
        .onAppear { generateBurstParticles() }
        .animation(.spring(duration: 0.8, bounce: 0.2), value: isActive)
    }

    private func generateBurstParticles() {
        particles = (0..<16).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...100)
            return BurstParticle(
                endX: cos(angle) * distance,
                endY: sin(angle) * distance,
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.4...0.8),
                color: Bool.random() ? CelleuxColors.warmGold.opacity(0.7) : CelleuxP3.champagne.opacity(0.6)
            )
        }
    }
}

struct BurstParticle {
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let opacity: Double
    let color: Color
}
