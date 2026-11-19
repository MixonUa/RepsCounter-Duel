/// One row of the single total-reps leaderboard (Global or Friends).
public struct LeaderboardEntry: Identifiable, Hashable, Codable, Sendable {
    public var player: PlayerProfile
    public var totalDuelReps: Int
    /// Displayed rank; players with equal totals share the same rank.
    public var rank: Int

    public var id: PlayerProfile.ID { player.id }

    public init(player: PlayerProfile, totalDuelReps: Int, rank: Int) {
        self.player = player
        self.totalDuelReps = totalDuelReps
        self.rank = rank
    }
}

public enum LeaderboardScope: String, CaseIterable, Sendable, Identifiable {
    case global
    case friends

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .global: "Global"
        case .friends: "Friends"
        }
    }
}
