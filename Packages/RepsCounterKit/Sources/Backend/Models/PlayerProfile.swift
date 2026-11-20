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

    /// A player received from the server, which never sends account IDs: the local ID is derived
    /// from the (unique, case-insensitive) nickname, so the same player keeps the same identity
    /// across fetches.
    public init(serverNickname nickname: String, emoji: String) {
        self.init(id: Self.stableID(for: nickname), nickname: nickname, emoji: emoji)
    }

    /// FNV-1a over the lowercased nickname, spread into 128 bits (not a security hash).
    static func stableID(for nickname: String) -> UUID {
        var high: UInt64 = 0xcbf29ce484222325
        var low: UInt64 = 0x84222325cbf29ce4
        for byte in nickname.lowercased().utf8 {
            high = (high ^ UInt64(byte)) &* 0x100000001b3
            low = (low ^ UInt64(byte) ^ (high >> 7)) &* 0x100000001b3
        }
        var bytes = [UInt8](repeating: 0, count: 16)
        for i in 0..<8 {
            bytes[i] = UInt8(truncatingIfNeeded: high >> (8 * UInt64(i)))
            bytes[8 + i] = UInt8(truncatingIfNeeded: low >> (8 * UInt64(i)))
        }
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
