import Foundation

/// Another player as seen on their card (FIGMA player profile).
public struct PlayerCard: Identifiable, Hashable, Sendable {
    public enum Relationship: Hashable, Sendable {
        case none
        /// My request is pending.
        case requestSent
        /// They asked me; "+ Add Friend" accepts it.
        case requestReceived
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

/// Outcome of "+ Add Friend".
public enum FriendRequestResult: Sendable, Equatable {
    case sent
    case alreadySent
    case alreadyFriends
    /// They had already asked me, so we are friends now.
    case accepted
}

public enum FriendsError: Error, Equatable {
    case playerNotFound
    case cannotAddSelf
    /// Too many requests today (server anti-abuse limit).
    case rateLimited
}

/// Friend search, requests and lists (stage 2: server RPCs identify players by nickname and
/// return only nickname / emoji / relationship — account IDs never leave the server).
public protocol FriendsServicing: Sendable {
    /// Exact, case-insensitive nickname match; nil when nobody has it.
    func findPlayer(nickname: String) async throws -> PlayerCard?
    @discardableResult
    func sendFriendRequest(to player: PlayerProfile) async throws -> FriendRequestResult
    /// Accept or decline an incoming request (`friend_requests` pending → accepted | declined).
    func respondToFriendRequest(from player: PlayerProfile, accept: Bool) async throws
    /// My accepted friends (newest first), then my pending sent requests.
    func fetchFriends() async throws -> [FriendListItem]
    /// Requests waiting for my answer, oldest first.
    func fetchIncomingRequests() async throws -> [PlayerProfile]
    /// All friends of another player (player card → see all).
    func fetchFriends(of player: PlayerProfile) async throws -> [FriendListItem]
    /// Unfriend (either side may do it).
    func removeFriend(_ player: PlayerProfile) async throws
    /// Withdraw my pending request.
    func cancelFriendRequest(to player: PlayerProfile) async throws
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

    public func sendFriendRequest(to player: PlayerProfile) async throws -> FriendRequestResult {
        try await Task.sleep(for: delay)
        return .sent
    }

    public func respondToFriendRequest(from player: PlayerProfile, accept: Bool) async throws {
        try await Task.sleep(for: delay)
    }

    public func fetchFriends() async throws -> [FriendListItem] { [] }

    public func fetchIncomingRequests() async throws -> [PlayerProfile] { [] }

    public func removeFriend(_ player: PlayerProfile) async throws {
        try await Task.sleep(for: delay)
    }

    public func cancelFriendRequest(to player: PlayerProfile) async throws {
        try await Task.sleep(for: delay)
    }

    public func fetchFriends(of player: PlayerProfile) async throws -> [FriendListItem] {
        players.first { $0.profile.nickname.lowercased() == player.nickname.lowercased() }?.allFriends ?? []
    }
}
