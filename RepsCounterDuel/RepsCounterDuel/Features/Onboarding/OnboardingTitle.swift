import SwiftUI
import DesignSystem

/// FIGMA: two-line onboarding title — first line black, second line accent blue.
struct OnboardingTitle: View {
    private let line: String
    private let accent: String
    private let accentColor: Color

    /// `accentColor` lets a screen keep both lines black (e.g. "Camera is Restricted").
    init(_ line: String, accent: String, accentColor: Color = RCColor.accent) {
        self.line = line
        self.accent = accent
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: -1) {
            Text(line)
                .foregroundStyle(RCColor.textPrimary)
            Text(accent)
                .foregroundStyle(accentColor)
        }
        .font(RCFont.onboardingTitle)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
