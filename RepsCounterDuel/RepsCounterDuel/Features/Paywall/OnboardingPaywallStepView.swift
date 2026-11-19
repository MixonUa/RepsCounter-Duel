import SwiftUI

/// Onboarding use of the shared paywall: ✕ and a started trial both continue onboarding;
/// footer links open the legal sheets; Restore reports the result.
struct OnboardingPaywallStepView: View {
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
            content: .onboardingTrial,
            isBusy: isBusy,
            onClose: onDone,
            onPurchase: purchase,
            onTerms: { legalDocument = .terms },
            onPrivacy: { legalDocument = .privacy },
            onRestore: restore
        )
        .sheet(item: $legalDocument) { LegalDocumentView(document: $0) }
        .alert(item: $alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }

    private func purchase() {
        run {
            if try await purchases.purchase() { onDone() }
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
