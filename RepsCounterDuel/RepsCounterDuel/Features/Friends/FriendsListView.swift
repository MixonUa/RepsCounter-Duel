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
            VStack(spacing: RCSpacing.xxs) {
                if !friends.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(friends.enumerated()), id: \.element.id) { index, item in
                            row(item)
                            if index < friends.count - 1 {
                                Rectangle()
                                    .fill(RCColor.cardDivider.opacity(0.7))
                                    .frame(height: 1)
                                    .padding(.horizontal, RCSpacing.m)
                            }
                        }
                    }
                    .background(.white, in: UnevenRoundedRectangle(
                        topLeadingRadius: RCRadius.card,
                        bottomLeadingRadius: onAddFriend == nil ? RCRadius.card : 0,
                        bottomTrailingRadius: onAddFriend == nil ? RCRadius.card : 0,
                        topTrailingRadius: RCRadius.card,
                        style: .continuous
                    ))
                }
                if onAddFriend != nil {
                    addFriendRow
                }
            }
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

    @ViewBuilder
    private func row(_ item: FriendListItem) -> some View {
        let content = HStack(spacing: RCSpacing.s) {
            Text(item.profile.emoji)
                .font(.system(size: 26))
                .grayscale(item.status == .requestSent ? 1 : 0)
                .opacity(item.status == .requestSent ? 0.6 : 1)
                .frame(width: 44, height: 44)
                .background(item.status == .requestSent ? RCColor.pendingFill : RCColor.friendAvatarFill, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(item.profile.nickname)
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(RCColor.textPrimary)
                    .lineLimit(1)
                if let rank = item.weeklyRank {
                    Text("Top \(rank)")
                        .font(.system(size: 15))
                        .foregroundStyle(RCColor.textSecondary)
                }
            }
            Spacer(minLength: RCSpacing.xs)
            switch item.status {
            case .friend:
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(RCColor.textSecondary.opacity(0.5))
            case .requestSent:
                Text("Request Sent")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RCColor.textSecondary)
                    .padding(.horizontal, RCSpacing.m)
                    .frame(height: 36)
                    .background(RCColor.pendingFill, in: Capsule())
            }
        }
        .padding(.horizontal, RCSpacing.m)
        .frame(height: 68)
        .contentShape(Rectangle())

        if item.status == .friend {
            Button { onOpenFriend(item) } label: { content }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.profile.nickname), top \(item.weeklyRank ?? 0)")
        } else {
            content
                .accessibilityElement(children: .combine)
        }
    }

    /// FIGMA: separate block under the list (square top corners when the list is above).
    private var addFriendRow: some View {
        Button { onAddFriend?() } label: {
            HStack(spacing: RCSpacing.s) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(RCColor.accent)
                    .frame(width: 44, height: 44)
                    .background(RCColor.friendAvatarFill.opacity(0.6), in: Circle())
                    .overlay(Circle().strokeBorder(RCColor.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                Text("Add New Friend")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(RCColor.accent)
                Spacer()
            }
            .padding(.horizontal, RCSpacing.m)
            .frame(height: 67)
            .background(.white, in: UnevenRoundedRectangle(
                topLeadingRadius: friends.isEmpty ? RCRadius.card : 0,
                bottomLeadingRadius: RCRadius.card,
                bottomTrailingRadius: RCRadius.card,
                topTrailingRadius: friends.isEmpty ? RCRadius.card : 0,
                style: .continuous
            ))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        FriendsListView(friends: MockData.profileFilled.friends, onOpenFriend: { _ in }, onAddFriend: {})
    }
}
