import SwiftUI

/// Schedule tab. Full implementation in Step 10.
struct ScheduleView: View {
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
            }
            .navigationTitle("Schedule")
        }
    }
}
