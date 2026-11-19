/// The weekly rating (CLAUDE.md §2: resets Monday 00:00 UTC) for both Rating tabs.
public struct RatingOverview: Sendable {
    public var global: [LeaderboardEntry]
    /// Me + my accepted friends, same rules as global.
    public var friends: [LeaderboardEntry]

    public init(global: [LeaderboardEntry], friends: [LeaderboardEntry]) {
        self.global = global
        self.friends = friends
    }

    public func entries(for scope: LeaderboardScope) -> [LeaderboardEntry] {
        scope == .global ? global : friends
    }

    public static let empty = RatingOverview(global: [], friends: [])
}
