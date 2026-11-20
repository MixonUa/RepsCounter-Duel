import Foundation
import ExerciseAnalyzer

/// A duel as one participant sees it, straight from the server (`duel_view` and friends in
/// `supabase/migrations/20261120050000_duels.sql`). Times are already converted to this device's
/// clock using the server's `server_now`, so they can be compared with `Date.now` directly.
public struct DuelSnapshot: Sendable, Hashable, Identifiable {
    public enum Phase: String, Sendable, Hashable {
        case invited, expired, declined, cancelled, lobby, countdown, live, finishing, completed, forfeited
        /// A player was silent longer than the reconnect grace: no winner, no rating reps.
        case interrupted

        /// The duel is over (no more changes expected).
        public var isClosed: Bool {
            switch self {
            case .expired, .declined, .cancelled, .completed, .forfeited, .interrupted: true
            default: false
            }
        }
    }

    public enum Role: String, Sendable, Hashable { case host, guest }

    public let id: UUID
    public let phase: Phase
    public let role: Role
    public let opponent: PlayerProfile
    public let exercise: Exercise
    public let duration: DuelDuration
    public let expiresAt: Date
    public let myReady: Bool
    public let opponentReady: Bool
    public let startsAt: Date?
    public let endsAt: Date?
    public let myReps: Int
    public let opponentReps: Int
    public let forfeitedByMe: Bool

    public init(
        id: UUID, phase: Phase, role: Role, opponent: PlayerProfile, exercise: Exercise, duration: DuelDuration,
        expiresAt: Date, myReady: Bool, opponentReady: Bool, startsAt: Date?, endsAt: Date?,
        myReps: Int, opponentReps: Int, forfeitedByMe: Bool
    ) {
        self.id = id
        self.phase = phase
        self.role = role
        self.opponent = opponent
        self.exercise = exercise
        self.duration = duration
        self.expiresAt = expiresAt
        self.myReady = myReady
        self.opponentReady = opponentReady
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.myReps = myReps
        self.opponentReps = opponentReps
        self.forfeitedByMe = forfeitedByMe
    }

    /// The incoming-invitation view of this duel (for the invitee).
    public var invitation: DuelInvitation {
        DuelInvitation(id: id, host: opponent, exercise: exercise, duration: duration, expiresAt: expiresAt)
    }
}

/// Both players' numbers for HEAD TO HEAD (training PR for the duel's exercise, completed duels).
public struct DuelHeadToHead: Sendable, Equatable {
    public let me: PlayerStats
    public let opponent: PlayerStats

    public init(me: PlayerStats, opponent: PlayerStats) {
        self.me = me
        self.opponent = opponent
    }
}

public enum DuelServiceError: Error, Equatable {
    case playerNotFound
    case notFriends
    /// One of the players is already in a duel.
    case busy
    /// The invitation expired or was answered already.
    case noLongerAvailable
    case rateLimited
}

/// Server-authoritative duel lifecycle (CLAUDE.md §6). Clients poll `view` and send reps one by
/// one numbered 1, 2, 3…; the server decides what counts.
public protocol DuelServicing: Sendable {
    func create(friend: PlayerProfile, exercise: Exercise, duration: DuelDuration) async throws -> DuelSnapshot
    func incomingInvitations() async throws -> [DuelSnapshot]
    /// nil when the duel is not mine (or doesn't exist).
    func view(_ duel: UUID) async throws -> DuelSnapshot?
    func respond(to duel: UUID, accept: Bool) async throws -> DuelSnapshot
    func setReady(_ duel: UUID) async throws -> DuelSnapshot
    func submitRep(_ duel: UUID, sequence: Int) async throws -> DuelSnapshot
    func finish(_ duel: UUID) async throws -> DuelSnapshot
    func leave(_ duel: UUID) async throws -> DuelSnapshot
    /// "I'm still here" (lobby / countdown / live, about every second); returns the duel view.
    func heartbeat(_ duel: UUID) async throws -> DuelSnapshot
    /// Real stats of both players for the lobby; nil when the duel is not mine.
    func headToHead(_ duel: UUID, exercise: Exercise) async throws -> DuelHeadToHead?
}

/// Saves my best training session per exercise on the server (shown to opponents as "PR";
/// never affects ratings). The server keeps the greatest value.
public protocol TrainingRecordSyncing: Sendable {
    @discardableResult
    func saveTrainingRecord(_ reps: Int, for exercise: Exercise) async throws -> Int
}

/// `player_stats` JSON from the server.
struct PlayerStatsRow: Decodable {
    let duels_won: Int
    let duels_lost: Int
    let duels_tied: Int
    let total_duel_reps: Int
    let training_record: Int

    func stats(exercise: Exercise) -> PlayerStats {
        PlayerStats(
            totalDuelReps: total_duel_reps, duelsWon: duels_won, duelsLost: duels_lost, duelsTied: duels_tied,
            trainingRecords: [exercise: training_record]
        )
    }
}

// MARK: - Wire format

/// JSON from the duel RPCs.
struct DuelRow: Decodable {
    struct Player: Decodable {
        let nickname: String
        let emoji: String
    }

    let id: UUID
    let phase: String
    let role: String
    let opponent: Player
    let exercise: String
    let duration_seconds: Int
    let expires_at: String
    let my_ready: Bool
    let opponent_ready: Bool
    let starts_at: String?
    let ends_at: String?
    let my_reps: Int
    let opponent_reps: Int
    let forfeited_by_me: Bool
    let server_now: String

    /// - Parameter receivedAt: local time when the response arrived (for the clock offset).
    func snapshot(receivedAt: Date = .now) throws -> DuelSnapshot {
        guard let serverNow = Self.date(server_now), let expires = Self.date(expires_at),
              let phase = DuelSnapshot.Phase(rawValue: phase),
              let role = DuelSnapshot.Role(rawValue: role),
              let exercise = Exercise(rawValue: exercise) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unexpected duel row"))
        }
        // Server time + offset = local time. Network delay makes it slightly late (safe side).
        let offset = receivedAt.timeIntervalSince(serverNow)
        func local(_ date: Date?) -> Date? { date.map { $0.addingTimeInterval(offset) } }
        return DuelSnapshot(
            id: id,
            phase: phase,
            role: role,
            opponent: PlayerProfile(serverNickname: opponent.nickname, emoji: opponent.emoji),
            exercise: exercise,
            duration: DuelDuration(seconds: duration_seconds),
            expiresAt: expires.addingTimeInterval(offset),
            myReady: my_ready,
            opponentReady: opponent_ready,
            startsAt: local(starts_at.flatMap(Self.date)),
            endsAt: local(ends_at.flatMap(Self.date)),
            myReps: my_reps,
            opponentReps: opponent_reps,
            forfeitedByMe: forfeited_by_me
        )
    }

    /// Postgres JSON timestamps: `2026-11-20T09:10:43.899099+00:00` (fraction optional).
    static func date(_ string: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: string) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }
}
