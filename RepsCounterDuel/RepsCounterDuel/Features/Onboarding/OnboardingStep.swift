/// Onboarding steps in the order of the Figma flow (CLAUDE.md §8.1).
enum OnboardingStep: Int, CaseIterable {
    /// 2 intro slides.
    case intro
    case nickname
    case emoji
    /// Confirm nickname + emoji (server registration in stage 1).
    case confirmProfile
    /// 3 buttons; engagement only, not stored on the server.
    case motivation
    /// 3 explanation slides, each its own step (no page dots in Figma).
    case explanationTrainOrChallenge
    case explanationBuildingPath
    /// FIGMA paywall (3-day trial); ✕ or a started trial continues. No progress bar.
    case paywall
    /// FIGMA "Allow Access To Your Camera"; when denied the same step switches to
    /// "Access to the Camera is Restricted" with Open Settings. No progress bar.
    case cameraPermission

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }

    /// Top progress bar value. Nickname 20%, emoji 30%, profile 40%, goal 68%, explanation slides
    /// 77% / 87% (confirmed / measured from Figma 2026-11-19); the later values are PROVISIONAL.
    var progress: Double? {
        switch self {
        case .intro, .paywall, .cameraPermission: nil
        case .nickname: 0.2
        case .emoji: 0.3
        case .confirmProfile: 0.4
        case .motivation: 0.68
        case .explanationTrainOrChallenge: 0.77
        case .explanationBuildingPath: 0.87
        }
    }
}
