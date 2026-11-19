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

    public static let empty = PlayerStats(totalDuelReps: 0, duelsWon: 0, duelsLost: 0, duelsTied: 0)
}
