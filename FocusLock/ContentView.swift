import SwiftUI

/// Root view. Routes between the authorization gate, onboarding wizard, and main tab bar.
struct ContentView: View {
    private static let store = UserDefaults(suiteName: "group.focuslock")

    @AppStorage("authorizationStatus", store: store)
    private var authStatus: String = "notDetermined"

    @AppStorage("hasCompletedOnboarding", store: store)
    private var hasCompletedOnboarding: Bool = false

    /// 0 = AppSelectionView, 1 = ScheduleSetupView.
    /// Writing this from any child view re-renders ContentView and swaps the screen.
    @AppStorage("onboardingStep", store: store)
    private var onboardingStep: Int = 0

    var body: some View {
        Group {
            switch authStatus {
            case "denied":
                AuthorizationGateView()
            case "authorized":
                if !hasCompletedOnboarding {
                    if onboardingStep == 0 {
                        AppSelectionView()
                    } else {
                        ScheduleSetupView()
                    }
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
