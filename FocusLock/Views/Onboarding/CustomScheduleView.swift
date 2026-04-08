import SwiftUI

/// Per-day schedule editor. Pushed from ScheduleSetupView via NavigationLink.
/// Changes are written back through the `days` binding shared with ScheduleSetupView.
struct CustomScheduleView: View {
    @Binding var days: [DayConfig]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            ForEach(days.indices, id: \.self) { i in
                Section {
                    Toggle(days[i].name, isOn: $days[i].isEnabled)
                    if days[i].isEnabled {
                        DatePicker("Start", selection: $days[i].startTime, displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: $days[i].endTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
        }
        .navigationTitle("Custom Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
