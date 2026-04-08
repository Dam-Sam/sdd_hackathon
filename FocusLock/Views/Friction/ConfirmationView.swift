import SwiftUI

/// Universal confirmation popup. Shown after completing any friction activity.
/// "Stay Focused" dismisses and keeps locked. "Yes" will call BlockingService (wired in Step 7).
struct ConfirmationView: View {
    let source: UnlockSource
    let onDismiss: () -> Void   // Called by both buttons; BlockingService call added in Step 7

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 72))
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Text("Are you sure you want to give your time away?")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text("There is only \(timeRemaining) left until your focus session ends.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Button("Stay Focused") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Yes") {
                    // BlockingService.unlockApp(source: source) wired in Step 7.
                    print("[ConfirmationView] Unlock confirmed — source: \(source). BlockingService wired in Step 7.")
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
        }
        .padding(32)
    }

    private var timeRemaining: String {
        guard let end = SharedStore.shared.sessionEndTime else { return "your session" }
        let remaining = max(0, Int(end.timeIntervalSinceNow))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
