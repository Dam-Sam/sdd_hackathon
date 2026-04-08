import SwiftUI
import FamilyControls

/// Full-screen gate shown when Family Controls authorization is denied.
/// Blocks all access to onboarding and the main tab bar until access is granted.
struct AuthorizationGateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Text("Screen Time Access Required")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("FocusLock needs Screen Time access to block apps")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Grant Access") {
                Task { await requestAuthorization() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
    }

    private func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            SharedStore.shared.authorizationStatus = "authorized"
        } catch {
            SharedStore.shared.authorizationStatus = "denied"
        }
    }
}
