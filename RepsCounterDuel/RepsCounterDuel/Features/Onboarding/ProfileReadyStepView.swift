import SwiftUI
import Backend
import DesignSystem

/// FIGMA "Your Profile Is Ready!": shows the chosen emoji and nickname. "Great !" registers the
/// profile (mock until stage 1) and moves on.
struct ProfileReadyStepView: View {
    let nickname: String
    let emoji: String
    let registrar: any ProfileRegistering
    let onRegistered: (PlayerProfile) -> Void
    /// The nickname was taken between the check and registration: go back to the nickname step.
    let onNicknameTaken: () -> Void

    @State private var isRegistering = false
    @State private var isErrorPresented = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle("Your Profile", accent: "Is Ready!")
                .padding(.top, RCSpacing.xxl)

            Spacer(minLength: RCSpacing.m)

            VStack(spacing: RCSpacing.xxl + RCSpacing.xs) {
                OnboardingAvatarCircle(emoji: emoji, diameter: 170)
                // FIGMA: ≈ 49 pt heavy.
                Text(nickname)
                    .font(.system(size: 49, weight: .heavy))
                    .foregroundStyle(RCColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .padding(.horizontal, RCSpacing.xl)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(nickname), avatar \(emoji)")

            Spacer(minLength: RCSpacing.m)

            Button(action: register) {
                if isRegistering {
                    ProgressView().tint(.white)
                } else {
                    Text("Great !")
                }
            }
            .buttonStyle(.rcPrimaryLarge)
            .disabled(isRegistering)
            .padding(.horizontal, RCSpacing.xl)
            .padding(.bottom, RCSpacing.xxs)
        }
        // PROVISIONAL: no Figma frame for a registration error.
        .alert("Couldn't create your profile", isPresented: $isErrorPresented) {
            Button("Try Again", action: register)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Check your internet connection and try again.")
        }
    }

    private func register() {
        guard !isRegistering else { return }
        isRegistering = true
        Task {
            defer { isRegistering = false }
            do {
                onRegistered(try await registrar.register(nickname: nickname, emoji: emoji))
            } catch ProfileRegistrationError.nicknameTaken {
                onNicknameTaken()
            } catch {
                isErrorPresented = true
            }
        }
    }
}

#Preview {
    ProfileReadyStepView(
        nickname: "Nova_07",
        emoji: "🐧",
        registrar: MockProfileRegistrationService(),
        onRegistered: { _ in },
        onNicknameTaken: {}
    )
    .rcGradientBackground()
}
