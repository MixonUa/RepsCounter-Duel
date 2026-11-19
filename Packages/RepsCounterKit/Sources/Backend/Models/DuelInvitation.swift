import Foundation
import ExerciseAnalyzer

/// A duel invitation as the invited friend sees it (CLAUDE.md §6): host, exercise, duration and
/// the expiry deadline. Stage 4 loads it from `duel_invitations` (+ realtime / push).
public struct DuelInvitation: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let host: PlayerProfile
    public let exercise: Exercise
    public let duration: DuelDuration
    /// Server-owned deadline; after it the invitation is expired.
    public let expiresAt: Date

    /// Invitation lifetime shown in Figma ("3:00 LEFT"); configurable, the server decides.
    public static let defaultLifetime: TimeInterval = 180

    public init(id: UUID = UUID(), host: PlayerProfile, exercise: Exercise, duration: DuelDuration, expiresAt: Date) {
        self.id = id
        self.host = host
        self.exercise = exercise
        self.duration = duration
        self.expiresAt = expiresAt
    }

    /// Whole seconds left at `date` (never negative).
    public func secondsLeft(at date: Date) -> Int {
        max(0, Int(expiresAt.timeIntervalSince(date).rounded(.up)))
    }

    public func isExpired(at date: Date) -> Bool { secondsLeft(at: date) == 0 }

    /// "3:00".
    public static func countdownText(seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
