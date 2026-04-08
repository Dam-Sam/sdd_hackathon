import CoreMotion
import Foundation
import Observation

/// Wraps CMMotionManager for rotation and shake detection.
/// Used only by ModerateView. Properties are observable so views auto-update on progress.
@Observable
final class MotionService {

    // MARK: - Observable progress

    private(set) var rotationCount: Int = 0
    private(set) var shakeCount: Int = 0

    // MARK: - Private state

    private let motionManager = CMMotionManager()
    private var cumulativeRotation: Double = 0
    private var lastShakeTime: Date = .distantPast

    // MARK: - Rotation detection

    /// Tracks cumulative Z-axis rotation. Every ±2π = one full rotation.
    /// Fires `onComplete` on the main actor when `target` rotations are reached.
    func startRotationDetection(target: Int, onComplete: @escaping @MainActor () -> Void) {
        guard motionManager.isDeviceMotionAvailable else { return }
        cumulativeRotation = 0
        rotationCount = 0
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.cumulativeRotation += motion.rotationRate.z * self.motionManager.deviceMotionUpdateInterval
            let newCount = Int(abs(self.cumulativeRotation) / (2 * .pi))
            if newCount > self.rotationCount {
                self.rotationCount = newCount
                if self.rotationCount >= target {
                    self.stopDetection()
                    Task { @MainActor in onComplete() }
                }
            }
        }
    }

    // MARK: - Shake detection

    /// Acceleration magnitude > 2.5g, 0.5s debounce between counted shakes.
    /// Fires `onComplete` on the main actor when `target` shakes are reached.
    func startShakeDetection(target: Int, onComplete: @escaping @MainActor () -> Void) {
        guard motionManager.isAccelerometerAvailable else { return }
        shakeCount = 0
        lastShakeTime = .distantPast
        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let magnitude = sqrt(
                data.acceleration.x * data.acceleration.x +
                data.acceleration.y * data.acceleration.y +
                data.acceleration.z * data.acceleration.z
            )
            let now = Date()
            if magnitude > 2.5 && now.timeIntervalSince(self.lastShakeTime) > 0.5 {
                self.lastShakeTime = now
                self.shakeCount += 1
                if self.shakeCount >= target {
                    self.stopDetection()
                    Task { @MainActor in onComplete() }
                }
            }
        }
    }

    // MARK: - Control

    func stopDetection() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    /// Called on sceneDidBecomeActive — resets progress so user can't background-cheat.
    func resetCounts() {
        cumulativeRotation = 0
        rotationCount = 0
        shakeCount = 0
        lastShakeTime = .distantPast
    }
}
