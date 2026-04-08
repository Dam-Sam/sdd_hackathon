# FocusLock — Product Requirements

## Problem Statement

People who recognize their own distraction patterns — a notification pulls them in, thirty minutes disappears — don't need a gentle nudge. They need a system that creates real resistance. FocusLock blocks selected apps on a schedule and makes unlocking them deliberately tedious, reframing every wasted minute as time stolen from the user. The experience is empowerment, not punishment: "time regained," not "time blocked."

---

## User Stories

### Epic: First-Time Setup

- As a first-time user, I want to select which apps are stealing my time so that FocusLock knows exactly what to block during my focus sessions.
  - [ ] On first launch, the wizard opens to a screen titled "Which apps are stealing your time?"
  - [ ] The screen shows a scrollable list of installed apps, each in its own box: app icon on the left, app name on the right
  - [ ] A search bar at the top of the list filters apps as the user types
  - [ ] Tapping an app outlines its box in green to indicate selection; tapping again deselects it
  - [ ] A friction level selector appears below the app list: Minimal (pre-selected by default), Moderate, Extreme — the selected level is visually highlighted
  - [ ] The Continue button is grayed out until at least one app is selected
  - [ ] Once one or more apps are selected, the Continue button lights up and becomes tappable

- As a first-time user, I want to set my focus schedule so that FocusLock automatically locks my apps during my work hours.
  - [ ] Tapping Continue brings the user to the schedule setup screen
  - [ ] Default configuration shows "Every weekday" with a start time of 9:00 AM and end time of 5:00 PM, both editable via a time picker
  - [ ] An "Include weekends" checkbox appears below the default schedule
  - [ ] A "Custom" button below the checkbox navigates to the custom schedule page (bypasses the default settings entirely)
  - [ ] A "Finish" button at the bottom of both pages completes setup and navigates to the home screen
  - [ ] The custom schedule page lists all seven days (Monday–Sunday), each with a toggleable on/off state and configurable start/end times
  - [ ] Individual days on the custom schedule can be enabled or disabled independently

- As a user who is interrupted mid-setup, I want the wizard to resume where I left off so that I don't have to start from scratch.
  - [ ] If the user exits the app before completing setup, their progress is saved
  - [ ] On re-launch, the wizard resumes at the last incomplete step (app selection or schedule)
  - [ ] The wizard is only shown once; completing it (tapping Finish) permanently transitions to the main app

---

### Epic: Home Screen

- As a focused user, I want to see my current session status at a glance so that I always know whether I'm locked in.
  - [ ] A lock icon displays at the center of the screen — closed lock during an active session, open lock otherwise
  - [ ] A countdown timer above the lock icon shows time remaining in the current session
  - [ ] Countdown shows 0:00 when no session is active (non-scheduled time, non-scheduled days, or the window before a session starts)
  - [ ] A "time saved today" counter appears below the lock icon, calculated as: (historical daily average of all selected apps) minus (current daily usage of all selected apps)
  - [ ] Counter shows 0 on the user's first day (no historical baseline yet)
  - [ ] An Unlock button appears below the counter; grayed out when no session is active, lit and tappable during an active session

- As a user in an active session, I want to be able to unlock all blocked apps for 15 minutes so that I can take a deliberate break if I choose to.
  - [ ] Tapping the Unlock button during a session triggers the friction activity for the user's current tier
  - [ ] Completing the friction activity shows the universal confirmation popup
  - [ ] Confirming unlocks ALL blocked apps for 15 minutes
  - [ ] The main countdown continues to show time until session end
  - [ ] A secondary, smaller countdown appears below the main countdown showing remaining unlock time
  - [ ] A notification fires when 3 minutes of unlock time remain
  - [ ] When the 15-minute unlock expires, all blocked apps re-lock and the user is kicked out of any currently open blocked app
  - [ ] The secondary countdown disappears when the unlock window ends

- As a user in an active session, I want editing to be blocked so that I can't undermine my own commitment by changing settings mid-session.
  - [ ] Schedule changes, app list changes, and friction level changes are all non-interactive during an active session
  - [ ] Edit controls on the Schedule tab appear visually disabled during a session

---

### Epic: Unlock Flow & Friction Activities

- As a user who taps on a blocked app during a session, I want to face a friction activity so that opening a distracting app takes real effort.
  - [ ] Tapping a blocked app during an active session intercepts the open and triggers a tier-specific friction activity
  - [ ] Only the tapped app is unlocked for 15 minutes upon successful completion; all other blocked apps remain locked
  - [ ] If the user has already unlocked all apps via the home screen button, tapping any blocked app opens freely (no additional friction)
  - [ ] If the user taps a different blocked app while only one app is individually unlocked, friction triggers for the new app

- As a user on Minimal friction, I want to see a cat picture and a gentle guilt prompt when I try to unlock so that there is light resistance nudging me back to focus.
  - [ ] A popup appears with a randomly selected cute cat picture
  - [ ] A randomly selected guilt-trip prompt accompanies the image (e.g., "Please don't waste time, do it for me :)")
  - [ ] "OK" keeps the app locked and dismisses the popup
  - [ ] "No" dismisses the cat popup and triggers the universal confirmation popup

- As a user on Moderate friction, I want to complete a physical action before unlocking so that opening a blocked app requires genuine physical effort.
  - [ ] One activity is randomly selected from: wait 10 seconds, rotate phone 3–5 times (count randomized), shake phone 2–4 times (count randomized)
  - [ ] The activity is detected automatically — no "Done" button; "Cancel" is the only interactive control
  - [ ] "Cancel" dismisses the activity and keeps the app locked
  - [ ] If the user switches away from FocusLock or backgrounds the app mid-activity, the activity resets when they return
  - [ ] Completing the activity successfully triggers the universal confirmation popup

- As a user on Extreme friction, I want to solve a math problem before unlocking so that opening a blocked app requires genuine mental effort.
  - [ ] A randomly generated math problem is displayed — challenging enough to require a moment of real thought
  - [ ] The user enters their answer in a text input field and taps "Submit"
  - [ ] A "Cancel" button is available at all times; tapping it keeps the app locked
  - [ ] An incorrect answer shows an "Incorrect" popup and allows the user to try the same problem again
  - [ ] A correct answer triggers the universal confirmation popup

- As a user who has pushed through a friction activity, I want one final confirmation before unlocking so that impulsive decisions are caught at the last moment.
  - [ ] Popup reads: "Are you sure you want to give your time away? There is only {time remaining} left until your focus session ends."
  - [ ] {time remaining} reflects time until the scheduled session ends
  - [ ] "Yes" → unlocks the app or all apps (depending on unlock entry point) for 15 minutes
  - [ ] "Stay Focused" → keeps everything locked and dismisses the popup

---

### Epic: Schedule & App Management

- As a returning user, I want to see my full schedule at a glance so that I know when my sessions run each day.
  - [ ] The Schedule tab lists all seven days (Monday–Sunday) with the configured start and end times for each
  - [ ] Days with no scheduled session are shown as off/disabled
  - [ ] The view is read-only; editing requires tapping a dedicated button

- As a user, I want to edit my focus schedule so that it stays aligned with my actual work hours.
  - [ ] A "Change Time" button at the bottom of the Schedule tab navigates to the schedule setup page (same design as the wizard step)
  - [ ] Changes are saved when the user taps Finish
  - [ ] The Change Time button is disabled during an active session

- As a user, I want to update which apps I'm blocking and my friction level so that the app stays calibrated to my life.
  - [ ] An "Apps" button below "Change Time" navigates to the app selection page (same design as the wizard step, including the friction level selector beneath the list)
  - [ ] Changes to the app list take effect immediately
  - [ ] Changes to the friction level take effect immediately
  - [ ] The Apps button is disabled during an active session

---

### Epic: Stats

- As a motivated user, I want to see my total time reclaimed from distraction so that I can feel the cumulative impact of my focus sessions.
  - [ ] The Stats tab displays a single number: total time saved across all sessions since the app was installed
  - [ ] Calculated as the sum of each day's "time saved" value
  - [ ] Updates daily

---

## What We're Building

Everything required for a complete, submittable app:

1. **Onboarding wizard** — app selection (with search + icon list), friction level selector, schedule setup (default weekday + custom per-day), wizard progress saved on exit
2. **Home screen** — session status lock icon, session countdown, time saved today counter, Unlock button (schedule-driven state), secondary unlock countdown with 3-min warning notification and re-lock on expiry
3. **Three friction tiers** — Minimal (cat picture + guilt prompt), Moderate (random physical action with phone detection), Extreme (math problem with answer input)
4. **Universal confirmation popup** — final gate with dynamic time-remaining text across all tiers and both unlock entry points
5. **Two unlock modes** — home screen (all apps, 15 min) and app-tap (one app, 15 min), with correct scope behavior for each
6. **Schedule & App Management tab** — read-only schedule view, Change Time and Apps editing flows, all editing disabled during active sessions
7. **Stats tab** — cumulative time saved since install
8. **Bottom tab navigation** — Home, Schedule, Stats

---

## What We'd Add With More Time

- **Accountability partner** — real-time approval flow where a partner gets notified and can approve/deny an unlock request. Requires backend and two-sided app experience. Fully designed in scope, deferred to post-MVP.
- **Streaks and leaderboards** — daily consistency tracking and social accountability layer (from Opal). Adds motivation but expands scope significantly.
- **Cumulative work session timer** — tracks total focused work time in addition to time saved. Complements the home screen but isn't core to the blocking mechanic.
- **Per-app stats breakdown** — shows time saved per individual app rather than a single aggregate total.
- **Onboarding tooltips** — guided callouts on first home screen visit explaining each element.

---

## Non-Goals

- **Emergency bypass** — no way to end a committed session early. Philosophically consistent with the app's stance on deep work; can be revisited post-launch based on user feedback.
- **Accountability partner (MVP)** — requires a backend, push notification coordination across two devices, and a two-sided app experience. Too complex for this build window.
- **Social features** — streaks, leaderboards, sharing. A social layer doubles scope and changes the product's character.
- **Cloud sync or multi-device support** — app state lives entirely on device for MVP.
- **App usage analytics beyond time saved** — no per-app breakdowns, trends over time, or charts in this version.

---

## Open Questions

- **Screen Time API entitlements** *(resolve before /spec)* — The Family Controls / ManagedSettings frameworks required to block apps at the OS level need a special device entitlement. This affects how the blocking mechanic actually works and may constrain implementation options. Needs investigation before spec to avoid a late-stage surprise.
- **Source of "historical daily average"** *(resolve before /spec)* — Does FocusLock pull pre-existing Screen Time history from iOS, or does it build its own baseline by observing usage over time? The answer changes what the time-saved counter shows in the first week of use.
- **3-minute notification while phone is locked** *(can wait until build)* — If the phone screen is off when the 3-minute warning fires, does it appear as a standard lock screen notification? Expected to work via standard iOS local notifications, but worth verifying during build.
- **Force-quit behavior** *(can wait until build)* — If the user force-quits FocusLock during an active 15-minute unlock window, does the unlock persist or collapse? Behavior depends on how unlock state is stored.
