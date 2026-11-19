import SwiftUI
import DesignSystem

/// FIGMA: two-line onboarding title — first line black, second line accent blue.
struct OnboardingTitle: View {
    private let line: String
    private let accent: String

    init(_ line: String, accent: String) {
        self.line = line
        self.accent = accent
    }

    var body: some View {
        VStack(spacing: -1) {
            Text(line)
                .foregroundStyle(RCColor.textPrimary)
            Text(accent)
                .foregroundStyle(RCColor.accent)
        }
        .font(RCFont.onboardingTitle)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
