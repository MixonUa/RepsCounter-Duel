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
    public static func normalized(_ nickname: String) -> String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Continue is enabled as soon as there is at least one non-space character.
    public static func canSubmit(_ nickname: String) -> Bool {
        !normalized(nickname).isEmpty
    }

    /// Decided 2026-11-20 (also enforced by the server's `profiles_nickname_format` check):
    /// 3–20 Latin letters, digits, underscore or dot.
    public static let minLength = 3
    public static let maxLength = 20

    public static func isValid(_ nickname: String) -> Bool {
        let value = normalized(nickname)
        guard (minLength...maxLength).contains(value.count) else { return false }
        return value.unicodeScalars.allSatisfy { scalar in
            scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || scalar == "_" || scalar == ".")
        }
    }

    /// PROVISIONAL copy (no Figma frame).
    public static let formatHint = "Use 3–20 letters, digits, _ or ."

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
