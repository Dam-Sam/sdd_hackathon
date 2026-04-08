# FocusLock

## Idea
An iOS productivity app that blocks distracting apps on a user-defined schedule and makes unblocking them deliberately tedious — framing the experience as reclaiming time that distraction is stealing from you.

## Who It's For
People who recognize their own distraction patterns — a notification pulls them in, 30 minutes disappears — and want a system that creates real resistance, not just a gentle nudge. The primary user is someone who values deep, uninterrupted work but struggles to maintain it without external enforcement.

## Inspiration & References
- **OneSec** — friction-as-interception philosophy; physical action mechanics (follow a moving dot, rotate phone, wait 10 seconds). Research-backed: 57% reduction in app opens. The closest conceptual cousin.
- **Opal** — strict session commitment ("no way out" deep focus mode), streaks and leaderboards for accountability.
- **Cal Newport's *Deep Work*** — the philosophical backbone. The app's framing ("time regained" not "time blocked") is directly aligned with Newport's argument that distraction steals time and attention that belongs to you.
- **Design direction:** iOS 26 Liquid Glass aesthetic. Calm, organized, modern, smooth. Clean functional design — no gimmicks. Substance over flash.

## Goals
- Ship a working iOS app that genuinely helps the user (and people like them) stay focused during scheduled work sessions.
- Demonstrate thoughtful product thinking: the friction mechanic isn't punitive, it's intentional design.
- Practice spec-driven development end-to-end for the first time.
- Build something worth showing — not just functional, but considered.

## What "Done" Looks Like
A working iOS app where a user can:
1. Set a recurring block schedule (weekday default with configurable start/end times; custom per-day option; weekend toggle)
2. Select which installed apps to block from a scrollable list with search
3. Choose a friction level (Minimal / Moderate / Extreme) that governs what happens when they try to open a blocked app during a session
4. Experience a randomly selected friction activity from their chosen tier when attempting to open a blocked app
5. See a home screen overview showing: current locked status, countdown to session end, and total "time regained" across all sessions

**Friction tiers:**
- **Minimal:** cute cat pictures, multiple "are you sure?" confirmation prompts
- **Moderate:** physical actions — follow a moving dot, wait 10 seconds, rotate phone 3 times (drawn from OneSec mechanics)
- **Extreme:** mental math problems

The app speaks the language of empowerment: "time regained," not "time blocked."

## What's Explicitly Cut
- **Accountability partner feature** — real-time approval flow where a partner gets notified and can approve/deny with a custom time limit. Strong idea, real complexity: requires a backend, push notification coordination between two devices, and a two-sided app experience. Post-MVP.
- **Timer/tracker for cumulative work time** — backlog feature; would complement the home screen but isn't core to the blocking mechanic.
- **Streaks and leaderboards** — interesting from Opal, but a social layer adds scope. Post-MVP.
- **Emergency bypass** — no way out during a committed session. Philosophically consistent with the app's stance on deep work. Can be revisited based on user feedback.

## Loose Implementation Notes
- iOS Screen Time API (Family Controls / ManagedSettings frameworks) is likely required to actually block apps at the OS level — this is how Opal achieves real blocking rather than VPN-based interception. Worth investigating early as it has restrictions (requires device entitlement, may need ScreenTime authorization from user).
- OneSec uses iOS Shortcuts Automation for its interception mechanic — an alternative approach if Screen Time API proves restrictive.
- Friction activities need to be implemented as native UI interruptions, triggered when the user attempts to open a blocked app.
- Schedule persistence and app selection state will need local storage (SwiftData or UserDefaults for MVP).
- Liquid Glass design is native to iOS 26 — standard UIKit/SwiftUI components will adopt it automatically on supported devices.
