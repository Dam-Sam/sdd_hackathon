import UserNotifications
import Foundation

/// Wraps UNUserNotificationCenter. Schedules and cancels local notifications
/// for unlock window warnings. The main app calls this; extensions do not.
final class NotificationService: @unchecked Sendable {

    nonisolated(unsafe) static let shared = NotificationService()

    private init() {}

    // MARK: - Permission

    /// Request notification permission on first launch.
    /// Called once from FocusLockApp on startup.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("[NotificationService] Permission request error: \(error)")
            }
        }
    }

    // MARK: - Schedule / Cancel

    /// Schedule a "3 minutes left" notification at `expiry - 3min`.
    /// Safe to call even if the warning time has already passed — it's a no-op.
    func scheduleUnlockWarning(expiry: Date, identifier: String) {
        let warningTime = expiry.addingTimeInterval(-3 * 60)
        let interval = warningTime.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "FocusLock"
        content.body = "3 minutes left — your apps will re-lock soon"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationService] Failed to schedule \(identifier): \(error)")
            }
        }
    }

    /// Cancel a pending warning by identifier.
    func cancelWarning(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
