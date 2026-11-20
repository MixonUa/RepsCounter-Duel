import Foundation
import Testing
@testable import ExerciseAnalyzer

/// Synthetic front-camera poses: `extension` 1 = start position, 0 = deepest point.
private struct PoseScript {
    let exercise: Exercise
    var time: TimeInterval = 0
    var frames: [PoseFrame] = []
    let fps = 30.0
    var hideRightSide = false

    init(_ exercise: Exercise) { self.exercise = exercise }

    func frame(extension e: Double, noise: Double = 0) -> PoseFrame {
        var joints: [BodyJoint: PosePoint] = [:]
        func put(_ joint: BodyJoint, _ x: Double, _ y: Double) {
            joints[joint] = PosePoint(x: x, y: y + noise, confidence: 0.9)
        }
        switch exercise {
        case .squats:
            // Shin 0.2 tall; the thigh's vertical span shrinks from 0.2 (standing) to 0 (parallel).
            for (side, x) in [(0, 0.4), (1, 0.6)] where !(side == 1 && hideRightSide) {
                let ankleY = 0.9, kneeY = 0.7, hipY = kneeY - 0.2 * e
                put(side == 0 ? .leftAnkle : .rightAnkle, x, ankleY)
                put(side == 0 ? .leftKnee : .rightKnee, x, kneeY)
                put(side == 0 ? .leftHip : .rightHip, x, hipY)
                put(side == 0 ? .leftShoulder : .rightShoulder, x, hipY - 0.25)
            }
        case .pushUps:
            // Shoulder width 0.3; shoulders drop from 0.45 above the wrists to 0.05 above.
            let shoulderY = 0.8 - (0.05 + 0.4 * e)
            put(.leftShoulder, 0.35, shoulderY)
            put(.rightShoulder, 0.65, shoulderY)
            put(.leftWrist, 0.3, 0.8)
            if !hideRightSide { put(.rightWrist, 0.7, 0.8) }
        }
        return PoseFrame(timestamp: time, joints: joints)
    }

    mutating func hold(_ e: Double, seconds: Double, noise: Double = 0) {
        for i in 0..<Int(seconds * fps) {
            let jitter = noise == 0 ? 0 : (i.isMultiple(of: 2) ? noise : -noise)
            frames.append(frame(extension: e, noise: jitter))
            time += 1 / fps
        }
    }

    mutating func move(from a: Double, to b: Double, seconds: Double) {
        let count = max(1, Int(seconds * fps))
        for i in 1...count {
            frames.append(frame(extension: a + (b - a) * Double(i) / Double(count)))
            time += 1 / fps
        }
    }

    mutating func rep(depth: Double = 0.05, down: Double = 0.6, up: Double = 0.6) {
        move(from: 1, to: depth, seconds: down)
        move(from: depth, to: 1, seconds: up)
        hold(1, seconds: 0.3)
    }

    mutating func lose(seconds: Double) {
        for _ in 0..<Int(seconds * fps) {
            frames.append(PoseFrame(timestamp: time, joints: [:]))
            time += 1 / fps
        }
    }

    func run() -> (reps: Int, feedback: [PoseFeedback]) {
        var counter = RepCounter(exercise: exercise)
        var feedback: [PoseFeedback] = []
        for frame in frames {
            if let item = counter.process(frame).feedback { feedback.append(item) }
        }
        return (counter.reps, feedback)
    }
}

@Suite struct RepCounterTests {
    @Test(arguments: Exercise.allCases)
    func countsFullRepsExactlyOnce(exercise: Exercise) {
        var script = PoseScript(exercise)
        script.hold(1, seconds: 1)
        for _ in 0..<3 { script.rep() }
        #expect(script.run().reps == 3)
    }

    @Test(arguments: Exercise.allCases)
    func shallowRepsDoNotCountAndAskToGoLower(exercise: Exercise) {
        var script = PoseScript(exercise)
        script.hold(1, seconds: 1)
        script.rep(depth: 0.7)
        let result = script.run()
        #expect(result.reps == 0)
        #expect(result.feedback.contains(.goLower))
    }

    @Test(arguments: Exercise.allCases)
    func noiseAtTheTopDoesNotCount(exercise: Exercise) {
        var script = PoseScript(exercise)
        script.hold(1, seconds: 4, noise: 0.01)
        #expect(script.run().reps == 0)
    }

    @Test func needsCalibrationBeforeCounting() {
        var script = PoseScript(.squats)
        // Starts moving immediately: no stable start position yet, so this rep is ignored…
        script.rep()
        // …until the start position is held.
        script.hold(1, seconds: 1)
        script.rep()
        let result = script.run()
        #expect(result.reps == 1)
        #expect(result.feedback.first == .getIntoStartPosition)
    }

    @Test func trackingLossMidRepCancelsItAndRecovers() {
        var script = PoseScript(.squats)
        script.hold(1, seconds: 1)
        script.move(from: 1, to: 0.05, seconds: 0.6)
        script.lose(seconds: 1)
        // Comes back at the bottom and stands up: not a full observed cycle.
        script.hold(0.05, seconds: 0.2)
        script.move(from: 0.05, to: 1, seconds: 0.6)
        script.hold(1, seconds: 0.5)
        #expect(script.run().reps == 0)
        script.rep()
        #expect(script.run().reps == 1)
    }

    @Test func notVisibleFeedbackWithoutAPerson() {
        var script = PoseScript(.pushUps)
        script.lose(seconds: 0.5)
        let result = script.run()
        #expect(result.reps == 0)
        #expect(result.feedback.allSatisfy { $0 == .bodyNotVisible })
    }

    @Test(arguments: Exercise.allCases)
    func oneVisibleSideIsEnough(exercise: Exercise) {
        var script = PoseScript(exercise)
        script.hideRightSide = true
        script.hold(1, seconds: 1)
        script.rep()
        script.rep()
        #expect(script.run().reps == 2)
    }

    @Test func tooFastBounceIsRejected() {
        var script = PoseScript(.pushUps)
        script.hold(1, seconds: 1)
        script.rep(down: 0.1, up: 0.1)
        #expect(script.run().reps == 0)
    }

    @Test func holdingAtTheBottomStillCountsOnceWhenStandingUp() {
        var script = PoseScript(.squats)
        script.hold(1, seconds: 1)
        script.move(from: 1, to: 0.05, seconds: 0.6)
        script.hold(0.05, seconds: 2, noise: 0.003)
        script.move(from: 0.05, to: 1, seconds: 0.6)
        script.hold(1, seconds: 0.5)
        #expect(script.run().reps == 1)
    }

    @Test func tooCloseAsksToMoveBack() {
        var counter = RepCounter(exercise: .pushUps)
        let frame = PoseFrame(timestamp: 0, joints: [
            .leftShoulder: PosePoint(x: 0.05, y: 0.4, confidence: 0.9),
            .rightShoulder: PosePoint(x: 0.95, y: 0.4, confidence: 0.9),
        ])
        #expect(counter.process(frame).feedback == .moveBack)
    }
}
