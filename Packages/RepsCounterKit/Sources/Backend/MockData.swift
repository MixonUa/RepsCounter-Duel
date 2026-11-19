import Foundation
import ExerciseAnalyzer

/// Sample data for SwiftUI previews and the stage-0 app shell. Not real users.
public enum MockData {
    public static let me = PlayerProfile(nickname: "mike", emoji: "🦊")

    public static let friends: [PlayerProfile] = [
        PlayerProfile(nickname: "anna_fit", emoji: "🐯"),
        PlayerProfile(nickname: "danik", emoji: "🐻"),
        PlayerProfile(nickname: "olga", emoji: "🦄"),
        PlayerProfile(nickname: "sergey", emoji: "🐺"),
        PlayerProfile(nickname: "kate", emoji: "🐼"),
    ]

    public static let myStats = PlayerStats(
        totalDuelReps: 412, duelsWon: 9, duelsLost: 5, duelsTied: 1,
        trainingRecords: [.pushUps: 74, .squats: 82]
    )

    /// Last 7 days, oldest first.
    public static let dailyDuelReps: [DailyDuelReps] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let reps = [24, 0, 41, 33, 0, 57, 45]
        return reps.enumerated().compactMap { offset, value in
            calendar.date(byAdding: .day, value: offset - (reps.count - 1), to: today)
                .map { DailyDuelReps(day: $0, reps: value) }
        }
    }()

    public static let lastDuel = DuelSummary(
        opponent: friends[0],
        exercise: .squats,
        duration: .sixty,
        myReps: 31,
        opponentReps: 28,
        finishedAt: .now.addingTimeInterval(-3_600)
    )

    public static let friendTotals: [(player: PlayerProfile, totalDuelReps: Int)] = [
        (me, myStats.totalDuelReps),
        (friends[0], 530),
        (friends[1], 412),
        (friends[2], 287),
        (friends[3], 150),
        (friends[4], 96),
    ]

    public static let globalTotals: [(player: PlayerProfile, totalDuelReps: Int)] = friendTotals + [
        (PlayerProfile(nickname: "ironlegs", emoji: "🦍"), 2_140),
        (PlayerProfile(nickname: "pushqueen", emoji: "👑"), 1_875),
        (PlayerProfile(nickname: "squatbot", emoji: "🤖"), 1_875),
        (PlayerProfile(nickname: "maxreps", emoji: "🔥"), 990),
    ]

    public static func leaderboard(_ scope: LeaderboardScope) -> [LeaderboardEntry] {
        LeaderboardRanking.rank(scope == .global ? globalTotals : friendTotals)
    }
}
