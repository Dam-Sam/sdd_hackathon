import SwiftUI
import SwiftData

struct HomeView: View {
    private static let store = UserDefaults(suiteName: "group.com.sddhackathon.focuslock")
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    @AppStorage("isSessionActive", store: store)
    private var isSessionActive: Bool = false

    // Date? values not natively supported by @AppStorage — polled from SharedStore on each timer tick.
    @State private var sessionEndTime: Date? = SharedStore.shared.sessionEndTime
    @State private var allAppsUnlockExpiry: Date? = SharedStore.shared.allAppsUnlockExpiry
    @State private var now: Date = Date()

    @Query private var sessionLogs: [SessionLog]

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {

                // MARK: Countdown timer
                Text(countdownText)
                    .font(.system(size: 56, weight: .thin, design: .monospaced))
                    .foregroundStyle(isSessionActive ? .primary : .secondary)
                    .contentTransition(.numericText())

                // MARK: Lock icon
                // Three states: no session (open, secondary), unlock window active (open, green),
                // session locked (closed, red).
                Image(systemName: isAppsUnlocked ? "lock.open.fill" : (isSessionActive ? "lock.fill" : "lock.open.fill"))
                    .font(.system(size: 72))
                    .foregroundStyle(isAppsUnlocked ? .green : (isSessionActive ? .red : .secondary))
                    .symbolEffect(.bounce, value: isSessionActive)
                    .symbolEffect(.bounce, value: isAppsUnlocked)

                // MARK: Time saved today
                VStack(spacing: 4) {
                    Text(timeSavedToday)
                        .font(.title2.bold())
                    Text("time saved today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: Unlock button
                // Disabled when no session is running, or when an unlock window is already active.
                Button("Unlock") {
                    router.pendingUnlockSource = .homeScreen
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isSessionActive || isAppsUnlocked)

                // MARK: Debug controls (DEBUG builds only)
                #if DEBUG
                Divider()
                VStack(spacing: 12) {
                    Button("DEBUG: Start Session") {
                        SharedStore.shared.isSessionActive = true
                        SharedStore.shared.sessionEndTime = Date().addingTimeInterval(30 * 60)
                        BlockingService.shared.relockAll()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Button("DEBUG: End Session") {
                        SharedStore.shared.isSessionActive = false
                        SharedStore.shared.sessionEndTime = nil
                        BlockingService.shared.relockAll()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
                #endif

                // MARK: Secondary countdown (visible only when allAppsUnlockExpiry is set)
                if let expiry = allAppsUnlockExpiry, expiry > now {
                    VStack(spacing: 4) {
                        Text(unlockCountdownText(expiry: expiry))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.orange)
                        Text("unlock window remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(32)
            .navigationTitle("FocusLock")
            .onAppear {
                consumePendingSessionLog()
            }
            .onReceive(timer) { tick in
                now = tick
                sessionEndTime = SharedStore.shared.sessionEndTime
                allAppsUnlockExpiry = SharedStore.shared.allAppsUnlockExpiry
            }
        }
    }

    // MARK: - Helpers

    /// True when an all-apps unlock window is currently active.
    private var isAppsUnlocked: Bool {
        guard let expiry = allAppsUnlockExpiry else { return false }
        return expiry > now
    }

    private var countdownText: String {
        guard isSessionActive, let end = sessionEndTime, end > now else { return "0:00" }
        let remaining = Int(end.timeIntervalSince(now))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }

    private func unlockCountdownText(expiry: Date) -> String {
        let remaining = max(0, Int(expiry.timeIntervalSince(now)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Reads any pending session log written by MonitorExtension and persists it to SwiftData.
    /// The extension can't write SwiftData directly — this is the handoff point.
    private func consumePendingSessionLog() {
        guard let log = SharedStore.shared.pendingSessionLog else { return }
        let entry = SessionLog(
            date: log.date,
            sessionDuration: log.sessionDuration,
            totalUnlockMinutes: log.totalUnlockMinutes
        )
        modelContext.insert(entry)
        SharedStore.shared.pendingSessionLog = nil
    }

    private var timeSavedToday: String {
        let calendar = Calendar.current
        let total = sessionLogs
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.timeSaved }
        let hours = total / 60
        let minutes = total % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
