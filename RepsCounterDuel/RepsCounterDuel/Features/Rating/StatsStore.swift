import Foundation
import Observation
import OSLog
import Backend

/// Server numbers for Home, Profile and Rating (stage 5): this week's Global / Friends boards,
/// my recent completed duels, my all-time stats and Top Friends. Refreshed when the app becomes
/// active, when Home / Rating / Profile appear, and after a duel.
@Observable
final class StatsStore {
    private(set) var global: [LeaderboardEntry] = []
    private(set) var friends: [LeaderboardEntry] = []
    /// My completed duels of the last 8 days, newest first (Home chart and last duel).
    private(set) var recentDuels: [DuelSummary] = []
    private(set) var myStats: PlayerStats = .empty
    private(set) var topFriends: [TopFriend] = []

    @ObservationIgnored private let service: any StatsServicing

    init(service: any StatsServicing = AppServices.statsService) {
        self.service = service
    }

    func refresh() async {
        do {
            async let global = service.leaderboard(.global)
            async let friends = service.leaderboard(.friends)
            async let history = service.duelHistory(since: .now.addingTimeInterval(-8 * 24 * 3600), limit: 100)
            async let stats = service.myStats()
            async let top = service.topFriendsThisWeek()
            (self.global, self.friends, recentDuels, myStats, topFriends) = try await (global, friends, history, stats, top)
        } catch {
            AppLog.backend.error("Loading stats failed: \(String(describing: error), privacy: .public)")
        }
    }

    var rating: RatingOverview { RatingOverview(global: global, friends: friends) }

    /// Accepted duel reps per local calendar day (Home "This week" chart; CLAUDE.md §11: the
    /// chart uses the user's local day, the rating resets Monday 00:00 UTC).
    func dailyReps(calendar: Calendar = .current) -> [Date: Int] {
        recentDuels.reduce(into: [:]) { result, duel in
            result[calendar.startOfDay(for: duel.finishedAt), default: 0] += duel.myReps
        }
    }
}
