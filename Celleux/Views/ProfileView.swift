import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.resetOnboarding) private var resetOnboarding
    @Query private var profiles: [UserProfile]
    @Query private var scans: [SkinScanRecord]
    @Query private var checkIns: [DailyCheckIn]
    @Query(filter: #Predicate<AchievementRecord> { $0.unlockedAt != nil }) private var unlockedAchievements: [AchievementRecord]
    @Query private var baselines: [CalibrationBaseline]
    @State private var appeared: Bool = false
    @State private var showSettings: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showDeleteScansAlert: Bool = false
    @State private var settingsHaptic: Int = 0
    @State private var toggleHaptic: Int = 0
    @State private var ringGlowing: Bool = false

    @State private var supplementReminders: Bool = UserDefaults.standard.bool(forKey: "supplementReminders")
    @State private var weeklySummary: Bool = UserDefaults.standard.bool(forKey: "weeklySummary")
    @State private var achievementAlerts: Bool = UserDefaults.standard.bool(forKey: "achievementAlerts")

    private var profile: UserProfile? { profiles.first }
    private var streak: Int { UserDefaults.standard.integer(forKey: "adherenceStreak") }

    private var bestScore: Int? {
        scans.map(\.overallScore).max()
    }

    private var latestScore: Int? {
        scans.sorted(by: { $0.date > $1.date }).first?.overallScore
    }

    private var skinTypeBadge: String? {
        guard let raw = profile?.skinType, !raw.isEmpty,
              let type = FitzpatrickType(rawValue: raw) else { return nil }
        return type.badge
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    statsCard
                    achievementsSection
                    challengeSection
                    notificationToggles
                    settingsSections
                    appVersionFooter
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(CelleuxMeshBackground())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showSettings) {
                SettingsSheet(
                    showDeleteAlert: $showDeleteAlert,
                    showDeleteScansAlert: $showDeleteScansAlert,
                    supplementReminders: $supplementReminders,
                    weeklySummary: $weeklySummary,
                    achievementAlerts: $achievementAlerts
                )
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(32)
            }
            .alert("Delete All Scan Photos?", isPresented: $showDeleteScansAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteAllScans() }
            } message: {
                Text("This will permanently delete all scan records and photos. This cannot be undone.")
            }
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) { deleteAllData() }
            } message: {
                Text("This will delete all your data including scans, check-ins, and profile. This cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        settingsHaptic += 1
                        showSettings = true
                    } label: {
                        ChromeToolbarButton(icon: "gearshape")
                    }
                    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.4), trigger: settingsHaptic)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
                    ringGlowing = true
                }
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        GlassCard(depth: .elevated) {
            VStack(spacing: 18) {
                ZStack {
                    let progress = Double(bestScore ?? 0) / 100.0
                    ChromeRingView(
                        progress: progress,
                        size: 120,
                        lineWidth: 8,
                        glowing: $ringGlowing
                    )

                    VStack(spacing: 2) {
                        if let best = bestScore {
                            Text("\(best)")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundStyle(CelleuxColors.textPrimary)
                                .contentTransition(.numericText())
                            Text("BEST")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(CelleuxColors.warmGold)
                                .tracking(1.2)
                        } else {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(CelleuxColors.textLabel)
                            Text("NO SCANS")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(CelleuxColors.textLabel)
                                .tracking(1.0)
                        }
                    }
                }

                if let latest = latestScore, let best = bestScore, latest != best {
                    Text("Latest: \(latest)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CelleuxColors.textSecondary)
                }

                VStack(spacing: 6) {
                    Text(profile?.name ?? "Welcome")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    HStack(spacing: 8) {
                        if let badge = skinTypeBadge {
                            Text(badge)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CelleuxColors.warmGold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(CelleuxColors.warmGold.opacity(0.08))
                                        .overlay(
                                            Capsule()
                                                .stroke(CelleuxColors.warmGold.opacity(0.2), lineWidth: 0.5)
                                        )
                                )
                        }

                        if let age = profile?.ageRange, !age.isEmpty {
                            Text(age)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CelleuxColors.textLabel)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(CelleuxColors.silverLight.opacity(0.15))
                                )
                        }
                    }

                    if let created = profile?.createdAt {
                        Text("Member since \(memberSince(created))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.textSecondary)
                            .padding(.top, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

    // MARK: - Stats

    private var statsCard: some View {
        GlassCard {
            HStack(spacing: 0) {
                statItem(value: "\(scans.count)", label: "Scans")
                statDivider
                statItem(value: "\(streak)", label: "Day Streak")
                statDivider
                statItem(value: "\(checkIns.count)", label: "Check-Ins")
                statDivider
                statItem(value: "\(unlockedAchievements.count)", label: "Badges")
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.08)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundStyle(CelleuxColors.textPrimary)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.20).opacity(0.45))
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color(hex: "D4C4A0").opacity(0.05), Color(hex: "C9A96E").opacity(0.2), Color(hex: "D4C4A0").opacity(0.05)], startPoint: .top, endPoint: .bottom))
            .frame(width: 1, height: 32)
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(spacing: 12) {
            HStack {
                SectionHeader(title: "Achievements")
                Spacer()
                NavigationLink(destination: AchievementsView()) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(CelleuxColors.warmGold)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(AchievementDefinition.allCases.prefix(8)) { def in
                        let unlocked = unlockedAchievements.contains { $0.identifier == def.rawValue }
                        achievementBadge(def: def, unlocked: unlocked)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
        .staggeredAppear(appeared: appeared, delay: 0.16)
    }

    private func achievementBadge(def: AchievementDefinition, unlocked: Bool) -> some View {
        VStack(spacing: 10) {
            if unlocked {
                GlowingAccentBadge(def.icon, color: CelleuxColors.roseGold, size: 60)
            } else {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color(hex: "F2F0ED"), Color(hex: "E8E6E3")], center: .init(x: 0.35, y: 0.35), startRadius: 0, endRadius: 32))
                        .frame(width: 60, height: 60)
                    Circle()
                        .stroke(CelleuxColors.silverBorder.opacity(0.2), lineWidth: 0.5)
                        .frame(width: 60, height: 60)
                    Image(systemName: def.icon)
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(CelleuxColors.silverGradient)
                        .opacity(0.35)
                }
            }
            Text(def.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(unlocked ? CelleuxColors.textPrimary : CelleuxColors.textLabel)
                .multilineTextAlignment(.center)
        }
        .frame(width: 82)
    }

    // MARK: - Challenge Section

    private var challengeSection: some View {
        VStack(spacing: 12) {
            HStack {
                SectionHeader(title: "Challenge")
                Spacer()
                NavigationLink(destination: ChallengeDetailView()) {
                    HStack(spacing: 4) {
                        Text("View")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(CelleuxColors.warmGold)
                }
            }

            NavigationLink(destination: ChallengeDetailView()) {
                GlassCard(cornerRadius: 20) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [CelleuxColors.warmGold.opacity(0.12), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 28
                                    )
                                )
                                .frame(width: 52, height: 52)
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [CelleuxColors.roseGold, CelleuxColors.warmGold],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("90-Day Skin Transformation")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(CelleuxColors.textPrimary)
                            Text("Track your journey with milestones & rewards")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(CelleuxColors.textLabel)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CelleuxColors.silver)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .staggeredAppear(appeared: appeared, delay: 0.20)
    }

    // MARK: - Quick Toggles

    private var notificationToggles: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Notifications")
                .padding(.bottom, 10)

            GlassCard(cornerRadius: 20) {
                VStack(spacing: 0) {
                    toggleRow(icon: "pill.fill", title: "Supplement Reminders", isOn: $supplementReminders)
                    PremiumDivider()
                    toggleRow(icon: "chart.bar.doc.horizontal", title: "Weekly Summary", isOn: $weeklySummary)
                    PremiumDivider()
                    toggleRow(icon: "trophy.fill", title: "Achievement Alerts", isOn: $achievementAlerts)
                }
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0.24)
        .sensoryFeedback(.selection, trigger: toggleHaptic)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ChromeIconBadge(icon, size: 34)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CelleuxColors.textPrimary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isOn.wrappedValue },
                set: { newValue in
                    withAnimation(CelleuxSpring.snappy) {
                        isOn.wrappedValue = newValue
                    }
                    toggleHaptic += 1
                    saveTogglePreferences()
                }
            ))
            .labelsHidden()
            .tint(CelleuxColors.warmGold)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Settings Groups

    private var settingsSections: some View {
        VStack(spacing: 22) {
            settingsGroup(title: "HEALTH", items: [
                ("applewatch", "Apple Watch", healthWatchSubtitle, {
                    Task { await HealthKitService.shared.requestAuthorization() }
                }),
                ("heart.text.square", "Apple Health", healthKitSubtitle, {
                    if let url = URL(string: "x-apple-health://") {
                        UIApplication.shared.open(url)
                    }
                }),
            ])

            settingsGroup(title: "DATA", items: [
                ("square.and.arrow.up", "Export My Data", "Download all your data", {
                    exportData(format: .json)
                }),
                ("trash", "Delete Scan Photos", "Remove all stored scans", {
                    showDeleteScansAlert = true
                }),
            ])

            settingsGroup(title: "ACCOUNT", items: [
                ("arrow.right.square", "Sign Out", "Return to onboarding", {
                    resetOnboarding()
                }),
                ("xmark.circle", "Delete Account", "Remove all data", {
                    showDeleteAlert = true
                }),
            ])
        }
        .staggeredAppear(appeared: appeared, delay: 0.32)
    }

    private var healthWatchSubtitle: String {
        HealthKitService.shared.hasWatchData ? "Connected" : "Connect for biometrics"
    }

    private var healthKitSubtitle: String {
        HealthKitService.shared.isAuthorized ? "Connected" : "Sync health data"
    }

    private func settingsGroup(title: String, items: [(String, String, String, () -> Void)]) -> some View {
        VStack(spacing: 0) {
            SectionHeader(title: title)
                .padding(.bottom, 10)

            GlassCard(cornerRadius: 20) {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        if index > 0 {
                            PremiumDivider()
                        }
                        Button { item.3() } label: {
                            HStack(spacing: 14) {
                                ChromeIconBadge(item.0, size: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.1)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(CelleuxColors.textPrimary)
                                    HStack(spacing: 5) {
                                        if item.2 == "Connected" {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 6, height: 6)
                                        }
                                        Text(item.2)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundStyle(item.2 == "Connected" ? Color.green : CelleuxColors.textLabel)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(CelleuxColors.warmGold)
                            }
                            .padding(.vertical, 13)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var appVersionFooter: some View {
        VStack(spacing: 6) {
            Text("Celleux v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
            Text("Powered by ARKit + Vision + Core Image")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(CelleuxColors.textLabel.opacity(0.6))
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private var initials: String {
        guard let name = profile?.name, !name.isEmpty else { return "CE" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func memberSince(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    private func saveTogglePreferences() {
        UserDefaults.standard.set(supplementReminders, forKey: "supplementReminders")
        UserDefaults.standard.set(weeklySummary, forKey: "weeklySummary")
        UserDefaults.standard.set(achievementAlerts, forKey: "achievementAlerts")
    }

    // MARK: - Export

    nonisolated enum ExportFormat { case json, csv }

    private func exportData(format: ExportFormat) {
        let tempURL: URL
        switch format {
        case .json:
            tempURL = exportJSON()
        case .csv:
            tempURL = exportCSV()
        }

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }

    private func exportJSON() -> URL {
        var exportDict: [String: Any] = [:]

        if let p = profile {
            exportDict["profile"] = ["name": p.name, "ageRange": p.ageRange, "goals": p.goals, "skinConcerns": p.skinConcerns, "gender": p.gender, "skinType": p.skinType]
        }

        exportDict["scans"] = scans.map { ["date": $0.date.ISO8601Format(), "overallScore": $0.overallScore, "brightness": $0.brightnessScore, "redness": $0.rednessScore, "texture": $0.textureScore, "hydration": $0.hydrationScore] }
        exportDict["checkIns"] = checkIns.map { ["date": $0.date.ISO8601Format(), "mood": $0.mood, "energy": $0.energy, "note": $0.note] }

        let data = (try? JSONSerialization.data(withJSONObject: exportDict, options: [.prettyPrinted, .sortedKeys])) ?? Data()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("celleux_export.json")
        try? data.write(to: url)
        return url
    }

    private func exportCSV() -> URL {
        var csv = "Date,Overall Score,Brightness,Redness,Texture,Hydration\n"
        for scan in scans.sorted(by: { $0.date < $1.date }) {
            csv += "\(scan.date.ISO8601Format()),\(scan.overallScore),\(scan.brightnessScore),\(scan.rednessScore),\(scan.textureScore),\(scan.hydrationScore)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("celleux_scans.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Destructive Actions

    private func deleteAllScans() {
        for scan in scans {
            modelContext.delete(scan)
        }
        UserDefaults.standard.removeObject(forKey: "latestSkinScore")
        try? modelContext.save()
    }

    private func deleteAllData() {
        let scanDesc = FetchDescriptor<SkinScanRecord>()
        let checkInDesc = FetchDescriptor<DailyCheckIn>()
        let profileDesc = FetchDescriptor<UserProfile>()
        let achievementDesc = FetchDescriptor<AchievementRecord>()
        let doseDesc = FetchDescriptor<SupplementDose>()
        let scoreDesc = FetchDescriptor<DailyLongevityScore>()

        for record in (try? modelContext.fetch(scanDesc)) ?? [] { modelContext.delete(record) }
        for record in (try? modelContext.fetch(checkInDesc)) ?? [] { modelContext.delete(record) }
        for record in (try? modelContext.fetch(profileDesc)) ?? [] { modelContext.delete(record) }
        for record in (try? modelContext.fetch(achievementDesc)) ?? [] { modelContext.delete(record) }
        for record in (try? modelContext.fetch(doseDesc)) ?? [] { modelContext.delete(record) }
        for record in (try? modelContext.fetch(scoreDesc)) ?? [] { modelContext.delete(record) }

        UserDefaults.standard.removeObject(forKey: "adherenceStreak")
        UserDefaults.standard.removeObject(forKey: "latestSkinScore")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "supplementReminders")
        UserDefaults.standard.removeObject(forKey: "weeklySummary")
        UserDefaults.standard.removeObject(forKey: "achievementAlerts")
        UserDefaults.standard.removeObject(forKey: "lightingSensitivity")
        UserDefaults.standard.removeObject(forKey: "scanDuration")

        try? modelContext.save()
        resetOnboarding()
    }
}

// MARK: - Settings Sheet

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var baselines: [CalibrationBaseline]
    @Query private var scans: [SkinScanRecord]
    @Query private var checkIns: [DailyCheckIn]
    @Binding var showDeleteAlert: Bool
    @Binding var showDeleteScansAlert: Bool
    @Binding var supplementReminders: Bool
    @Binding var weeklySummary: Bool
    @Binding var achievementAlerts: Bool

    @State private var editName: String = ""
    @State private var editSkinType: FitzpatrickType? = nil
    @State private var lightingSensitivity: String = UserDefaults.standard.string(forKey: "lightingSensitivity") ?? "Normal"
    @State private var scanDuration: String = UserDefaults.standard.string(forKey: "scanDuration") ?? "Standard 8s"
    @State private var showCalibrationResetAlert: Bool = false
    @State private var showExportPicker: Bool = false
    @State private var hapticTrigger: Int = 0

    private let lightingOptions = ["Strict", "Normal", "Lenient"]
    private let durationOptions = ["Quick 4s", "Standard 8s", "Thorough 12s"]

    var body: some View {
        NavigationStack {
            List {
                personalInfoSection
                scanSettingsSection
                notificationsSection
                healthConnectionsSection
                dataManagementSection
                aboutSection
                dangerZone
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sensoryFeedback(.selection, trigger: hapticTrigger)
            .alert("Reset Calibration?", isPresented: $showCalibrationResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetCalibration() }
            } message: {
                Text("This will clear your 3-scan baseline. Your next 3 scans will establish a new reference point for all future comparisons.")
            }
            .confirmationDialog("Export Format", isPresented: $showExportPicker) {
                Button("CSV (Spreadsheet)") { exportAndShare(format: .csv) }
                Button("JSON (Raw Data)") { exportAndShare(format: .json) }
                Button("Cancel", role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(CelleuxColors.warmGold)
                }
            }
            .onAppear {
                editName = profiles.first?.name ?? ""
                if let raw = profiles.first?.skinType, !raw.isEmpty {
                    editSkinType = FitzpatrickType(rawValue: raw)
                }
            }
        }
    }

    // MARK: - Personal Info

    private var personalInfoSection: some View {
        Section {
            HStack {
                Text("Name")
                Spacer()
                TextField("Your name", text: $editName)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(CelleuxColors.textSecondary)
            }

            Picker("Skin Type", selection: $editSkinType) {
                Text("Not Set").tag(nil as FitzpatrickType?)
                ForEach(FitzpatrickType.allCases) { type in
                    Text(type.badge).tag(type as FitzpatrickType?)
                }
            }
            .onChange(of: editSkinType) { _, _ in
                hapticTrigger += 1
            }
        } header: {
            Text("Personal Info")
        }
    }

    // MARK: - Scan Settings

    private var scanSettingsSection: some View {
        Section {
            Picker("Lighting Sensitivity", selection: $lightingSensitivity) {
                ForEach(lightingOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .onChange(of: lightingSensitivity) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "lightingSensitivity")
                hapticTrigger += 1
            }

            Picker("Scan Duration", selection: $scanDuration) {
                ForEach(durationOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .onChange(of: scanDuration) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "scanDuration")
                hapticTrigger += 1
            }

            Button {
                showCalibrationResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Calibration Baseline")
                    Spacer()
                    if !baselines.isEmpty {
                        Text("\(baselines.first?.scanCount ?? 0) scans")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(CelleuxColors.textPrimary)
            }
        } header: {
            Text("Scan Settings")
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $supplementReminders) {
                Label("Supplement Reminders", systemImage: "pill.fill")
            }
            .tint(CelleuxColors.warmGold)
            .onChange(of: supplementReminders) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "supplementReminders")
                hapticTrigger += 1
            }

            Toggle(isOn: $weeklySummary) {
                Label("Weekly Summary", systemImage: "chart.bar.doc.horizontal")
            }
            .tint(CelleuxColors.warmGold)
            .onChange(of: weeklySummary) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "weeklySummary")
                hapticTrigger += 1
            }

            Toggle(isOn: $achievementAlerts) {
                Label("Achievement Alerts", systemImage: "trophy.fill")
            }
            .tint(CelleuxColors.warmGold)
            .onChange(of: achievementAlerts) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "achievementAlerts")
                hapticTrigger += 1
            }
        } header: {
            Text("Notifications")
        }
    }

    // MARK: - Health Connections

    private var healthConnectionsSection: some View {
        Section {
            HStack {
                Label("Apple Health", systemImage: "heart.fill")
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(HealthKitService.shared.isAuthorized ? Color.green : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                    Text(HealthKitService.shared.isAuthorized ? "Connected" : "Not Connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Label("Apple Watch", systemImage: "applewatch")
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(HealthKitService.shared.hasWatchData ? Color.green : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                    Text(HealthKitService.shared.hasWatchData ? "Detected" : "Not Detected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !HealthKitService.shared.isAuthorized {
                Button {
                    Task { await HealthKitService.shared.requestAuthorization() }
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Connect Apple Health")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundStyle(CelleuxColors.warmGold)
                }
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "hand.raised")
                    Text("Manage Permissions")
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption)
                }
                .foregroundStyle(CelleuxColors.textPrimary)
            }
        } header: {
            Text("Health Connections")
        }
    }

    // MARK: - Data Management

    private var dataManagementSection: some View {
        Section {
            Button {
                showExportPicker = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Scan History")
                    Spacer()
                    Text("CSV / JSON")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(CelleuxColors.textPrimary)
            }

            Button(role: .destructive) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showDeleteScansAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete All Scan Photos")
                }
            }
        } header: {
            Text("Data Management")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://celleux.com/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundStyle(CelleuxColors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
                }
            }

            Link(destination: URL(string: "https://celleux.com/terms")!) {
                HStack {
                    Text("Terms of Service")
                        .foregroundStyle(CelleuxColors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
                }
            }

            HStack {
                Spacer()
                Text("Powered by ARKit + Vision + Core Image")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .listRowBackground(Color.clear)
        } header: {
            Text("About")
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        Section {
            Button(role: .destructive) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showDeleteAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Delete Account & Data")
                }
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        guard let profile = profiles.first else { return }
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            profile.name = trimmed
        }
        profile.skinType = editSkinType?.rawValue ?? ""
        try? modelContext.save()
    }

    private func resetCalibration() {
        for baseline in baselines {
            modelContext.delete(baseline)
        }
        try? modelContext.save()
    }

    private func exportAndShare(format: ProfileView.ExportFormat) {
        let tempURL: URL
        switch format {
        case .csv:
            tempURL = exportCSVFromSheet()
        case .json:
            tempURL = exportJSONFromSheet()
        }

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }

    private func exportJSONFromSheet() -> URL {
        var exportDict: [String: Any] = [:]
        if let p = profiles.first {
            exportDict["profile"] = ["name": p.name, "ageRange": p.ageRange, "goals": p.goals, "skinConcerns": p.skinConcerns, "gender": p.gender, "skinType": p.skinType]
        }
        exportDict["scans"] = scans.map { ["date": $0.date.ISO8601Format(), "overallScore": $0.overallScore, "brightness": $0.brightnessScore, "redness": $0.rednessScore, "texture": $0.textureScore, "hydration": $0.hydrationScore] }
        exportDict["checkIns"] = checkIns.map { ["date": $0.date.ISO8601Format(), "mood": $0.mood, "energy": $0.energy, "note": $0.note] }
        let data = (try? JSONSerialization.data(withJSONObject: exportDict, options: [.prettyPrinted, .sortedKeys])) ?? Data()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("celleux_export.json")
        try? data.write(to: url)
        return url
    }

    private func exportCSVFromSheet() -> URL {
        var csv = "Date,Overall Score,Brightness,Redness,Texture,Hydration\n"
        for scan in scans.sorted(by: { $0.date < $1.date }) {
            csv += "\(scan.date.ISO8601Format()),\(scan.overallScore),\(scan.brightnessScore),\(scan.rednessScore),\(scan.textureScore),\(scan.hydrationScore)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("celleux_scans.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
