import SwiftUI
import Backend
import DesignSystem

/// FIGMA "Friends" (Profile → see all): accepted friends with their weekly place (→ player card),
/// sent requests marked "Request Sent", and "Add New Friend" at the bottom. No tab bar.
/// Also used read-only for another player's friends (`onAddFriend == nil`).
struct FriendsListView: View {
    var title = "Friends"
    let friends: [FriendListItem]
    let onOpenFriend: (FriendListItem) -> Void
    let onAddFriend: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            FriendsCard(friends: friends, showsChevron: true, onSelectFriend: onOpenFriend, onAddFriend: onAddFriend)
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.s - 2)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) { navigationHeader }
        .background(RCColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
    }

    /// FIGMA: plain chevron on the left, centered "Friends".
    private var navigationHeader: some View {
        ZStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, RCSpacing.xxl + RCSpacing.l)
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(RCColor.textPrimary)
                        .frame(width: RCSize.minTouchTarget, height: RCSize.minTouchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.leading, RCSpacing.xxs)
        }
        .padding(.top, RCSpacing.xs + 1)
        .padding(.bottom, RCSpacing.xs)
        .background(RCColor.background)
    }
}

#Preview {
    NavigationStack {
        FriendsListView(friends: MockData.profileFilled.friends, onOpenFriend: { _ in }, onAddFriend: {})
    }
}
