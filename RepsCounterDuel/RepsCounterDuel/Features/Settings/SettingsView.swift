import SwiftUI
import StoreKit
import DesignSystem

/// FIGMA Settings (full screen, ✕ in the top-right): PRO card → shared paywall; General
/// (Rep sound, First day of the week); Support (Rate the app, Share with friends);
/// More (Contact us, Privacy Policy, Terms of Service).
struct SettingsView: View {
    var purchases: any PaywallPurchasing = MockPaywallPurchaseService()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    @AppStorage(LocalStorageKeys.repSound) private var repSound = true
    @AppStorage(LocalStorageKeys.firstWeekday) private var firstWeekday = 2

    @State private var isPaywallPresented = false
    @State private var legalDocument: LegalDocumentView.Document?
    @State private var isContactPlaceholderPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                proCard
                    .padding(.top, RCSpacing.l + 2)

                section("General")
                group {
                    row(icon: "speaker.wave.2.fill", title: "Rep sound") {
                        RCSegmentedToggle([(true, "On"), (false, "Off")], selection: $repSound)
                    }
                    divider
                    row(icon: "calendar", title: "First day of the week") {
                        RCSegmentedToggle([(2, "Mon"), (1, "Sun")], selection: $firstWeekday)
                    }
                }

                section("Support")
                group {
                    linkRow(icon: "heart.fill", title: "Rate the app") { requestReview() }
                    divider
                    ShareLink(item: shareItem) {
                        rowContent(icon: "square.and.arrow.up.fill", title: "Share with friends") { arrow }
                    }
                    .buttonStyle(.plain)
                }

                section("More")
                group {
                    linkRow(icon: "envelope.fill", title: "Contact us", action: contactUs)
                    divider
                    linkRow(icon: "checkmark.shield.fill", title: "Privacy Policy") { legalDocument = .privacy }
                    divider
                    linkRow(icon: "doc.text.fill", title: "Terms of Service") { legalDocument = .terms }
                }
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.bottom, RCSpacing.xxl)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .background(RCColor.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $isPaywallPresented) {
            PaywallFlowView(content: .goPro, purchases: purchases, onDone: { isPaywallPresented = false })
        }
        .sheet(item: $legalDocument) { LegalDocumentView(document: $0) }
        .sheet(isPresented: $isContactPlaceholderPresented) {
            PlaceholderSheet(title: "Contact us", message: "The support e-mail will be added before release.")
        }
    }

    // MARK: - Header

    /// FIGMA: centered "Settings", glass ✕ on the right.
    private var header: some View {
        ZStack {
            Text("Settings")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(RCColor.textPrimary)
                        .frame(width: RCSize.backButton, height: RCSize.backButton)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .rcGlass(in: Circle(), interactive: true)
                .accessibilityLabel("Close")
            }
            .padding(.trailing, RCSpacing.m)
        }
        .padding(.top, RCSpacing.xxs)
        .padding(.bottom, RCSpacing.xs)
        .background(RCColor.background)
    }

    // MARK: - PRO

    /// FIGMA: deep-navy card with a diagonal light streak. Figma reads "Rep Counter PRO";
    /// the app name is "Reps Counter".
    private var proCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Reps Counter PRO")
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Endless duels, every leaderboard\nand deeper insights")
                .font(.system(size: 16))
                .tracking(-0.3)
                .foregroundStyle(.white.opacity(0.92))
                .padding(.top, RCSpacing.xs)
            Button("Go PRO") { isPaywallPresented = true }
                .buttonStyle(.rcPrimary)
                .padding(.top, RCSpacing.l)
        }
        .padding(.horizontal, RCSpacing.m)
        .padding(.top, RCSpacing.l)
        .padding(.bottom, RCSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                RadialGradient(
                    colors: [RCColor.proCardBase, RCColor.proCardEdge],
                    center: .center, startRadius: 20, endRadius: 260
                )
                // Diagonal light streak from the top-right to the bottom-left.
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.36),
                        .init(color: RCColor.proCardStreak.opacity(0.7), location: 0.5),
                        .init(color: .clear, location: 0.6),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blur(radius: 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    // MARK: - Rows

    private func section(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .tracking(-0.4)
            .foregroundStyle(RCColor.sectionTitle)
            .padding(.leading, RCSpacing.m)
            .padding(.top, RCSpacing.xxl + RCSpacing.xs)
            .padding(.bottom, RCSpacing.s)
            .accessibilityAddTraits(.isHeader)
    }

    private func group<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0, content: content)
            .background(RCColor.settingsGroup, in: RoundedRectangle(cornerRadius: RCRadius.card + 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RCRadius.card + 4, style: .continuous)
                    .strokeBorder(.white, lineWidth: 1)
            )
    }

    private var divider: some View {
        Rectangle()
            .fill(RCColor.cardDivider)
            .frame(height: 1)
            .padding(.horizontal, RCSpacing.m)
    }

    private var arrow: some View {
        Image(systemName: "arrow.up.right")
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(RCColor.rowArrow)
    }

    private func row<Trailing: View>(icon: String, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        rowContent(icon: icon, title: title, trailing: trailing)
    }

    private func linkRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowContent(icon: icon, title: title) { arrow }
        }
        .buttonStyle(.plain)
    }

    /// FIGMA: 60 pt row — accent icon, title, trailing control.
    private func rowContent<Trailing: View>(icon: String, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: RCSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(RCColor.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 17))
                .tracking(-0.4)
                .foregroundStyle(RCColor.textPrimary)
            Spacer(minLength: RCSpacing.xs)
            trailing()
        }
        .padding(.horizontal, RCSpacing.m)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private var shareItem: String {
        [AppLinks.shareMessage, AppLinks.appStoreURL].compactMap { $0 }.joined(separator: " ")
    }

    private func contactUs() {
        if let email = AppLinks.supportEmail, let url = URL(string: "mailto:\(email)") {
            openURL(url)
        } else {
            isContactPlaceholderPresented = true
        }
    }
}

#Preview {
    SettingsView()
}
