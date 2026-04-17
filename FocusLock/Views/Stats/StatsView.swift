import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var sessions: [SessionLog]

    /// Sum of (sessionDuration - totalUnlockMinutes) across all completed sessions.
    private var totalMinutesSaved: Int {
        sessions.reduce(0) { $0 + $1.timeSaved }
    }

    private var formattedTotal: String {
        let hours = totalMinutesSaved / 60
        let minutes = totalMinutesSaved % 60
        if hours == 0 {
            return "\(minutes)m"
        } else if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Time Saved")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(formattedTotal)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())
                }

                Text("Total time reclaimed from distraction\nsince you installed FocusLock.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
            .navigationTitle("Stats")
        }
    }
}
