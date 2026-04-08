import Observation

/// Observable routing state shared across the app.
/// FocusLockApp writes pendingUnlockSource when an unlock is triggered
/// (Unlock button tap or URL scheme). ContentView observes and presents FrictionRouter.
@Observable
final class AppRouter {
    /// Non-nil when a friction flow should be presented. Cleared when dismissed.
    var pendingUnlockSource: UnlockSource? = nil
}
