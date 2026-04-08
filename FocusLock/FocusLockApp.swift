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
    private let stubStatus = "denied"   // "denied" | "authorized" | "notDetermined"
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleURL(url)
                }
                .task {
                    await requestAuthorization()
                }
        }
        .modelContainer(for: [Schedule.self, DaySchedule.self, SessionLog.self])
    }

    // MARK: - Authorization

    private func requestAuthorization() async {
        #if DEBUG
        if useAuthStub {
            SharedStore.shared.authorizationStatus = stubStatus
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
        // URL scheme handler — wired up fully in Step 9 (ShieldConfiguration + FrictionRouter).
        guard url.scheme == "focuslock",
              url.host == "unlock",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let source = components.queryItems?.first(where: { $0.name == "source" })?.value
        else { return }

        print("[FocusLockApp] Received unlock URL — source: \(source)")
        // Step 9 will route to FrictionRouter based on source/app params.
    }
}
