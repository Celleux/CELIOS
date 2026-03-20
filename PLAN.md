# Premium Tab Bar & Navigation System Upgrade


## What's Changing

Upgrading the floating tab bar and navigation to a luxury jewelry-display aesthetic with richer animations, haptics, and quick-action shortcuts.

---

### **Features**

- **Gold chrome border** on the tab bar — an animated angular gradient cycling silver → gold → silver around the edges
- **Animated gold underline** slides beneath the active tab icon using smooth matched geometry
- **Symbol bounce effect** on each tab icon when tapped
- **Gold-tinted labels** when a tab is selected, using the luxury label typography style
- **Long-press quick actions** — hold any tab to see a popover with shortcuts (e.g. last scan score, start ritual, quick scan)
- **Staggered content appearance** — child views fade and slide in with a cascade delay when switching tabs
- **Pull-to-refresh gold spinner** — a custom spinning gold ring replaces the default refresh indicator (on views that support it)
- **Haptic feedback** on long-press and quick action selection

---

### **Design**

- Tab bar background: frosted white glass at 0.95 opacity with inner highlight gradient
- 3-tier depth shadow (tight + medium + ambient) applied to the tab bar for a floating jewel-case look
- Active tab icon tinted dark, inactive icons in soft silver
- Gold underline indicator: 20pt wide, 2pt tall capsule with a subtle gold glow
- Quick actions popover styled as a compact glass card with gold-accented icons
- All animations use the luxury/snappy spring tokens — no linear or ease-in-out
- Tab labels are uppercase with wide letter spacing (luxury label style)

---

### **Screens / Areas Affected**

- **Tab Bar (ContentView)** — upgraded floating bar with chrome border, gold underline, symbol bounce, long-press quick actions, 3-tier shadow, and staggered tab transitions
- **Design System** — a new gold refresh spinner component and a quick-action popover card added as reusable pieces
