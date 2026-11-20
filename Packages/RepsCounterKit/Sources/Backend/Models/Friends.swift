import Foundation

/// A row of the Friends list (FIGMA "Friends").
public struct FriendListItem: Identifiable, Hashable, Sendable {
    public enum Status: Hashable, Sendable {
        /// Accepted friend: the row opens their player card.
        case friend
        /// My request is waiting for their answer (`friend_requests.pending`).
        case requestSent
    }

    public let profile: PlayerProfile
    /// Their place in the weekly rating ("Top 120").
    public let weeklyRank: Int?
    public let status: Status

    public var id: PlayerProfile.ID { profile.id }

    public init(profile: PlayerProfile, weeklyRank: Int?, status: Status) {
        self.profile = profile
        self.weeklyRank = weeklyRank
        self.status = status
    }
}

/// A row of Profile "Top Friends": the best friends of the week, recalculated once a week.
public struct TopFriend: Identifiable, Hashable, Sendable {
    public let profile: PlayerProfile
    /// The friend's own win rate ("60% win rate"); nil before their first duel.
    public let winRate: Double?
    /// "joint reps": the friend's combined reps of the week (push-ups + squats from ranked duels).
    public let jointReps: Int

    public var id: PlayerProfile.ID { profile.id }

    public init(profile: PlayerProfile, winRate: Double?, jointReps: Int) {
        self.profile = profile
        self.winRate = winRate
        self.jointReps = jointReps
    }
}

/// Everything the Profile tab shows. Mock until stage 2 (friends) / stage 5 (stats).
public struct ProfileOverview: Sendable {
    public var stats: PlayerStats
    /// Place in the weekly rating ("Top 11"); nil before the first ranked duel.
    public var weeklyRank: Int?
    /// At most 3, best first.
    public var topFriends: [TopFriend]
    public var friends: [FriendListItem]

    public init(stats: PlayerStats, weeklyRank: Int?, topFriends: [TopFriend], friends: [FriendListItem]) {
        self.stats = stats
        self.weeklyRank = weeklyRank
        self.topFriends = Array(topFriends.prefix(3))
        self.friends = friends
    }
}
