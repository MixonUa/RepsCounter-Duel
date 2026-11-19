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
    /// 3 explanation slides.
    case explanation
    case cameraPermission
    /// Shown only when camera access was denied; leads to Settings.
    case cameraTips

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }

    /// Top progress bar value, shown on 6 screens. Nickname 20%, emoji 30%, profile 40%
    /// (confirmed 2026-11-19); the later values are PROVISIONAL until their frames arrive.
    var progress: Double? {
        switch self {
        case .intro, .cameraTips: nil
        case .nickname: 0.2
        case .emoji: 0.3
        case .confirmProfile: 0.4
        case .motivation: 0.68
        case .explanation: 0.84
        case .cameraPermission: 1.0
        }
    }
}
