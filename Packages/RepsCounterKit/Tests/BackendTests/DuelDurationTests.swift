import Foundation
import Testing
@testable import Backend

@Suite struct DuelDurationTests {
    @Test func stepsByTenSecondsWithinBounds() {
        var duration = DuelDuration.default
        duration = duration.incremented()
        #expect(duration.seconds == 70)
        #expect(!DuelDuration.presets.contains(duration))
        #expect(DuelDuration(seconds: 10).canDecrement == false)
        #expect(DuelDuration(seconds: 600).canIncrement == false)
        #expect(DuelDuration(seconds: 5).seconds == 10)
        #expect(DuelDuration(seconds: 9_999).seconds == 600)
        #expect(DuelDuration(seconds: 64).seconds == 60)
    }

    @Test func displayNames() {
        #expect(DuelDuration(seconds: 60).displayName == "1 min")
        #expect(DuelDuration(seconds: 90).displayName == "1 min 30 s")
        #expect(DuelDuration(seconds: 40).displayName == "40 s")
        #expect(DuelDuration.presets.compactMap(\.wholeMinutes) == [1, 2, 3, 5, 10])
    }
}

@Suite struct DuelInvitationTests {
    @Test func countdownAndExpiry() {
        let start = Date(timeIntervalSince1970: 1_000)
        let invite = DuelInvitation(
            host: PlayerProfile(nickname: "Nova_07", emoji: "🐧"),
            exercise: .pushUps,
            duration: .default,
            expiresAt: start.addingTimeInterval(DuelInvitation.defaultLifetime)
        )
        #expect(DuelInvitation.countdownText(seconds: invite.secondsLeft(at: start)) == "3:00")
        #expect(invite.secondsLeft(at: start.addingTimeInterval(0.4)) == 180)
        #expect(DuelInvitation.countdownText(seconds: invite.secondsLeft(at: start.addingTimeInterval(170))) == "0:10")
        #expect(invite.isExpired(at: start.addingTimeInterval(180)))
    }
}

@Suite struct DuelResultStatsTests {
    @Test func applyingOutcomeUpdatesTotalsAndWinRate() {
        let before = PlayerStats(totalDuelReps: 83, duelsWon: 16, duelsLost: 9, duelsTied: 0)
        #expect(before.winRatePercent == 64)
        let won = before.applying(.win, reps: 17)
        #expect(won.totalDuelReps == 100)
        #expect(won.winRatePercent == 65)
        let lost = before.applying(.loss, reps: 10)
        #expect(lost.duelsLost == 10)
        #expect(lost.winRatePercent == 62)
        #expect(PlayerStats.empty.applying(.draw, reps: 0).winRatePercent == 0)
    }
}

@Suite struct TrainingProgressTests {
    @Test func totalsAndRecordsPerExercise() {
        var progress = TrainingProgress()
        let results = [
            progress.add(reps: 20, of: .squats),
            progress.add(reps: 12, of: .squats),
            progress.add(reps: 5, of: .pushUps),
            progress.add(reps: 0, of: .pushUps),
        ]
        #expect(results == [true, false, true, false])
        #expect(progress.totalReps == 37)
        #expect(progress.record(for: .squats) == 20)
        #expect(progress.record(for: .pushUps) == 5)
    }
}

@Suite struct TrainingRecordGainTests {
    private let weekStart = Date(timeIntervalSince1970: 1_000_000)

    @Test func gainIsTheGrowthSinceTheWeekStarted() {
        var progress = TrainingProgress()
        progress.add(reps: 10, of: .squats, at: weekStart.addingTimeInterval(-86_400))
        progress.add(reps: 14, of: .squats, at: weekStart.addingTimeInterval(3_600))
        progress.add(reps: 9, of: .squats, at: weekStart.addingTimeInterval(7_200))
        progress.add(reps: 5, of: .pushUps, at: weekStart.addingTimeInterval(60))
        #expect(progress.gains(since: weekStart) == [.squats: 4, .pushUps: 5])
    }

    @Test func gainIsNewRecordMinusOldRecord() {
        var progress = TrainingProgress()
        progress.add(reps: 5, of: .squats, at: weekStart.addingTimeInterval(-86_400 * 10))
        progress.add(reps: 8, of: .squats, at: weekStart.addingTimeInterval(60))
        #expect(progress.gain(for: .squats, since: weekStart) == 3)
    }

    @Test func unknownOldRecordShowsNoGain() throws {
        // A record event saved before `previous` existed: the old value is unknown.
        let json = #"{"totalReps":8,"records":["squats",8],"recordHistory":[{"exercise":"squats","reps":8,"date":1000060}]}"#
        let progress = try JSONDecoder().decode(TrainingProgress.self, from: Data(json.utf8))
        #expect(progress.gain(for: .squats, since: weekStart) == 0)
    }

    @Test func noGainWithoutAnImprovementThisWeek() {
        var progress = TrainingProgress()
        progress.add(reps: 10, of: .squats, at: weekStart.addingTimeInterval(-86_400))
        progress.add(reps: 8, of: .squats, at: weekStart.addingTimeInterval(60))
        #expect(progress.gains(since: weekStart).isEmpty)
    }

    @Test func oldSavesWithoutHistoryStillDecode() throws {
        let json = #"{"totalReps":30,"records":["squats",12]}"#
        let progress = try JSONDecoder().decode(TrainingProgress.self, from: Data(json.utf8))
        #expect(progress.record(for: .squats) == 12)
        #expect(progress.recordHistory.isEmpty)
    }
}
