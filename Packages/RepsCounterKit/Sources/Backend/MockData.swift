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

    /// FIGMA Home_empty: first launch — no duels, no training, rank #244.
    public static func homeEmpty(today: Date = .now, firstWeekday: Int = 2) -> HomeOverview {
        HomeOverview(
            week: WeekSummary.make(today: today, dailyReps: [:], firstWeekday: firstWeekday),
            trainingRecords: [:],
            trainingRecordGains: [:],
            lastDuel: nil,
            rank: WeeklyRank(position: 244, repsToNextMilestone: 50)
        )
    }

    /// FIGMA Home (filled): duel reps on the days before today, today 55, rank #24.
    public static func homeFilled(today: Date = .now, calendar: Calendar = .current, firstWeekday: Int = 2) -> HomeOverview {
        let pastValues = [34, 19, 30, 41, 26, 22]
        var daily: [Date: Int] = [:]
        let week = WeekSummary.make(today: today, dailyReps: [:], calendar: calendar, firstWeekday: firstWeekday)
        var pastIndex = 0
        for day in week.days where !day.isFuture {
            if day.isToday {
                daily[day.date] = 55
            } else {
                daily[day.date] = pastValues[pastIndex % pastValues.count]
                pastIndex += 1
            }
        }
        return HomeOverview(
            week: WeekSummary.make(today: today, dailyReps: daily, calendar: calendar, firstWeekday: firstWeekday),
            trainingRecords: [.pushUps: 42, .squats: 36],
            trainingRecordGains: [.pushUps: 4, .squats: 2],
            lastDuel: DuelSummary(
                opponent: PlayerProfile(nickname: "Lena_V", emoji: "🐱"),
                exercise: .pushUps,
                duration: .sixty,
                myReps: 12,
                opponentReps: 9,
                finishedAt: today.addingTimeInterval(-3_600)
            ),
            rank: WeeklyRank(position: 24, repsToNextMilestone: 6)
        )
    }

    /// FIGMA Profile: 24 won, 66% win rate, 100 total reps, weekly Top 11, three top friends.
    public static let profileFilled = ProfileOverview(
        stats: PlayerStats(totalDuelReps: 100, duelsWon: 24, duelsLost: 12, duelsTied: 0),
        weeklyRank: 11,
        topFriends: [
            TopFriend(profile: PlayerProfile(nickname: "Theo_9", emoji: "🦁"), winRate: 0.6, jointReps: 412),
            TopFriend(profile: PlayerProfile(nickname: "Sophie", emoji: "🐰"), winRate: 0.7, jointReps: 403),
            TopFriend(profile: PlayerProfile(nickname: "Captain_Max", emoji: "🐼"), winRate: 0.42, jointReps: 399),
        ],
        friends: [
            FriendListItem(profile: PlayerProfile(nickname: "Ravi_M", emoji: "🐯"), weeklyRank: 120, status: .friend),
            FriendListItem(profile: PlayerProfile(nickname: "Lena_V", emoji: "🐱"), weeklyRank: 7, status: .friend),
            FriendListItem(profile: PlayerProfile(nickname: "Oscar_D", emoji: "🦊"), weeklyRank: 24, status: .friend),
            FriendListItem(profile: PlayerProfile(nickname: "Mila_K", emoji: "🐨"), weeklyRank: 68, status: .requestSent),
        ]
    )

    /// First launch: no duels, no friends.
    public static let profileEmpty = ProfileOverview(
        stats: .empty,
        weeklyRank: nil,
        topFriends: [],
        friends: []
    )

    /// Players the mock friend search can find (exact nickname, any case).
    public static let searchablePlayers: [PlayerCard] = [
        PlayerCard(
            profile: PlayerProfile(nickname: "Theo_9", emoji: "🦁"),
            stats: PlayerStats(totalDuelReps: 412, duelsWon: 18, duelsLost: 12, duelsTied: 0),
            weeklyRank: 9,
            friends: [
                PlayerProfile(nickname: "Sophie", emoji: "🐰"),
                PlayerProfile(nickname: "Lena_V", emoji: "🐱"),
                PlayerProfile(nickname: "Oscar_D", emoji: "🦊"),
                PlayerProfile(nickname: "Ravi_M", emoji: "🐯"),
            ],
            relationship: .friends
        ),
        PlayerCard(
            profile: PlayerProfile(nickname: "Max_Power", emoji: "🐔"),
            stats: PlayerStats(totalDuelReps: 100, duelsWon: 24, duelsLost: 12, duelsTied: 0),
            weeklyRank: 11,
            friends: [
                PlayerProfile(nickname: "Theo_9", emoji: "🦁"),
                PlayerProfile(nickname: "Kate", emoji: "🐼"),
                PlayerProfile(nickname: "Dima", emoji: "🐻"),
                PlayerProfile(nickname: "Olga", emoji: "🦄"),
            ],
            relationship: .none
        ),
        PlayerCard(
            profile: PlayerProfile(nickname: "Mila_K", emoji: "🐨"),
            stats: PlayerStats(totalDuelReps: 57, duelsWon: 3, duelsLost: 4, duelsTied: 1),
            weeklyRank: 68,
            friends: [PlayerProfile(nickname: "Kate", emoji: "🐼")],
            relationship: .requestSent
        ),
        PlayerCard(
            profile: PlayerProfile(nickname: "NewPlayer", emoji: "🐸"),
            stats: .empty,
            weeklyRank: nil,
            friends: [],
            relationship: .none
        ),
    ]

    /// FIGMA Leaderboard: podium Max / Lena_v / LukeR, rows from BlueComet down, me at #24 with 44.
    /// (Figma shows a 140/140/140 podium; distinct totals here because equal totals share a place.)
    public static func ratingFilled(me: PlayerProfile) -> RatingOverview {
        let named: [(String, String, Int)] = [
            ("Max", "🦁", 152), ("Lena_v", "🐰", 146), ("LukeR", "🐼", 140),
            ("BlueComet", "🐯", 130), ("SilverHawk", "🐨", 123), ("NightOwl", "🐶", 117), ("IronTiger", "🐲", 108),
        ]
        let others = ["Rocket", "Zed", "Mira", "Kai", "Nova", "Bolt", "Echo", "Juno",
                      "Pixel", "Rex", "Luna", "Orbit", "Ace", "Ivy", "Jet", "Sky"]
        let emojis = ["🦊", "🐸", "🐵", "🐷", "🐮", "🐔", "🦄", "🐺", "🐴", "🐹", "🐻", "🐱"]
        var totals: [(player: PlayerProfile, totalDuelReps: Int)] = named.map {
            (PlayerProfile(nickname: $0.0, emoji: $0.1), $0.2)
        }
        for (index, name) in others.enumerated() {
            totals.append((PlayerProfile(nickname: name, emoji: emojis[index % emojis.count]), 100 - index * 3))
        }
        totals.append((me, 44))
        for index in 0..<6 {
            totals.append((PlayerProfile(nickname: "Player\(index + 25)", emoji: emojis[(index + 4) % emojis.count]), 40 - index * 4))
        }
        let friends: [(player: PlayerProfile, totalDuelReps: Int)] = [
            (PlayerProfile(nickname: "Lena_V", emoji: "🐱"), 140),
            (PlayerProfile(nickname: "Theo_9", emoji: "🦁"), 96),
            (PlayerProfile(nickname: "Sophie", emoji: "🐰"), 80),
            (me, 44),
            (PlayerProfile(nickname: "Captain_Max", emoji: "🐼"), 30),
            (PlayerProfile(nickname: "Ravi_M", emoji: "🐯"), 22),
            (PlayerProfile(nickname: "Oscar_D", emoji: "🦊"), 12),
        ]
        return RatingOverview(global: LeaderboardRanking.rank(totals), friends: LeaderboardRanking.rank(friends))
    }

    public static func leaderboard(_ scope: LeaderboardScope) -> [LeaderboardEntry] {
        LeaderboardRanking.rank(scope == .global ? globalTotals : friendTotals)
    }
}
