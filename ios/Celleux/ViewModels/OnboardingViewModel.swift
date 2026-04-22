import SwiftUI
import SwiftData
import AVFoundation
import UserNotifications
import HealthKit

@Observable
final class OnboardingViewModel {
    var currentPage: OnboardingPage = .welcome
    var showQRScanner: Bool = false
    var qrScanSuccess: Bool = false

    var name: String = ""
    var selectedAgeRange: String? = nil
    var selectedGoals: Set<String> = []
    var selectedConcerns: Set<String> = []
    var selectedGender: String? = nil
    var selectedSkinType: FitzpatrickType? = nil
    var referralSource: String? = nil

    var healthConnected: Bool = false
    var notificationsEnabled: Bool = false
    var cameraEnabled: Bool = false

    var isComplete: Bool = false

    let ageRanges = ["18-24", "25-34", "35-44", "45-54", "55+"]
    let goals = ["Glowing skin", "Anti-aging", "Energy & vitality", "Longevity", "Better sleep"]
    let concerns = ["Fine lines", "Dullness", "Uneven tone", "Dryness", "Texture", "Dark circles"]
    let genders = ["Female", "Male", "Prefer not to say"]

    var progressFraction: CGFloat {
        let all = OnboardingPage.allCases
        guard let idx = all.firstIndex(of: currentPage) else { return 0 }
        return CGFloat(idx + 1) / CGFloat(all.count)
    }

    func nextPage() {
        guard let next = currentPage.next else {
            return
        }
        currentPage = next
    }

    func goToPersonalization() {
        currentPage = .personalization
    }

    func saveProfile(modelContext: ModelContext) {
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            ageRange: selectedAgeRange ?? "",
            goals: Array(selectedGoals),
            skinConcerns: Array(selectedConcerns),
            gender: selectedGender ?? "",
            skinType: selectedSkinType?.rawValue ?? ""
        )
        modelContext.insert(profile)
        try? modelContext.save()
    }

    func requestHealthPermission() async {
        let service = HealthKitService.shared
        let authorized = await service.requestAuthorization()
        healthConnected = authorized
    }

    func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            cameraEnabled = true
            return
        }
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraEnabled = granted
    }

    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            notificationsEnabled = granted
        } catch {
            notificationsEnabled = false
        }
    }

    func checkExistingPermissions() async {
        let healthService = HealthKitService.shared
        healthConnected = healthService.isAvailable && healthService.isAuthorized

        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        cameraEnabled = cameraStatus == .authorized

        let notifSettings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsEnabled = notifSettings.authorizationStatus == .authorized
    }

    func completeOnboarding() {
        isComplete = true
    }

    func toggleGoal(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func toggleConcern(_ concern: String) {
        if selectedConcerns.contains(concern) {
            selectedConcerns.remove(concern)
        } else {
            selectedConcerns.insert(concern)
        }
    }
}

nonisolated enum OnboardingPage: Int, CaseIterable, Sendable {
    case welcome
    case skinTracking
    case longevityScore
    case smartTiming
    case socialProof
    case personalization
    case referralSource
    case analyzing
    case projectedResults
    case permissions
    case completion

    var next: OnboardingPage? {
        let all = OnboardingPage.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    var isCarousel: Bool {
        switch self {
        case .skinTracking, .longevityScore, .smartTiming: true
        default: false
        }
    }

    var showSkip: Bool {
        switch self {
        case .skinTracking, .longevityScore, .smartTiming, .permissions: true
        default: false
        }
    }

    var showProgress: Bool {
        self != .welcome && self != .completion
    }

    var showDots: Bool {
        switch self {
        case .skinTracking, .longevityScore, .smartTiming: true
        default: false
        }
    }

    var dotIndex: Int {
        switch self {
        case .skinTracking: 0
        case .longevityScore: 1
        case .smartTiming: 2
        default: 0
        }
    }

    static let dotCount = 3
}
