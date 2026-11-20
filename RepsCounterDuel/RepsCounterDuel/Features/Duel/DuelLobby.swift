import Foundation
import Backend
import ExerciseAnalyzer

/// A duel both players agreed to: what the "Ready to duel?" lobby shows.
/// Built from the server duel once it reaches the lobby. Stats start with my local training
/// records only; `withServerStats` adds both players' real numbers (`duel_head_to_head`).
struct DuelLobby: Identifiable, Hashable {
    /// The server duel (`duels.id`).
    let id: UUID
    let me: PlayerProfile
    let opponent: PlayerProfile
    let exercise: Exercise
    let duration: DuelDuration
    private(set) var myStats: PlayerStats
    private(set) var opponentStats: PlayerStats = .empty
    /// False until the server stats arrived (the opponent's numbers show "—").
    private(set) var hasServerStats = false

    init(id: UUID = UUID(), me: PlayerProfile, opponent: PlayerProfile, exercise: Exercise, duration: DuelDuration, myStats: PlayerStats) {
        self.id = id
        self.me = me
        self.opponent = opponent
        self.exercise = exercise
        self.duration = duration
        self.myStats = myStats
    }

    /// Server numbers for both; my PR is the greater of the server and this phone (not synced yet).
    func withServerStats(_ stats: DuelHeadToHead?) -> DuelLobby {
        guard let stats else { return self }
        var copy = self
        var mine = stats.me
        mine.trainingRecords[exercise] = max(stats.me.trainingRecord(for: exercise), myStats.trainingRecord(for: exercise))
        copy.myStats = mine
        copy.opponentStats = stats.opponent
        copy.hasServerStats = true
        return copy
    }
}

extension DuelLobby {
    init(snapshot: DuelSnapshot, me: PlayerProfile, myStats: PlayerStats) {
        self.init(id: snapshot.id, me: me, opponent: snapshot.opponent, exercise: snapshot.exercise, duration: snapshot.duration, myStats: myStats)
    }
}
