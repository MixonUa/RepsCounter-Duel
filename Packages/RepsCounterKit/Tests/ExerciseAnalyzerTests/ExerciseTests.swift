import Testing
@testable import ExerciseAnalyzer

@Suite struct ExerciseTests {
    @Test func supportsExactlySquatsAndPushUps() {
        #expect(Exercise.allCases == [.squats, .pushUps])
    }

    @Test func rawValuesAreStableForTheBackend() {
        #expect(Exercise.squats.rawValue == "squats")
        #expect(Exercise.pushUps.rawValue == "push_ups")
    }
}
