import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

@main
struct FocusLockApp: App {

    // MARK: - Auth Stub (Step 2)
    // useAuthStub = true → skip the real FamilyControls call and use stubStatus directly.
    // Flip stubStatus to "authorized" to test the onboarding path, "denied" to test the gate.
    // Set useAuthStub = false when you have the real entitlement and want to test on device.
    #if DEBUG
    private let useAuthStub = false
    private let stubStatus = "authorized"   // "denied" | "authorized" | "notDetermined"
    #endif

    @State private var router = AppRouter()
    @Environment(\.scenePhase) private var scenePhase

    // Explicit container anchored to the app's private Application Support directory.
    // SwiftData on iOS 26 defaults to the App Group container when an app group entitlement
    // is present, which causes CoreData errors because Application Support doesn't exist there.
    private static let modelContainer: ModelContainer = {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let storeURL = appSupport.appendingPathComponent("FocusLock.store")
        let schema = Schema([Schedule.self, DaySchedule.self, SessionLog.self])
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .onOpenURL { url in
                    handleURL(url)
                }
                .task {
                    await requestAuthorization()
                    NotificationService.shared.requestPermission()
                }
        }
        .modelContainer(Self.modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                consumePendingShieldUnlock()
                activateSessionIfCurrentlyScheduled()
            }
        }
    }

    // MARK: - Authorization

    private func requestAuthorization() async {
        #if DEBUG
        if useAuthStub {
            SharedStore.shared.authorizationStatus = stubStatus
            // Reset onboarding so you can walk the full flow from any stub state.
            // Remove these lines if you want to test post-onboarding screens.
            SharedStore.shared.hasCompletedOnboarding = false
            SharedStore.shared.onboardingStep = 0
            SharedStore.shared.allAppsUnlockExpiry = nil
            return
        }
        #endif

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            SharedStore.shared.authorizationStatus = "authorized"
        } catch {
            SharedStore.shared.authorizationStatus = "denied"
        }
    }

    // MARK: - Mid-Interval Session Activation

    /// DeviceActivityCenter doesn't fire intervalDidStart retroactively when a schedule is
    /// registered mid-interval (e.g. user completes onboarding at 4 PM for a 9–5 schedule).
    /// This method checks on every scene-active whether the current time falls inside a
    /// scheduled window and activates blocking directly if the session isn't already running.
    private func activateSessionIfCurrentlyScheduled() {
        guard SharedStore.shared.hasCompletedOnboarding else { return }
        guard !SharedStore.shared.isSessionActive else { return }

        let cal = Calendar.current
        let now = Date()

        // Convert Gregorian weekday (1=Sun…7=Sat) to our dayId (1=Mon…7=Sun).
        let gregorian = cal.component(.weekday, from: now)
        let dayId = gregorian == 1 ? 7 : gregorian - 1

        let startTimes = SharedStore.shared.scheduledStartTimes
        let endTimes   = SharedStore.shared.scheduledEndTimes

        guard let storedStart = startTimes[dayId],
              let storedEnd   = endTimes[dayId] else { return }

        // Reconstruct today's start/end as absolute dates.
        let todayStart = cal.date(bySettingHour:   cal.component(.hour,   from: storedStart),
                                  minute:           cal.component(.minute, from: storedStart),
                                  second: 0, of: now)!
        let todayEnd   = cal.date(bySettingHour:   cal.component(.hour,   from: storedEnd),
                                  minute:           cal.component(.minute, from: storedEnd),
                                  second: 0, of: now)!

        guard now >= todayStart, now < todayEnd else { return }

        // We're inside a scheduled window — activate immediately.
        print("[FocusLockApp] Mid-interval launch detected. Activating session for day \(dayId).")
        Task.detached(priority: .userInitiated) {
            let store = ManagedSettingsStore()
            guard let data = SharedStore.shared.blockedApps,
                  let selection = try? PropertyListDecoder().decode(
                      FamilyActivitySelection.self, from: data) else {
                print("[FocusLockApp] No blocked apps configured — skipping activation.")
                return
            }
            store.shield.applications = selection.applicationTokens
            SharedStore.shared.isSessionActive  = true
            SharedStore.shared.sessionStartTime = Date()
            SharedStore.shared.sessionEndTime   = todayEnd
            print("[FocusLockApp] Session activated. End time: \(todayEnd)")
        }
    }

    // MARK: - Shield Handoff

    /// Reads SharedStore.pendingShieldUnlockToken written by ShieldActionExt when the user
    /// taps "Unlock" on a blocked app's shield. Decodes the ApplicationToken and routes
    /// to FrictionRouter with .shieldToken(token) so BlockingService surgically unblocks
    /// only that app on confirmation.
    private func consumePendingShieldUnlock() {
        guard let data = SharedStore.shared.pendingShieldUnlockToken else { return }
        SharedStore.shared.pendingShieldUnlockToken = nil
        guard let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) else { return }
        router.pendingUnlockSource = .shieldToken(token)
    }

    // MARK: - URL Scheme

    private func handleURL(_ url: URL) {
        guard url.scheme == "focuslock",
              url.host == "unlock",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let source = components.queryItems?.first(where: { $0.name == "source" })?.value
        else { return }

        let app = components.queryItems?.first(where: { $0.name == "app" })?.value

        switch source {
        case "home":
            router.pendingUnlockSource = .homeScreen
        case "shield":
            if let bundleID = app {
                router.pendingUnlockSource = .shield(bundleID: bundleID)
            }
        default:
            print("[FocusLockApp] Unknown unlock source: \(source)")
        }
    }
}
