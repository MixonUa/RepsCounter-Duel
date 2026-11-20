import Foundation
import ExerciseAnalyzer

/// Personal training progress kept on the phone (CLAUDE.md §2: training never affects ratings or
/// the daily duel chart). `totalReps` is every training rep ever done on this device;
/// `records` is the best single session per exercise (the training record). Every new record is
/// also logged with its date, so Home can show "+N this week".
public struct TrainingProgress: Codable, Hashable, Sendable {
    /// A new record set at `date`, replacing `previous` (the old record; nil in saves from before
    /// it was stored — then the improvement is unknown).
    public struct RecordEvent: Codable, Hashable, Sendable {
        public let exercise: Exercise
        public let reps: Int
        public let date: Date
        public let previous: Int?
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
        let previous = record(for: exercise)
        guard reps > previous else { return false }
        records[exercise] = reps
        recordHistory.append(RecordEvent(exercise: exercise, reps: reps, date: date, previous: previous))
        return true
    }

    /// How much the record grew this week ("+3 this week"): new record − old record, where the old
    /// record is the one replaced by the first improvement since `weekStart` (was 5, now 8 → +3;
    /// 5 → 8 → 10 within the week → +5). 0 when the record wasn't improved this week or the old
    /// value is unknown (saves from before it was stored).
    ///
    /// An event saved without `previous` takes it from the record event before it; when that is
    /// unknown too, the week's growth starts at the first event whose old value is known.
    public func gain(for exercise: Exercise, since weekStart: Date) -> Int {
        let events = recordHistory.filter { $0.exercise == exercise }
        var knownOldRecordThisWeek: Int?
        for (index, event) in events.enumerated() where event.date >= weekStart {
            let old = event.previous ?? (index > 0 ? events[index - 1].reps : nil)
            if let old {
                knownOldRecordThisWeek = old
                break
            }
        }
        guard let old = knownOldRecordThisWeek else { return 0 }
        return max(0, record(for: exercise) - old)
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
