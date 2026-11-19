import CoreGraphics

/// A subscription option on a paywall with plans (FIGMA Go PRO paywall).
struct PaywallPlan: Identifiable, Hashable {
    let id: String
    let title: String
    /// e.g. "$29.99 year".
    let price: String
    /// Right-hand "$0.58 / per week"; nil hides it.
    let pricePerWeek: (amount: String, unit: String)?
    /// Green capsule on the card border, e.g. "1 Week Free".
    let badge: String?
    /// Primary button text while this plan is selected.
    let callToAction: String

    static func == (lhs: PaywallPlan, rhs: PaywallPlan) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Everything that differs between paywalls; `PaywallView` is the shared layout.
struct PaywallContent {
    enum TitlePosition { case aboveHero, belowHero }

    /// FIGMA: black bold title lines (no accent line on paywalls).
    let titleLines: [String]
    var titlePosition: TitlePosition = .aboveHero
    let heroImageName: String
    let heroAccessibilityLabel: String
    /// Max hero size in points (FIGMA: 176×364 onboarding, 157×326 Go PRO).
    var heroSize = CGSize(width: 176, height: 364)
    /// Selectable plans; empty → no plan list.
    var plans: [PaywallPlan] = []
    var defaultPlanID: String?
    /// Bold line above the button, e.g. "✅ No Payment Today".
    let highlight: String
    /// Gray text under the highlight; nil hides it.
    var details: String?
    /// Button text when there are no plans.
    let callToAction: String
}

extension PaywallContent {
    /// FIGMA onboarding paywall: 3-day free trial, then weekly.
    /// PROVISIONAL: prices and trials are hard-coded copy; with StoreKit they must come from the
    /// products (localized price) so the screen never disagrees with the App Store sheet.
    static let onboardingTrial = PaywallContent(
        titleLines: ["Train Smarter", "Free for 3 Days"],
        heroImageName: "PaywallTrialHero",
        heroAccessibilityLabel: "Live duel screen with pose tracking and a rep counter",
        highlight: "✅ No Payment Today",
        details: "Enjoy 3 days free, then just\n$6.99 per week. Cancel anytime",
        callToAction: "Start for $0.00"
    )

    /// FIGMA Go PRO paywall (Settings → Go PRO): yearly (1 week free, preselected) or weekly.
    /// PROVISIONAL copy and prices, see `onboardingTrial`. The weekly plan's button text is not in
    /// Figma.
    static let goPro = PaywallContent(
        titleLines: ["Go PRO, Keep Going"],
        titlePosition: .belowHero,
        heroImageName: "PaywallTrialHero",
        heroAccessibilityLabel: "Live duel screen with pose tracking and a rep counter",
        heroSize: CGSize(width: 157, height: 326),
        plans: [
            PaywallPlan(
                id: "pro.yearly",
                title: "Yearly Plan",
                price: "$29.99 year",
                pricePerWeek: ("$0.58", "per week"),
                badge: "1 Week Free",
                callToAction: "Start for $0.00"
            ),
            PaywallPlan(
                id: "pro.weekly",
                title: "Weekly Plan",
                price: "$7.99 / week",
                pricePerWeek: nil,
                badge: nil,
                callToAction: "Continue"
            ),
        ],
        defaultPlanID: "pro.yearly",
        highlight: "✅ Full Refund, No Questions Asked",
        details: nil,
        callToAction: "Continue"
    )
}
