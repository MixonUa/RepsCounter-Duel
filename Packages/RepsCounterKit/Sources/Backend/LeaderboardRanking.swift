import Foundation

/// Deterministic leaderboard ordering (CLAUDE.md §7).
///
/// The authoritative ranking will be computed on the server; this mirrors the same rules for
/// local data and previews. Equal totals share one displayed rank ("1, 2, 2, 4"); nickname and
/// profile ID are only a stable secondary sort, never a sporting tie-break.
public enum LeaderboardRanking {
    public static func rank(_ totals: [(player: PlayerProfile, totalDuelReps: Int)]) -> [LeaderboardEntry] {
        let sorted = totals.sorted { lhs, rhs in
            if lhs.totalDuelReps != rhs.totalDuelReps { return lhs.totalDuelReps > rhs.totalDuelReps }
            let nicknameOrder = lhs.player.nickname.localizedCaseInsensitiveCompare(rhs.player.nickname)
            if nicknameOrder != .orderedSame { return nicknameOrder == .orderedAscending }
            return lhs.player.id.uuidString < rhs.player.id.uuidString
        }

        var entries: [LeaderboardEntry] = []
        entries.reserveCapacity(sorted.count)
        for (index, item) in sorted.enumerated() {
            let rank: Int
            if let previous = entries.last, previous.totalDuelReps == item.totalDuelReps {
                rank = previous.rank
            } else {
                rank = index + 1
            }
            entries.append(LeaderboardEntry(player: item.player, totalDuelReps: item.totalDuelReps, rank: rank))
        }
        return entries
    }
}
