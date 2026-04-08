import DeviceActivity
import ManagedSettings

/// Handles DeviceActivity schedule events: session start/end and unlock expiry re-locks.
/// Full implementation in Step 8.
class MonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Step 8: Activate ManagedSettings blocking, write isSessionActive = true
        print("[MonitorExtension] Interval started: \(activity.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Step 8: Deactivate blocking, write isSessionActive = false, log SessionLog
        print("[MonitorExtension] Interval ended: \(activity.rawValue)")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // Step 8: Handle unlock expiry re-lock
        print("[MonitorExtension] Event threshold reached: \(event.rawValue)")
    }
}
