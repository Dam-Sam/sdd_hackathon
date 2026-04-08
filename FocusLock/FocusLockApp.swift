import SwiftUI
import SwiftData
import FamilyControls

@main
struct FocusLockApp: App {

    // MARK: - Auth Stub (Step 2)
    // useAuthStub = true → skip the real FamilyControls call and use stubStatus directly.
    // Flip stubStatus to "authorized" to test the onboarding path, "denied" to test the gate.
    // Set useAuthStub = false when you have the real entitlement and want to test on device.
    #if DEBUG
    private let useAuthStub = true
    private let stubStatus = "authorized"   // "denied" | "authorized" | "notDetermined"
    #endif

    @State private var router = AppRouter()

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
            SharedStore.shared.allAppsUnlockExpiry = Date().addingTimeInterval(300)
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
