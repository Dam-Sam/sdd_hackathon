import SwiftUI
import ManagedSettings

// MARK: - Unlock Source

/// Where the unlock request originated. Determines which apps are unlocked in BlockingService.
enum UnlockSource: Identifiable {
    case homeScreen                         // unlocks ALL blocked apps
    case shield(bundleID: String)           // unlocks one app (URL scheme / manual testing path)
    case shieldToken(ApplicationToken)      // unlocks one app (real shield flow; surgical)

    var id: String {
        switch self {
        case .homeScreen:               return "homeScreen"
        case .shield(let bundleID):     return "shield-\(bundleID)"
        case .shieldToken(let token):   return "shieldToken-\(token.hashValue)"
        }
    }
}

// MARK: - Moderate Activity Type

/// The specific activity randomly chosen for the Moderate tier.
enum ModerateActivity {
    case wait(seconds: Int)
    case rotate(count: Int)
    case shake(count: Int)
}

// MARK: - Internal Activity Selection

private enum FrictionActivity {
    case minimal
    case moderate(ModerateActivity)
    case extreme
}

// MARK: - FrictionRouter

/// Entry point for all unlock flows. Reads frictionTier, picks a random activity,
/// presents the correct view, then routes to ConfirmationView on completion.
/// Presented as a fullScreenCover by ContentView via AppRouter.pendingUnlockSource.
struct FrictionRouter: View {
    let source: UnlockSource

    @Environment(\.dismiss) private var dismiss
    @State private var activity: FrictionActivity
    @State private var activityCompleted = false

    init(source: UnlockSource) {
        self.source = source
        _activity = State(initialValue: Self.pickActivity())
    }

    var body: some View {
        if activityCompleted {
            ConfirmationView(source: source) {
                dismiss()
            }
        } else {
            activityView
        }
    }

    @ViewBuilder
    private var activityView: some View {
        switch activity {
        case .minimal:
            MinimalView(
                onKeepLocked: { dismiss() },
                onProceed: { activityCompleted = true }
            )
        case .moderate(let moderateActivity):
            ModerateView(
                activityType: moderateActivity,
                onCancel: { dismiss() },
                onComplete: { activityCompleted = true }
            )
        case .extreme:
            ExtremeView(
                onCancel: { dismiss() },
                onProceed: { activityCompleted = true }
            )
        }
    }

    // MARK: - Activity selection

    private static func pickActivity() -> FrictionActivity {
        switch SharedStore.shared.frictionTier {
        case "moderate":
            let roll = Int.random(in: 0...2)
            switch roll {
            case 0:  return .moderate(.wait(seconds: 10))
            case 1:  return .moderate(.rotate(count: Int.random(in: 3...5)))
            default: return .moderate(.shake(count: Int.random(in: 2...4)))
            }
        case "extreme":
            return .extreme
        default: // "minimal"
            return .minimal
        }
    }
}
