import SwiftUI

/// Root view. Routes between the authorization gate, onboarding wizard, and main tab bar.
/// Also presents FrictionRouter as a fullScreenCover when AppRouter.pendingUnlockSource is set.
struct ContentView: View {
    private static let store = UserDefaults(suiteName: "group.com.sddhackathon.focuslock")

    @AppStorage("authorizationStatus", store: store)
    private var authStatus: String = "notDetermined"

    @AppStorage("hasCompletedOnboarding", store: store)
    private var hasCompletedOnboarding: Bool = false

    /// 0 = AppSelectionView, 1 = ScheduleSetupView.
    /// Writing this from any child view re-renders ContentView and swaps the screen.
    @AppStorage("onboardingStep", store: store)
    private var onboardingStep: Int = 0

    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
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
        .fullScreenCover(item: $router.pendingUnlockSource) { source in
            FrictionRouter(source: source)
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
