import Foundation
import Supabase
import ExerciseAnalyzer

/// Duels over the stage-4 RPCs.
public struct SupabaseDuelService: DuelServicing {
    private let backend: SupabaseBackend

    public init(backend: SupabaseBackend) {
        self.backend = backend
    }

    public func create(friend: PlayerProfile, exercise: Exercise, duration: DuelDuration) async throws -> DuelSnapshot {
        struct Params: Encodable {
            let friend_nickname: String
            let exercise: String
            let duration_seconds: Int
        }
        return try await snapshot("create_duel", Params(friend_nickname: friend.nickname, exercise: exercise.rawValue, duration_seconds: duration.seconds))
    }

    public func incomingInvitations() async throws -> [DuelSnapshot] {
        try await backend.ensureSession()
        let rows: [DuelRow] = try await mapErrors {
            try await backend.client.rpc("incoming_duel_invitations").execute().value
        }
        let now = Date.now
        return try rows.map { try $0.snapshot(receivedAt: now) }
    }

    public func view(_ duel: UUID) async throws -> DuelSnapshot? {
        try await backend.ensureSession()
        let row: DuelRow? = try await mapErrors {
            try await backend.client.rpc("duel_view", params: ["duel": duel]).execute().value
        }
        return try row?.snapshot()
    }

    public func respond(to duel: UUID, accept: Bool) async throws -> DuelSnapshot {
        struct Params: Encodable {
            let duel: UUID
            let accept: Bool
        }
        return try await snapshot("respond_to_duel", Params(duel: duel, accept: accept))
    }

    public func setReady(_ duel: UUID) async throws -> DuelSnapshot {
        try await snapshot("set_duel_ready", ["duel": duel])
    }

    public func submitRep(_ duel: UUID, sequence: Int) async throws -> DuelSnapshot {
        struct Params: Encodable {
            let duel: UUID
            let seq: Int
        }
        return try await snapshot("submit_duel_rep", Params(duel: duel, seq: sequence))
    }

    public func finish(_ duel: UUID) async throws -> DuelSnapshot {
        try await snapshot("finish_duel", ["duel": duel])
    }

    public func leave(_ duel: UUID) async throws -> DuelSnapshot {
        try await snapshot("leave_duel", ["duel": duel])
    }

    public func headToHead(_ duel: UUID, exercise: Exercise) async throws -> DuelHeadToHead? {
        struct Row: Decodable {
            let me: PlayerStatsRow
            let opponent: PlayerStatsRow
        }
        try await backend.ensureSession()
        let row: Row? = try await mapErrors {
            try await backend.client.rpc("duel_head_to_head", params: ["duel": duel]).execute().value
        }
        return row.map { DuelHeadToHead(me: $0.me.stats(exercise: exercise), opponent: $0.opponent.stats(exercise: exercise)) }
    }

    // MARK: - Calls

    private func snapshot(_ function: String, _ params: some Encodable & Sendable) async throws -> DuelSnapshot {
        try await backend.ensureSession()
        let row: DuelRow = try await mapErrors {
            try await backend.client.rpc(function, params: params).execute().value
        }
        return try row.snapshot()
    }

    private func mapErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as PostgrestError {
            let message = error.message
            switch error.code {
            case "P0002": throw DuelServiceError.playerNotFound
            case "42501" where message.contains("not_friends"): throw DuelServiceError.notFriends
            case "55000" where message.contains("busy"): throw DuelServiceError.busy
            case "55000": throw DuelServiceError.noLongerAvailable
            case "P0001" where message.contains("rate_limited"): throw DuelServiceError.rateLimited
            default: throw error
            }
        }
    }
}
