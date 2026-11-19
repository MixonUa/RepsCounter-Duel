import SwiftUI
import Backend
import DesignSystem

/// Rating tab: one leaderboard by the single total of duel reps, Global / Friends.
/// PROVISIONAL layout, mock data until stage 5 (server pagination).
struct RatingView: View {
    @State private var scope: LeaderboardScope = .global
    var me: PlayerProfile = MockData.me
    var entries: (LeaderboardScope) -> [LeaderboardEntry] = MockData.leaderboard

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Leaderboard", selection: $scope) {
                        ForEach(LeaderboardScope.allCases) { scope in
                            Text(scope.displayName).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                Section {
                    ForEach(entries(scope)) { entry in
                        LeaderboardRow(entry: entry, isMe: entry.player == me)
                    }
                } footer: {
                    Text("Total accepted reps from finalized duels. Training is not counted.")
                }
            }
            .navigationTitle("Rating")
        }
    }
}

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isMe: Bool

    var body: some View {
        HStack(spacing: RCSpacing.s) {
            Text("\(entry.rank)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 32, alignment: .leading)
            RCEmojiAvatar(entry.player.emoji, size: 36)
            Text(entry.player.nickname)
                .font(isMe ? .body.weight(.semibold) : .body)
            if isMe {
                Text("You")
                    .font(RCFont.caption.weight(.semibold))
                    .foregroundStyle(RCColor.accent)
            }
            Spacer()
            Text("\(entry.totalDuelReps)")
                .font(.body.monospacedDigit().weight(.semibold))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Place \(entry.rank), \(entry.player.nickname)\(isMe ? ", you" : ""), \(entry.totalDuelReps) reps")
    }
}

#Preview {
    RatingView()
}
