import Foundation
import Backend
import ExerciseAnalyzer

/// A duel both players agreed to: what the "Ready to duel?" lobby shows.
/// UI stage: built locally from the invitation; stage 4 gets it from the server match
/// (`duels` + `duel_participants`).
struct DuelLobby: Identifiable, Hashable {
    let id = UUID()
    let me: PlayerProfile
    let opponent: PlayerProfile
    let exercise: Exercise
    let duration: DuelDuration
    let myStats: PlayerStats
    let opponentStats: PlayerStats

    init(me: PlayerProfile, opponent: PlayerProfile, exercise: Exercise, duration: DuelDuration, myStats: PlayerStats) {
        self.me = me
        self.opponent = opponent
        self.exercise = exercise
        self.duration = duration
        self.myStats = myStats
        self.opponentStats = Self.mockStats(for: opponent)
    }

    /// UI stage: the opponent's public stats from the mock search data, or fixed numbers.
    private static func mockStats(for player: PlayerProfile) -> PlayerStats {
        if let card = MockData.searchablePlayers.first(where: { $0.profile.nickname.lowercased() == player.nickname.lowercased() }) {
            var stats = card.stats
            if stats.trainingRecords.isEmpty { stats.trainingRecords = [.pushUps: 49, .squats: 62] }
            return stats
        }
        return PlayerStats(totalDuelReps: 210, duelsWon: 19, duelsLost: 19, duelsTied: 0, trainingRecords: [.pushUps: 49, .squats: 62])
    }
}
