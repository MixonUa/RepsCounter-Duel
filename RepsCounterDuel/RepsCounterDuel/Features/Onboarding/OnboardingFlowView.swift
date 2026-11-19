import SwiftUI
import Backend
import DesignSystem

/// First-launch onboarding. The gradient background is painted once here (not per step) so it
/// does not restart under the progress header.
/// UI stage: nickname check, registration and purchases use mock services (stage 1 wires the
/// server); the camera permission is real.
///
/// Once the profile is registered, the current step is remembered: changing the camera permission
/// in Settings makes iOS terminate the app, and onboarding must resume, not start over.
struct OnboardingFlowView: View {
    let onFinish: () -> Void
    var nicknameChecker: any NicknameAvailabilityChecking = MockNicknameAvailabilityService()
    var registrar: any ProfileRegistering = MockProfileRegistrationService()
    var purchases: any PaywallPurchasing = MockPaywallPurchaseService()
    var cameraPermission: any CameraPermissionProviding = SystemCameraPermission()

    @State private var step: OnboardingStep = OnboardingFlowView.initialStep
    @State private var isMovingForward = true
    @State private var introPage = OnboardingFlowView.initialIntroPage
    @State private var nickname = OnboardingFlowView.savedNickname
    @State private var avatar = OnboardingFlowView.savedAvatar

    /// UI stage persistence (stage 1 reads the registered profile from the server instead).
    @AppStorage(StorageKey.resumeStep) private var resumeStep = 0
    @AppStorage(StorageKey.nickname) private var storedNickname = ""
    @AppStorage(StorageKey.emoji) private var storedEmoji = ""

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
        .background {
            // The paywall has a plain background in Figma; other steps use the blue gradient.
            if step == .paywall {
                RCColor.background.ignoresSafeArea()
            } else {
                Color.clear.rcGradientBackground()
            }
        }
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
                    storedNickname = profile.nickname
                    storedEmoji = profile.emoji
                    advance()
                },
                onNicknameTaken: { go(to: .nickname) }
            )
        case .motivation:
            MotivationStepView(onSelect: { _ in advance() })
        case .explanationTrainOrChallenge:
            TrainOrChallengeStepView(
                me: PlayerProfile(nickname: nickname.isEmpty ? "Nova_07" : nickname, emoji: avatar.emoji),
                onContinue: advance
            )
        case .explanationBuildingPath:
            BuildingPathStepView(onFinished: advance)
        case .paywall:
            OnboardingPaywallStepView(purchases: purchases, onDone: advance)
        case .cameraPermission:
            CameraAccessStepView(permission: cameraPermission, onGranted: finish)
        }
    }

    private var stepTransition: AnyTransition {
        isMovingForward
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }

    private func advance() {
        guard let next = step.next else { return finish() }
        go(to: next)
    }

    private func goBack() {
        guard let previous = step.previous else { return }
        go(to: previous)
    }

    private func go(to target: OnboardingStep) {
        isMovingForward = target.rawValue > step.rawValue
        withAnimation(.snappy) { step = target }
        // Resume point only exists after registration.
        if !storedNickname.isEmpty, target.rawValue > OnboardingStep.confirmProfile.rawValue {
            resumeStep = target.rawValue
        }
    }

    private func finish() {
        resumeStep = 0
        onFinish()
    }

    // MARK: - Initial state

    private enum StorageKey {
        static let resumeStep = "onboardingResumeStep"
        static let nickname = "onboardingRegisteredNickname"
        static let emoji = "onboardingRegisteredEmoji"
    }

    /// DEBUG `-debugOnboardingStep N` wins; otherwise the remembered resume step; otherwise intro.
    private static var initialStep: OnboardingStep {
        let defaults = UserDefaults.standard
        #if DEBUG
        if defaults.object(forKey: "debugOnboardingStep") != nil,
           let step = OnboardingStep(rawValue: defaults.integer(forKey: "debugOnboardingStep")) {
            return step
        }
        #endif
        return OnboardingStep(rawValue: defaults.integer(forKey: StorageKey.resumeStep))
            .flatMap { $0.rawValue > 0 ? $0 : nil } ?? .intro
    }

    private static var initialIntroPage: Int {
        #if DEBUG
        UserDefaults.standard.integer(forKey: "debugIntroPage")
        #else
        0
        #endif
    }

    private static var savedNickname: String {
        UserDefaults.standard.string(forKey: StorageKey.nickname) ?? ""
    }

    private static var savedAvatar: AvatarEmoji {
        let emoji = UserDefaults.standard.string(forKey: StorageKey.emoji)
        return AvatarEmoji.all.first { $0.emoji == emoji } ?? .default
    }
}

#Preview {
    OnboardingFlowView(onFinish: {})
}
