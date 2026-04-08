import SwiftUI

/// Moderate friction tier. Randomly presents one of: 10-second wait, phone rotations, or phone shakes.
/// No Done button — completion is automatic. Cancel keeps locked and dismisses.
/// Detection resets on sceneDidBecomeActive so users can't background-cheat.
struct ModerateView: View {
    let activityType: ModerateActivity
    let onCancel: () -> Void
    let onComplete: () -> Void

    @State private var motionService = MotionService()
    @State private var secondsRemaining: Int = 0
    @State private var totalSeconds: Int = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 40) {
            activityContent

            Button("Cancel") {
                motionService.stopDetection()
                onCancel()
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .padding(32)
        .onAppear {
            startActivity()
        }
        .onReceive(timer) { _ in
            guard case .wait = activityType, secondsRemaining > 0 else { return }
            secondsRemaining -= 1
            if secondsRemaining == 0 { onComplete() }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
        ) { _ in
            motionService.stopDetection()
            motionService.resetCounts()
            startActivity()
        }
    }

    @ViewBuilder
    private var activityContent: some View {
        switch activityType {

        case .wait(let seconds):
            VStack(spacing: 20) {
                Image(systemName: "timer")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("Wait \(seconds) seconds")
                    .font(.title2.bold())

                Text("\(secondsRemaining)s remaining")
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())

                ProgressView(
                    value: Double(totalSeconds - secondsRemaining),
                    total: Double(totalSeconds)
                )
                .progressViewStyle(.linear)
                .padding(.horizontal)
                .animation(.linear(duration: 1), value: secondsRemaining)
            }

        case .rotate(let count):
            VStack(spacing: 20) {
                Image(systemName: "arrow.circlepath")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(Double(motionService.rotationCount) * 360))
                    .animation(.easeInOut, value: motionService.rotationCount)

                Text("Rotate your phone")
                    .font(.title2.bold())

                Text("\(motionService.rotationCount) / \(count) full rotations")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())

                Text("Spin it in your hand like a wheel")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                #if targetEnvironment(simulator)
                Button("Complete (Simulator)") { onComplete() }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.top, 8)
                #endif
            }

        case .shake(let count):
            VStack(spacing: 20) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, value: motionService.shakeCount)

                Text("Shake your phone")
                    .font(.title2.bold())

                Text("\(motionService.shakeCount) / \(count) shakes")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())

                Text("Shake it hard enough to feel it")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                #if targetEnvironment(simulator)
                Button("Complete (Simulator)") { onComplete() }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.top, 8)
                #endif
            }
        }
    }

    private func startActivity() {
        switch activityType {
        case .wait(let seconds):
            totalSeconds = seconds
            secondsRemaining = seconds

        case .rotate(let count):
            motionService.startRotationDetection(target: count) {
                onComplete()
            }

        case .shake(let count):
            motionService.startShakeDetection(target: count) {
                onComplete()
            }
        }
    }
}
