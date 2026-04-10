import Foundation
import ManagedSettings
import ManagedSettingsUI

/// Handles primary button presses on the shield block screen.
/// Extension point: com.apple.screentime.shield.action
///
/// When the user taps "Unlock" on a blocked app's shield, this handler:
/// 1. Encodes the ApplicationToken and writes it to SharedStore.pendingShieldUnlockToken.
/// 2. Closes the shield via completionHandler(.close).
/// FocusLockApp reads pendingShieldUnlockToken on foreground, decodes the token,
/// and presents FrictionRouter with .shieldToken(token) so BlockingService can
/// surgically remove only that app from the ManagedSettings shield set on confirm.
class ShieldActionExt: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        if action == .primaryButtonPressed {
            // Encode the token so FocusLock can do surgical per-app unblocking on confirm.
            if let tokenData = try? JSONEncoder().encode(application) {
                SharedStore.shared.pendingShieldUnlockToken = tokenData
            }
        }
        completionHandler(.close)
    }
}
