import SwiftUI

enum ErrorStateType {
    case cameraPermissionDenied
    case healthKitDenied
    case noInternet
    case scanFailedLighting
    case scanFailedNoFace
    case scanFailedMovement
    case scanFailedGeneric(String)

    var icon: String {
        switch self {
        case .cameraPermissionDenied: "camera.fill"
        case .healthKitDenied: "heart.text.square"
        case .noInternet: "wifi.slash"
        case .scanFailedLighting: "sun.min.fill"
        case .scanFailedNoFace: "face.dashed"
        case .scanFailedMovement: "hand.raised.fill"
        case .scanFailedGeneric: "exclamationmark.triangle.fill"
        }
    }

    var title: String {
        switch self {
        case .cameraPermissionDenied: "Camera Access Required"
        case .healthKitDenied: "Health Data Unavailable"
        case .noInternet: "No Connection"
        case .scanFailedLighting: "Lighting Too Dim"
        case .scanFailedNoFace: "Face Not Detected"
        case .scanFailedMovement: "Hold Still"
        case .scanFailedGeneric: "Scan Failed"
        }
    }

    var message: String {
        switch self {
        case .cameraPermissionDenied:
            "Celleux needs camera access for skin analysis. Enable it in Settings to use the scanner."
        case .healthKitDenied:
            "Connect Apple Health for sleep, HRV, and activity insights that improve your longevity score."
        case .noInternet:
            "An internet connection is needed for NFC verification. Your data is saved and will sync when reconnected."
        case .scanFailedLighting:
            "Move to a well-lit area with even, natural light. Avoid harsh shadows or backlighting."
        case .scanFailedNoFace:
            "Position your face within the frame and ensure nothing is obstructing the camera."
        case .scanFailedMovement:
            "Keep your head still during the scan. The analysis requires a steady image for accurate results."
        case .scanFailedGeneric(let detail):
            detail.isEmpty ? "Something went wrong during the scan. Please try again." : detail
        }
    }

    var actionLabel: String {
        switch self {
        case .cameraPermissionDenied: "Open Settings"
        case .healthKitDenied: "Continue Without"
        case .noInternet: "Retry"
        case .scanFailedLighting, .scanFailedNoFace, .scanFailedMovement, .scanFailedGeneric: "Try Again"
        }
    }

    var iconGradient: LinearGradient {
        switch self {
        case .cameraPermissionDenied, .healthKitDenied:
            CelleuxColors.iconGoldGradient
        case .noInternet:
            CelleuxColors.iconBlueGradient
        case .scanFailedLighting:
            CelleuxColors.iconAmberGradient
        case .scanFailedNoFace, .scanFailedMovement, .scanFailedGeneric:
            CelleuxColors.iconGoldGradient
        }
    }
}

struct ErrorStateView: View {
    let type: ErrorStateType
    let action: () -> Void
    var secondaryAction: (() -> Void)? = nil
    var secondaryLabel: String? = nil

    var body: some View {
        GlassCard(cornerRadius: 24, depth: .elevated) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    iconBackgroundColor.opacity(0.15),
                                    iconBackgroundColor.opacity(0.03)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 72, height: 72)

                    Image(systemName: type.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(type.iconGradient)
                        .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5), isActive: true)
                }

                VStack(spacing: 8) {
                    Text(type.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    Text(type.message)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(CelleuxColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    Button {
                        action()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: actionIcon)
                                .font(.system(size: 13, weight: .medium))
                            Text(type.actionLabel)
                                .font(.system(size: 14, weight: .semibold))
                                .tracking(0.3)
                        }
                        .foregroundStyle(CelleuxColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(GlassButtonStyle(style: .primary))
                    .accessibilityLabel(type.actionLabel)

                    if let secondaryAction, let secondaryLabel {
                        Button {
                            secondaryAction()
                        } label: {
                            Text(secondaryLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }
                        .accessibilityLabel(secondaryLabel)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
    }

    private var iconBackgroundColor: Color {
        switch type {
        case .scanFailedLighting: Color(.displayP3, red: 0.92, green: 0.75, blue: 0.35)
        case .noInternet: CelleuxColors.silver
        default: CelleuxColors.warmGold
        }
    }

    private var actionIcon: String {
        switch type {
        case .cameraPermissionDenied: "gear"
        case .healthKitDenied: "arrow.right"
        case .noInternet: "arrow.clockwise"
        case .scanFailedLighting, .scanFailedNoFace, .scanFailedMovement, .scanFailedGeneric: "arrow.counterclockwise"
        }
    }
}

struct ScanErrorBanner: View {
    let message: String
    let icon: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(CelleuxColors.warmGold)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CelleuxColors.textPrimary)
                .lineLimit(2)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(CelleuxColors.textLabel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CelleuxColors.warmGold.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: CelleuxColors.warmGold.opacity(0.1), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap dismiss to close")
    }
}
