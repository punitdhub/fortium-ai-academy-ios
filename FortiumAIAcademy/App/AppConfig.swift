import Foundation

/// Central place for values you will want to change before launch.
enum AppConfig {
    static let appName = "Fortium AI Academy"

    /// Must match the product IDs you create in App Store Connect (and Products.storekit).
    static let monthlyProductID = "com.fortiumgroup.aiacademy.pro.monthly"
    static let yearlyProductID = "com.fortiumgroup.aiacademy.pro.yearly"

    // TODO: Replace with your hosted privacy policy before submitting to the App Store.
    static let privacyPolicyURL = URL(string: "https://punitdhub.github.io/business-portfolio/privacy/")!
    // Apple's standard EULA is acceptable for subscriptions unless you have your own terms.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let supportEmail = "support@fortiumgroup.com"

    /// Opens a new Claude chat. The prompt is always copied to the clipboard first,
    /// so the learner can paste it even if the pre-fill parameter is ignored.
    static func claudeURL(prefill prompt: String? = nil) -> URL {
        var components = URLComponents(string: "https://claude.ai/new")!
        if let prompt, !prompt.isEmpty {
            components.queryItems = [URLQueryItem(name: "q", value: prompt)]
        }
        return components.url!
    }

    static let disclaimer = "Fortium AI Academy is an independent educational app. It is not affiliated with, endorsed by, or sponsored by Anthropic. Claude is a trademark of Anthropic, PBC. Features and plan availability in Claude change over time and may differ from what you see."
}

enum SettingsKey {
    static let hasOnboarded = "hasOnboarded"
    static let userName = "userName"
    static let interests = "interests"
    static let largeText = "largeText"
    static let haptics = "haptics"
    static let celebrations = "celebrations"
    static let debugUnlockPro = "debugUnlockPro"
    static let remindersEnabled = "remindersEnabled"
    static let reminderHour = "reminderHour"
    static let reminderMinute = "reminderMinute"
}
