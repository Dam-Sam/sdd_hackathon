import SwiftUI

/// Schedule tab. Full implementation in Step 10.
struct ScheduleView: View {
    private static let store = UserDefaults(suiteName: "group.focuslock")

    // Session editing gate — all edit controls are .disabled(isSessionActive).
    @AppStorage("isSessionActive", store: store)
    private var isSessionActive: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "calendar")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("Schedule")
                    .font(.title2.bold())
                Text("7-day schedule · Change Time · Apps buttons")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if isSessionActive {
                    Label("Editing disabled during an active session", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle("Schedule")
        }
    }
}
