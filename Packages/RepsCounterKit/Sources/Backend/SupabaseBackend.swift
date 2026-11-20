import Foundation
import Supabase

/// The app's single Supabase client and its anonymous session (CLAUDE.md §3).
/// - First launch: `ensureSession()` signs in anonymously (needs network).
/// - The session lives in the Keychain and refreshes itself while the app stays installed.
/// - Fresh install (`isFreshInstall`): a session left in the Keychain by a previous install is
///   dropped before anything else, so a reinstall always starts a new, empty profile.
public final class SupabaseBackend: Sendable {
    public let client: SupabaseClient
    private let launchCleanup: Task<Void, Never>

    public init(configuration: BackendConfiguration, isFreshInstall: Bool) {
        let client = configuration.makeClient()
        self.client = client
        launchCleanup = Task {
            guard isFreshInstall else { return }
            try? await client.auth.signOut(scope: .local)
        }
    }

    /// The current auth user ID, signing in anonymously when there is no session yet.
    @discardableResult
    public func ensureSession() async throws -> UUID {
        await launchCleanup.value
        if let session = try? await client.auth.session {
            return session.user.id
        }
        return try await client.auth.signInAnonymously().user.id
    }
}

/// `is_nickname_available` RPC: answers yes / no without exposing anyone's data.
public struct SupabaseNicknameAvailabilityService: NicknameAvailabilityChecking {
    private let backend: SupabaseBackend

    public init(backend: SupabaseBackend) {
        self.backend = backend
    }

    public func isNicknameAvailable(_ nickname: String) async throws -> Bool {
        try await backend.ensureSession()
        let available: Bool = try await backend.client
            .rpc("is_nickname_available", params: ["candidate": NicknameRules.normalized(nickname)])
            .execute()
            .value
        return available
    }
}

/// Registration and Edit Profile on the `profiles` table (RLS: only my own row).
public struct SupabaseProfileService: ProfileRegistering, ProfileUpdating {
    private let backend: SupabaseBackend

    public init(backend: SupabaseBackend) {
        self.backend = backend
    }

    private struct ProfileRow: Codable {
        let id: UUID
        let nickname: String
        let emoji: String
    }

    private struct NicknameChange: Encodable { let nickname: String }
    private struct EmojiChange: Encodable { let emoji: String }

    /// Upsert by user ID, so retrying after a lost response does not fail on my own row.
    public func register(nickname: String, emoji: String) async throws -> PlayerProfile {
        let userID = try await backend.ensureSession()
        let row = ProfileRow(id: userID, nickname: NicknameRules.normalized(nickname), emoji: emoji)
        let saved: ProfileRow = try await Self.mappingErrors {
            try await backend.client.from("profiles")
                .upsert(row, onConflict: "id")
                .select()
                .single()
                .execute()
                .value
        }
        return PlayerProfile(nickname: saved.nickname, emoji: saved.emoji)
    }

    public func updateNickname(_ nickname: String) async throws -> String {
        let userID = try await backend.ensureSession()
        let saved: ProfileRow = try await Self.mappingErrors {
            try await backend.client.from("profiles")
                .update(NicknameChange(nickname: NicknameRules.normalized(nickname)))
                .eq("id", value: userID)
                .select()
                .single()
                .execute()
                .value
        }
        return saved.nickname
    }

    public func updateEmoji(_ emoji: String) async throws {
        let userID = try await backend.ensureSession()
        try await backend.client.from("profiles")
            .update(EmojiChange(emoji: emoji))
            .eq("id", value: userID)
            .execute()
    }

    /// Postgres unique violation → taken; check violation → invalid nickname.
    private static func mappingErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as PostgrestError {
            switch error.code {
            case "23505": throw ProfileRegistrationError.nicknameTaken
            case "23514": throw ProfileRegistrationError.invalidNickname
            default: throw error
            }
        }
    }
}
