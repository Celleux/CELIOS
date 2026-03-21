# Premium Profile & Settings Upgrade

## Features

### Profile Header Upgrade
- Enlarged profile header with a **ChromeRingView** showing your all-time best skin score as a gold progress arc
- Your name, skin type badge (Fitzpatrick classification), and "Member since" date
- Below the ring: latest scan score displayed as text alongside the best score
- Total scans, current streak, check-ins, and badges shown as stats

### Skin Type (Fitzpatrick) Selection
- New skin type field added to your profile data
- New skin type picker added to the **onboarding personalization** step (optional field)
- Editable from the profile settings sheet as well
- Displayed as a subtle badge (e.g. "Type III · Medium") next to your name

### Quick Toggles (Inline on Profile)
- **Supplement Reminders** — toggle on/off directly on the profile page
- **Weekly Summary** — toggle on/off
- **Achievement Alerts** — toggle on/off
- Each toggle uses gold-tinted styling and plays a haptic on change

### Settings Sheet (Gear Button → Full Settings)
- **Scan Settings section:**
  - Lighting sensitivity picker (Strict / Normal / Lenient)
  - Scan duration picker (Quick 4s / Standard 8s / Thorough 12s)
  - Calibration reset button with confirmation dialog explaining what gets cleared
- **Notifications section:**
  - Supplement reminder time adjustment
  - Weekly summary and achievement alert toggles (mirrors inline)
- **Health Connections section:**
  - HealthKit connection status with green/gray indicator dot
  - Apple Watch detected status
  - List of data sources with live status
- **Data Management section:**
  - Export scan history — choose between CSV or JSON format
  - Clear calibration baseline (with confirmation)
  - Delete all scan photos (existing)
  - Delete account (existing)
- **About section:**
  - App version
  - "Powered by ARKit + Vision + Core Image" footer
  - Privacy policy & Terms of service placeholder links

### Animations & Haptics
- Section cards animate in with staggered spring entrance (existing pattern)
- Toggle changes animate with `.symbolEffect(.bounce)`
- Haptic feedback (`.sensoryFeedback(.selection)`) on every toggle and picker change
- Settings sheet sections expand/collapse with `CelleuxSpring.luxury`

### Data Persistence
- All new settings (lighting, scan duration, notification prefs) saved to UserDefaults
- Skin type saved to UserProfile via SwiftData
- HealthKit authorization status checked live on appear
- Real-time connection status indicators (pulsing green dot for connected, gray for disconnected)

## Design

- Profile header: elevated GlassCard with the ChromeRingView centered, gold arc showing best score percentage, score number inside the ring, name and skin type badge below
- Stats row: four metrics in a horizontal layout with premium dividers (existing style)
- Quick toggles: compact GlassCard with gold-tinted Toggle switches
- Settings sheet: presented with `.ultraThinMaterial` background, grouped sections with ChromeIconBadge icons, premium dividers between rows
- Consistent with existing Celleux luxury aesthetic — warm gold accents, chrome borders, Display P3 colors
- Calibration reset confirmation: system alert explaining "This will clear your 3-scan baseline. Your next 3 scans will establish a new reference point."

## Screens

- **Profile Page** — scrollable page with: enlarged header (ring + name + skin type), stats row, achievements horizontal scroll, quick notification toggles, health/data/account settings groups, app version footer
- **Settings Sheet** — gear button opens a sheet with: personal info editing (name, skin type), scan settings (lighting, duration, calibration), notification preferences, health connection status dashboard, data management (export CSV/JSON, clear data, delete account), about section