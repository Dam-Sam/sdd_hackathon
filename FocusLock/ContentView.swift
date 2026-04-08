import SwiftUI

/// Root view. Routes between the authorization gate, onboarding wizard, and main tab bar.
struct ContentView: View {
    private static let store = UserDefaults(suiteName: "group.focuslock")

    @AppStorage("authorizationStatus", store: store)
    private var authStatus: String = "notDetermined"

    @AppStorage("hasCompletedOnboarding", store: store)
    private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            switch authStatus {
            case "denied":
                AuthorizationGateView()
            case "authorized":
                if !hasCompletedOnboarding {
                    // Step 3–4: Onboarding wizard (placeholder)
                    OnboardingPlaceholder()
                } else {
                    MainTabView()
                }
            default:
                // "notDetermined" — authorization check in flight; show blank while .task fires
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Main Tab Bar

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
        }
    }
}

// MARK: - Onboarding Placeholder (replaced in Steps 3–4)

private struct OnboardingPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text("Onboarding")
                .font(.title2.bold())
            Text("(App selection + schedule setup — built in Steps 3–4)")
                .font(.caption)
                .foregroundStyle(.secondary)
            // DEV SHORTCUT — removed when real onboarding is built in Steps 3–4
            Button("Skip to Tab Bar (Dev)") {
                SharedStore.shared.hasCompletedOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }
}
