import Foundation

/// Subscription purchase / restore. PROVISIONAL: StoreKit 2 replaces the mock once products are
/// set up in App Store Connect (needs the paid Apple Developer Program).
protocol PaywallPurchasing: Sendable {
    /// - Parameter planID: the selected `PaywallPlan.id` (StoreKit product), nil for a paywall
    ///   without plans.
    /// - Returns: `true` when the subscription (trial) started; `false` when the user cancelled.
    func purchase(planID: String?) async throws -> Bool
    /// - Returns: `true` when an active subscription was found.
    func restore() async throws -> Bool
}

/// UI-stage stand-in: purchase always succeeds, restore finds nothing.
struct MockPaywallPurchaseService: PaywallPurchasing {
    var delay: Duration = .milliseconds(700)

    func purchase(planID: String?) async throws -> Bool {
        try await Task.sleep(for: delay)
        return true
    }

    func restore() async throws -> Bool {
        try await Task.sleep(for: delay)
        return false
    }
}
