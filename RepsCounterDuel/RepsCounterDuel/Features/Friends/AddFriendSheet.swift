import SwiftUI
import Backend
import DesignSystem

/// FIGMA "Add a Friend" (page sheet): glass ✕, title, hint with an accent "username", capsule
/// field with Paste, "Find User" above the keyboard (enabled from the first character).
/// Exact, case-insensitive search; not found → red "User not found…"; found → `onFound`.
struct AddFriendSheet: View {
    let service: any FriendsServicing
    let myNickname: String
    let onFound: (PlayerCard) -> Void

    private enum SearchError {
        case notFound, ownNickname, network

        var message: String {
            switch self {
            // FIGMA copy (given by the product owner).
            case .notFound: "User not found. Check username and try again"
            // PROVISIONAL.
            case .ownNickname: "That's your username. Enter a friend's username"
            case .network: "No connection. Check your internet\nand try again."
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFieldFocused: Bool
    @State private var nickname = ""
    @State private var error: SearchError?
    @State private var isSearching = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(RCColor.textPrimary)
                        .frame(width: RCSize.backButton, height: RCSize.backButton)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .rcGlass(in: Circle(), interactive: true)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.m)

            Text("Add a Friend")
                .font(RCFont.onboardingTitle)
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, RCSpacing.l)

            (Text("Enter or paste your friend's full ")
                .foregroundStyle(RCColor.textSecondary)
             + Text("username")
                .foregroundStyle(RCColor.accent)
                .fontWeight(.semibold))
                .font(RCFont.onboardingSubtitle)
                .tracking(-0.4)
                .multilineTextAlignment(.center)
                .padding(.top, RCSpacing.xs)
                .padding(.horizontal, RCSpacing.m)

            field
                .padding(.horizontal, RCSpacing.m)
                .padding(.top, RCSpacing.l + 4)

            Text(error?.message ?? " \n ")
                .font(RCFont.fieldError)
                .tracking(-0.5)
                .foregroundStyle(RCColor.error)
                .multilineTextAlignment(.center)
                .opacity(error == nil ? 0 : 1)
                .padding(.top, RCSpacing.s + 2)
                .accessibilityHidden(error == nil)

            Spacer(minLength: RCSpacing.m)

            Button(action: search) {
                if isSearching { ProgressView().tint(.white) } else { Text("Find User") }
            }
            .buttonStyle(.rcPrimaryLarge)
            .disabled(!NicknameRules.canSubmit(nickname) || isSearching)
            .padding(.horizontal, RCSpacing.xl)
            .padding(.bottom, RCSpacing.s)
        }
        .background(RCColor.background.ignoresSafeArea())
        .presentationDetents([.large])
        .onAppear { isFieldFocused = true }
        .onChange(of: nickname) { error = nil }
    }

    /// FIGMA: white capsule with a light-blue glassy "Paste" capsule on the right.
    private var field: some View {
        HStack(spacing: RCSpacing.xs) {
            TextField("username", text: $nickname)
                .font(RCFont.fieldText)
                .foregroundStyle(RCColor.textPrimary)
                .focused($isFieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .onSubmit(search)
                .accessibilityLabel("Friend's username")
            Button {
                if let pasted = UIPasteboard.general.string {
                    nickname = NicknameRules.normalized(pasted)
                }
            } label: {
                Text("Paste")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(RCColor.accent)
                    .padding(.horizontal, RCSpacing.m)
                    .frame(height: 34)
                    .background(RCColor.friendAvatarFill, in: Capsule())
                    .overlay(Capsule().strokeBorder(.white, lineWidth: 1))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, RCSpacing.m + 1)
        .padding(.trailing, RCSpacing.s)
        .frame(maxWidth: .infinity, minHeight: RCSize.field)
        .background(.white, in: Capsule())
    }

    private func search() {
        guard NicknameRules.canSubmit(nickname), !isSearching else { return }
        let submitted = NicknameRules.normalized(nickname)
        isFieldFocused = true
        if submitted.lowercased() == myNickname.lowercased() {
            error = .ownNickname
            return
        }
        isSearching = true
        Task {
            let result: Result<PlayerCard?, any Error>
            do { result = .success(try await service.findPlayer(nickname: submitted)) } catch { result = .failure(error) }
            isSearching = false
            guard NicknameRules.normalized(nickname) == submitted else { return }
            switch result {
            case .success(let card?): onFound(card)
            case .success(nil): error = .notFound
            case .failure: error = .network
            }
        }
    }
}

#Preview {
    Color.gray.sheet(isPresented: .constant(true)) {
        AddFriendSheet(service: MockFriendsService(), myNickname: "Nova_07", onFound: { _ in })
    }
}
