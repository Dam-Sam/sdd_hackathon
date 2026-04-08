# Process Notes

## /onboard

**Technical experience:** Recent CS grad, minimal professional experience. Knows Python best, has touched Java, JS, C++, SQL. Done coursework in web, iOS, and general software dev. Describes himself as rusty. AI experience is primarily Cursor in "build it for me" mode — limited independent debugging ability.

**Learning goals:** Understand LLM capabilities and limits; develop best practices for AI-assisted dev; keep own skills sharp while leveraging AI. Well-articulated goals — not just here to ship, here to grow.

**Creative sensibility:** Heavy technical/productivity reading list (Chip Huyen, Neal Ford, Cal Newport, Kleppmann). Struggling with consistency and prioritization. Strong *Deep Work* connection to his app idea — worth surfacing in scope.

**Prior SDD experience:** None. Complete baseline. First exposure to structured planning before building.

**Energy and engagement:** Came in with a clear, concrete app idea already formed. Thoughtful and self-aware about his gaps. Motivated by growth, not just output. Should respond well to being pushed toward deeper thinking.

## /scope

**How the idea evolved:** Sam arrived with a well-formed concept (schedule-based blocking with friction mechanics) and it sharpened considerably through conversation. The accountability partner feature was initially central but got correctly demoted to post-MVP once the scope was interrogated. The "time regained" framing emerged from Sam's description of the home screen and became a core product philosophy.

**Pushback received:** Challenged on what the absolute MVP core was — Sam correctly identified schedule-based blocking + friction mechanics, cutting the accountability partner and timer/tracker. Also probed on where friction becomes annoying; Sam's response (user-configurable friction levels) was a smart, principled answer rather than a cop-out.

**References that resonated:** OneSec (friction mechanics, physical actions) and Opal (strict commitment, streaks) both landed well. Sam took specific things from each rather than wholesale adopting either approach. The Deep Work connection (Cal Newport) was already present in Sam's thinking — the "time regained" framing is a natural expression of Newport's philosophy.

**Deepening rounds:** Two rounds. Round 1 surfaced the app's vibe (calm, organized, modern), the friction tier system (Minimal/Moderate/Extreme with random selection within tier), the scheduling UX (weekday default + custom), and the home screen layout. Round 2 fleshed out the exact unblock flow, app selection UX (scrollable list + search), and the no-emergency-bypass stance. The extra rounds materially improved the scope doc — the friction tier structure and "time regained" framing both came from round 1+2.

**Active shaping:** Sam drove several key decisions independently: the three friction tiers with random selection (not prompted), the "time regained" language (unprompted), the no-emergency-bypass stance (firm). Accepted the suggestion to cut the accountability partner from MVP without pushback, which was the right call. Genuinely engaged, not passively accepting suggestions.

## /prd

**What the learner added vs the scope doc:** The scope doc sketched 5 high-level bullet points. The PRD conversation expanded each into detailed behavior: the wizard is two sequential screens (app selection → schedule), friction activities have exact UI flows (cat picture + two button options, physical actions with random counts, math problems with retry), the home screen has a precise layout (countdown above lock, secondary unlock countdown below), and the unlock mechanic split into two distinct modes (home screen = all apps, app tap = single app) with defined expiry behavior.

**"What if" questions that surprised Sam:** The mid-wizard exit scenario (what happens if you close the app partway through setup) hadn't been considered — Sam landed on resume-where-you-left-off after being pushed to think about user experience rather than implementation convenience. The pre-session countdown question (what does the timer show at 8:50am before a 9am session?) also hadn't been thought through; Sam's answer (0) was immediate and consistent. The "editing during a session" scenario prompted a principled call: block all changes mid-session, consistent with the app's no-escape philosophy.

**What Sam pushed back on or felt strongly about:** The manual lock/unlock button — Sam initially described it as a toggle, then revised it mid-conversation to be unlock-only, with locked/unlocked state driven purely by the schedule. This was a significant design clarification he initiated himself. The no-emergency-bypass stance remained firm (carried over from scope). The "whichever is easier to implement" response on wizard resume behavior was the one moment he tried to defer to tech — redirected back to UX, he landed immediately on the right answer.

**Scope guard:** No new scope creep emerged during the PRD conversation. The session-editing block and live app list changes were refinements, not additions. All post-MVP items (accountability partner, streaks, per-app stats) stayed deferred without revisiting.

**Deepening rounds:** One round. Surfaced: pre-session countdown shows 0 (consistent with non-scheduled days), custom schedule supports per-day on/off toggling, friction doesn't transfer between unlock modes (app-specific unlock doesn't cover other apps), friction activity resets on app background/switch, app list changes take effect immediately. The round meaningfully sharpened the unlock mechanics and schedule edge cases.

**Active shaping:** Sam was consistently active. Key moments: revised the lock button design mid-conversation (his own initiative), specified the exact two-popup structure for Minimal tier (cat picture → "are you sure") including the detail that the second popup is universal across all tiers, and made the "immediately" call on app list changes without hesitation. The friction tier descriptions were unprompted and specific. Passive moments were rare — the wizard resume behavior was the clearest one.

## /spec

**Stack decisions:**
- Swift + SwiftUI + Family Controls (FamilyControls, ManagedSettings, DeviceActivity) + CoreMotion + SwiftData + UserNotifications
- FamilyActivityPicker adopted over custom app list (saves entitlement complexity, trades design control)
- Family Controls (Path B, true OS-level blocking) chosen over Shortcuts Automation despite entitlement delay — Sam correctly identified that the app's core commitment requires genuine blocking, not friction-only
- Hackathon plan: local device demo with screenshots; apply for distribution entitlement post-hackathon

**Architecture decisions:**
- Three-target Xcode project: main app + DeviceActivityMonitor extension + ShieldConfiguration extension
- SharedStore (App Group UserDefaults) for cross-target communication; SwiftData for main app only
- "Time saved" reframed from historical-baseline comparison to blocked-time-minus-unlock-time; Sam accepted quickly — the reframe was clean and technically unblocked an API limitation
- Unlock state: allAppsUnlockExpiry supersedes individual unlocks; Instagram re-locks when all-apps expiry fires (Sam's call, clean and consistent)
- Authorization gate: blocks all access (onboarding + home) if Family Controls denied; re-prompts immediately

**What Sam was confident about:** The Path B choice, the re-lock behavior (Instagram re-locks with everything), the authorization gate UX. These were immediate, clear answers.

**What Sam was uncertain about / needed explaining:** The multi-target extension architecture required re-explanation before the SharedStore question landed. He asked for clarification on what each extension does — answered with a table, then the question connected. Not a gap in his thinking, just unfamiliar territory.

**Deepening rounds:** One round. Surfaced: full SharedStore contents (blockedApps, isSessionActive, sessionEndTime, frictionTier, allAppsUnlockExpiry, individualUnlockExpiries, onboarding state, auth status), both unlock expiry modes and their interaction, and the Family Controls authorization failure strategy. The round meaningfully tightened the data architecture — without it, SharedStore would have been underspecified and /build would have had to make these decisions on the fly.

**Active shaping:** Sam drove the Path B decision independently and pushed back implicitly on Path A (Shortcuts) by identifying the loophole in the entitlement requirement (dev builds on personal device). The time-saved reframe was accepted without friction. The unlock interaction edge case (all-apps expiry + individual unlock) was a prompted question and Sam answered immediately and correctly.

## /build

### Step 1: Xcode project scaffold — three targets, SharedStore, SwiftData models, tab bar

**What was built:**
- Three-target Xcode project generated via xcodegen (xcodegen 2.45.3, Xcode 26.2, iOS 26 SDK)
- Three targets: FocusLock (main app), DeviceActivityMonitor extension, ShieldConfiguration extension
- App Group `group.focuslock` configured in all three targets via entitlements
- Family Controls entitlement added to all three targets
- `SharedStore.swift` (Shared/) wraps `UserDefaults(suiteName: "group.focuslock")` — all nine keys from spec defined
- SwiftData models: `Schedule`, `DaySchedule`, `SessionLog` in `FocusLock/Models/FocusData.swift`
- `ContentView.swift` with routing logic (auth gate placeholder → onboarding placeholder → MainTabView)
- `MainTabView` with three tabs: Home, Schedule, Stats (each a placeholder view)
- `focuslock://` URL scheme registered in Info.plist; stub handler in `FocusLockApp.swift`
- Stub implementations of `MonitorExtension` and `ShieldConfigExtension` compile cleanly
- Build SUCCEEDED with no errors on iPhone 17 Pro simulator

**Issues encountered:**
- xcodegen cleared entitlement files when `properties` wasn't specified inline — fixed by moving entitlement values into project.yml
- Swift 6 concurrency: `SharedStore.shared` static property flagged as non-`Sendable` — fixed with `nonisolated(unsafe)` and `@unchecked Sendable`
- `ShieldConfiguration.Label` initializer changed in newer SDK to require `text:` label — fixed

**Learner verification observation:** Saw onboarding placeholder on first launch (correct — routing logic was live). Tapped "Skip to Tab Bar (Dev)" button, confirmed three-tab MainTabView appeared (Home, Schedule, Stats).

**Comprehension check answer:** "All three targets need it" — correct. Understood that SharedStore.swift must be compiled into each target's binary separately because extensions can't import from the main app module.

### Step 2: Authorization gate — FamilyControls auth request and denial handling

**What was built:**
- `AuthorizationGateView.swift` — full-screen gate with orange lock shield icon, "Screen Time Access Required" title, and "Grant Access" button that calls `AuthorizationCenter.shared.requestAuthorization(for: .individual)` and writes result to SharedStore
- `FocusLockApp.swift` updated — `.task` modifier calls `requestAuthorization()` on launch; `#if DEBUG` stub with `useAuthStub` / `stubStatus` flags bypasses real API for visual testing; stub also resets `hasCompletedOnboarding = false` for clean flow testing
- `ContentView.swift` updated — replaced `AuthorizationGatePlaceholder` with real `AuthorizationGateView`; routing switched from `if/else` to `switch` on authStatus with explicit handling of "notDetermined" (blank screen during auth check), "denied" (gate), "authorized" (onboarding or tabs)

**Issues encountered:**
- `FamilyControlsMember.individualWebDomains` does not exist in this SDK — fixed to `.individual`
- On first verification run, app jumped straight to tab bar because `hasCompletedOnboarding = true` was persisted from Step 1's "Skip to Tab Bar (Dev)" button — fixed by adding `hasCompletedOnboarding = false` reset to the debug stub

**Learner verification observation:** Confirmed gate appeared with `stubStatus = "denied"`. After fix, confirmed onboarding placeholder appeared with `stubStatus = "authorized"`.

**Comprehension check answer:** "@AppStorage re-renders automatically" — correct. Understood that the routing lives in ContentView because `@AppStorage` subscribes to UserDefaults changes and triggers re-renders automatically, eliminating manual state plumbing.

### Step 3: Onboarding — app selection (FamilyActivityPicker + friction tier selector)

**What was built:**
- `AppSelectionView.swift` — "Choose Apps" button triggers `.familyActivityPicker()` sheet; segmented control for friction tier (Minimal pre-selected); Continue button disabled until selection is non-empty; `#if DEBUG` bypass button for simulator testing (no Family Controls in sim); `saveAndContinue()` encodes `FamilyActivitySelection` via `PropertyListEncoder`, writes `blockedApps`, `frictionTier`, and `onboardingStep = 1` to SharedStore
- `ScheduleSetupView.swift` — placeholder for Step 4, with dev skip button
- `ContentView.swift` updated — added `@AppStorage("onboardingStep")` routing; `OnboardingPlaceholder` removed; now routes to `AppSelectionView` (step 0) or `ScheduleSetupView` (step 1)
- `FocusLockApp.swift` debug reset updated to also reset `onboardingStep = 0`
- `xcodegen generate` required after file creation — noted for future steps

**Issues encountered:**
- New Swift files created on disk weren't included in the Xcode project until `xcodegen generate` was re-run. Will need to do this after every new file creation.

**Learner verification observation:** Saw AppSelectionView on launch (past auth gate). Tapped Continue (via debug bypass), navigated to ScheduleSetupView placeholder. Flow confirmed correct.

**Comprehension check answer:** "NavigationStack push" — incorrect. Correct answer: `@AppStorage` write in `ContentView` triggers re-render which swaps the view. Brief explanation given pointing to `ContentView.swift` line 25.

---

## /checklist

**Sequencing decisions:** Scaffold-first approach: three-target Xcode project + SharedStore + SwiftData models before any feature work. Authorization gate second — gates all subsequent UI. Onboarding before home screen (home screen reads SharedStore values written during onboarding). Friction activities before BlockingService (router needs to exist before unlock calls through). Extensions (DeviceActivityMonitor, ShieldConfiguration) after the blocking layer is wired — they depend on SharedStore and BlockingService being functional. Schedule/Stats tabs last — pure read views that can be built once data is flowing.

**Build mode:** Step-by-step. Sam's learning goals (best practices for AI-assisted dev, keeping own skills sharp) made step-by-step the right fit over autonomous.

**Methodology preferences:** Comprehension checks: yes. Verification: yes, after each item. Git: commit per item. Check-in cadence: learning-driven (most discussion).

**Checklist size:** 11 items. Estimated total build time: 3–4 hours at 15–30 min per item.

**Entitlement discussion:** Sam wants to skip the Family Controls entitlement for now and proceed with stub/mock implementations for the blocking layer during development. Flagged that FamilyControls/ManagedSettings/DeviceActivity are non-functional without it — both on simulator and device. Items 8 and 9 include notes about what can and can't be verified without the entitlement.

**Devpost planning:** Core story: "Productivity app that eliminates distractions on your phone; allowing you to take back your time and spend it on what really matters." Wow-moment screenshots: block screen + friction activities. Deployment: conditional on entitlement approval, otherwise screenshots/screen recording. GitHub repo: to be created as part of submission step (Sam has not yet set one up).

**Active shaping:** Sam proposed the scaffold-first, then app-logic sequence independently — correct instinct, minimal guidance needed on ordering. Accepted the dependency chain explanation (auth → onboarding → home → friction → blocking → extensions → tabs) without pushback. Build mode and preferences chosen quickly and confidently.

**Deepening rounds:** Zero rounds. Sam was ready to generate after the initial checklist walkthrough. The spec was detailed enough that no deepening was needed to achieve specificity.
