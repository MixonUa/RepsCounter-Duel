import Foundation
import Testing
@testable import Backend

@Suite struct WeekSummaryTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Kyiv")!
        return calendar
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    @Test func weekRunsMondayToSundayAroundToday() {
        // Thursday 19 Nov 2026.
        let week = WeekSummary.make(today: date(2026, 11, 19), dailyReps: [:], calendar: calendar)
        #expect(week.days.count == 7)
        #expect(calendar.component(.weekday, from: week.start) == 2) // Monday
        #expect(calendar.component(.day, from: week.start) == 16)
        #expect(calendar.component(.day, from: week.end) == 22)
        #expect(week.days.map(\.isToday) == [false, false, false, true, false, false, false])
        #expect(week.days.map(\.isFuture) == [false, false, false, false, true, true, true])
    }

    @Test func sumsRepsPerLocalDayAndIgnoresOtherWeeks() {
        let reps: [Date: Int] = [
            date(2026, 11, 16, hour: 9): 10,
            date(2026, 11, 16, hour: 21): 5,   // same Monday
            date(2026, 11, 19, hour: 8): 7,    // today
            date(2026, 11, 15): 100,           // previous Sunday — other week
        ]
        let week = WeekSummary.make(today: date(2026, 11, 19), dailyReps: reps, calendar: calendar)
        #expect(week.days.map(\.reps) == [15, 0, 0, 7, 0, 0, 0])
        #expect(week.total == 22)
    }

    @Test func futureDaysNeverHaveReps() {
        let reps = [date(2026, 11, 21): 30] // Saturday, after today
        let week = WeekSummary.make(today: date(2026, 11, 19), dailyReps: reps, calendar: calendar)
        #expect(week.total == 0)
    }

    @Test func sundayFirstWeekStartsOnSunday() {
        let week = WeekSummary.make(today: date(2026, 11, 19), dailyReps: [:], calendar: calendar, firstWeekday: 1)
        #expect(calendar.component(.weekday, from: week.start) == 1)
        #expect(calendar.component(.day, from: week.start) == 15)
        #expect(calendar.component(.day, from: week.end) == 21)
    }

    @Test func sundayBelongsToTheWeekThatStartedOnMonday() {
        let week = WeekSummary.make(today: date(2026, 11, 22), dailyReps: [:], calendar: calendar)
        #expect(calendar.component(.day, from: week.start) == 16)
        #expect(week.days.last?.isToday == true)
    }
}

@Suite struct WeeklyRankTests {
    @Test func milestoneIsTheNextRoundTopAbove() {
        #expect(WeeklyRank.milestone(above: 24) == 20)
        #expect(WeeklyRank.milestone(above: 244) == 200)
        #expect(WeeklyRank.milestone(above: 20) == 10)
        #expect(WeeklyRank.milestone(above: 11) == 10)
        #expect(WeeklyRank.milestone(above: 4) == 3)
        #expect(WeeklyRank.milestone(above: 2) == 1)
        #expect(WeeklyRank.milestone(above: 1) == nil)
    }

    @Test func emptyHomeHasNoRecordsOrDuels() {
        let home = MockData.homeEmpty()
        #expect(home.hasTrainingRecords == false)
        #expect(home.lastDuel == nil)
        #expect(home.week.total == 0)
        #expect(MockData.homeFilled().hasTrainingRecords)
    }
}

@Suite struct WeeklyRankFromBoardTests {
    private func board(_ totals: [Int]) -> [LeaderboardEntry] {
        LeaderboardRanking.rank(totals.enumerated().map { (PlayerProfile(serverNickname: "p\($0.offset)", emoji: "🐧"), $0.element) })
    }

    @Test func repsToTheNextTopN() throws {
        // 25 players, 100 → 4 by 4; "p23" is #24 with 8, #20 has 24 → 16 more reps.
        let entries = board((0..<25).map { 100 - $0 * 4 })
        let me = PlayerProfile(serverNickname: "P23", emoji: "🐧")
        let rank = try #require(LeaderboardEntry.weeklyRank(for: me, in: entries))
        #expect(rank.position == 24)
        #expect(rank.milestone == 20)
        #expect(rank.repsToNextMilestone == 16)
    }

    @Test func leaderHasNoMilestoneAndAbsentPlayerHasNoRank() {
        let entries = board([30, 20])
        #expect(LeaderboardEntry.weeklyRank(for: PlayerProfile(serverNickname: "p0", emoji: "🐧"), in: entries)?.repsToNextMilestone == nil)
        #expect(LeaderboardEntry.weeklyRank(for: PlayerProfile(serverNickname: "nobody", emoji: "🐧"), in: entries) == nil)
    }
}
