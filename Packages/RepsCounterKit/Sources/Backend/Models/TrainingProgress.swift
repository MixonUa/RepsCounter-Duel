import Foundation
import ExerciseAnalyzer

/// Personal training progress kept on the phone (CLAUDE.md §2: training never affects ratings or
/// the daily duel chart). `totalReps` is every training rep ever done on this device;
/// `records` is the best single session per exercise (the training record). Every new record is
/// also logged with its date, so Home can show "+N this week".
public struct TrainingProgress: Codable, Hashable, Sendable {
    /// A new record set at `date`.
    public struct RecordEvent: Codable, Hashable, Sendable {
        public let exercise: Exercise
        public let reps: Int
        public let date: Date
    }

    public private(set) var totalReps: Int
    public private(set) var records: [Exercise: Int]
    /// Every record improvement, oldest first (older saves have none: no gains shown for them).
    public private(set) var recordHistory: [RecordEvent]

    public init(totalReps: Int = 0, records: [Exercise: Int] = [:], recordHistory: [RecordEvent] = []) {
        self.totalReps = totalReps
        self.records = records
        self.recordHistory = recordHistory
    }

    public func record(for exercise: Exercise) -> Int { records[exercise] ?? 0 }

    /// Adds a finished session. Returns `true` when it beat the exercise's record.
    @discardableResult
    public mutating func add(reps: Int, of exercise: Exercise, at date: Date = .now) -> Bool {
        let reps = max(0, reps)
        totalReps += reps
        guard reps > record(for: exercise) else { return false }
        records[exercise] = reps
        recordHistory.append(RecordEvent(exercise: exercise, reps: reps, date: date))
        return true
    }

    /// How much the record grew since `weekStart` ("+4 this week"): the current record minus the
    /// best known before that moment (0 when the first record was set this week). 0 when the record
    /// wasn't improved this week, or for records saved before the history existed.
    public func gain(for exercise: Exercise, since weekStart: Date) -> Int {
        let events = recordHistory.filter { $0.exercise == exercise }
        guard let latest = events.last, latest.date >= weekStart else { return 0 }
        let before = events.filter { $0.date < weekStart }.map(\.reps).max() ?? 0
        return max(0, record(for: exercise) - before)
    }

    /// Gains for every exercise with an improvement since `weekStart`.
    public func gains(since weekStart: Date) -> [Exercise: Int] {
        Dictionary(uniqueKeysWithValues: Exercise.allCases.compactMap { exercise in
            let gain = gain(for: exercise, since: weekStart)
            return gain > 0 ? (exercise, gain) : nil
        })
    }

    // Saves from before `recordHistory` existed decode with an empty history.
    private enum CodingKeys: String, CodingKey { case totalReps, records, recordHistory }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalReps = try container.decode(Int.self, forKey: .totalReps)
        records = try container.decode([Exercise: Int].self, forKey: .records)
        recordHistory = try container.decodeIfPresent([RecordEvent].self, forKey: .recordHistory) ?? []
    }
}
