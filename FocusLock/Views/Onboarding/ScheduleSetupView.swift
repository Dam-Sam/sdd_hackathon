import SwiftUI

/// Schedule setup — second step of onboarding.
/// Implemented in Step 4.
struct ScheduleSetupView: View {
    private static let store = UserDefaults(suiteName: "group.focuslock")

    @AppStorage("hasCompletedOnboarding", store: store)
    private var hasCompletedOnboarding: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text("Set Your Schedule")
                .font(.title2.bold())
            Text("(Built in Step 4)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // DEV SHORTCUT — removed when Step 4 is complete
            Button("Skip to Tab Bar (Dev)") {
                SharedStore.shared.hasCompletedOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }
}
