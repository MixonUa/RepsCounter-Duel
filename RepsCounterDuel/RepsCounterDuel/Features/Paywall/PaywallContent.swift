/// Everything that differs between paywalls; `PaywallView` is the shared layout.
struct PaywallContent {
    /// FIGMA: black bold title lines (no accent line on the paywall).
    let titleLines: [String]
    let heroImageName: String
    let heroAccessibilityLabel: String
    /// Bold line above the details, e.g. "✅ No Payment Today".
    let highlight: String
    let details: String
    let callToAction: String
}

extension PaywallContent {
    /// FIGMA onboarding paywall: 3-day free trial, then weekly.
    /// PROVISIONAL: price and trial length are hard-coded copy; with StoreKit they must come from
    /// the product (localized price) so the screen never disagrees with the App Store sheet.
    static let onboardingTrial = PaywallContent(
        titleLines: ["Train Smarter", "Free for 3 Days"],
        heroImageName: "PaywallTrialHero",
        heroAccessibilityLabel: "Live duel screen with pose tracking and a rep counter",
        highlight: "✅ No Payment Today",
        details: "Enjoy 3 days free, then just\n$6.99 per week. Cancel anytime",
        callToAction: "Start for $0.00"
    )
}
