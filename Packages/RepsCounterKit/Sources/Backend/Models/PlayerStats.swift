import ExerciseAnalyzer

/// Player statistics. `totalDuelReps` is the single total shown in ratings
/// (squats + push-ups from finalized ranked duels); training never contributes to it.
public struct PlayerStats: Hashable, Codable, Sendable {
    public var totalDuelReps: Int
    public var duelsWon: Int
    public var duelsLost: Int
    public var duelsTied: Int
    /// Best reps in a single training session, stored per exercise (CLAUDE.md §2).
    /// Whether the record depends on the session duration is still open.
    public var trainingRecords: [Exercise: Int]

    public init(
        totalDuelReps: Int,
        duelsWon: Int,
        duelsLost: Int,
        duelsTied: Int,
        trainingRecords: [Exercise: Int] = [:]
    ) {
        self.totalDuelReps = totalDuelReps
        self.duelsWon = duelsWon
        self.duelsLost = duelsLost
        self.duelsTied = duelsTied
        self.trainingRecords = trainingRecords
    }

    public var duelsPlayed: Int { duelsWon + duelsLost + duelsTied }

    /// Share of won duels in 0...1, or `nil` when no duel has been played.
    public var winRate: Double? {
        duelsPlayed == 0 ? nil : Double(duelsWon) / Double(duelsPlayed)
    }

    /// Record for one exercise; 0 when the exercise was never trained.
    public func trainingRecord(for exercise: Exercise) -> Int {
        trainingRecords[exercise] ?? 0
    }

    /// Sum of the per-exercise records, for screens that show a single number.
    public var trainingRecordTotal: Int {
        Exercise.allCases.reduce(0) { $0 + trainingRecord(for: $1) }
    }

    /// Stats after a finalized ranked duel: the duel's accepted reps join the total and the
    /// outcome joins wins / losses / draws (CLAUDE.md §7). Training records are unchanged.
    public func applying(_ outcome: DuelSummary.Outcome, reps: Int) -> PlayerStats {
        var stats = self
        stats.totalDuelReps += max(0, reps)
        switch outcome {
        case .win: stats.duelsWon += 1
        case .loss: stats.duelsLost += 1
        case .draw: stats.duelsTied += 1
        }
        return stats
    }

    /// Win rate in whole percent (64), or nil before the first duel.
    public var winRatePercent: Int? {
        winRate.map { Int(($0 * 100).rounded()) }
    }

    public static let empty = PlayerStats(totalDuelReps: 0, duelsWon: 0, duelsLost: 0, duelsTied: 0)
}
