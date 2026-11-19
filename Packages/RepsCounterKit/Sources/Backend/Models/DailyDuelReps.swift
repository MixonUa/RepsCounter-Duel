import Foundation

/// Accepted duel repetitions on one calendar day — a point of the Home chart.
public struct DailyDuelReps: Identifiable, Hashable, Codable, Sendable {
    public var day: Date
    public var reps: Int

    public var id: Date { day }

    public init(day: Date, reps: Int) {
        self.day = day
        self.reps = reps
    }
}
