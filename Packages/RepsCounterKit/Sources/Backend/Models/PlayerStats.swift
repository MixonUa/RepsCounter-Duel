/// Player statistics. `totalDuelReps` is the single total shown everywhere
/// (squats + push-ups from finalized ranked duels); training never contributes to it.
public struct PlayerStats: Hashable, Codable, Sendable {
    public var totalDuelReps: Int
    public var duelsWon: Int
    public var duelsLost: Int
    public var duelsTied: Int
    /// Best result achieved in a single training session (definition still open, see CLAUDE.md §11).
    public var trainingRecord: Int

    public init(totalDuelReps: Int, duelsWon: Int, duelsLost: Int, duelsTied: Int, trainingRecord: Int) {
        self.totalDuelReps = totalDuelReps
        self.duelsWon = duelsWon
        self.duelsLost = duelsLost
        self.duelsTied = duelsTied
        self.trainingRecord = trainingRecord
    }

    public var duelsPlayed: Int { duelsWon + duelsLost + duelsTied }

    /// Share of won duels in 0...1, or `nil` when no duel has been played.
    public var winRate: Double? {
        duelsPlayed == 0 ? nil : Double(duelsWon) / Double(duelsPlayed)
    }

    public static let empty = PlayerStats(totalDuelReps: 0, duelsWon: 0, duelsLost: 0, duelsTied: 0, trainingRecord: 0)
}
