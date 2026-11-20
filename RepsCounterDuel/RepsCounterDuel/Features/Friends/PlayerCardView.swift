import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA player profile (found by nickname or opened from the friends list): Profile-style blue
/// header with a glass back button, the same stats card, "Friends" — their 3 most recently added
/// friends (Figma shows 4 by mistake) with "see all", and "+ Add Friend" at the bottom. No tab bar.
/// The button states after sending (Request Sent / Friends) are PROVISIONAL; tapping them asks to
/// cancel the request / remove the friend (PROVISIONAL, no Figma frame).
struct PlayerCardView: View {
    let card: PlayerCard
    let service: any FriendsServicing
    let onSeeAllFriends: () -> Void
    /// Called after my request / acceptance went through (refreshes my friends list).
    var onRelationshipChanged: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var relationship: PlayerCard.Relationship
    @State private var isSending = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""
    @State private var isUndoConfirmationPresented = false

    init(card: PlayerCard, service: any FriendsServicing, onSeeAllFriends: @escaping () -> Void, onRelationshipChanged: @escaping () -> Void = {}) {
        self.card = card
        self.service = service
        self.onSeeAllFriends = onSeeAllFriends
        self.onRelationshipChanged = onRelationshipChanged
        _relationship = State(initialValue: card.relationship)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PlayerHeader(profile: card.profile, weeklyRank: card.weeklyRank) {
                    HeaderGlassButton(systemImage: "chevron.left", label: "Back") { dismiss() }
                } trailing: {
                    // Keeps the avatar centered: same width as the back button.
                    Color.clear.frame(width: RCSize.backButton, height: RCSize.backButton)
                }

                RecordsCard(items: [
                    .init(systemImage: "bolt.fill", value: "\(card.stats.duelsWon)", label: "Duels Won", weeklyChange: nil),
                    .init(
                        systemImage: "flame.fill",
                        value: card.stats.winRate.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—",
                        label: "Win Rate",
                        weeklyChange: nil
                    ),
                    .init(systemImage: "dumbbell.fill", value: "\(card.stats.totalDuelReps)", label: "Total Reps", weeklyChange: nil),
                ])
                .padding(.top, RCSpacing.xl)

                friendsSection
                    .padding(.top, RCSpacing.xxl + RCSpacing.xs)
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.bottom, RCSpacing.l)
        }
        .scrollIndicators(.hidden)
        .background(alignment: .top) { ProfileHeaderBackground() }
        .safeAreaInset(edge: .bottom, spacing: 0) { actionButton }
        .toolbar(.hidden, for: .navigationBar)
        .hidesTabBar()
        .alert("Couldn't update the friendship", isPresented: $isErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("Friends")
                    .font(RCFont.homeHeading)
                    .tracking(-0.8)
                    .foregroundStyle(RCColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !card.allFriends.isEmpty {
                    Button("see all", action: onSeeAllFriends)
                        .font(.system(size: 17))
                        .foregroundStyle(RCColor.accent)
                }
            }

            Group {
                if card.recentFriends.isEmpty {
                    // PROVISIONAL: no Figma frame for a player without friends.
                    Text("No friends yet")
                        .font(.system(size: 15))
                        .foregroundStyle(RCColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    HStack(spacing: RCSpacing.xs) {
                        ForEach(card.recentFriends) { friend in
                            friendBubble(friend)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, RCSpacing.l + 2)
                    .frame(minHeight: 100)
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
        }
    }

    /// FIGMA: 52 pt blue-gradient circle with the emoji, nickname under it.
    private func friendBubble(_ friend: PlayerProfile) -> some View {
        VStack(spacing: 6) {
            Text(friend.emoji)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(colors: [Color(red: 0.35, green: 0.68, blue: 0.98), Color(red: 0.16, green: 0.49, blue: 0.94)],
                                   startPoint: .top, endPoint: .bottom),
                    in: Circle()
                )
            Text(friend.nickname)
                .font(.system(size: 15, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(RCColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 72)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var actionButton: some View {
        Button {
            if canSend { sendRequest() } else { isUndoConfirmationPresented = true }
        } label: {
            if isSending {
                ProgressView().tint(.white)
            } else {
                switch relationship {
                case .none, .requestReceived: Text("+ Add Friend")
                case .requestSent: Text("Request Sent")
                case .friends: Label("Friends", systemImage: "checkmark")
                }
            }
        }
        .buttonStyle(.rcPrimaryLarge)
        .disabled(isSending)
        .confirmationDialog(
            relationship == .friends ? "Remove \(card.profile.nickname) from friends?" : "Cancel your friend request?",
            isPresented: $isUndoConfirmationPresented,
            titleVisibility: .visible
        ) {
            if relationship == .friends {
                Button("Remove from Friends", role: .destructive, action: undo)
            } else {
                Button("Cancel Request", role: .destructive, action: undo)
            }
            Button("Keep", role: .cancel) {}
        }
        .padding(.horizontal, RCSpacing.xl)
        .padding(.bottom, RCSpacing.xxs)
    }

    private var canSend: Bool { relationship == .none || relationship == .requestReceived }

    /// Removes the friend or withdraws my pending request.
    private func undo() {
        guard !isSending else { return }
        let wasFriend = relationship == .friends
        isSending = true
        Task {
            do {
                if wasFriend {
                    try await service.removeFriend(card.profile)
                } else {
                    try await service.cancelFriendRequest(to: card.profile)
                }
                withAnimation(.snappy) { relationship = .none }
                onRelationshipChanged()
            } catch {
                errorMessage = "Check your internet connection and try again."
                isErrorPresented = true
            }
            isSending = false
        }
    }

    /// "+ Add Friend": sends a request, or accepts theirs when they had already asked me.
    private func sendRequest() {
        guard canSend, !isSending else { return }
        isSending = true
        Task {
            do {
                let result = try await service.sendFriendRequest(to: card.profile)
                withAnimation(.snappy) {
                    relationship = switch result {
                    case .sent, .alreadySent: .requestSent
                    case .accepted, .alreadyFriends: .friends
                    }
                }
                onRelationshipChanged()
            } catch {
                errorMessage = (error as? FriendsError) == .rateLimited
                    ? "You've sent too many requests today. Try again tomorrow."
                    : "Check your internet connection and try again."
                isErrorPresented = true
            }
            isSending = false
        }
    }
}

#Preview {
    NavigationStack {
        PlayerCardView(card: MockData.searchablePlayers[1], service: MockFriendsService(), onSeeAllFriends: {})
    }
}
