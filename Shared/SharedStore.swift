import Foundation

/// Wraps UserDefaults(suiteName: "group.focuslock").
/// All three targets (main app, DeviceActivityMonitor, ShieldConfiguration) share this file.
/// Extensions only read. The main app writes.
final class SharedStore: @unchecked Sendable {

    nonisolated(unsafe) static let shared = SharedStore()

    private let defaults: UserDefaults

    private init() {
        guard let defaults = UserDefaults(suiteName: "group.focuslock") else {
            fatalError("App Group 'group.focuslock' not configured. Check entitlements.")
        }
        self.defaults = defaults
    }

    // MARK: - Blocked Apps

    /// Encoded FamilyActivitySelection. Written during onboarding / settings.
    var blockedApps: Data? {
        get { defaults.data(forKey: Keys.blockedApps) }
        set { defaults.set(newValue, forKey: Keys.blockedApps) }
    }

    // MARK: - Friction Tier

    /// "minimal" | "moderate" | "extreme"
    var frictionTier: String {
        get { defaults.string(forKey: Keys.frictionTier) ?? "minimal" }
        set { defaults.set(newValue, forKey: Keys.frictionTier) }
    }

    // MARK: - Session State

    /// True during an active scheduled block session.
    var isSessionActive: Bool {
        get { defaults.bool(forKey: Keys.isSessionActive) }
        set { defaults.set(newValue, forKey: Keys.isSessionActive) }
    }

    /// Current session's end time. Read by HomeView countdown.
    var sessionEndTime: Date? {
        get { defaults.object(forKey: Keys.sessionEndTime) as? Date }
        set { defaults.set(newValue, forKey: Keys.sessionEndTime) }
    }

    // MARK: - Unlock Expiries

    /// Nil = no active all-apps unlock. Written by BlockingService on unlock-all.
    var allAppsUnlockExpiry: Date? {
        get { defaults.object(forKey: Keys.allAppsUnlockExpiry) as? Date }
        set { defaults.set(newValue, forKey: Keys.allAppsUnlockExpiry) }
    }

    /// BundleID → expiry time for per-app unlocks.
    var individualUnlockExpiries: [String: Date] {
        get {
            guard let data = defaults.data(forKey: Keys.individualUnlockExpiries),
                  let decoded = try? JSONDecoder().decode([String: Date].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                defaults.set(encoded, forKey: Keys.individualUnlockExpiries)
            }
        }
    }

    // MARK: - Onboarding

    /// Guards the onboarding flow. Once true, never show wizard again.
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    /// 0 = app selection, 1 = schedule. Enables wizard resume on re-launch.
    var onboardingStep: Int {
        get { defaults.integer(forKey: Keys.onboardingStep) }
        set { defaults.set(newValue, forKey: Keys.onboardingStep) }
    }

    // MARK: - Authorization

    /// "authorized" | "denied" | "notDetermined"
    var authorizationStatus: String {
        get { defaults.string(forKey: Keys.authorizationStatus) ?? "notDetermined" }
        set { defaults.set(newValue, forKey: Keys.authorizationStatus) }
    }

    // MARK: - Keys

    enum Keys {
        static let blockedApps = "blockedApps"
        static let frictionTier = "frictionTier"
        static let isSessionActive = "isSessionActive"
        static let sessionEndTime = "sessionEndTime"
        static let allAppsUnlockExpiry = "allAppsUnlockExpiry"
        static let individualUnlockExpiries = "individualUnlockExpiries"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let onboardingStep = "onboardingStep"
        static let authorizationStatus = "authorizationStatus"
    }
}
