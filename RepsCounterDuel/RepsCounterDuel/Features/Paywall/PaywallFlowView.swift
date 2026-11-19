import SwiftUI

/// The shared paywall with its behaviour: ✕ and a started subscription both call `onDone`
/// (onboarding continues / Settings closes it); footer links open the legal sheets; Restore
/// reports the result.
struct PaywallFlowView: View {
    var content: PaywallContent = .onboardingTrial
    let purchases: any PaywallPurchasing
    let onDone: () -> Void

    @State private var isBusy = false
    @State private var legalDocument: LegalDocumentView.Document?
    @State private var alert: AlertMessage?

    private struct AlertMessage: Identifiable {
        let title: String
        let message: String
        var id: String { title + message }
    }

    var body: some View {
        PaywallView(
            content: content,
            isBusy: isBusy,
            onClose: onDone,
            onPurchase: { plan in purchase(plan) },
            onTerms: { legalDocument = .terms },
            onPrivacy: { legalDocument = .privacy },
            onRestore: restore
        )
        .sheet(item: $legalDocument) { LegalDocumentView(document: $0) }
        .alert(item: $alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }

    private func purchase(_ plan: PaywallPlan?) {
        run {
            if try await purchases.purchase(planID: plan?.id) { onDone() }
        }
    }

    private func restore() {
        run {
            alert = try await purchases.restore()
                ? AlertMessage(title: "Subscription restored", message: "Your subscription is active.")
                : AlertMessage(title: "Nothing to restore", message: "No active subscription was found for this Apple Account.")
        }
    }

    /// PROVISIONAL error copy: no Figma frame for purchase errors.
    private func run(_ work: @escaping () async throws -> Void) {
        guard !isBusy else { return }
        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                try await work()
            } catch {
                alert = AlertMessage(title: "Something went wrong", message: "Please try again.")
            }
        }
    }
}
