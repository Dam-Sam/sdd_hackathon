import SwiftUI
import SwiftData

struct ScheduleView: View {
    private static let store = UserDefaults(suiteName: "group.com.sddhackathon.focuslock")

    /// Disables edit buttons during an active session.
    @AppStorage("isSessionActive", store: store)
    private var isSessionActive: Bool = false

    @Query private var schedules: [Schedule]

    @State private var showChangeTime = false
    @State private var showApps = false

    private var schedule: Schedule? { schedules.first }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Day rows
                Section("Your Schedule") {
                    if let schedule = schedule {
                        let sortedDays = schedule.days.sorted { $0.weekday < $1.weekday }
                        ForEach(sortedDays, id: \.weekday) { day in
                            HStack {
                                Text(day.weekdayName)
                                    .foregroundStyle(day.isEnabled ? .primary : .secondary)
                                Spacer()
                                if day.isEnabled {
                                    Text(timeRange(day))
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                } else {
                                    Text("Off")
                                        .foregroundStyle(.tertiary)
                                        .font(.subheadline)
                                }
                            }
                            .opacity(day.isEnabled ? 1.0 : 0.5)
                        }
                    } else {
                        Text("No schedule configured yet.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }

                // MARK: - Edit buttons
                Section {
                    Button("Change Time") {
                        showChangeTime = true
                    }
                    .disabled(isSessionActive)

                    Button("Apps") {
                        showApps = true
                    }
                    .disabled(isSessionActive)
                }

                // MARK: - Session gate notice
                if isSessionActive {
                    Section {
                        Label("Editing disabled during an active session", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Schedule")
            .sheet(isPresented: $showChangeTime) {
                ScheduleSetupView()
            }
            .sheet(isPresented: $showApps) {
                AppSelectionView()
            }
        }
    }

    // MARK: - Helpers

    private func timeRange(_ day: DaySchedule) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: day.startTime)) – \(formatter.string(from: day.endTime))"
    }
}
