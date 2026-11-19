import SwiftUI
import Backend
import DesignSystem

/// FIGMA "Choose a Friend" (duel flow, after Choose Exercise). Three states:
/// - no friends and no sent requests: 🤝, title, hint and "+ Add Friend";
/// - only sent requests: hint + list; requests are grayed with "Request Sent" and can't be
///   challenged (Figma shows "Level 7" there — a design bug, no subtitle is shown);
/// - accepted friends: list without the hint; tapping a friend opens the invitation screen.
struct ChooseFriendView: View {
    let friends: [FriendListItem]
    let onBack: () -> Void
    let onClose: () -> Void
    let onAddFriend: () -> Void
    let onSelect: (FriendListItem) -> Void

    private var hasAcceptedFriends: Bool { friends.contains { $0.status == .friend } }

    var body: some View {
        Group {
            if friends.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                RCBackButton(action: onBack)
                Spacer()
                ActivityCloseButton(action: onClose)
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.m)
            .background(RCColor.background)
        }
        .background(RCColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var title: some View {
        Text("Choose a Friend")
            .font(RCFont.homeTitle)
            .foregroundStyle(RCColor.textPrimary)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
    }

    private var hint: some View {
        Text("You can challenge only your friends.\nAdd friend to create a duel.")
            .font(.system(size: 17))
            .tracking(-0.4)
            .foregroundStyle(RCColor.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, RCSpacing.m)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: RCSpacing.l)
            Text("🤝")
                .font(.system(size: 110))
                .accessibilityHidden(true)
            title
                .padding(.top, 88)
            hint
                .padding(.top, RCSpacing.s)
            Button(action: onAddFriend) {
                Text("+ Add Friend")
            }
            .buttonStyle(.rcPrimaryLarge)
            .padding(.horizontal, 36)
            .padding(.top, RCSpacing.l)
            Spacer(minLength: RCSpacing.l)
                .frame(maxHeight: 140)
        }
    }

    // MARK: - List

    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                title
                    .padding(.top, RCSpacing.l)
                if !hasAcceptedFriends {
                    hint
                        .padding(.top, 38)
                }
                FriendsCard(
                    friends: friends,
                    showsChevron: false,
                    onSelectFriend: onSelect,
                    onAddFriend: onAddFriend
                )
                .padding(.horizontal, RCSpacing.m)
                .padding(.top, hasAcceptedFriends ? 36 : RCSpacing.xxl)
                .padding(.bottom, RCSpacing.l)
            }
        }
        .scrollIndicators(.hidden)
    }
}

#Preview("Empty") {
    ChooseFriendView(friends: [], onBack: {}, onClose: {}, onAddFriend: {}, onSelect: { _ in })
}

#Preview("Friends") {
    ChooseFriendView(friends: MockData.profileFilled.friends, onBack: {}, onClose: {}, onAddFriend: {}, onSelect: { _ in })
}

#Preview("Requests only") {
    ChooseFriendView(
        friends: MockData.profileFilled.friends.filter { $0.status == .requestSent },
        onBack: {}, onClose: {}, onAddFriend: {}, onSelect: { _ in }
    )
}
