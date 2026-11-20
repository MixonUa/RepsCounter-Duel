import Foundation
import Supabase

/// Friends over the stage-2 RPCs (`supabase/migrations/20261120030000_friends.sql`).
/// Players are addressed by nickname; the server answers with nickname / emoji / relationship
/// plus public numbers: all-time duel stats (card) and this week's global place ("Top N").
public struct SupabaseFriendsService: FriendsServicing {
    private let backend: SupabaseBackend

    public init(backend: SupabaseBackend) {
        self.backend = backend
    }

    private struct PlayerRow: Decodable {
        let nickname: String
        let emoji: String
        /// This week's global place; nil without reps this week (or where not sent).
        let weekly_rank: Int?
        var profile: PlayerProfile { PlayerProfile(serverNickname: nickname, emoji: emoji) }
    }

    private struct FriendRow: Decodable {
        let nickname: String
        let emoji: String
        let status: String
        let weekly_rank: Int?
    }

    private struct StatsRow: Decodable {
        let duels_won: Int
        let duels_lost: Int
        let duels_tied: Int
        let total_duel_reps: Int
    }

    private struct CardRow: Decodable {
        let nickname: String
        let emoji: String
        let relationship: String
        let stats: StatsRow?
        let weeklyRank: Int?
        let recentFriends: [PlayerRow]

        enum CodingKeys: String, CodingKey {
            case nickname, emoji, relationship, stats
            case weeklyRank = "weekly_rank"
            case recentFriends = "recent_friends"
        }
    }

    public func findPlayer(nickname: String) async throws -> PlayerCard? {
        let row: CardRow? = try await call("find_player", ["player_nickname": NicknameRules.normalized(nickname)])
        guard let row else { return nil }
        let relationship: PlayerCard.Relationship = switch row.relationship {
        case "friends": .friends
        case "request_sent": .requestSent
        case "request_received": .requestReceived
        default: .none
        }
        return PlayerCard(
            profile: PlayerProfile(serverNickname: row.nickname, emoji: row.emoji),
            stats: row.stats.map {
                PlayerStats(totalDuelReps: $0.total_duel_reps, duelsWon: $0.duels_won, duelsLost: $0.duels_lost, duelsTied: $0.duels_tied)
            } ?? .empty,
            weeklyRank: row.weeklyRank,
            friends: row.recentFriends.map(\.profile),
            relationship: relationship
        )
    }

    public func sendFriendRequest(to player: PlayerProfile) async throws -> FriendRequestResult {
        let result: String = try await call("send_friend_request", ["player_nickname": player.nickname])
        switch result {
        case "already_sent": return .alreadySent
        case "already_friends": return .alreadyFriends
        case "accepted": return .accepted
        default: return .sent
        }
    }

    public func respondToFriendRequest(from player: PlayerProfile, accept: Bool) async throws {
        struct Params: Encodable {
            let player_nickname: String
            let accept: Bool
        }
        try await backend.ensureSession()
        _ = try await mapErrors {
            try await backend.client
                .rpc("respond_to_friend_request", params: Params(player_nickname: player.nickname, accept: accept))
                .execute()
        }
    }

    public func fetchFriends() async throws -> [FriendListItem] {
        let rows: [FriendRow] = try await call("my_friends")
        return rows.map {
            FriendListItem(
                profile: PlayerProfile(serverNickname: $0.nickname, emoji: $0.emoji),
                weeklyRank: $0.weekly_rank,
                status: $0.status == "request_sent" ? .requestSent : .friend
            )
        }
    }

    public func fetchIncomingRequests() async throws -> [PlayerProfile] {
        let rows: [PlayerRow] = try await call("incoming_friend_requests")
        return rows.map(\.profile)
    }

    public func fetchFriends(of player: PlayerProfile) async throws -> [FriendListItem] {
        let rows: [PlayerRow] = try await call("player_friends", ["player_nickname": player.nickname])
        return rows.map { FriendListItem(profile: $0.profile, weeklyRank: $0.weekly_rank, status: .friend) }
    }

    // MARK: - Calls

    private func call<T: Decodable>(_ function: String, _ params: [String: String] = [:]) async throws -> T {
        try await backend.ensureSession()
        return try await mapErrors {
            try await backend.client.rpc(function, params: params).execute().value
        }
    }

    private func mapErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as PostgrestError {
            switch (error.code, error.message) {
            case ("P0002", _): throw FriendsError.playerNotFound
            case ("22023", _): throw FriendsError.cannotAddSelf
            case (_, let message) where message.contains("rate_limited"): throw FriendsError.rateLimited
            default: throw error
            }
        }
    }
}
