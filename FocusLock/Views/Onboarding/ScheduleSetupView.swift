import SwiftUI
import SwiftData
import DeviceActivity

// MARK: - DayConfig

/// In-memory representation of one day's schedule, used while the user is editing.
/// Converted to SwiftData `DaySchedule` objects on Finish.
struct DayConfig: Identifiable {
    /// 1 = Monday … 7 = Sunday (ISO 8601 convention).
    let id: Int
    var isEnabled: Bool
    var startTime: Date
    var endTime: Date

    var name: String {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][id - 1]
    }
}

// MARK: - ScheduleSetupView

/// Second step of onboarding. Lets the user configure their blocking schedule.
/// Also reused from ScheduleView's "Change Time" button (Step 10).
struct ScheduleSetupView: View {
    @Environment(\.modelContext) private var modelContext

    // Default times
    private static let nineAM = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    private static let fivePM = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!

    /// Per-day configuration shared with CustomScheduleView.
    @State private var days: [DayConfig] = (1...7).map { weekday in
        DayConfig(
            id: weekday,
            isEnabled: weekday <= 5,
            startTime: nineAM,
            endTime: fivePM
        )
    }

    /// Default-view time pickers — kept in sync with all enabled days.
    @State private var defaultStart: Date = nineAM
    @State private var defaultEnd: Date = fivePM

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Default Schedule") {
                    Toggle("Every weekday (Mon–Fri)", isOn: weekdaysBinding)
                    DatePicker("Start time", selection: $defaultStart, displayedComponents: .hourAndMinute)
                        .onChange(of: defaultStart) { _, new in
                            syncTimes(start: new, end: defaultEnd)
                        }
                    DatePicker("End time", selection: $defaultEnd, displayedComponents: .hourAndMinute)
                        .onChange(of: defaultEnd) { _, new in
                            syncTimes(start: defaultStart, end: new)
                        }
                    Toggle("Include weekends", isOn: weekendsBinding)
                }

                Section {
                    NavigationLink("Custom schedule") {
                        CustomScheduleView(days: $days)
                    }
                }

                Section {
                    Button("Finish") {
                        saveAndFinish()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .fontWeight(.semibold)
                }
            }
            .navigationTitle("Set Your Schedule")
        }
    }

    // MARK: Bindings

    private var weekdaysBinding: Binding<Bool> {
        Binding(
            get: { days.prefix(5).allSatisfy(\.isEnabled) },
            set: { enabled in for i in 0..<5 { days[i].isEnabled = enabled } }
        )
    }

    private var weekendsBinding: Binding<Bool> {
        Binding(
            get: { days[5].isEnabled || days[6].isEnabled },
            set: { enabled in
                days[5].isEnabled = enabled
                days[6].isEnabled = enabled
            }
        )
    }

    // MARK: Helpers

    /// Applies new start/end times to all currently-enabled days.
    private func syncTimes(start: Date, end: Date) {
        for i in days.indices where days[i].isEnabled {
            days[i].startTime = start
            days[i].endTime = end
        }
    }

    /// Saves the schedule to SwiftData, registers DeviceActivity monitoring, and marks onboarding complete.
    private func saveAndFinish() {
        // Remove any existing schedules (e.g. if user revisits from settings).
        let descriptor = FetchDescriptor<Schedule>()
        if let existing = try? modelContext.fetch(descriptor) {
            for schedule in existing { modelContext.delete(schedule) }
        }

        // Build and insert new Schedule with per-day entries.
        let daySchedules = days.map { config in
            DaySchedule(
                weekday: config.id,
                isEnabled: config.isEnabled,
                startTime: config.startTime,
                endTime: config.endTime
            )
        }
        let schedule = Schedule(days: daySchedules)
        modelContext.insert(schedule)

        // Store scheduled end times so MonitorExtension can reconstruct sessionEndTime.
        let endTimes = days.filter(\.isEnabled).reduce(into: [Int: Date]()) { dict, day in
            dict[day.id] = day.endTime
        }
        SharedStore.shared.scheduledEndTimes = endTimes

        // Register DeviceActivity monitoring for each enabled day.
        registerDeviceActivitySchedules()

        SharedStore.shared.hasCompletedOnboarding = true
    }

    /// Registers one DeviceActivitySchedule per enabled day.
    /// The weekday component restricts each activity to its specific day of the week.
    private func registerDeviceActivitySchedules() {
        let center = DeviceActivityCenter()

        // Clear any previously registered focus sessions before re-registering.
        let allFocusActivities = (1...7).map { DeviceActivityName("focus-session-\($0)") }
        center.stopMonitoring(allFocusActivities)

        for day in days where day.isEnabled {
            var startComponents = Calendar.current.dateComponents([.hour, .minute], from: day.startTime)
            var endComponents = Calendar.current.dateComponents([.hour, .minute], from: day.endTime)

            // Convert our 1=Mon…7=Sun to Gregorian weekday (1=Sun, 2=Mon…7=Sat).
            let gregorianWeekday = (day.id % 7) + 1
            startComponents.weekday = gregorianWeekday
            endComponents.weekday = gregorianWeekday

            let activitySchedule = DeviceActivitySchedule(
                intervalStart: startComponents,
                intervalEnd: endComponents,
                repeats: true
            )

            do {
                try center.startMonitoring(
                    DeviceActivityName("focus-session-\(day.id)"),
                    during: activitySchedule
                )
            } catch {
                print("[ScheduleSetupView] Failed to register day \(day.id): \(error)")
            }
        }
    }
}
