import Foundation

/// Wraps UserDefaults(suiteName: "group.com.sddhackathon.focuslock").
/// All three targets (main app, DeviceActivityMonitor, ShieldConfiguration) share this file.
/// Extensions only read. The main app writes.
final class SharedStore: @unchecked Sendable {

    nonisolated(unsafe) static let shared = SharedStore()

    private let defaults: UserDefaults

    private init() {
        guard let defaults = UserDefaults(suiteName: "group.com.sddhackathon.focuslock") else {
            fatalError("App Group 'group.com.sddhackathon.focuslock' not configured. Check entitlements.")
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

    // MARK: - Session Tracking (written by DeviceActivityMonitor)

    /// Set to Date() when a session starts. Used to compute sessionDuration on end.
    var sessionStartTime: Date? {
        get { defaults.object(forKey: Keys.sessionStartTime) as? Date }
        set { defaults.set(newValue, forKey: Keys.sessionStartTime) }
    }

    // MARK: - Schedule End Times (written by main app at onboarding/settings)

    /// Maps day ID (1=Mon … 7=Sun) to the scheduled start time for that day.
    /// Written by the main app at onboarding/settings. Used to detect mid-interval launches.
    var scheduledStartTimes: [Int: Date] {
        get {
            guard let data = defaults.data(forKey: Keys.scheduledStartTimes),
                  let decoded = try? JSONDecoder().decode([String: Date].self, from: data) else {
                return [:]
            }
            return Dictionary(uniqueKeysWithValues: decoded.compactMap { k, v in
                Int(k).map { ($0, v) }
            })
        }
        set {
            let stringKeyed = Dictionary(uniqueKeysWithValues: newValue.map { ("\($0.key)", $0.value) })
            if let encoded = try? JSONEncoder().encode(stringKeyed) {
                defaults.set(encoded, forKey: Keys.scheduledStartTimes)
            }
        }
    }

    /// Maps day ID (1=Mon … 7=Sun) to the scheduled end time for that day.
    /// DeviceActivityMonitor reads this on session start to set sessionEndTime.
    var scheduledEndTimes: [Int: Date] {
        get {
            guard let data = defaults.data(forKey: Keys.scheduledEndTimes),
                  let decoded = try? JSONDecoder().decode([String: Date].self, from: data) else {
                return [:]
            }
            return Dictionary(uniqueKeysWithValues: decoded.compactMap { k, v in
                Int(k).map { ($0, v) }
            })
        }
        set {
            let stringKeyed = Dictionary(uniqueKeysWithValues: newValue.map { ("\($0.key)", $0.value) })
            if let encoded = try? JSONEncoder().encode(stringKeyed) {
                defaults.set(encoded, forKey: Keys.scheduledEndTimes)
            }
        }
    }

    // MARK: - Pending Session Log (written by extension, consumed by main app)

    /// Written by DeviceActivityMonitor on session end. Main app reads this on HomeView appear
    /// and persists it as a SwiftData SessionLog, then clears this value.
    var pendingSessionLog: PendingSessionLog? {
        get {
            guard let data = defaults.data(forKey: Keys.pendingSessionLog) else { return nil }
            return try? JSONDecoder().decode(PendingSessionLog.self, from: data)
        }
        set {
            if let value = newValue, let encoded = try? JSONEncoder().encode(value) {
                defaults.set(encoded, forKey: Keys.pendingSessionLog)
            } else {
                defaults.removeObject(forKey: Keys.pendingSessionLog)
            }
        }
    }

    // MARK: - Shield Handoff

    /// Encoded ApplicationToken written by ShieldActionExt when the user taps Unlock
    /// on a blocked app's shield. FocusLockApp decodes it on foreground, passes the
    /// token to FrictionRouter as .shieldToken so BlockingService can do surgical
    /// per-app unblocking without clearing other apps' unlock windows.
    var pendingShieldUnlockToken: Data? {
        get { defaults.data(forKey: Keys.pendingShieldUnlockToken) }
        set { defaults.set(newValue, forKey: Keys.pendingShieldUnlockToken) }
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
        static let sessionStartTime = "sessionStartTime"
        static let scheduledStartTimes = "scheduledStartTimes"
        static let scheduledEndTimes = "scheduledEndTimes"
        static let pendingSessionLog = "pendingSessionLog"
        static let pendingShieldUnlockToken = "pendingShieldUnlockToken"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let onboardingStep = "onboardingStep"
        static let authorizationStatus = "authorizationStatus"
    }
}
