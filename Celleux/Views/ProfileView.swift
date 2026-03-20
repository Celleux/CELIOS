import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.resetOnboarding) private var resetOnboarding
    @Query private var profiles: [UserProfile]
    @Query private var scans: [SkinScanRecord]
    @Query private var checkIns: [DailyCheckIn]
    @Query(filter: #Predicate<AchievementRecord> { $0.unlockedAt != nil }) private var unlockedAchievements: [AchievementRecord]
    @State private var appeared: Bool = false
    @State private var showSettings: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showDeleteScansAlert: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var settingsHaptic: Int = 0

    private var profile: UserProfile? { profiles.first }
    private var streak: Int { UserDefaults.standard.integer(forKey: "adherenceStreak") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    profileHeader
                    statsCard
                    achievementsSection
                    settingsSections
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(CelleuxMeshBackground())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showSettings) {
                SettingsSheet(showDeleteAlert: $showDeleteAlert, showDeleteScansAlert: $showDeleteScansAlert)
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(32)
            }
            .alert("Delete All Scan Photos?", isPresented: $showDeleteScansAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAllScans()
                }
            } message: {
                Text("This will permanently delete all scan records and photos. This cannot be undone.")
            }
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
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
            }
        }
    }

    private var profileHeader: some View {
        GlassCard(depth: .elevated) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color.white.opacity(0.95), Color(hex: "F5F0E8")], center: .center, startRadius: 0, endRadius: 38))
                        .frame(width: 72, height: 72)
                    Circle()
                        .stroke(AngularGradient(colors: [Color(hex: "E8DCC8").opacity(0.7), Color(hex: "C9A96E").opacity(0.3), Color.white.opacity(0.5)], center: .center), lineWidth: 1.5)
                        .frame(width: 72, height: 72)
                    Text(initials)
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(CelleuxColors.warmGold)
                }
                .shadow(color: CelleuxColors.goldGlow.opacity(0.25), radius: 10, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 5) {
                    Text(profile?.name ?? "Welcome")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(CelleuxColors.textPrimary)

                    if let age = profile?.ageRange, !age.isEmpty {
                        Text("Age: \(age)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(CelleuxColors.textLabel)
                    }

                    if let created = profile?.createdAt {
                        let formatter = DateFormatter()
                        Text("Member since \(memberSince(created))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(CelleuxColors.textSecondary)
                    }
                }
                Spacer()
            }
        }
        .staggeredAppear(appeared: appeared, delay: 0)
    }

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

    private var achievementsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Achievements")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(AchievementDefinition.allCases) { def in
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

    private var settingsSections: some View {
        VStack(spacing: 22) {
            settingsGroup(title: "HEALTH", items: [
                ("applewatch", "Apple Watch", "Connect for biometrics", {
                    Task { await HealthKitService.shared.requestAuthorization() }
                }),
                ("heart.text.square", "Apple Health", "Sync health data", {
                    if let url = URL(string: "x-apple-health://") {
                        UIApplication.shared.open(url)
                    }
                }),
            ])

            settingsGroup(title: "DATA", items: [
                ("square.and.arrow.up", "Export My Data", "Download all your data", {
                    exportData()
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

            appVersionFooter
        }
        .staggeredAppear(appeared: appeared, delay: 0.24)
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
                                    Text(item.2)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundStyle(CelleuxColors.textLabel)
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

    private var appVersionFooter: some View {
        VStack(spacing: 4) {
            Text("Celleux v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CelleuxColors.textLabel)
            Text("Built with care for your skin")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(CelleuxColors.textLabel.opacity(0.6))
        }
        .padding(.top, 8)
    }

    private func exportData() {
        var exportDict: [String: Any] = [:]

        if let p = profile {
            exportDict["profile"] = ["name": p.name, "ageRange": p.ageRange, "goals": p.goals, "skinConcerns": p.skinConcerns, "gender": p.gender]
        }

        exportDict["scans"] = scans.map { ["date": $0.date.ISO8601Format(), "overallScore": $0.overallScore, "brightness": $0.brightnessScore, "redness": $0.rednessScore, "texture": $0.textureScore, "hydration": $0.hydrationScore] }

        exportDict["checkIns"] = checkIns.map { ["date": $0.date.ISO8601Format(), "mood": $0.mood, "energy": $0.energy, "note": $0.note] }

        guard let data = try? JSONSerialization.data(withJSONObject: exportDict, options: [.prettyPrinted, .sortedKeys]) else { return }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("celleux_export.json")
        try? data.write(to: tempURL)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }

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

        try? modelContext.save()
        resetOnboarding()
    }
}

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var editName: String = ""
    @Binding var showDeleteAlert: Bool
    @Binding var showDeleteScansAlert: Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Personal Info") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your name", text: $editName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(CelleuxColors.textSecondary)
                    }
                }

                Section("Privacy") {
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
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }

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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let profile = profiles.first, !editName.trimmingCharacters(in: .whitespaces).isEmpty {
                            profile.name = editName.trimmingCharacters(in: .whitespaces)
                            try? modelContext.save()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(CelleuxColors.warmGold)
                }
            }
            .onAppear {
                editName = profiles.first?.name ?? ""
            }
        }
    }
}
