import SwiftUI

/// Root view. Routes between the authorization gate, onboarding wizard, and main tab bar.
struct ContentView: View {
    @State private var authStatus = SharedStore.shared.authorizationStatus
    @State private var hasCompletedOnboarding = SharedStore.shared.hasCompletedOnboarding

    var body: some View {
        Group {
            if authStatus == "denied" {
                // Step 2: AuthorizationGateView (placeholder until that step is built)
                AuthorizationGatePlaceholder()
            } else if !hasCompletedOnboarding {
                // Step 3–4: Onboarding wizard (placeholder)
                OnboardingPlaceholder()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            // Refresh from SharedStore on each appearance (step 2 will replace with live observation)
            authStatus = SharedStore.shared.authorizationStatus
            hasCompletedOnboarding = SharedStore.shared.hasCompletedOnboarding
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

// MARK: - Placeholders (replaced in subsequent steps)

private struct AuthorizationGatePlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text("FocusLock needs Screen Time access to block apps")
                .multilineTextAlignment(.center)
            Text("(Authorization gate — built in Step 2)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

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
        }
        .padding()
    }
}
