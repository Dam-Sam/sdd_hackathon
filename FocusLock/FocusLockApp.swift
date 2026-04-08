import SwiftUI
import SwiftData

@main
struct FocusLockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleURL(url)
                }
        }
        .modelContainer(for: [Schedule.self, DaySchedule.self, SessionLog.self])
    }

    private func handleURL(_ url: URL) {
        // URL scheme handler — wired up fully in Step 9 (ShieldConfiguration + FrictionRouter).
        // Stub: parse source parameter and log for now.
        guard url.scheme == "focuslock",
              url.host == "unlock",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let source = components.queryItems?.first(where: { $0.name == "source" })?.value
        else { return }

        print("[FocusLockApp] Received unlock URL — source: \(source)")
        // Step 9 will route to FrictionRouter based on source/app params.
    }
}
