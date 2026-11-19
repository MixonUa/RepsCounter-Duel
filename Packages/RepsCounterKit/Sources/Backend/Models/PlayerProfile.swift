import Foundation

/// Public part of a player's profile: unique nickname and emoji icon.
public struct PlayerProfile: Identifiable, Hashable, Codable, Sendable {
    /// Profile ID (used only for stable ordering and lookups; never shown in the UI).
    public let id: UUID
    public var nickname: String
    public var emoji: String

    public init(id: UUID = UUID(), nickname: String, emoji: String) {
        self.id = id
        self.nickname = nickname
        self.emoji = emoji
    }
}
