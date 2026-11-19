import SwiftUI
import DesignSystem

/// FIGMA paywall layout, reusable for any paywall: close button, title above or below the hero
/// image, optional plan cards, highlight, optional details, primary button and footer links
/// (Terms of Use · Privacy Policy · Restore). All behaviour comes from the caller.
struct PaywallView: View {
    let content: PaywallContent
    var isBusy = false
    let onClose: () -> Void
    /// Called with the selected plan (nil when the paywall has no plans).
    let onPurchase: (PaywallPlan?) -> Void
    let onTerms: () -> Void
    let onPrivacy: () -> Void
    let onRestore: () -> Void

    @State private var selectedPlanID: String?

    private var selectedPlan: PaywallPlan? {
        content.plans.first { $0.id == (selectedPlanID ?? content.defaultPlanID) } ?? content.plans.first
    }

    var body: some View {
        VStack(spacing: 0) {
            closeButton

            // The flexible gap keeps the hero at the top and the button + links at the bottom on
            // any screen height (and lets the gray background fill a full-screen cover).
            if content.titlePosition == .aboveHero {
                title.padding(.top, RCSpacing.s)
                hero.padding(.top, RCSpacing.xxl + RCSpacing.xs)
                Spacer(minLength: 0)
            } else {
                // FIGMA Go PRO: the phone starts right under the ✕ row.
                hero.padding(.top, -RCSpacing.xxs)
                Spacer(minLength: 0)
                title.padding(.top, RCSpacing.xxl)
            }

            if !content.plans.isEmpty {
                VStack(spacing: RCSpacing.s) {
                    ForEach(content.plans) { plan in
                        PaywallPlanCard(plan: plan, isSelected: plan == selectedPlan) {
                            withAnimation(.snappy) { selectedPlanID = plan.id }
                        }
                    }
                }
                .padding(.horizontal, RCSpacing.xl)
                .padding(.top, RCSpacing.xl)
            }

            VStack(spacing: RCSpacing.xxs) {
                Text(content.highlight)
                    .font(.system(size: 21, weight: .semibold))
                    .tracking(-0.6)
                    .foregroundStyle(RCColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let details = content.details {
                    Text(details)
                        .font(RCFont.onboardingSubtitle)
                        .tracking(-0.7)
                        .foregroundStyle(RCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, content.plans.isEmpty ? RCSpacing.xxl : RCSpacing.m)
            .padding(.horizontal, RCSpacing.m)

            Button { onPurchase(selectedPlan) } label: {
                if isBusy {
                    ProgressView().tint(.white)
                } else {
                    Text(selectedPlan?.callToAction ?? content.callToAction)
                        .contentTransition(.opacity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RCColor.background.ignoresSafeArea())
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var title: some View {
        VStack(spacing: -1) {
            ForEach(content.titleLines, id: \.self) { Text($0) }
        }
        .font(RCFont.onboardingTitle)
        .foregroundStyle(RCColor.textPrimary)
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, RCSpacing.m)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var hero: some View {
        Image(content.heroImageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: content.heroSize.width, maxHeight: content.heroSize.height)
            .accessibilityLabel(content.heroAccessibilityLabel)
            .layoutPriority(-1)
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

/// FIGMA plan card (63 pt capsule): selected — light-blue fill, accent border and a filled accent
/// check; unselected — light fill, white border, empty gray circle. Optional green badge on the
/// top border and a per-week price on the right.
private struct PaywallPlanCard: View {
    let plan: PaywallPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: RCSpacing.m) {
                ZStack {
                    Circle().fill(isSelected ? RCColor.accent : RCColor.pendingFill)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 0) {
                    Text(plan.title)
                        .font(.system(size: 20, weight: .semibold))
                        .tracking(-0.4)
                        .foregroundStyle(RCColor.textPrimary)
                    Text(plan.price)
                        .font(.system(size: 17))
                        .foregroundStyle(isSelected ? RCColor.textPrimary : RCColor.textSecondary)
                }
                Spacer(minLength: RCSpacing.xs)
                if let perWeek = plan.pricePerWeek {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(perWeek.amount)
                            .font(.system(size: 17, weight: .medium))
                        Text(perWeek.unit)
                            .font(.system(size: 15))
                    }
                    .foregroundStyle(RCColor.textPrimary)
                    .padding(.top, RCSpacing.xs)
                }
            }
            .padding(.leading, RCSpacing.m)
            .padding(.trailing, RCSpacing.l)
            .frame(maxWidth: .infinity, minHeight: 63)
            .background(isSelected ? RCColor.avatarFill : RCColor.settingsGroup, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? RCColor.accent : .white, lineWidth: 2))
            .overlay(alignment: .topTrailing) {
                if let badge = plan.badge {
                    Text(badge)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, RCSpacing.s)
                        .frame(height: 22)
                        .background(RCColor.win, in: Capsule())
                        .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
                        .offset(x: -RCSpacing.l + 4, y: -11)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Onboarding") {
    PaywallView(
        content: .onboardingTrial,
        onClose: {}, onPurchase: { _ in }, onTerms: {}, onPrivacy: {}, onRestore: {}
    )
}

#Preview("Go PRO") {
    PaywallView(
        content: .goPro,
        onClose: {}, onPurchase: { _ in }, onTerms: {}, onPrivacy: {}, onRestore: {}
    )
}
