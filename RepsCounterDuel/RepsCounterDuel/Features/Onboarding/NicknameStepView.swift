import SwiftUI
import Backend
import DesignSystem

/// FIGMA "Pick Your Username": keyboard opens immediately; Continue is enabled once the field
/// has a character; on Continue the nickname is checked and either the "taken" error is shown
/// or the flow moves on. Registration itself happens on the confirm step (stage 1).
struct NicknameStepView: View {
    private enum CheckError: Equatable {
        case taken
        case network

        var message: String {
            switch self {
            // FIGMA copy, verbatim.
            case .taken: "This username is already taken.\nPlease, choose different variant."
            // PROVISIONAL: no frame for the offline state yet.
            case .network: "No connection. Check your internet\nand try again."
            }
        }
    }

    @Binding var nickname: String
    let checker: any NicknameAvailabilityChecking
    let onContinue: () -> Void

    @FocusState private var isFieldFocused: Bool
    @State private var error: CheckError?
    @State private var isChecking = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle("Pick Your", accent: "Username")
                .padding(.top, RCSpacing.xxl)

            Spacer(minLength: RCSpacing.l)
                .frame(maxHeight: 77)

            TextField("username", text: $nickname)
                .rcCapsuleField()
                .focused($isFieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                // PROVISIONAL: Latin keyboard (as in Figma); allowed nickname characters are still open.
                .keyboardType(.asciiCapable)
                .onSubmit(submit)
                .padding(.horizontal, RCSpacing.m)
                .accessibilityLabel("Username")

            errorArea

            Button(action: submit) {
                if isChecking {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Continue")
                }
            }
            .buttonStyle(.rcPrimaryLarge)
            .disabled(!NicknameRules.canSubmit(nickname) || isChecking)
            .padding(.horizontal, RCSpacing.xl)

            Spacer(minLength: RCSpacing.s)
        }
        .onAppear { isFieldFocused = true }
        .onChange(of: nickname) { error = nil }
    }

    /// Reserved space so the button does not jump when the error appears (as in Figma).
    private var errorArea: some View {
        Text(error?.message ?? " \n ")
            .font(RCFont.fieldError)
            .tracking(-0.5)
            .foregroundStyle(RCColor.error)
            .multilineTextAlignment(.center)
            .opacity(error == nil ? 0 : 1)
            .padding(.top, RCSpacing.s + 2)
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 78, alignment: .top)
            .accessibilityHidden(error == nil)
    }

    /// The field stays editable (keyboard stays up) while checking; a result for text that
    /// was edited in the meantime is ignored.
    private func submit() {
        guard NicknameRules.canSubmit(nickname), !isChecking else { return }
        let submitted = nickname
        // Return on the keyboard resigns focus by default; keep the keyboard up while checking.
        isFieldFocused = true
        isChecking = true
        Task {
            let result: Result<Bool, any Error>
            do {
                result = .success(try await checker.isNicknameAvailable(submitted))
            } catch {
                result = .failure(error)
            }
            isChecking = false
            guard nickname == submitted else { return }
            switch result {
            case .success(true):
                nickname = NicknameRules.normalized(submitted)
                onContinue()
            case .success(false):
                error = .taken
            case .failure:
                error = .network
            }
        }
    }
}

#Preview {
    @Previewable @State var nickname = ""
    NicknameStepView(nickname: $nickname, checker: MockNicknameAvailabilityService(), onContinue: {})
        .rcGradientBackground()
}
