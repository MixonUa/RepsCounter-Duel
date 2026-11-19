import Foundation

/// Checks whether a nickname is free before registration.
///
/// The real implementation (stage 1) asks the server, where uniqueness is enforced by a
/// case-insensitive unique constraint; the client check is only a convenience for the UI.
public protocol NicknameAvailabilityChecking: Sendable {
    /// - Returns: `true` when the nickname is free.
    /// - Throws: a network error when the server cannot be reached.
    func isNicknameAvailable(_ nickname: String) async throws -> Bool
}

public enum NicknameRules {
    /// Value sent to the server: surrounding whitespace removed.
    /// Allowed characters and length are still an open decision (CLAUDE.md §11).
    public static func normalized(_ nickname: String) -> String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Continue is enabled as soon as there is at least one non-space character.
    public static func canSubmit(_ nickname: String) -> Bool {
        !normalized(nickname).isEmpty
    }
}

/// UI-stage stand-in for the server check.
///
/// Only `admin` is taken by default (to see the "taken" error); compared case-insensitively.
/// Typing `offline` simulates a network error.
public struct MockNicknameAvailabilityService: NicknameAvailabilityChecking {
    public static let offlineTrigger = "offline"

    private let takenNicknames: Set<String>
    private let delay: Duration

    public init(
        takenNicknames: Set<String> = ["admin"],
        delay: Duration = .milliseconds(600)
    ) {
        self.takenNicknames = Set(takenNicknames.map { $0.lowercased() })
        self.delay = delay
    }

    public func isNicknameAvailable(_ nickname: String) async throws -> Bool {
        try await Task.sleep(for: delay)
        let key = NicknameRules.normalized(nickname).lowercased()
        if key == Self.offlineTrigger { throw URLError(.notConnectedToInternet) }
        return !takenNicknames.contains(key)
    }
}
