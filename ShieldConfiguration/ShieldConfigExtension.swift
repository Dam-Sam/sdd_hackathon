import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Returns the custom block screen UI when a user taps a blocked app.
/// Full implementation in Step 9.
class ShieldConfigExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Step 9 will add the URL-scheme primary button action.
        return ShieldConfiguration(
            title: .init(text: "Stay Focused", color: .label),
            subtitle: .init(text: "You're in a focus session", color: .secondaryLabel),
            primaryButtonLabel: .init(text: "Unlock", color: .white),
            primaryButtonBackgroundColor: .systemGreen
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }
}
