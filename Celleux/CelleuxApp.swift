import SwiftUI
import SwiftData

@main
struct CelleuxApp: App {
    @State private var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var appearanceManager = AppearanceManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .transition(.opacity)
                } else {
                    OnboardingView()
                        .environment(\.completeOnboarding, {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                hasCompletedOnboarding = true
                            }
                        })
                        .environment(\.resetOnboarding, {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                                hasCompletedOnboarding = false
                            }
                        })
                }
            }
            .preferredColorScheme(appearanceManager.colorScheme)
        }
        .modelContainer(for: [
            UserProfile.self,
            DailyLongevityScore.self,
            SupplementDose.self,
            SkinScanRecord.self,
            DailyCheckIn.self,
            AchievementRecord.self,
            CalibrationBaseline.self,
            DoseCompletionPattern.self,
            SkinTransformationChallenge.self,
        ])
    }
}

private struct CompleteOnboardingKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct ResetOnboardingKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var completeOnboarding: () -> Void {
        get { self[CompleteOnboardingKey.self] }
        set { self[CompleteOnboardingKey.self] = newValue }
    }

    var resetOnboarding: () -> Void {
        get { self[ResetOnboardingKey.self] }
        set { self[ResetOnboardingKey.self] = newValue }
    }
}
