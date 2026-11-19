import Foundation

/// Creates the player's profile (nickname + emoji) on the server.
///
/// Stage 1: anonymous Supabase session + insert into `profiles`; the unique constraint can still
/// reject a nickname taken since the availability check, which surfaces as `.nicknameTaken`.
public protocol ProfileRegistering: Sendable {
    func register(nickname: String, emoji: String) async throws -> PlayerProfile
}

public enum ProfileRegistrationError: Error, Equatable {
    case nicknameTaken
}

/// UI-stage stand-in: succeeds after a short delay, except for the same triggers as
/// `MockNicknameAvailabilityService` (`admin` → taken, `offline` → network error).
public struct MockProfileRegistrationService: ProfileRegistering {
    private let delay: Duration

    public init(delay: Duration = .milliseconds(600)) {
        self.delay = delay
    }

    public func register(nickname: String, emoji: String) async throws -> PlayerProfile {
        try await Task.sleep(for: delay)
        let normalized = NicknameRules.normalized(nickname)
        switch normalized.lowercased() {
        case "admin": throw ProfileRegistrationError.nicknameTaken
        case MockNicknameAvailabilityService.offlineTrigger: throw URLError(.notConnectedToInternet)
        default: return PlayerProfile(nickname: normalized, emoji: emoji)
        }
    }
}
