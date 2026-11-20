import Foundation
import ExerciseAnalyzer

/// Offline stand-in for one-device testing (`-useMockBackend YES`) and previews. Simulates the
/// friend: accepts an invitation after `acceptDelay`, gets ready after `readyDelay`, and makes a
/// rep every `opponentRepInterval` seconds during the live window. Same rules as the server
/// (sequential reps, window, grace) in a simplified form.
public actor MockDuelService: DuelServicing {
    private struct Duel {
        var id = UUID()
        var role: DuelSnapshot.Role
        var opponent: PlayerProfile
        var exercise: Exercise
        var duration: DuelDuration
        var createdAt = Date.now
        var expiresAt = Date.now.addingTimeInterval(DuelInvitation.defaultLifetime)
        var acceptedAt: Date?
        var myReady = false
        var startsAt: Date?
        var endsAt: Date?
        var myReps = 0
        var closedPhase: DuelSnapshot.Phase?
        var forfeitedByMe = false
    }

    private var duels: [UUID: Duel] = [:]
    private let acceptDelay: TimeInterval
    private let readyDelay: TimeInterval
    private let opponentRepInterval: TimeInterval

    /// - Parameter incomingFrom: when set, an invitation from this player waits for me.
    public init(
        incomingFrom host: PlayerProfile? = nil,
        acceptDelay: TimeInterval = 3,
        readyDelay: TimeInterval = 3,
        opponentRepInterval: TimeInterval = 3.5
    ) {
        self.acceptDelay = acceptDelay
        self.readyDelay = readyDelay
        self.opponentRepInterval = opponentRepInterval
        if let host {
            var duel = Duel(role: .guest, opponent: host, exercise: .pushUps, duration: .default)
            duel.acceptedAt = nil
            duels[duel.id] = duel
        }
    }

    public func create(friend: PlayerProfile, exercise: Exercise, duration: DuelDuration) async throws -> DuelSnapshot {
        let duel = Duel(role: .host, opponent: friend, exercise: exercise, duration: duration)
        duels[duel.id] = duel
        return snapshot(duel)
    }

    public func incomingInvitations() async throws -> [DuelSnapshot] {
        duels.values.filter { $0.role == .guest && phase($0) == .invited }.map(snapshot)
    }

    public func view(_ id: UUID) async throws -> DuelSnapshot? {
        guard var duel = duels[id] else { return nil }
        // The simulated friend accepts the host's invitation after a moment.
        if duel.role == .host, duel.acceptedAt == nil, phase(duel) == .invited,
           Date.now.timeIntervalSince(duel.createdAt) >= acceptDelay {
            duel.acceptedAt = .now
        }
        startIfBothReady(&duel)
        duels[id] = duel
        return snapshot(duel)
    }

    public func respond(to id: UUID, accept: Bool) async throws -> DuelSnapshot {
        guard var duel = duels[id], duel.role == .guest else { throw DuelServiceError.noLongerAvailable }
        guard phase(duel) == .invited else { throw DuelServiceError.noLongerAvailable }
        if accept { duel.acceptedAt = .now } else { duel.closedPhase = .declined }
        duels[id] = duel
        return snapshot(duel)
    }

    public func setReady(_ id: UUID) async throws -> DuelSnapshot {
        guard var duel = duels[id] else { throw DuelServiceError.noLongerAvailable }
        if phase(duel) == .lobby { duel.myReady = true }
        startIfBothReady(&duel)
        duels[id] = duel
        return snapshot(duel)
    }

    public func submitRep(_ id: UUID, sequence: Int) async throws -> DuelSnapshot {
        guard var duel = duels[id] else { throw DuelServiceError.noLongerAvailable }
        if let start = duel.startsAt, let end = duel.endsAt, Date.now >= start, Date.now < end.addingTimeInterval(2),
           sequence == duel.myReps + 1 {
            duel.myReps += 1
        }
        duels[id] = duel
        return snapshot(duel)
    }

    public func finish(_ id: UUID) async throws -> DuelSnapshot {
        guard var duel = duels[id] else { throw DuelServiceError.noLongerAvailable }
        if duel.closedPhase == nil, let end = duel.endsAt, Date.now >= end.addingTimeInterval(2) {
            duel.closedPhase = .completed
        }
        duels[id] = duel
        return snapshot(duel)
    }

    public func leave(_ id: UUID) async throws -> DuelSnapshot {
        guard var duel = duels[id] else { throw DuelServiceError.noLongerAvailable }
        switch phase(duel) {
        case .invited: duel.closedPhase = duel.role == .host ? .cancelled : .declined
        case .lobby, .countdown: duel.closedPhase = .cancelled
        case .live:
            duel.closedPhase = .forfeited
            duel.forfeitedByMe = true
        default: break
        }
        duels[id] = duel
        return snapshot(duel)
    }

    public func activeDuel() async throws -> DuelSnapshot? {
        duels.values
            .filter { [.lobby, .countdown, .live, .finishing].contains(phase($0)) || ($0.role == .host && phase($0) == .invited) }
            .max { $0.createdAt < $1.createdAt }
            .map(snapshot)
    }

    public func heartbeat(_ id: UUID) async throws -> DuelSnapshot {
        guard let snapshot = try await view(id) else { throw DuelServiceError.noLongerAvailable }
        return snapshot
    }

    /// The simulated friend has no history yet.
    public func headToHead(_ id: UUID, exercise: Exercise) async throws -> DuelHeadToHead? {
        guard duels[id] != nil else { return nil }
        return DuelHeadToHead(me: .empty, opponent: .empty)
    }

    // MARK: - Simulation

    private func opponentReady(_ duel: Duel) -> Bool {
        guard let accepted = duel.acceptedAt else { return false }
        return Date.now.timeIntervalSince(accepted) >= readyDelay
    }

    private func startIfBothReady(_ duel: inout Duel) {
        guard duel.startsAt == nil, duel.myReady, opponentReady(duel) else { return }
        let start = Date.now.addingTimeInterval(4)
        duel.startsAt = start
        duel.endsAt = start.addingTimeInterval(TimeInterval(duel.duration.seconds))
    }

    private func phase(_ duel: Duel) -> DuelSnapshot.Phase {
        if let closed = duel.closedPhase { return closed }
        if let start = duel.startsAt, let end = duel.endsAt {
            if Date.now < start { return .countdown }
            return Date.now < end ? .live : .finishing
        }
        if duel.acceptedAt != nil { return .lobby }
        return Date.now >= duel.expiresAt ? .expired : .invited
    }

    private func opponentReps(_ duel: Duel) -> Int {
        guard let start = duel.startsAt, let end = duel.endsAt, Date.now > start else { return 0 }
        let elapsed = min(Date.now, end).timeIntervalSince(start)
        return Int(elapsed / opponentRepInterval)
    }

    private func snapshot(_ duel: Duel) -> DuelSnapshot {
        DuelSnapshot(
            id: duel.id, phase: phase(duel), role: duel.role, opponent: duel.opponent,
            exercise: duel.exercise, duration: duel.duration, expiresAt: duel.expiresAt,
            myReady: duel.myReady, opponentReady: opponentReady(duel),
            startsAt: duel.startsAt, endsAt: duel.endsAt,
            myReps: duel.myReps, opponentReps: opponentReps(duel), forfeitedByMe: duel.forfeitedByMe
        )
    }
}
