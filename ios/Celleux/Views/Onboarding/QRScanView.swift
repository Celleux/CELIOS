import SwiftUI
import AVFoundation

struct QRScanView: View {
    @Binding var isPresented: Bool
    @Binding var scanSuccess: Bool
    let onSuccess: () -> Void
    @State private var appeared: Bool = false
    @State private var cornerPulse: Bool = false
    @State private var showCheckmark: Bool = false
    @State private var checkmarkScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            CelleuxMeshBackground()

            RadialGradient(
                colors: [CelleuxColors.warmGold.opacity(0.04), Color.clear],
                center: .init(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 40, height: 40)
                            Circle()
                                .stroke(CelleuxColors.goldChromeBorder, lineWidth: 0.5)
                                .frame(width: 40, height: 40)

                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CelleuxColors.textSecondary)
                        }
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: "F5F2ED"))
                        .frame(width: 280, height: 280)

                    RoundedRectangle(cornerRadius: 28)
                        .stroke(CelleuxColors.goldChromeBorder, lineWidth: 1.5)
                        .frame(width: 280, height: 280)

                    RoundedRectangle(cornerRadius: 27)
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                        .frame(width: 277, height: 277)

                    cornerBrackets
                        .frame(width: 280, height: 280)

                    if showCheckmark {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "F5F0E8"), Color.white],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Circle()
                                .stroke(CelleuxColors.goldChromeBorder, lineWidth: 1.5)
                                .frame(width: 80, height: 80)

                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(CelleuxColors.warmGold)
                        }
                        .shadow(color: CelleuxColors.goldGlow, radius: 20, x: 0, y: 0)
                        .scaleEffect(checkmarkScale)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 48, weight: .ultraLight))
                                .foregroundStyle(CelleuxColors.warmGold.opacity(0.6))

                            Text("Point at QR code")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }
                }
                .shadow(color: CelleuxColors.goldGlow.opacity(0.15), radius: 20, x: 0, y: 10)

                Spacer()
                    .frame(height: 40)

                VStack(spacing: 12) {
                    if showCheckmark {
                        Text("Welcome to Celleux")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                        Text("Your AeonDerm is verified")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(CelleuxColors.textSecondary)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Text("Scan the QR code on your\nAeonDerm packaging")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showCheckmark)

                Spacer()

                if !showCheckmark {
                    VStack(spacing: 14) {
                        Button {
                            simulateScan()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 16, weight: .light))
                                Text("Simulate Scan")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(CelleuxColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(GlassButtonStyle())

                        Button {
                            isPresented = false
                            onSuccess()
                        } label: {
                            Text("Continue without scanning")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .staggeredAppear(appeared: appeared, delay: 0.3)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                cornerPulse = true
            }
        }
    }

    private func simulateScan() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCheckmark = true
            checkmarkScale = 1.0
        }
        scanSuccess = true

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            isPresented = false
            onSuccess()
        }
    }

    private var cornerBrackets: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { corner in
                CornerBracket()
                    .stroke(
                        CelleuxColors.warmGold.opacity(cornerPulse ? 0.9 : 0.5),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(Double(corner) * 90))
                    .offset(
                        x: corner == 0 || corner == 3 ? -120 : 120,
                        y: corner == 0 || corner == 1 ? -120 : 120
                    )
            }
        }
    }
}

struct CornerBracket: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 8))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 8, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
