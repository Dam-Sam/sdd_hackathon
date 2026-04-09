import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

/// Handles DeviceActivity schedule events: session start/end and unlock expiry re-locks.
///
/// Activity name conventions used across the app:
///   "focus-session-1" … "focus-session-7" — daily session for day ID 1=Mon … 7=Sun
///   "unlock-all"                           — all-apps 15-minute unlock expiry
///   "unlock-<bundleID>"                    — per-app 15-minute unlock expiry
class MonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    // MARK: - Interval Started

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        let name = activity.rawValue
        guard name.hasPrefix("focus-session") else { return }

        // Activate ManagedSettings blocking for all selected apps.
        activateBlocking()
        SharedStore.shared.isSessionActive = true
        SharedStore.shared.sessionStartTime = Date()

        // Set sessionEndTime so HomeView's countdown can tick.
        // The end time for this day is stored in SharedStore by the main app at onboarding.
        if let dayId = dayId(from: name) {
            let endTimes = SharedStore.shared.scheduledEndTimes
            if let storedEndTime = endTimes[dayId] {
                let cal = Calendar.current
                let now = Date()
                let hour = cal.component(.hour, from: storedEndTime)
                let minute = cal.component(.minute, from: storedEndTime)
                SharedStore.shared.sessionEndTime = cal.date(
                    bySettingHour: hour, minute: minute, second: 0, of: now
                )
            }
        }

        print("[MonitorExtension] Session started: \(name)")
    }

    // MARK: - Interval Ended

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        let name = activity.rawValue

        if name.hasPrefix("focus-session") {
            handleSessionEnd()

        } else if name == "unlock-all" {
            // All-apps 15-minute unlock window expired — re-lock everything.
            relockAll()
            SharedStore.shared.allAppsUnlockExpiry = nil
            print("[MonitorExtension] All-apps unlock expired — relocked")

        } else if name.hasPrefix("unlock-") {
            // Per-app 15-minute unlock window expired — re-lock that app.
            let bundleID = String(name.dropFirst("unlock-".count))
            relock(bundleID: bundleID)
            print("[MonitorExtension] Per-app unlock expired: \(bundleID)")
        }
    }

    // MARK: - Session End

    private func handleSessionEnd() {
        relockAll()

        // Compute how long the session ran (in minutes).
        let duration: Int
        if let start = SharedStore.shared.sessionStartTime {
            duration = max(0, Int(Date().timeIntervalSince(start) / 60))
        } else {
            duration = 0
        }

        // Store a pending session log. The main app can't receive SwiftData writes from
        // extensions, so we write here and HomeView picks it up on next appear.
        SharedStore.shared.pendingSessionLog = PendingSessionLog(
            date: Date(),
            sessionDuration: duration,
            totalUnlockMinutes: 0   // Future: track unlock window minutes during session
        )

        SharedStore.shared.isSessionActive = false
        SharedStore.shared.sessionEndTime = nil
        SharedStore.shared.sessionStartTime = nil

        print("[MonitorExtension] Session ended — duration: \(duration)min")
    }

    // MARK: - ManagedSettings Helpers

    /// Shield all apps listed in SharedStore.blockedApps.
    private func activateBlocking() {
        guard let data = SharedStore.shared.blockedApps,
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }
        store.shield.applications = selection.applicationTokens
    }

    /// Re-shield all apps and clear all unlock state.
    private func relockAll() {
        guard let data = SharedStore.shared.blockedApps,
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            store.shield.applications = nil
            return
        }
        store.shield.applications = selection.applicationTokens
        SharedStore.shared.allAppsUnlockExpiry = nil
        SharedStore.shared.individualUnlockExpiries = [:]
    }

    /// Re-lock a single app by bundle ID and remove its individual expiry entry.
    /// Uses relockAll() as a safe fallback — surgical per-app token available in Step 9.
    private func relock(bundleID: String) {
        relockAll()
        var expiries = SharedStore.shared.individualUnlockExpiries
        expiries.removeValue(forKey: bundleID)
        SharedStore.shared.individualUnlockExpiries = expiries
    }

    // MARK: - Utility

    /// Extracts the day ID from an activity name like "focus-session-3" → 3.
    private func dayId(from activityName: String) -> Int? {
        guard let suffix = activityName.split(separator: "-").last else { return nil }
        return Int(suffix)
    }
}
