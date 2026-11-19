import SwiftUI
import DesignSystem

/// PROVISIONAL stand-in for onboarding steps whose Figma frames have not been provided yet,
/// so the whole flow can already be walked through in the simulator.
struct OnboardingPlaceholderStepView: View {
    let title: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: RCSpacing.m) {
            Spacer()
            Text(title)
                .font(RCFont.onboardingTitle)
                .multilineTextAlignment(.center)
            Text("Waiting for the design of this step")
                .font(RCFont.onboardingSubtitle)
                .foregroundStyle(RCColor.textSecondary)
            Spacer()
            Button("Continue", action: onContinue)
                .buttonStyle(.rcPrimaryLarge)
                .padding(.bottom, RCSpacing.xxs)
        }
        .padding(.horizontal, RCSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}
