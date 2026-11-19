import SwiftUI
import Backend
import DesignSystem

/// PROVISIONAL design (no Figma frame): Profile-style blue header with the avatar and nickname.
/// Tap the avatar → emoji grid; pencil next to the nickname → custom alert to rename with the
/// same validation and availability check as onboarding. Changes are saved locally (UI stage;
/// stage 1 sends them to the server, which re-checks nickname uniqueness).
struct EditProfileView: View {
    var nicknameChecker: any NicknameAvailabilityChecking = MockNicknameAvailabilityService()

    @Environment(\.dismiss) private var dismiss
    @AppStorage(LocalStorageKeys.nickname) private var storedNickname = ""
    @AppStorage(LocalStorageKeys.emoji) private var storedEmoji = ""

    @State private var isAvatarPickerPresented = false
    @State private var isRenaming = false

    private var nickname: String { storedNickname.isEmpty ? "Nova_07" : storedNickname }
    private var avatar: AvatarEmoji {
        AvatarEmoji.all.first { $0.emoji == storedEmoji } ?? .default
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                VStack(spacing: RCSpacing.xs) {
                    Text("Tap the avatar to choose another one")
                    Text("Tap the pencil to change your nickname")
                }
                .font(.system(size: 15))
                .foregroundStyle(RCColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, RCSpacing.xxl)
                Spacer()
            }
            .background(alignment: .top) { ProfileHeaderBackground() }

            if isRenaming {
                NicknameChangeAlert(
                    currentNickname: nickname,
                    checker: nicknameChecker,
                    onSave: { newNickname in
                        storedNickname = newNickname
                        withAnimation(.snappy) { isRenaming = false }
                    },
                    onCancel: { withAnimation(.snappy) { isRenaming = false } }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .sheet(isPresented: $isAvatarPickerPresented) {
            AvatarPickerSheet(selection: Binding(
                get: { avatar },
                set: { storedEmoji = $0.emoji }
            ))
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Edit Profile")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: RCSize.backButton, height: RCSize.backButton)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .rcClearGlass(in: Circle())
                    .accessibilityLabel("Close")
                }
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.xxs)

            Button { isAvatarPickerPresented = true } label: {
                OnboardingAvatarCircle(emoji: avatar.emoji, diameter: 141, fill: RCColor.profileAvatarFill)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(RCColor.accent, in: Circle())
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                            .offset(x: -4, y: -4)
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, RCSpacing.l)
            .accessibilityLabel("Avatar \(avatar.name). Change avatar")

            HStack(spacing: RCSpacing.s) {
                Text(nickname)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Button { withAnimation(.snappy) { isRenaming = true } } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .rcClearGlass(in: Circle())
                .accessibilityLabel("Change nickname")
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.xs)
        }
    }
}

/// Same blue header gradient as Profile.
struct ProfileHeaderBackground: View {
    var body: some View {
        ZStack(alignment: .top) {
            RCColor.background
            LinearGradient(
                stops: [
                    .init(color: RCColor.profileHeaderTop, location: 0),
                    .init(color: RCColor.profileHeaderDeep, location: 0.45),
                    .init(color: RCColor.background, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 450)
        }
        .ignoresSafeArea()
    }
}

/// Emoji grid in a sheet; a tap selects and saves immediately.
private struct AvatarPickerSheet: View {
    @Binding var selection: AvatarEmoji
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AvatarGrid(selection: $selection)
                .padding(.horizontal, RCSpacing.m)
                .padding(.top, RCSpacing.s)
                .background(RCColor.background)
                .navigationTitle("Choose Avatar")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// PROVISIONAL custom alert: capsule field with the current nickname, the onboarding error
/// messages ("taken" / offline), Cancel and Save. Save is enabled when the text is a new,
/// non-empty nickname; it checks availability first.
private struct NicknameChangeAlert: View {
    let currentNickname: String
    let checker: any NicknameAvailabilityChecking
    let onSave: (String) -> Void
    let onCancel: () -> Void

    private enum CheckError {
        case taken, network
        var message: String {
            switch self {
            case .taken: "This username is already taken.\nPlease, choose different variant."
            case .network: "No connection. Check your internet\nand try again."
            }
        }
    }

    @State private var text = ""
    @State private var error: CheckError?
    @State private var isChecking = false
    @FocusState private var isFocused: Bool

    private var canSave: Bool {
        NicknameRules.canSubmit(text)
            && NicknameRules.normalized(text).lowercased() != currentNickname.lowercased()
            && !isChecking
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 0) {
                Text("Change Nickname")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(-0.4)
                Text("Your friends will see the new nickname")
                    .font(.system(size: 14))
                    .foregroundStyle(RCColor.textSecondary)
                    .padding(.top, RCSpacing.xxs)

                TextField("username", text: $text)
                    .font(RCFont.fieldText)
                    .padding(.horizontal, RCSpacing.m + 1)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(RCColor.background, in: Capsule())
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .onSubmit(save)
                    .padding(.top, RCSpacing.l)
                    .accessibilityLabel("New nickname")

                Text(error?.message ?? " \n ")
                    .font(RCFont.fieldError)
                    .tracking(-0.5)
                    .foregroundStyle(RCColor.error)
                    .multilineTextAlignment(.center)
                    .opacity(error == nil ? 0 : 1)
                    .padding(.top, RCSpacing.s)
                    .accessibilityHidden(error == nil)

                HStack(spacing: RCSpacing.s) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.rcSecondary)
                    Button(action: save) {
                        if isChecking { ProgressView().tint(.white) } else { Text("Save") }
                    }
                    .buttonStyle(.rcPrimary)
                    .disabled(!canSave)
                }
                .padding(.top, RCSpacing.s)
            }
            .padding(RCSpacing.l)
            .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card + 4, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 24, y: 8)
            .padding(.horizontal, RCSpacing.l)
        }
        .onAppear {
            text = currentNickname
            isFocused = true
        }
        .onChange(of: text) { error = nil }
    }

    private func save() {
        guard canSave else { return }
        let submitted = text
        isFocused = true
        isChecking = true
        Task {
            let result: Result<Bool, any Error>
            do { result = .success(try await checker.isNicknameAvailable(submitted)) } catch { result = .failure(error) }
            isChecking = false
            guard text == submitted else { return }
            switch result {
            case .success(true): onSave(NicknameRules.normalized(submitted))
            case .success(false): error = .taken
            case .failure: error = .network
            }
        }
    }
}

#Preview {
    EditProfileView()
}
