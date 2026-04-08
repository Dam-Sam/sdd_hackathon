import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    private static let store = UserDefaults(suiteName: "group.focuslock")

    /// Writing onboardingStep = 1 triggers ContentView to swap to ScheduleSetupView.
    @AppStorage("onboardingStep", store: store)
    private var onboardingStep: Int = 0

    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var frictionTier = "minimal"

    // DEBUG: FamilyActivityPicker doesn't function in the simulator — no Family Controls support.
    // Tap "Dev: Force-enable Continue" to test the rest of the flow without a real selection.
    // Remove this block (or flip to false) when testing on device with the entitlement.
    #if DEBUG
    @State private var debugForceEnabled = false
    private var canContinue: Bool { !selection.applications.isEmpty || debugForceEnabled }
    #else
    private var canContinue: Bool { !selection.applications.isEmpty }
    #endif

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Header
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                Text("Select Apps to Block")
                    .font(.title2.bold())
                Text("Choose which apps you want blocked during focus sessions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 56)
            .padding(.bottom, 36)

            // MARK: - App Picker Button
            // .familyActivityPicker modifier attaches the system sheet to this button.
            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Image(systemName: selection.applications.isEmpty ? "plus.circle" : "checkmark.circle.fill")
                        .foregroundStyle(selection.applications.isEmpty ? .blue : .green)
                    Text(selection.applications.isEmpty
                         ? "Choose Apps"
                         : "\(selection.applications.count) app\(selection.applications.count == 1 ? "" : "s") selected")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)

            // MARK: - Friction Tier Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Friction Level")
                    .font(.headline)
                    .padding(.horizontal)
                Text("How hard should it be to unlock apps during a session?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Picker("Friction tier", selection: $frictionTier) {
                    Text("Minimal").tag("minimal")
                    Text("Moderate").tag("moderate")
                    Text("Extreme").tag("extreme")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            .padding(.top, 32)

            Spacer()

            // MARK: - Debug Bypass
            #if DEBUG
            Button("Dev: Force-enable Continue (simulator)") {
                debugForceEnabled = true
            }
            .font(.caption)
            .foregroundStyle(.orange)
            .padding(.bottom, 8)
            #endif

            // MARK: - Continue Button
            Button {
                saveAndContinue()
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canContinue ? Color.blue : Color(.systemGray4))
                    .foregroundStyle(canContinue ? .white : Color(.systemGray2))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canContinue)
            .animation(.easeInOut(duration: 0.15), value: canContinue)
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Save

    private func saveAndContinue() {
        // Encode FamilyActivitySelection as Data using PropertyListEncoder.
        // PropertyListEncoder is Apple's recommended encoder for FamilyActivitySelection.
        if let encoded = try? PropertyListEncoder().encode(selection) {
            SharedStore.shared.blockedApps = encoded
        }
        SharedStore.shared.frictionTier = frictionTier

        // Writing onboardingStep triggers ContentView's @AppStorage to re-render,
        // swapping this view out for ScheduleSetupView.
        SharedStore.shared.onboardingStep = 1
    }
}
