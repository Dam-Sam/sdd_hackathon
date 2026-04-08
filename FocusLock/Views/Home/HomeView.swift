import SwiftUI

/// Home tab. Full implementation in Step 5.
struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("Home")
                    .font(.title2.bold())
                Text("Countdown · Lock icon · Time saved · Unlock button")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("FocusLock")
        }
    }
}
