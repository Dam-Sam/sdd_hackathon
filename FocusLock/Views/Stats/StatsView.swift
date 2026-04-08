import SwiftUI

/// Stats tab. Full implementation in Step 10.
struct StatsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("Stats")
                    .font(.title2.bold())
                Text("Total time saved since install")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Stats")
        }
    }
}
