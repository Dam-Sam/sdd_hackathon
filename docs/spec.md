# FocusLock — Technical Spec

## Stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | Swift 6 | Only viable choice for native iOS |
| UI | SwiftUI | Modern, declarative, best for learners. Liquid Glass aesthetic is automatic on iOS 26. |
| Persistence | SwiftData | Recommended replacement for Core Data in new iOS projects. Clean API for beginners. |
| Shared state | UserDefaults (App Group) | Only way to share data between the main app and extensions. Simple key-value. |
| Blocking | ManagedSettings + FamilyControls + DeviceActivity | Apple's Screen Time API for OS-level app blocking. |
| Motion detection | CoreMotion | Accelerometer (shake) and gyroscope (rotation) for Moderate friction tier. |
| Notifications | UserNotifications | Local notifications for 3-minute unlock warning and re-lock events. |
| App selection UI | FamilyActivityPicker | Apple's built-in system sheet for selecting apps to block. No custom list needed. |

**Key docs:**
- [FamilyControls](https://developer.apple.com/documentation/familycontrols)
- [ManagedSettings](https://developer.apple.com/documentation/managedsettings)
- [DeviceActivity](https://developer.apple.com/documentation/deviceactivity)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [CoreMotion](https://developer.apple.com/documentation/coremotion)
- [UserNotifications](https://developer.apple.com/documentation/usernotifications)
- [FamilyActivityPicker](https://developer.apple.com/documentation/familycontrols/familyactivitypicker)

---

## Runtime & Deployment

- **Platform:** iOS 26+
- **Xcode:** Xcode 26 (required for iOS 26 SDK — App Store submissions require iOS 26 SDK from April 28, 2026)
- **Hackathon demo:** Local device. Run on Sam's iPhone via Xcode. Screenshots for submission page.
- **Post-hackathon:** App Store. Requires distribution entitlement for `com.apple.developer.family-controls` (apply separately — 2–8 week approval window).
- **Entitlement note:** Development-level `family-controls` entitlement needed to test on device. Apply through Apple Developer portal before building. Distribution entitlement is a separate subsequent request.
- **No backend.** All data lives on device. No cloud sync, no accounts.

---

## Architecture Overview

FocusLock is a **three-target Xcode project.** Each target is a separate process with a specific job. They communicate via a shared UserDefaults container (App Group: `group.focuslock`).

```
┌─────────────────────────────────────────────────────────────┐
│                        User's iPhone                         │
│                                                              │
│  ┌─────────────────────────────┐                           │
│  │      FocusLock (main app)   │                           │
│  │  Onboarding, Home, Friction │                           │
│  │  Schedule, Stats, Settings  │◄──── User interaction     │
│  └──────────────┬──────────────┘                           │
│                 │ reads/writes                              │
│  ┌──────────────▼──────────────┐                           │
│  │  SharedStore (App Group)    │                           │
│  │  UserDefaults group.focus.. │                           │
│  └──────┬───────────┬──────────┘                           │
│         │           │                                       │
│  ┌──────▼──────┐  ┌─▼──────────────────────┐              │
│  │  DeviceAct. │  │  ShieldConfiguration    │              │
│  │  Monitor    │  │  Extension              │              │
│  │  Extension  │  │  (custom block screen)  │              │
│  │  (scheduler)│  └─────────────────────────┘              │
│  └──────┬──────┘            ▲                              │
│         │                   │ iOS calls when               │
│         ▼                   │ blocked app tapped           │
│  ┌──────────────┐           │                              │
│  │ ManagedSett. │───────────┘                              │
│  │ (iOS blocks  │                                          │
│  │  the apps)   │                                          │
│  └──────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

### Blocked app tap — full data flow

```
1. User taps Instagram (blocked)
   └── iOS intercepts → calls ShieldConfiguration extension

2. ShieldConfiguration returns: title, subtitle, "Unlock" button
   └── Button action: open focuslock://unlock?source=shield&app=<bundleID>

3. FocusLock opens via URL scheme
   └── FrictionRouter reads frictionTier from SharedStore
   └── Randomly selects and presents activity for that tier

4. User completes friction → ConfirmationView ("Are you sure?")
   └── "Yes" → BlockingService removes that app from ManagedSettings blocked set
             → Writes individualUnlockExpiries[bundleID] = now + 15min to SharedStore
             → Schedules DeviceActivity interval to re-block at expiry
             → Schedules local notification at expiry - 3min

5. 15 minutes later: DeviceActivityMonitor extension fires
   └── Re-adds app to ManagedSettings blocked set
   └── Removes entry from individualUnlockExpiries in SharedStore
   └── If user is in that app: iOS kicks them out automatically
```

### Home screen "unlock all" data flow

```
1. User taps Unlock button on Home screen
   └── FrictionRouter presents friction activity

2. User completes friction → ConfirmationView
   └── "Yes" → BlockingService removes ALL blocked apps from ManagedSettings
             → Clears individualUnlockExpiries (all superseded)
             → Writes allAppsUnlockExpiry = now + 15min to SharedStore
             → Schedules DeviceActivity interval for re-lock at expiry
             → Schedules local notification at expiry - 3min

3. 15 minutes later: DeviceActivityMonitor fires
   └── Re-adds all apps to ManagedSettings blocked set
   └── Clears allAppsUnlockExpiry from SharedStore
   └── Users in any blocked app are kicked out
```

---

## Shared State

### SharedStore

`SharedStore.swift` wraps `UserDefaults(suiteName: "group.focuslock")`. All three targets import and use this file. Extensions only read — the main app writes.

```swift
// All keys in group.focuslock UserDefaults

blockedApps: Data               // Encoded FamilyActivitySelection
                                // Written during onboarding/settings
                                // Read by DeviceActivityMonitor to start blocking

frictionTier: String            // "minimal" | "moderate" | "extreme"
                                // Read by FrictionRouter

isSessionActive: Bool           // True during a scheduled block session
                                // Read by HomeView (lock icon, edit gating)
                                // Written by DeviceActivityMonitor at session start/end

sessionEndTime: Date?           // Current session's end time
                                // Read by HomeView countdown
                                // Written by DeviceActivityMonitor at session start

allAppsUnlockExpiry: Date?      // Nil = no active all-unlock
                                // Written by BlockingService on unlock-all
                                // Cleared by DeviceActivityMonitor on expiry

individualUnlockExpiries:       // BundleID → expiry time
  [String: Date]                // Written by BlockingService on per-app unlock
                                // Cleared when allAppsUnlockExpiry is set
                                // Cleared by DeviceActivityMonitor on per-app expiry

hasCompletedOnboarding: Bool    // Onboarding gate
onboardingStep: Int             // 0 = app selection, 1 = schedule
                                // Enables wizard resume on re-launch

authorizationStatus: String     // "authorized" | "denied" | "notDetermined"
                                // Written at launch after AuthorizationCenter check
```

---

## SwiftData Models

Used only in the main app target. Extensions never touch SwiftData.

```swift
@Model
class Schedule {
    var days: [DaySchedule]     // Array of 7 DaySchedule objects (Mon–Sun)
}

@Model
class DaySchedule {
    var weekday: Int            // 1 = Monday, 7 = Sunday
    var isEnabled: Bool
    var startTime: Date
    var endTime: Date
}

@Model
class SessionLog {
    var date: Date              // Day this session occurred
    var sessionDuration: Int    // Minutes the session ran
    var totalUnlockMinutes: Int // Minutes spent unlocked during session
    // timeSaved = sessionDuration - totalUnlockMinutes
}
```

**Stats query:** `SELECT SUM(sessionDuration - totalUnlockMinutes) FROM SessionLog` — cumulative time saved since install.

**Time saved today:** `SELECT sessionDuration - totalUnlockMinutes FROM SessionLog WHERE date = today` — shown on home screen.

---

## Targets

### Main App — FocusLock

Implements `prd.md > First-Time Setup`, `prd.md > Home Screen`, `prd.md > Unlock Flow & Friction Activities`, `prd.md > Schedule & App Management`, `prd.md > Stats`.

All user-facing UI. Handles the `focuslock://` URL scheme. Writes to SharedStore. Owns SwiftData.

### DeviceActivityMonitor Extension

Implements schedule enforcement. Woken by DeviceActivity framework on schedule events. Reads SharedStore to know which apps to block/unblock. Never shown to user.

**Events it handles:**
- Session start (scheduled) → activate ManagedSettings blocking for all apps
- Session end (scheduled) → deactivate all blocking, update `isSessionActive` in SharedStore
- Per-app unlock expiry (dynamic, 15 min after unlock) → re-block that app
- All-apps unlock expiry (dynamic, 15 min after unlock) → re-block all apps

### ShieldConfiguration Extension

Called by iOS when a user taps a blocked app during a session. Returns a `ShieldConfiguration` object specifying the visual appearance of the block screen. No logic — just UI configuration.

```swift
// What it returns:
ShieldConfiguration(
    applicationName: "FocusLock",
    title: .init("Stay Focused"),
    subtitle: .init("You're in a focus session"),
    primaryButtonLabel: .init("Unlock"),
    primaryButtonBackgroundColor: .systemGreen
)
// Primary button action: open focuslock://unlock?source=shield&app=<bundleID>
```

---

## Views

### Onboarding

Implements `prd.md > First-Time Setup`.

#### AppSelectionView

- Presents `FamilyActivityPicker` as a sheet
- Below picker: friction tier selector (Minimal pre-selected, Moderate, Extreme) — segmented control or custom highlight
- Continue button disabled until at least one app selected (check `selection.applications.isEmpty`)
- On Continue: encode selection → write to SharedStore `blockedApps`, write `frictionTier`

#### ScheduleSetupView

- Default mode: "Every weekday" toggle + start/end `DatePicker`
- "Include weekends" checkbox
- "Custom" button → CustomScheduleView
- CustomScheduleView: list of 7 days, each with on/off toggle + start/end pickers when enabled
- Finish button: save to SwiftData `Schedule`, write `hasCompletedOnboarding = true`, navigate to HomeView

#### Wizard Resume

- On app launch: check `hasCompletedOnboarding` in SharedStore
- If false: check `onboardingStep` to resume at correct screen
- If 0 → AppSelectionView; if 1 → ScheduleSetupView
- Completing setup writes `hasCompletedOnboarding = true` → never show wizard again

#### Authorization Gate

- On launch (before wizard): call `AuthorizationCenter.shared.requestAuthorization(for: .individualWebDomains)`
- If denied: show full-screen gate. "FocusLock needs Screen Time access to block apps." + "Grant Access" button → retrigger authorization
- Gate shown both on first launch and on subsequent launches if auth was revoked in Settings
- No user can reach onboarding or home screen without authorization

### Home Screen

Implements `prd.md > Home Screen`.

#### HomeView

Layout (top to bottom):
```
[Countdown timer]         ← time until session end, "0:00" when no session
[Lock icon]               ← SF Symbol: lock.fill (session active) / lock.open.fill
[Time saved today]        ← queried from SessionLog for today
[Unlock button]           ← disabled + grayed when isSessionActive = false
[Secondary countdown]     ← visible only when allAppsUnlockExpiry is set
```

- Reads `isSessionActive` and `sessionEndTime` from SharedStore
- Queries SwiftData for today's SessionLog to calculate time saved
- Countdown updates every second via `Timer.publish`
- Secondary countdown tracks `allAppsUnlockExpiry - now`, disappears when nil
- Unlock button taps route to `FrictionRouter` with `source: .homeScreen`

#### Session editing gate

- All edit controls in Schedule tab read `isSessionActive` from SharedStore
- If `true`: controls are `.disabled(true)`, visually dimmed

### Friction Activities

Implements `prd.md > Unlock Flow & Friction Activities`.

#### FrictionRouter

- Entry point for all unlock flows (URL scheme + home screen button)
- Reads `frictionTier` from SharedStore
- Randomly selects one activity from the tier
- Presents the correct view
- Receives completion callback → presents ConfirmationView

```swift
enum UnlockSource {
    case homeScreen             // unlocks ALL apps
    case shield(bundleID: String) // unlocks ONE app
}
```

#### MinimalView

Implements `prd.md > Unlock Flow & Friction Activities > Minimal`.

- Randomly picks one image from `Assets.xcassets/CatImages/`
- Randomly picks one guilt-trip string from a hardcoded array
- "OK" → dismiss, keep locked
- "No" → dismiss, present ConfirmationView

#### ModerateView

Implements `prd.md > Unlock Flow & Friction Activities > Moderate`.

- On appear: randomly select one activity: wait10, rotate(count: Int.random(3...5)), shake(count: Int.random(2...4))
- `MotionService` starts the appropriate CoreMotion detection
- No "Done" button — detection is automatic
- "Cancel" → stop detection, dismiss, keep locked
- On `sceneDidBecomeActive` (return from background): reset detection counter to 0
- On successful detection: stop CoreMotion, present ConfirmationView

**MotionService — rotation detection:**
- `CMMotionManager.startDeviceMotionUpdates`
- Track cumulative Z-axis rotation (in radians)
- Every ±2π (360°) = one full rotation
- When target count reached: fire completion

**MotionService — shake detection:**
- `CMMotionManager.startAccelerometerUpdates`
- Threshold: acceleration magnitude > 2.5g
- Debounce: 0.5s between counted shakes
- When target count reached: fire completion

#### ExtremeView

Implements `prd.md > Unlock Flow & Friction Activities > Extreme`.

- Generate random math problem on appear (e.g., two-step arithmetic: `(a × b) + c`)
- Text input for answer + Submit button
- Cancel button available at all times
- Incorrect answer → show "Incorrect" banner, same problem, try again
- Correct answer → present ConfirmationView

**Math generation:**
```swift
// Example: generates problems requiring real thought
let a = Int.random(in: 10...30)
let b = Int.random(in: 2...9)
let c = Int.random(in: 10...50)
let answer = (a * b) + c
let display = "(\(a) × \(b)) + \(c)"
```

#### ConfirmationView

Implements `prd.md > Unlock Flow & Friction Activities > Universal Confirmation`. Shared across all tiers and both unlock entry points.

```
"Are you sure you want to give your time away?
There is only {timeRemaining} left until your focus session ends."

[Stay Focused]    [Yes]
```

- `timeRemaining` = `sessionEndTime - now`, formatted as "Xh Xm"
- "Stay Focused" → dismiss everything, keep locked
- "Yes" → call BlockingService with the `UnlockSource`

### Schedule & App Management

Implements `prd.md > Schedule & App Management`.

#### ScheduleView

- Read-only list of all 7 days with start/end times
- Disabled days shown as off/greyed
- "Change Time" button → ScheduleSetupView (reused from onboarding)
- "Apps" button → AppSelectionView (reused from onboarding, pre-populated with current selection)
- Both buttons `.disabled(isSessionActive)`

### Stats

Implements `prd.md > Stats`.

#### StatsView

- Single `@Query` on `SessionLog` for all records
- Computes `sum(sessionDuration - totalUnlockMinutes)` in Swift
- Displays formatted total (hours and minutes)
- Updates daily — no real-time updates needed

---

## Services

### BlockingService

Wraps ManagedSettings. Called by main app after friction is completed.

```swift
func unlockApp(bundleID: String, source: UnlockSource)
// source == .homeScreen → remove ALL apps from ManagedSettings store,
//                         clear individualUnlockExpiries,
//                         write allAppsUnlockExpiry = now + 15min
// source == .shield(id) → remove only bundleID from store,
//                         write individualUnlockExpiries[bundleID] = now + 15min

func relock(bundleID: String)   // Re-add single app to ManagedSettings store
func relockAll()                // Re-add all apps from SharedStore.blockedApps
```

### NotificationService

Schedules and cancels local notifications for unlock warnings.

```swift
func scheduleUnlockWarning(expiry: Date, identifier: String)
// fires at expiry - 3min
// body: "3 minutes left — your apps will re-lock soon"

func cancelWarning(identifier: String)
```

### MotionService

Wraps CMMotionManager. Used only by ModerateView.

```swift
func startRotationDetection(target: Int, onComplete: () -> Void)
func startShakeDetection(target: Int, onComplete: () -> Void)
func stopDetection()
func resetCounts()  // Called on sceneDidBecomeActive
```

---

## Navigation & URL Scheme

**Tab bar (bottom):** Home | Schedule | Stats

**URL scheme:** `focuslock://`

Registered in `Info.plist`. Handled in `FocusLockApp.swift` via `.onOpenURL`.

```
focuslock://unlock?source=shield&app=<bundleID>
→ present FrictionRouter(source: .shield(bundleID))

focuslock://unlock?source=home
→ present FrictionRouter(source: .homeScreen)
```

---

## File Structure

```
FocusLock.xcodeproj

FocusLock/                              # Main app target
├── FocusLockApp.swift                  # Entry point, URL scheme handler, auth check
├── ContentView.swift                   # Root: tab view (Home/Schedule/Stats) or onboarding
├── Models/
│   └── FocusData.swift                 # SwiftData models: Schedule, DaySchedule, SessionLog
├── Views/
│   ├── Onboarding/
│   │   ├── AuthorizationGateView.swift # Full-screen Family Controls auth prompt
│   │   ├── AppSelectionView.swift      # FamilyActivityPicker + friction tier selector
│   │   ├── ScheduleSetupView.swift     # Default weekday + custom schedule UI
│   │   └── CustomScheduleView.swift    # Per-day on/off toggles + time pickers
│   ├── Home/
│   │   └── HomeView.swift              # Lock icon, countdown, time saved, unlock button
│   ├── Friction/
│   │   ├── FrictionRouter.swift        # Selects and presents correct friction view
│   │   ├── MinimalView.swift           # Cat picture + guilt prompt
│   │   ├── ModerateView.swift          # Physical action with CoreMotion
│   │   ├── ExtremeView.swift           # Math problem + text input
│   │   └── ConfirmationView.swift      # Universal "are you sure?" popup
│   ├── Schedule/
│   │   └── ScheduleView.swift          # Read-only schedule + edit buttons
│   └── Stats/
│       └── StatsView.swift             # Cumulative time saved
├── Services/
│   ├── BlockingService.swift           # ManagedSettings wrapper
│   ├── NotificationService.swift       # Local notification scheduling
│   └── MotionService.swift             # CoreMotion shake/rotate detection
├── Shared/
│   └── SharedStore.swift               # UserDefaults(suiteName: "group.focuslock")
└── Assets.xcassets/
    └── CatImages/                      # 10–20 bundled cat photos

DeviceActivityMonitor/                  # Extension target
└── MonitorExtension.swift              # Handles session start/end + unlock expiry events

ShieldConfiguration/                   # Extension target
└── ShieldConfigExtension.swift         # Returns ShieldConfiguration for blocked apps

docs/
├── scope.md
├── prd.md
├── spec.md
└── (checklist.md — generated next)

process-notes.md
```

---

## Key Technical Decisions

### 1. Shortcuts Automation rejected in favor of Family Controls
**Decision:** Use Family Controls / ManagedSettings (Path B) for true OS-level blocking.
**Tradeoff accepted:** Requires Apple entitlement approval (2–8 weeks for distribution). Development entitlement needed before testing on device. Hackathon submission will be local-only with screenshots while distribution entitlement processes.
**Why:** The app's core value is genuine commitment — no way out. Shortcuts-based interception can be bypassed. Family Controls cannot (during the session).

### 2. FamilyActivityPicker over custom app list
**Decision:** Use Apple's built-in `FamilyActivityPicker` system sheet for app selection.
**Tradeoff accepted:** Visual design is Apple's (system modal), not FocusLock's Liquid Glass aesthetic.
**Why:** Enumerating installed apps requires separate entitlements and is complex. FamilyActivityPicker is purpose-built, reliable, and ships with the Family Controls entitlement.

### 3. Time saved = blocked time minus unlock time (not historical comparison)
**Decision:** "Time saved today" = `sessionDuration - totalUnlockMinutes` for today.
**Tradeoff accepted:** No before/after comparison to pre-install behavior.
**Why:** DeviceActivity framework does not expose arbitrary historical Screen Time data for third-party reads. The "time you actually stayed focused" framing is arguably more honest and motivating than a comparison to a hypothetical baseline.

---

## Dependencies & External Services

| Dependency | Type | Notes |
|---|---|---|
| FamilyControls | Apple framework | Requires `com.apple.developer.family-controls` entitlement. Request at developer.apple.com before building. [Docs](https://developer.apple.com/documentation/familycontrols) |
| ManagedSettings | Apple framework | Bundled with FamilyControls entitlement. [Docs](https://developer.apple.com/documentation/managedsettings) |
| DeviceActivity | Apple framework | Bundled with FamilyControls entitlement. [Docs](https://developer.apple.com/documentation/deviceactivity) |
| CoreMotion | Apple framework | No entitlement needed. [Docs](https://developer.apple.com/documentation/coremotion) |
| UserNotifications | Apple framework | Requires `NSUserNotificationUsageDescription` in Info.plist. [Docs](https://developer.apple.com/documentation/usernotifications) |
| SwiftData | Apple framework | iOS 17+. Main app target only. [Docs](https://developer.apple.com/documentation/swiftdata) |
| Cat images | Bundled assets | Sam-provided. Stored in Assets.xcassets/CatImages. No external API. |

**No third-party packages.** All dependencies are Apple frameworks.

---

## Open Issues

1. **Family Controls entitlement** — apply for development-level entitlement before writing the first line of code. Without it, the entire Screen Time API is non-functional on device. The simulator does not support Family Controls. [Request here](https://developer.apple.com/contact/request/family-controls-distribution)

2. **ShieldConfiguration button routing** — Shield button actions are limited. The exact mechanism for the "Unlock" button to open FocusLock via URL scheme needs verification during build. The expected approach: `ShieldAction.defer` with a URL, or a custom button that calls `openURL`. Confirm against current DeviceActivity WWDC sessions.

3. **DeviceActivity dynamic scheduling for unlock expiry** — When a user unlocks an app, the 15-minute re-lock timer needs to be scheduled dynamically (not at setup time). Confirm that DeviceActivity supports dynamically registering new monitoring intervals at runtime. If not, the fallback is a background URLSession task or a scheduled local notification that calls back into the app.

4. **Force-quit behavior** — If the user force-quits FocusLock while an unlock window is active, does the ManagedSettings block stay lifted? Behavior depends on whether ManagedSettings state persists independently of the app process. Test early — if the unlock collapses on force-quit, that's actually the desired behavior (more secure). If it persists, the DeviceActivityMonitor extension will handle re-lock at expiry regardless.
