import Foundation
import ExerciseAnalyzer

/// One column of the Home "This week" chart.
public struct WeekDayReps: Identifiable, Hashable, Sendable {
    public let date: Date
    /// Accepted duel reps that day (training never counts).
    public let reps: Int
    public let isToday: Bool
    public let isFuture: Bool

    public var id: Date { date }
}

/// Week of daily duel reps containing `today` (FIGMA "This week"). Starts on Monday by default;
/// Settings → "First day of the week" can switch the chart to Sunday (display only — the weekly
/// rating always resets Monday 00:00 UTC).
public struct WeekSummary: Hashable, Sendable {
    public let days: [WeekDayReps]

    public var total: Int { days.reduce(0) { $0 + $1.reps } }
    public var start: Date { days.first!.date }
    public var end: Date { days.last!.date }

    /// - Parameter dailyReps: reps keyed by any time within the day.
    /// Days are calendar days in `calendar.timeZone` (the user's local day, CLAUDE.md §11).
    /// - Parameter firstWeekday: 2 = Monday (Figma default), 1 = Sunday.
    public static func make(
        today: Date,
        dailyReps: [Date: Int],
        calendar: Calendar = .current,
        firstWeekday: Int = 2
    ) -> WeekSummary {
        var calendar = calendar
        calendar.firstWeekday = firstWeekday
        let todayStart = calendar.startOfDay(for: today)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: todayStart)?.start ?? todayStart

        var repsByDay: [Date: Int] = [:]
        for (date, reps) in dailyReps {
            repsByDay[calendar.startOfDay(for: date), default: 0] += reps
        }

        let days = (0..<7).compactMap { offset -> WeekDayReps? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            return WeekDayReps(
                date: day,
                reps: day > todayStart ? 0 : repsByDay[day] ?? 0,
                isToday: day == todayStart,
                isFuture: day > todayStart
            )
        }
        return WeekSummary(days: days)
    }
}

/// The player's place in the weekly rating shown on Home (FIGMA "You're #24 this week").
public struct WeeklyRank: Hashable, Sendable {
    public let position: Int
    /// Reps still needed to reach `milestone`; nil when already at the top.
    public let repsToNextMilestone: Int?

    public init(position: Int, repsToNextMilestone: Int?) {
        self.position = position
        self.repsToNextMilestone = repsToNextMilestone
    }

    /// Next round "top N" above the player, from 1, 2, 3, 5, 10, 20, 30, 50, 100, 200…:
    /// #24 → top 20, #244 → top 200, #20 → top 10, #2 → top 1; nil for #1.
    public var milestone: Int? { Self.milestone(above: position) }

    public static func milestone(above position: Int) -> Int? {
        guard position > 1 else { return nil }
        var scale = 1
        var best = 1
        while true {
            for step in [1, 2, 3, 5] {
                let value = step * scale
                if value >= position { return best }
                best = value
            }
            scale *= 10
        }
    }
}

/// Everything the Home screen shows. Built by the server/repositories in stage 5; mock for now.
public struct HomeOverview: Sendable {
    public var week: WeekSummary
    /// Best training reps per exercise.
    public var trainingRecords: [Exercise: Int]
    /// Record improvement this week per exercise ("+4 this week"); missing or 0 hides the line.
    public var trainingRecordGains: [Exercise: Int]
    public var lastDuel: DuelSummary?
    public var rank: WeeklyRank?

    public init(
        week: WeekSummary,
        trainingRecords: [Exercise: Int],
        trainingRecordGains: [Exercise: Int],
        lastDuel: DuelSummary?,
        rank: WeeklyRank?
    ) {
        self.week = week
        self.trainingRecords = trainingRecords
        self.trainingRecordGains = trainingRecordGains
        self.lastDuel = lastDuel
        self.rank = rank
    }

    /// No training record yet → Home shows "Set a new record!".
    public var hasTrainingRecords: Bool { trainingRecords.values.contains { $0 > 0 } }
}
