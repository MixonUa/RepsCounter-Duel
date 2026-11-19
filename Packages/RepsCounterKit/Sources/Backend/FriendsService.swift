import Foundation

/// Another player as seen on their card (FIGMA player profile).
public struct PlayerCard: Identifiable, Hashable, Sendable {
    public enum Relationship: Hashable, Sendable {
        case none
        /// My request is pending.
        case requestSent
        case friends
    }

    public let profile: PlayerProfile
    public let stats: PlayerStats
    /// Place in the weekly rating ("Top 11").
    public let weeklyRank: Int?
    /// Their 3 most recently added friends, newest first.
    public let recentFriends: [PlayerProfile]
    public let allFriends: [FriendListItem]
    public var relationship: Relationship

    public var id: PlayerProfile.ID { profile.id }

    public init(
        profile: PlayerProfile,
        stats: PlayerStats,
        weeklyRank: Int?,
        friends: [PlayerProfile],
        relationship: Relationship
    ) {
        self.profile = profile
        self.stats = stats
        self.weeklyRank = weeklyRank
        self.recentFriends = Array(friends.prefix(3))
        self.allFriends = friends.map { FriendListItem(profile: $0, weeklyRank: nil, status: .friend) }
        self.relationship = relationship
    }
}

/// Friend search and requests (stage 2: `profiles` lookup by exact case-insensitive nickname and
/// `friend_requests` through a server function; the server never exposes account IDs).
public protocol FriendsServicing: Sendable {
    /// Exact, case-insensitive nickname match; nil when nobody has it.
    func findPlayer(nickname: String) async throws -> PlayerCard?
    func sendFriendRequest(to player: PlayerProfile) async throws
    /// Accept or decline an incoming request (`friend_requests` pending → accepted | declined).
    func respondToFriendRequest(from player: PlayerProfile, accept: Bool) async throws
}

/// UI-stage stand-in with a few known players. `offline` simulates a network error.
public struct MockFriendsService: FriendsServicing {
    private let players: [PlayerCard]
    private let delay: Duration

    public init(players: [PlayerCard] = MockData.searchablePlayers, delay: Duration = .milliseconds(500)) {
        self.players = players
        self.delay = delay
    }

    public func findPlayer(nickname: String) async throws -> PlayerCard? {
        try await Task.sleep(for: delay)
        let key = NicknameRules.normalized(nickname).lowercased()
        if key == MockNicknameAvailabilityService.offlineTrigger { throw URLError(.notConnectedToInternet) }
        return players.first { $0.profile.nickname.lowercased() == key }
    }

    public func sendFriendRequest(to player: PlayerProfile) async throws {
        try await Task.sleep(for: delay)
    }

    public func respondToFriendRequest(from player: PlayerProfile, accept: Bool) async throws {
        try await Task.sleep(for: delay)
    }
}
