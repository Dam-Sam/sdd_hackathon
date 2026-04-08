import SwiftUI

// MARK: - Math Problem

private struct MathProblem {
    let display: String
    let answer: Int

    /// Generates a two-step arithmetic problem: (a × b) + c
    static func generate() -> MathProblem {
        let a = Int.random(in: 10...30)
        let b = Int.random(in: 2...9)
        let c = Int.random(in: 10...50)
        return MathProblem(display: "(\(a) × \(b)) + \(c)", answer: (a * b) + c)
    }
}

// MARK: - ExtremeView

/// Extreme friction tier. Presents a two-step math problem.
/// Incorrect answer shows an error banner and resets the input. Cancel keeps locked.
struct ExtremeView: View {
    let onCancel: () -> Void
    let onProceed: () -> Void

    @State private var problem = MathProblem.generate()
    @State private var answerText = ""
    @State private var showError = false
    @FocusState private var keyboardFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Solve to unlock")
                    .font(.title2.bold())
                Text("Prove you really want this.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(problem.display)
                .font(.system(size: 44, weight: .light, design: .monospaced))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            ZStack {
                if showError {
                    Text("Incorrect — try again")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(height: 24)
            .animation(.easeInOut(duration: 0.25), value: showError)

            TextField("Answer", text: $answerText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(.title2, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 180)
                .focused($keyboardFocused)

            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Submit") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(answerText.isEmpty)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)
        }
        .padding(32)
        .onAppear {
            keyboardFocused = true
        }
    }

    private func submit() {
        guard let answer = Int(answerText.trimmingCharacters(in: .whitespaces)) else {
            triggerError()
            return
        }
        if answer == problem.answer {
            onProceed()
        } else {
            triggerError()
        }
    }

    private func triggerError() {
        withAnimation { showError = true }
        answerText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showError = false }
        }
    }
}
