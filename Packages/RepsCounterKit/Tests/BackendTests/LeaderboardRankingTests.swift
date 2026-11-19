import Foundation
import Testing
@testable import Backend

@Suite struct LeaderboardRankingTests {
    private func player(_ nickname: String) -> PlayerProfile {
        PlayerProfile(nickname: nickname, emoji: "🙂")
    }

    @Test func ordersByTotalDescending() {
        let entries = LeaderboardRanking.rank([(player("a"), 10), (player("b"), 30), (player("c"), 20)])
        #expect(entries.map(\.totalDuelReps) == [30, 20, 10])
        #expect(entries.map(\.rank) == [1, 2, 3])
    }

    @Test func equalTotalsShareTheSameRank() {
        let entries = LeaderboardRanking.rank([
            (player("d"), 5), (player("b"), 20), (player("c"), 20), (player("a"), 50),
        ])
        #expect(entries.map(\.rank) == [1, 2, 2, 4])
    }

    @Test func tiesUseCaseInsensitiveNicknameAsStableSecondarySort() {
        let entries = LeaderboardRanking.rank([(player("Zed"), 7), (player("alex"), 7), (player("Bob"), 7)])
        #expect(entries.map(\.player.nickname) == ["alex", "Bob", "Zed"])
        #expect(Set(entries.map(\.rank)) == [1])
    }

    @Test func orderingIsDeterministicRegardlessOfInputOrder() {
        let input = [(player("x"), 3), (player("y"), 3), (player("z"), 9)]
        let forward = LeaderboardRanking.rank(input).map(\.player.nickname)
        let reversed = LeaderboardRanking.rank(input.reversed()).map(\.player.nickname)
        #expect(forward == reversed)
    }

    @Test func emptyInputGivesEmptyLeaderboard() {
        #expect(LeaderboardRanking.rank([]).isEmpty)
    }
}

@Suite struct DuelSummaryTests {
    private func duel(my: Int, opponent: Int) -> DuelSummary {
        DuelSummary(
            opponent: PlayerProfile(nickname: "op", emoji: "🙂"),
            exercise: .squats, duration: .thirty,
            myReps: my, opponentReps: opponent, finishedAt: .now
        )
    }

    @Test func moreRepsWinsFewerLosesEqualIsDraw() {
        #expect(duel(my: 10, opponent: 9).outcome == .win)
        #expect(duel(my: 9, opponent: 10).outcome == .loss)
        #expect(duel(my: 10, opponent: 10).outcome == .draw)
    }

    @Test func winRateIsNilWithoutDuels() {
        #expect(PlayerStats.empty.winRate == nil)
        let stats = PlayerStats(totalDuelReps: 0, duelsWon: 1, duelsLost: 2, duelsTied: 1, trainingRecord: 0)
        #expect(stats.winRate == 0.25)
    }
}
