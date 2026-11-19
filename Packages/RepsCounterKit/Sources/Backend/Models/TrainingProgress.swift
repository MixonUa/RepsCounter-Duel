import ExerciseAnalyzer

/// Personal training progress kept on the phone (CLAUDE.md §2: training never affects ratings or
/// the daily duel chart). `totalReps` is every training rep ever done on this device;
/// `records` is the best single session per exercise (the training record).
/// Stage 3 moves it to SwiftData with background sync of the record.
public struct TrainingProgress: Codable, Hashable, Sendable {
    public private(set) var totalReps: Int
    public private(set) var records: [Exercise: Int]

    public init(totalReps: Int = 0, records: [Exercise: Int] = [:]) {
        self.totalReps = totalReps
        self.records = records
    }

    public func record(for exercise: Exercise) -> Int { records[exercise] ?? 0 }

    /// Adds a finished session. Returns `true` when it beat the exercise's record.
    @discardableResult
    public mutating func add(reps: Int, of exercise: Exercise) -> Bool {
        let reps = max(0, reps)
        totalReps += reps
        guard reps > record(for: exercise) else { return false }
        records[exercise] = reps
        return true
    }
}
