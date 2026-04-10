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
        print("[BlockingService] unlockApp START — source: \(source), thread: \(Thread.isMainThread ? "main" : "bg")")
        let expiry = Date().addingTimeInterval(15 * 60)

        switch source {
        case .homeScreen:
            print("[BlockingService] clearing shield...")
            store.shield.applications = nil
            print("[BlockingService] shield cleared")

            SharedStore.shared.individualUnlockExpiries = [:]
            SharedStore.shared.allAppsUnlockExpiry = expiry
            NotificationService.shared.cancelWarning(identifier: "allAppsUnlock")
            NotificationService.shared.scheduleUnlockWarning(expiry: expiry, identifier: "allAppsUnlock")
            registerUnlockExpiry(identifier: "unlock-all", expiry: expiry)

        case .shield(let bundleID):
            // URL scheme / manual testing path — no ApplicationToken available,
            // so fall back to clearing all shields.
            print("[BlockingService] clearing shield (per-app, fallback all-clear)...")
            store.shield.applications = nil
            print("[BlockingService] shield cleared")

            var expiries = SharedStore.shared.individualUnlockExpiries
            expiries[bundleID] = expiry
            SharedStore.shared.individualUnlockExpiries = expiries

            let notifID = "unlock-\(bundleID)"
            NotificationService.shared.cancelWarning(identifier: notifID)
            NotificationService.shared.scheduleUnlockWarning(expiry: expiry, identifier: notifID)
            registerUnlockExpiry(identifier: "unlock-\(bundleID)", expiry: expiry)

        case .shieldToken(let token):
            // Real shield flow — surgically remove only this app's token.
            print("[BlockingService] surgical shield removal for token...")
            if var apps = store.shield.applications {
                apps.remove(token)
                store.shield.applications = apps.isEmpty ? nil : apps
            }
            print("[BlockingService] surgical removal complete")

            let tokenID = "shieldToken-\(token.hashValue)"
            var expiries = SharedStore.shared.individualUnlockExpiries
            expiries[tokenID] = expiry
            SharedStore.shared.individualUnlockExpiries = expiries

            NotificationService.shared.cancelWarning(identifier: tokenID)
            NotificationService.shared.scheduleUnlockWarning(expiry: expiry, identifier: tokenID)
            registerUnlockExpiry(identifier: tokenID, expiry: expiry)
        }

        print("[BlockingService] unlockApp END")
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

        // DeviceActivityCenter.startMonitoring does IPC with a system process —
        // always run it off the main thread to avoid blocking the UI.
        Task.detached {
            do {
                try DeviceActivityCenter().startMonitoring(
                    DeviceActivityName(identifier),
                    during: schedule
                )
            } catch {
                print("[BlockingService] Failed to register unlock expiry '\(identifier)': \(error)")
            }
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
