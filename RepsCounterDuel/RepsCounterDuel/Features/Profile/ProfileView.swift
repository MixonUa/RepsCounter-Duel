import SwiftUI
import Backend
import DesignSystem

/// Profile tab: emoji, nickname, compact stats and top-3 friends' results.
/// PROVISIONAL layout, mock data until stage 2. "See all" / "Add friend" screens arrive in stage 2.
struct ProfileView: View {
    var me: PlayerProfile = MockData.me
    var stats: PlayerStats = MockData.myStats
    var friends: [LeaderboardEntry] = LeaderboardRanking.rank(
        MockData.friendTotals.filter { $0.player != MockData.me }
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RCSpacing.m) {
                    header
                    statsCard
                    friendsCard
                }
                .padding(.horizontal, RCSpacing.m)
                .padding(.vertical, RCSpacing.xs)
            }
            .background(RCColor.background)
            .navigationTitle("Profile")
        }
    }

    private var header: some View {
        VStack(spacing: RCSpacing.xs) {
            RCEmojiAvatar(me.emoji, size: 96)
            Text(me.nickname)
                .font(.title2.weight(.bold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RCSpacing.s)
    }

    private var statsCard: some View {
        HStack {
            RCStatTile(value: "\(stats.totalDuelReps)", label: "Duel reps")
            RCStatTile(value: "\(stats.duelsWon)/\(stats.duelsLost)/\(stats.duelsTied)", label: "W / L / D")
            RCStatTile(value: "\(stats.trainingRecordTotal)", label: "Training record")
        }
        .rcCard()
    }

    @ViewBuilder
    private var friendsCard: some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            if friends.isEmpty {
                RCSectionHeader("Friends")
                Text("Add friends to compare results and challenge them to duels.")
                    .foregroundStyle(RCColor.textSecondary)
            } else {
                RCSectionHeader("Friends", actionTitle: "See all") {
                    // Full friends list arrives in stage 2.
                }
                ForEach(friends.prefix(3)) { entry in
                    HStack(spacing: RCSpacing.s) {
                        RCEmojiAvatar(entry.player.emoji, size: 36)
                        Text(entry.player.nickname)
                        Spacer()
                        Text("\(entry.totalDuelReps) reps")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(RCColor.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            Button("Add friend") {
                // Add Friend search arrives in stage 2.
            }
            .buttonStyle(.rcSecondary)
        }
        .rcCard()
    }
}

#Preview("With friends") {
    ProfileView()
}

#Preview("No friends") {
    ProfileView(stats: .empty, friends: [])
}
