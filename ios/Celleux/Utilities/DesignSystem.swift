import SwiftUI

// MARK: - Typography System

enum CelleuxType {
    static var display: Font { .system(.largeTitle, design: .default).weight(.ultraLight) }
    static var title1: Font { .system(.title, design: .default).weight(.light) }
    static var headline: Font { .system(.headline, design: .default).weight(.regular) }
    static var body: Font { .system(.body, design: .default) }
    static var caption: Font { .system(.caption, design: .default).weight(.light) }
    static var label: Font { .system(size: 8, weight: .bold) }
    static var metric: Font { .system(.largeTitle, design: .default).weight(.thin) }

    static let displayTracking: CGFloat = 2
    static let title1Tracking: CGFloat = 1
    static let captionTracking: CGFloat = 0.8
    static let labelTracking: CGFloat = 1.5
    static let metricTracking: CGFloat = 0.5
    static let bodyLineSpacing: CGFloat = 8
}

// MARK: - Shadow System

enum CelleuxShadow {
    case tight
    case medium
    case ambient

    var color: Color {
        switch self {
        case .tight: .black.opacity(0.04)
        case .medium: .black.opacity(0.06)
        case .ambient: .black.opacity(0.03)
        }
    }

    var radius: CGFloat {
        switch self {
        case .tight: 2
        case .medium: 10
        case .ambient: 24
        }
    }

    var y: CGFloat {
        switch self {
        case .tight: 1
        case .medium: 5
        case .ambient: 12
        }
    }
}

extension View {
    func celleuxDepthShadow() -> some View {
        self
            .shadow(color: CelleuxShadow.tight.color, radius: CelleuxShadow.tight.radius, x: 0, y: CelleuxShadow.tight.y)
            .shadow(color: CelleuxShadow.medium.color, radius: CelleuxShadow.medium.radius, x: 0, y: CelleuxShadow.medium.y)
            .shadow(color: CelleuxShadow.ambient.color, radius: CelleuxShadow.ambient.radius, x: 0, y: CelleuxShadow.ambient.y)
    }
}

// MARK: - Spring Animation Tokens

enum CelleuxSpring {
    static let luxury: Animation = .spring(response: 0.7, dampingFraction: 0.85)
    static let snappy: Animation = .spring(response: 0.4, dampingFraction: 0.75)
    static let bouncy: Animation = .spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - Spacing Tokens

enum CelleuxSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Haptic Tokens

enum CelleuxHaptic {
    static let selection: SensoryFeedback = .selection
    static let impact: SensoryFeedback = .impact(flexibility: .rigid, intensity: 0.8)
    static let success: SensoryFeedback = .success
    static let softTap: SensoryFeedback = .impact(flexibility: .soft, intensity: 0.3)
}

// MARK: - Animated Number Modifier

struct AnimatedNumberModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentTransition(.numericText(countsDown: false))
            .transaction { t in
                t.animation = CelleuxSpring.luxury
            }
    }
}

extension View {
    func animatedNumber() -> some View {
        modifier(AnimatedNumberModifier())
    }
}

// MARK: - Display P3 Colors

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
    static let background = Color(.displayP3, red: 0.97, green: 0.96, blue: 0.94)
    static let cardSurface = Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.92)
    static let depthLayer = Color(.displayP3, red: 0.98, green: 0.98, blue: 0.98)

    static let silverLight = Color(.displayP3, red: 0.816, green: 0.847, blue: 0.878)
    static let silver = Color(.displayP3, red: 0.69, green: 0.722, blue: 0.757)
    static let silverBorder = Color(.displayP3, red: 0.753, green: 0.784, blue: 0.816)
    static let silverDark = Color(.displayP3, red: 0.627, green: 0.659, blue: 0.69)

    static let warmGold = Color(.displayP3, red: 0.788, green: 0.663, blue: 0.431)
    static let champagneGold = Color(.displayP3, red: 0.788, green: 0.663, blue: 0.431)
    static let roseGold = Color(.displayP3, red: 0.831, green: 0.647, blue: 0.455)

    static let textPrimary = Color(.displayP3, red: 0.10, green: 0.10, blue: 0.15)
    static let textSecondary = Color(.displayP3, red: 0.10, green: 0.10, blue: 0.15, opacity: 0.70)
    static let textTertiary = Color(.displayP3, red: 0.10, green: 0.10, blue: 0.15, opacity: 0.55)
    static let textLabel = Color(.displayP3, red: 0.10, green: 0.10, blue: 0.15, opacity: 0.55)
    static let sectionLabel = Color(.displayP3, red: 0.10, green: 0.10, blue: 0.15, opacity: 0.50)

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
            Color(.displayP3, red: 0.78, green: 0.78, blue: 0.80).opacity(0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dataGold = Color(.displayP3, red: 0.788, green: 0.663, blue: 0.431, opacity: 0.7)
    static let dataGoldGradient = LinearGradient(
        colors: [Color(.displayP3, red: 0.831, green: 0.769, blue: 0.627, opacity: 0.6), Color(.displayP3, red: 0.788, green: 0.663, blue: 0.431, opacity: 0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )

    @available(*, deprecated, renamed: "dataGold")
    static var dataViolet: Color { dataGold }
    @available(*, deprecated, renamed: "dataGoldGradient")
    static var dataVioletGradient: LinearGradient { dataGoldGradient }

    static let iconGoldGradient = LinearGradient(
        colors: [
            Color(.displayP3, red: 0.79, green: 0.66, blue: 0.43),
            Color(.displayP3, red: 0.65, green: 0.55, blue: 0.38)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let iconBlueGradient = LinearGradient(
        colors: [
            Color(.displayP3, red: 0.69, green: 0.722, blue: 0.757),
            Color(.displayP3, red: 0.816, green: 0.847, blue: 0.878)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let iconLavenderGradient = LinearGradient(
        colors: [
            Color(.displayP3, red: 0.69, green: 0.722, blue: 0.757),
            Color(.displayP3, red: 0.627, green: 0.659, blue: 0.69)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let iconAmberGradient = LinearGradient(
        colors: [
            Color(.displayP3, red: 0.92, green: 0.75, blue: 0.35),
            Color(.displayP3, red: 0.79, green: 0.60, blue: 0.30)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let iconHighlightGradient = LinearGradient(
        colors: [Color.white, Color.white.opacity(0.0)],
        startPoint: .topLeading,
        endPoint: .center
    )

    static let bezelOuterGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.95),
            Color(.displayP3, red: 0.78, green: 0.78, blue: 0.82).opacity(0.5),
            Color.white.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let bezelProgressGradient = LinearGradient(
        colors: [
            Color(.displayP3, red: 0.85, green: 0.72, blue: 0.45),
            Color(.displayP3, red: 0.78, green: 0.66, blue: 0.43)
        ],
        startPoint: .topLeading,
        endPoint: .trailing
    )

    static let cardInnerHighlight = LinearGradient(
        colors: [
            Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.15),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .center
    )
}

extension Color {
    nonisolated init(hex: String) {
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let drift = reduceMotion ? 0 : sin(t * 0.12) * 0.035
            let drift2 = reduceMotion ? 0 : cos(t * 0.09) * 0.03

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5 + Float(drift), 0.0], [1.0, 0.0],
                    [0.0, 0.5 + Float(drift2)], [0.5, 0.5], [1.0, 0.5 - Float(drift2)],
                    [0.0, 1.0], [0.5 - Float(drift), 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(.displayP3, red: 0.985, green: 0.975, blue: 0.955),
                    Color(.displayP3, red: 0.965, green: 0.945, blue: 0.905),
                    Color(.displayP3, red: 0.955, green: 0.955, blue: 0.965),
                    Color(.displayP3, red: 0.975, green: 0.965, blue: 0.940),
                    Color(.displayP3, red: 0.99, green: 0.98, blue: 0.96),
                    Color(.displayP3, red: 0.94, green: 0.94, blue: 0.96),
                    Color(.displayP3, red: 0.97, green: 0.955, blue: 0.925),
                    Color(.displayP3, red: 0.96, green: 0.95, blue: 0.94),
                    Color(.displayP3, red: 0.935, green: 0.935, blue: 0.955)
                ]
            )
            .ignoresSafeArea()
        }
        .overlay(
            RadialGradient(
                colors: [Color(.displayP3, red: 0.92, green: 0.84, blue: 0.66).opacity(0.12), .clear],
                center: .topLeading, startRadius: 40, endRadius: 360
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()
        )
        .overlay(
            RadialGradient(
                colors: [Color(.displayP3, red: 0.80, green: 0.82, blue: 0.88).opacity(0.10), .clear],
                center: .bottomTrailing, startRadius: 40, endRadius: 360
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()
        )
    }
}

struct CelleuxParticleView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [AmbientParticle] = []

    var body: some View {
        if reduceMotion {
            Color.clear.allowsHitTesting(false)
        } else {
            particleCanvas
        }
    }

    private var particleCanvas: some View {
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
    let showShimmer: Bool
    let content: Content

    init(cornerRadius: CGFloat = 24, depth: GlassDepth = .standard, showShimmer: Bool = false, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.depth = depth
        self.showShimmer = showShimmer
        self.content = content()
    }

    private var chromeBorder: AngularGradient {
        AngularGradient(
            colors: [
                CelleuxColors.silverLight.opacity(0.6),
                CelleuxColors.warmGold.opacity(0.4),
                Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.8),
                CelleuxColors.silverBorder.opacity(0.5),
                CelleuxColors.champagneGold.opacity(0.35),
                Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.7),
                CelleuxColors.silverLight.opacity(0.6)
            ],
            center: .center
        )
    }

    private var innerHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.15),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .center
        )
    }

    private var cardFill: Color {
        Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.92)
    }

    var body: some View {
        content
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(cardFill)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(innerHighlight)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(chromeBorder, lineWidth: 1)
            )
            .overlay {
                if showShimmer {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.clear)
                        .modifier(ShimmerEffect())
                        .opacity(0.06)
                        .allowsHitTesting(false)
                }
            }
            .celleuxDepthShadow()
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

    private var chromeBorder: AngularGradient {
        AngularGradient(
            colors: [
                CelleuxColors.silverLight.opacity(0.5),
                CelleuxColors.warmGold.opacity(0.3),
                Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.7),
                CelleuxColors.silverBorder.opacity(0.4),
                CelleuxColors.silverLight.opacity(0.5)
            ],
            center: .center
        )
    }

    private var cardFill: Color {
        Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.92)
    }

    private var cardHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.12),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .center
        )
    }

    var body: some View {
        content
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(cardFill)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(cardHighlight)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(chromeBorder, lineWidth: 1)
            )
            .celleuxDepthShadow()
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

enum GlassButtonVariant {
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
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color(.displayP3, red: 0.70, green: 0.72, blue: 0.76).opacity(0.55),
                            Color.white.opacity(0.85),
                            Color(.displayP3, red: 0.85, green: 0.80, blue: 0.68).opacity(0.60),
                            Color.white.opacity(0.95)
                        ],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: size + lineWidth + 10, height: size + lineWidth + 10)
                .shadow(color: .white.opacity(0.9), radius: 1, x: 0, y: -1)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(.displayP3, red: 0.88, green: 0.86, blue: 0.83),
                            Color(.displayP3, red: 0.94, green: 0.92, blue: 0.89)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        .frame(width: size - lineWidth * 0.5, height: size - lineWidth * 0.5)
                        .blur(radius: 1)
                        .mask(
                            Circle()
                                .stroke(lineWidth: lineWidth)
                                .frame(width: size, height: size)
                        )
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(.displayP3, red: 0.88, green: 0.78, blue: 0.55),
                            Color(.displayP3, red: 0.78, green: 0.66, blue: 0.43),
                            Color(.displayP3, red: 0.95, green: 0.88, blue: 0.68),
                            Color(.displayP3, red: 0.78, green: 0.66, blue: 0.43),
                            Color(.displayP3, red: 0.88, green: 0.78, blue: 0.55)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: CelleuxColors.goldGlow.opacity(glowing ? 0.7 : 0.25), radius: glowing ? 22 : 10)
                .shadow(color: Color(.displayP3, red: 0.78, green: 0.55, blue: 0.25).opacity(0.25), radius: 2, x: 0, y: 1)

            Circle()
                .trim(from: 0.04, to: 0.22)
                .stroke(Color.white.opacity(0.75), lineWidth: 1.8)
                .frame(width: size + 5, height: size + 5)
                .blur(radius: 0.6)
                .rotationEffect(.degrees(-82))

            Circle()
                .trim(from: 0.52, to: 0.62)
                .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                .frame(width: size + 5, height: size + 5)
                .blur(radius: 0.8)
                .rotationEffect(.degrees(-90))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Score ring")
        .accessibilityValue("\(Int(progress * 100)) out of 100")
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

struct SectionHeader: View {
    let title: String
    var action: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(.displayP3, red: 0.15, green: 0.15, blue: 0.20).opacity(0.55))
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating: Bool = false
    let color: Color

    var body: some View {
        ZStack {
            if !reduceMotion {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 16, height: 16)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0 : 0.6)
            }

            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct ShimmerEffect: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if !reduceMotion {
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
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct SkeletonShimmerEffect: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startPoint: UnitPoint = UnitPoint(x: -0.4, y: -0.4)

    private static let shimmerColors: [Color] = [
        .clear,
        CelleuxColors.warmGold.opacity(0.12),
        Color.white.opacity(0.22),
        CelleuxColors.warmGold.opacity(0.12),
        .clear
    ]

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(
                Group {
                    if !reduceMotion {
                        LinearGradient(
                            colors: Self.shimmerColors,
                            startPoint: startPoint,
                            endPoint: UnitPoint(x: startPoint.x + 0.5, y: startPoint.y + 0.5)
                        )
                        .allowsHitTesting(false)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    startPoint = UnitPoint(x: 1.4, y: 1.4)
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
        self.modifier(StaggeredAppearModifier(appeared: appeared, delay: delay))
    }

    func premiumCardStyle(depth: GlassDepth = .standard) -> some View {
        self
            .rotation3DEffect(.degrees(0.5), axis: (x: 1, y: 0, z: 0), perspective: 0.8)
    }

    func breathingShadow(color: Color = CelleuxColors.goldGlow, isActive: Bool) -> some View {
        self
            .shadow(color: color.opacity(isActive ? 0.12 : 0.06), radius: isActive ? 30 : 15, x: 0, y: 10)
    }

    func parallaxTilt(maxAngle: Double = 8, resetDelay: Double = 0.25) -> some View {
        modifier(ParallaxTiltModifier(maxAngle: maxAngle, resetDelay: resetDelay))
    }

    func ambientTilt(amount: Double = 1.4) -> some View {
        modifier(AmbientTiltModifier(amount: amount))
    }

    func specularSheen(active: Bool = true) -> some View {
        overlay {
            if active {
                GeometryReader { geo in
                    TimelineView(.animation) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let cycle = (t.truncatingRemainder(dividingBy: 6.0)) / 6.0
                        let x = (cycle * 1.8 - 0.4) * geo.size.width
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.22),
                                .clear
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.35)
                        .offset(x: x)
                        .rotationEffect(.degrees(18))
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                    }
                }
            }
        }
    }
}

struct AmbientTiltModifier: ViewModifier {
    let amount: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                let rx = sin(t * 0.35) * amount
                let ry = cos(t * 0.28) * amount
                content
                    .rotation3DEffect(.degrees(rx), axis: (x: 1, y: 0, z: 0), perspective: 0.8)
                    .rotation3DEffect(.degrees(ry), axis: (x: 0, y: 1, z: 0), perspective: 0.8)
            }
        }
    }
}

struct ParallaxTiltModifier: ViewModifier {
    let maxAngle: Double
    let resetDelay: Double
    @State private var tx: CGFloat = 0
    @State private var ty: CGFloat = 0
    @State private var size: CGSize = .zero
    @State private var isPressed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var normX: Double {
        guard size.width > 1 else { return 0 }
        return Double(tx / size.width)
    }
    private var normY: Double {
        guard size.height > 1 else { return 0 }
        return Double(ty / size.height)
    }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self, of: { $0.size }) { size = $0 }
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : -normY * maxAngle),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.8
            )
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : normX * maxAngle),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.8
            )
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let cx = size.width / 2
                        let cy = size.height / 2
                        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.7)) {
                            tx = value.location.x - cx
                            ty = value.location.y - cy
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
                            tx = 0
                            ty = 0
                            isPressed = false
                        }
                    }
            )
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
                .stroke(CelleuxColors.iconHighlightGradient, lineWidth: 1.5)
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(gradientStyle)
        }
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .accessibilityHidden(true)
    }
}

struct PremiumDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(.displayP3, red: 0.78, green: 0.78, blue: 0.80).opacity(0.02),
                        Color(.displayP3, red: 0.78, green: 0.78, blue: 0.80).opacity(0.25),
                        Color.white.opacity(0.3),
                        Color(.displayP3, red: 0.78, green: 0.78, blue: 0.80).opacity(0.25),
                        Color(.displayP3, red: 0.78, green: 0.78, blue: 0.80).opacity(0.02)
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
                .stroke(CelleuxColors.iconHighlightGradient, lineWidth: 1.5)
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
        .accessibilityHidden(true)
    }
}

// MARK: - Staggered Appear (Reduce Motion aware)

struct StaggeredAppearModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let appeared: Bool
    let delay: Double

    func body(content: Content) -> some View {
        if reduceMotion {
            content
                .opacity(appeared ? 1 : 0)
                .animation(.easeInOut(duration: 0.2).delay(delay * 0.5), value: appeared)
        } else {
            content
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .scaleEffect(appeared ? 1 : 0.97)
                .animation(.spring(duration: 0.5, bounce: 0.2).delay(delay), value: appeared)
        }
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

struct GoldRefreshSpinner: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(CelleuxColors.silverLight.opacity(0.3), lineWidth: 2)
                .frame(width: 28, height: 28)

            Circle()
                .trim(from: 0, to: 0.65)
                .stroke(
                    AngularGradient(
                        colors: [
                            CelleuxColors.warmGold.opacity(0.1),
                            CelleuxColors.warmGold,
                            CelleuxColors.champagneGold.opacity(0.8)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 28, height: 28)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
