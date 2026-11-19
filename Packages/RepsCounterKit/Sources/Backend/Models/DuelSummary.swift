import Foundation
import ExerciseAnalyzer

/// Result of a finalized duel from the current player's point of view.
public struct DuelSummary: Identifiable, Hashable, Codable, Sendable {
    public enum Outcome: String, Codable, Sendable {
        case win, loss, draw
    }

    public let id: UUID
    public var opponent: PlayerProfile
    public var exercise: Exercise
    public var duration: DuelDuration
    public var myReps: Int
    public var opponentReps: Int
    public var finishedAt: Date

    public init(
        id: UUID = UUID(),
        opponent: PlayerProfile,
        exercise: Exercise,
        duration: DuelDuration,
        myReps: Int,
        opponentReps: Int,
        finishedAt: Date
    ) {
        self.id = id
        self.opponent = opponent
        self.exercise = exercise
        self.duration = duration
        self.myReps = myReps
        self.opponentReps = opponentReps
        self.finishedAt = finishedAt
    }

    /// More accepted reps wins; equal reps is a draw (no tie-break).
    public var outcome: Outcome {
        if myReps > opponentReps { return .win }
        if myReps < opponentReps { return .loss }
        return .draw
    }
}
