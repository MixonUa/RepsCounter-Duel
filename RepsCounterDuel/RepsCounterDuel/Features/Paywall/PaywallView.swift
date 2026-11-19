import SwiftUI
import DesignSystem

/// FIGMA paywall layout, reusable for any paywall: close button, title, hero image, highlight,
/// details, primary button and footer links (Terms of Use · Privacy Policy · Restore).
/// All behaviour comes from the caller.
struct PaywallView: View {
    let content: PaywallContent
    var isBusy = false
    let onClose: () -> Void
    let onPurchase: () -> Void
    let onTerms: () -> Void
    let onPrivacy: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            closeButton

            VStack(spacing: -1) {
                ForEach(content.titleLines, id: \.self) { Text($0) }
            }
            .font(RCFont.onboardingTitle)
            .foregroundStyle(RCColor.textPrimary)
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .padding(.top, RCSpacing.s)

            Image(content.heroImageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 176, maxHeight: 364)
                .padding(.top, RCSpacing.xxl + RCSpacing.xs)
                .accessibilityLabel(content.heroAccessibilityLabel)
                .layoutPriority(-1)

            VStack(spacing: RCSpacing.xxs) {
                Text(content.highlight)
                    .font(.system(size: 21, weight: .semibold))
                    .tracking(-0.6)
                    .foregroundStyle(RCColor.textPrimary)
                Text(content.details)
                    .font(RCFont.onboardingSubtitle)
                    .tracking(-0.7)
                    .foregroundStyle(RCColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            .padding(.top, RCSpacing.xxl)
            .padding(.horizontal, RCSpacing.m)

            Button(action: onPurchase) {
                if isBusy {
                    ProgressView().tint(.white)
                } else {
                    Text(content.callToAction)
                }
            }
            .buttonStyle(.rcPrimaryLarge)
            .disabled(isBusy)
            .padding(.horizontal, RCSpacing.xl)
            .padding(.top, RCSpacing.s)

            footer
                // FIGMA: the links sit partly in the bottom safe area.
                .padding(.bottom, -9)
        }
        .frame(maxWidth: .infinity)
        .background(RCColor.background.ignoresSafeArea())
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    /// FIGMA: plain black ✕ in the top-right corner.
    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(RCColor.textPrimary)
                    .frame(width: RCSize.minTouchTarget, height: RCSize.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
            .accessibilityLabel("Close")
        }
        .padding(.trailing, RCSpacing.l - 6)
        .padding(.top, 3)
    }

    /// FIGMA: gray links separated by dots; each is a real button (44 pt tall tap area).
    private var footer: some View {
        HStack(spacing: 0) {
            footerLink("Terms of Use", action: onTerms)
            separator
            footerLink("Privacy Policy", action: onPrivacy)
            separator
            footerLink("Restore", action: onRestore)
        }
        .disabled(isBusy)
    }

    private func footerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 13))
            .tracking(0.3)
            .foregroundStyle(RCColor.textSecondary)
            .padding(.horizontal, RCSpacing.xxs)
            .frame(minHeight: RCSize.minTouchTarget)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
    }

    private var separator: some View {
        Text("·")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(RCColor.textSecondary)
            .padding(.horizontal, RCSpacing.s)
            .accessibilityHidden(true)
    }
}

#Preview {
    PaywallView(
        content: .onboardingTrial,
        onClose: {}, onPurchase: {}, onTerms: {}, onPrivacy: {}, onRestore: {}
    )
}
