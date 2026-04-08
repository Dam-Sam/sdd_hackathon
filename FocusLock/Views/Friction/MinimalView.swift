import SwiftUI

/// Minimal friction tier. Shows a random cat image and a guilt-trip message.
/// "OK" keeps locked and dismisses. "No" proceeds to ConfirmationView.
struct MinimalView: View {
    let onKeepLocked: () -> Void
    let onProceed: () -> Void

    private static let messages = [
        "Is this really how you want to spend your time?",
        "Cal Newport wouldn't approve.",
        "Your future self is watching.",
        "This moment won't come back.",
        "Every distraction costs more than it seems.",
        "What would you be building instead?",
        "Your focus is your most valuable asset.",
        "Deep work disappears one distraction at a time.",
    ]

    @State private var message = messages.randomElement()!
    @State private var catImageName = "cat_\(Int.random(in: 1...10))"

    var body: some View {
        VStack(spacing: 24) {
            Text("Hold on...")
                .font(.title2.bold())

            catImage
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 8)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Button("OK") {
                    onKeepLocked()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("No") {
                    onProceed()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
        }
        .padding(32)
    }

    /// Shows a bundled cat image if available; falls back to an SF Symbol placeholder.
    /// Add cat images to Assets.xcassets/CatImages/ named cat_1 through cat_10.
    @ViewBuilder
    private var catImage: some View {
        if UIImage(named: catImageName) != nil {
            Image(catImageName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
                VStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.secondary)
                    Text("Add cat images to Assets.xcassets/CatImages/")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
}
