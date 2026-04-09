import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity

/// Wraps ManagedSettingsStore. Called by the main app after friction is completed.
/// Extensions (DeviceActivityMonitor) call relockAll() / relock(bundleID:) to restore blocking.
final class BlockingService: @unchecked Sendable {

    nonisolated(unsafe) static let shared = BlockingService()
    private let store = ManagedSettingsStore()

    private init() {}

    // MARK: - Unlock

    /// Unlock based on the source. Writes expiry timestamps to SharedStore and schedules
    /// the 3-minute warning notification. ManagedSettings blocking is cleared immediately.
    func unlockApp(source: UnlockSource) {
        print("[BlockingService] unlockApp called — source: \(source)")
        let expiry = Date().addingTimeInterval(15 * 60)

        switch source {
        case .homeScreen:
            // Remove all apps from the shield set.
            store.shield.applications = nil

            // Supersede any per-app unlocks — all-apps unlock covers everything.
            SharedStore.shared.individualUnlockExpiries = [:]

            SharedStore.shared.allAppsUnlockExpiry = expiry
            NotificationService.shared.cancelWarning(identifier: "allAppsUnlock")
            NotificationService.shared.scheduleUnlockWarning(expiry: expiry, identifier: "allAppsUnlock")

            // Register DeviceActivity interval so MonitorExtension re-locks when it expires.
            registerUnlockExpiry(identifier: "unlock-all", expiry: expiry)

        case .shield(let bundleID):
            // Per-app unshielding requires ApplicationToken, not a bundle ID string.
            // ApplicationToken only flows through the ShieldConfigExtension (Step 9).
            // Until then: clear all shielding so the user can access the app.
            // Step 9 will refine this to surgical per-app removal once the token is available.
            store.shield.applications = nil

            var expiries = SharedStore.shared.individualUnlockExpiries
            expiries[bundleID] = expiry
            SharedStore.shared.individualUnlockExpiries = expiries

            let notifID = "unlock-\(bundleID)"
            NotificationService.shared.cancelWarning(identifier: notifID)
            NotificationService.shared.scheduleUnlockWarning(expiry: expiry, identifier: notifID)

            // Register DeviceActivity interval so MonitorExtension re-locks when it expires.
            registerUnlockExpiry(identifier: "unlock-\(bundleID)", expiry: expiry)
        }
    }

    /// Registers a one-shot DeviceActivity monitoring interval that ends at `expiry`.
    /// MonitorExtension.intervalDidEnd fires at that time and performs the re-lock.
    private func registerUnlockExpiry(identifier: String, expiry: Date) {
        let cal = Calendar.current
        let now = Date()
        let startComponents = cal.dateComponents([.hour, .minute, .second], from: now)
        let endComponents = cal.dateComponents([.hour, .minute, .second], from: expiry)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        do {
            try DeviceActivityCenter().startMonitoring(
                DeviceActivityName(identifier),
                during: schedule
            )
        } catch {
            print("[BlockingService] Failed to register unlock expiry '\(identifier)': \(error)")
        }
    }

    // MARK: - Relock

    /// Re-block all apps using the stored FamilyActivitySelection. Clears all expiry state.
    /// Called by DeviceActivityMonitor on session-end or all-apps unlock expiry.
    func relockAll() {
        guard let data = SharedStore.shared.blockedApps,
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            store.shield.applications = nil
            return
        }
        store.shield.applications = selection.applicationTokens
        SharedStore.shared.allAppsUnlockExpiry = nil
        SharedStore.shared.individualUnlockExpiries = [:]
        NotificationService.shared.cancelWarning(identifier: "allAppsUnlock")
    }

    /// Re-block a single app and remove its individual unlock expiry.
    /// Called by DeviceActivityMonitor when a per-app unlock interval expires.
    /// Note: surgical per-app relock needs the ApplicationToken (refined in Step 9).
    /// For now, relocks everything as a safe fallback.
    func relock(bundleID: String) {
        relockAll()
        var expiries = SharedStore.shared.individualUnlockExpiries
        expiries.removeValue(forKey: bundleID)
        SharedStore.shared.individualUnlockExpiries = expiries
        NotificationService.shared.cancelWarning(identifier: "unlock-\(bundleID)")
    }
}
