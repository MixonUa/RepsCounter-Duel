import SwiftUI
import Backend
import DesignSystem

/// First-launch onboarding. The gradient background is painted once here (not per step) so it
/// does not restart under the progress header.
/// UI stage: steps without a Figma frame are placeholders;
/// registration and the real camera permission are wired in stage 1.
struct OnboardingFlowView: View {
    let onFinish: () -> Void
    var nicknameChecker: any NicknameAvailabilityChecking = MockNicknameAvailabilityService()
    var registrar: any ProfileRegistering = MockProfileRegistrationService()

    @State private var step: OnboardingStep = OnboardingFlowView.initialStep
    @State private var isMovingForward = true
    @State private var introPage = OnboardingFlowView.initialIntroPage
    @State private var nickname = ""
    @State private var avatar = AvatarEmoji.default
    /// Set once the profile is registered on the "Your Profile Is Ready!" step.
    @State private var registeredProfile: PlayerProfile?

    var body: some View {
        VStack(spacing: 0) {
            if let progress = step.progress {
                OnboardingProgressHeader(progress: progress, onBack: goBack)
                    .transition(.opacity)
            }
            ZStack {
                stepView
                    .id(step)
                    .transition(stepTransition)
            }
            .frame(maxHeight: .infinity)
        }
        .rcGradientBackground()
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .intro:
            IntroPagerView(slides: [.introPushUp, .introSetUpPath], page: $introPage, onFinish: advance)
        case .nickname:
            NicknameStepView(nickname: $nickname, checker: nicknameChecker, onContinue: advance)
        case .emoji:
            AvatarStepView(selection: $avatar, onContinue: advance)
        case .confirmProfile:
            ProfileReadyStepView(
                nickname: nickname,
                emoji: avatar.emoji,
                registrar: registrar,
                onRegistered: { profile in
                    registeredProfile = profile
                    advance()
                },
                onNicknameTaken: { go(to: .nickname) }
            )
        case .motivation:
            OnboardingPlaceholderStepView(title: "Your motivation", onContinue: advance)
        case .explanation:
            OnboardingPlaceholderStepView(title: "How it works", onContinue: advance)
        case .cameraPermission:
            // Stage 1: granted → finish, denied → .cameraTips.
            OnboardingPlaceholderStepView(title: "Camera access", onContinue: onFinish)
        case .cameraTips:
            OnboardingPlaceholderStepView(title: "Camera tips", onContinue: onFinish)
        }
    }

    private var stepTransition: AnyTransition {
        isMovingForward
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }

    private func advance() {
        guard let next = step.next else { return onFinish() }
        isMovingForward = true
        withAnimation(.snappy) { step = next }
    }

    private func goBack() {
        guard let previous = step.previous else { return }
        go(to: previous)
    }

    private func go(to target: OnboardingStep) {
        isMovingForward = target.rawValue > step.rawValue
        withAnimation(.snappy) { step = target }
    }

    // DEBUG: `-debugOnboardingStep N` opens step N, `-debugIntroPage N` opens intro slide N
    // (for visual checks in the simulator).
    private static var initialStep: OnboardingStep {
        #if DEBUG
        OnboardingStep(rawValue: UserDefaults.standard.integer(forKey: "debugOnboardingStep")) ?? .intro
        #else
        .intro
        #endif
    }

    private static var initialIntroPage: Int {
        #if DEBUG
        UserDefaults.standard.integer(forKey: "debugIntroPage")
        #else
        0
        #endif
    }
}

#Preview {
    OnboardingFlowView(onFinish: {})
}
