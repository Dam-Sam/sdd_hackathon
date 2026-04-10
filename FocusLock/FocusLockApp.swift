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
        .modelContainer(for: [Schedule.self, DaySchedule.self, SessionLog.self])
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                consumePendingShieldUnlock()
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
