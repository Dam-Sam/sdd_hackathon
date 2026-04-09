import Foundation

/// Written to SharedStore by DeviceActivityMonitor on session end.
/// The main app reads this on next HomeView appear and persists it as a SwiftData SessionLog.
/// This bridge is necessary because extensions cannot access SwiftData directly.
struct PendingSessionLog: Codable {
    var date: Date
    /// Total minutes the session ran (from session start to end).
    var sessionDuration: Int
    /// Minutes spent unlocked during the session. Currently 0 — tracked in a future pass.
    var totalUnlockMinutes: Int
}
