import SwiftUI

/// Content of one intro / explanation slide (FIGMA layout: two-line title, subtitle,
/// illustration, optional tips card).
struct IntroSlide: Identifiable {
    enum Illustration {
        /// Image inside camera-viewfinder corners (slide 1).
        case viewfinder(imageName: String)
        /// Standalone image of a fixed width in points (slide 2).
        case plain(imageName: String, width: CGFloat)
    }

    struct Tip: Identifiable {
        let systemImage: String
        let text: String
        var id: String { text }
    }

    let id: Int
    let titleLine: String
    let accentTitleLine: String
    let subtitle: String
    let illustration: Illustration
    let imageAccessibilityLabel: String
    let tips: [Tip]
}

extension IntroSlide {
    /// FIGMA: onboarding intro slide 1.
    static let introPushUp = IntroSlide(
        id: 0,
        titleLine: "AI Reps",
        accentTitleLine: "Counter",
        subtitle: "Start training and smart tracker\nwill count your reps",
        illustration: .viewfinder(imageName: "OnboardingPushup"),
        imageAccessibilityLabel: "Figure doing a push-up with tracked arm joints",
        tips: [
            Tip(systemImage: "figure", text: "Keep your full body in frame"),
            Tip(systemImage: "iphone", text: "Place the phone stable"),
            Tip(systemImage: "arrow.up.and.down.and.arrow.left.and.right", text: "Leave some space around you"),
        ]
    )

    /// FIGMA: onboarding intro slide 2.
    static let introSetUpPath = IntroSlide(
        id: 1,
        titleLine: "Let's Set Up Your",
        accentTitleLine: "Training Path",
        subtitle: "Answer a few questions to create\nyour personal flow",
        illustration: .plain(imageName: "OnboardingSetupPath", width: 252),
        imageAccessibilityLabel: "Clipboard with a check mark",
        tips: []
    )
}
