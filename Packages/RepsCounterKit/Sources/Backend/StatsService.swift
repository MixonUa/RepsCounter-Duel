import Foundation
import Supabase
import ExerciseAnalyzer

/// Weekly rating, duel history and profile numbers (stage 5, `20261120080000_rating.sql`).
/// All derived on the server from completed duels; the rating week starts Monday 00:00 UTC.
public protocol StatsServicing: Sendable {
    /// Ranked entries of this week (equal totals share a rank); players with 0 reps have no place.
    func leaderboard(_ scope: LeaderboardScope) async throws -> [LeaderboardEntry]
    /// My completed duels since `since`, newest first.
    func duelHistory(since: Date, limit: Int) async throws -> [DuelSummary]
    /// My all-time duel numbers.
    func myStats() async throws -> PlayerStats
    /// My 3 friends with the most duel reps this week.
    func topFriendsThisWeek() async throws -> [TopFriend]
}

public extension LeaderboardEntry {
    /// "6 more reps to break into the top 20": reps I need to reach the next "top N" (the total
    /// of the player now at place N), from a ranked board. nil when unknown or already at #1.
    static func weeklyRank(for me: PlayerProfile, in board: [LeaderboardEntry]) -> WeeklyRank? {
        guard let mine = board.first(where: { $0.player.id == me.id }) else { return nil }
        guard let milestone = WeeklyRank.milestone(above: mine.rank), board.indices.contains(milestone - 1) else {
            return WeeklyRank(position: mine.rank, repsToNextMilestone: nil)
        }
        let needed = max(1, board[milestone - 1].totalDuelReps - mine.totalDuelReps)
        return WeeklyRank(position: mine.rank, repsToNextMilestone: needed)
    }
}

public struct SupabaseStatsService: StatsServicing {
    private let backend: SupabaseBackend

    public init(backend: SupabaseBackend) {
        self.backend = backend
    }

    private struct Player: Decodable {
        let nickname: String
        let emoji: String
    }

    public func leaderboard(_ scope: LeaderboardScope) async throws -> [LeaderboardEntry] {
        struct Board: Decodable {
            struct Entry: Decodable {
                let nickname: String
                let emoji: String
                let total: Int
                let rank: Int
            }
            let entries: [Entry]
        }
        struct Params: Encodable {
            let scope: String
            let max_entries: Int
        }
        try await backend.ensureSession()
        let board: Board = try await backend.client
            .rpc("weekly_leaderboard", params: Params(scope: scope == .global ? "global" : "friends", max_entries: 100))
            .execute()
            .value
        return board.entries.map {
            LeaderboardEntry(player: PlayerProfile(serverNickname: $0.nickname, emoji: $0.emoji), totalDuelReps: $0.total, rank: $0.rank)
        }
    }

    public func duelHistory(since: Date, limit: Int) async throws -> [DuelSummary] {
        struct Row: Decodable {
            let id: UUID
            let opponent: Player
            let exercise: String
            let duration_seconds: Int
            let my_reps: Int
            let opponent_reps: Int
            let finished_at: String
        }
        struct Params: Encodable {
            let since: String
            let max_entries: Int
        }
        try await backend.ensureSession()
        let formatter = ISO8601DateFormatter()
        let rows: [Row] = try await backend.client
            .rpc("my_duel_history", params: Params(since: formatter.string(from: since), max_entries: limit))
            .execute()
            .value
        return rows.compactMap { row in
            guard let exercise = Exercise(rawValue: row.exercise), let finished = DuelRow.date(row.finished_at) else { return nil }
            return DuelSummary(
                id: row.id,
                opponent: PlayerProfile(serverNickname: row.opponent.nickname, emoji: row.opponent.emoji),
                exercise: exercise,
                duration: DuelDuration(seconds: row.duration_seconds),
                myReps: row.my_reps,
                opponentReps: row.opponent_reps,
                finishedAt: finished
            )
        }
    }

    public func myStats() async throws -> PlayerStats {
        try await backend.ensureSession()
        let row: PlayerStatsRow = try await backend.client.rpc("my_stats").execute().value
        var stats = row.stats(exercise: .squats)
        stats.trainingRecords = [:]
        return stats
    }

    public func topFriendsThisWeek() async throws -> [TopFriend] {
        struct Row: Decodable {
            let nickname: String
            let emoji: String
            let weekly_total: Int
            let duels_won: Int
            let duels_lost: Int
            let duels_tied: Int
        }
        try await backend.ensureSession()
        let rows: [Row] = try await backend.client.rpc("top_friends_this_week").execute().value
        return rows.map {
            let stats = PlayerStats(totalDuelReps: 0, duelsWon: $0.duels_won, duelsLost: $0.duels_lost, duelsTied: $0.duels_tied)
            return TopFriend(profile: PlayerProfile(serverNickname: $0.nickname, emoji: $0.emoji), winRate: stats.winRate, jointReps: $0.weekly_total)
        }
    }
}

/// Offline stand-in (`-useMockBackend YES`): nothing played yet.
public struct MockStatsService: StatsServicing {
    public init() {}
    public func leaderboard(_ scope: LeaderboardScope) async throws -> [LeaderboardEntry] { [] }
    public func duelHistory(since: Date, limit: Int) async throws -> [DuelSummary] { [] }
    public func myStats() async throws -> PlayerStats { .empty }
    public func topFriendsThisWeek() async throws -> [TopFriend] { [] }
}
