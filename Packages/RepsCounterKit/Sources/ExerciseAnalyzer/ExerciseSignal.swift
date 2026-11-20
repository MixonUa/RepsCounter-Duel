import Foundation

/// What the player should fix so the pose can be tracked (shown on screen; never a rep).
public enum PoseFeedback: Hashable, Sendable {
    /// Nobody or not the needed joints in view.
    case bodyNotVisible
    /// Too close / feet or hands out of frame.
    case moveBack
    /// Hold the start position still so counting can begin.
    case getIntoStartPosition
    /// The last movement did not go deep enough to count.
    case goLower

    /// Distance-readable copy (PROVISIONAL, no Figma frame).
    public var message: String {
        switch self {
        case .bodyNotVisible: "Full body not visible"
        case .moveBack: "Move back"
        case .getIntoStartPosition: "Hold the start position"
        case .goLower: "Go lower to count the rep"
        }
    }
}

/// Reduces a frame to the exercise's extension signal (see `RepCounterConfiguration`).
enum ExerciseSignal {
    enum Result: Equatable {
        case value(Double)
        case missing(PoseFeedback)
    }

    static func measure(_ frame: PoseFrame, exercise: Exercise, configuration: RepCounterConfiguration) -> Result {
        let c = configuration.minJointConfidence
        if frame.joints.isEmpty { return .missing(.bodyNotVisible) }
        if let left = frame.point(.leftShoulder, minConfidence: c),
           let right = frame.point(.rightShoulder, minConfidence: c),
           abs(left.x - right.x) > configuration.maxShoulderWidth {
            return .missing(.moveBack)
        }
        switch exercise {
        case .squats: return squats(frame, minConfidence: c)
        case .pushUps: return pushUps(frame, minConfidence: c)
        }
    }

    /// Mean over the visible sides of (kneeY − hipY) / (ankleY − kneeY).
    private static func squats(_ frame: PoseFrame, minConfidence c: Double) -> Result {
        let sides: [(BodyJoint, BodyJoint, BodyJoint)] = [(.leftHip, .leftKnee, .leftAnkle), (.rightHip, .rightKnee, .rightAnkle)]
        var values: [Double] = []
        var hipsVisible = false
        for (hipJoint, kneeJoint, ankleJoint) in sides {
            guard let hip = frame.point(hipJoint, minConfidence: c) else { continue }
            hipsVisible = true
            guard let knee = frame.point(kneeJoint, minConfidence: c),
                  let ankle = frame.point(ankleJoint, minConfidence: c) else { continue }
            let shin = ankle.y - knee.y
            guard shin > 0.02 else { continue }
            values.append(max(0, (knee.y - hip.y) / shin))
        }
        if values.isEmpty { return .missing(hipsVisible ? .moveBack : .bodyNotVisible) }
        return .value(values.reduce(0, +) / Double(values.count))
    }

    /// Mean over the visible wrists of (wristY − shoulderY) / shoulder width.
    private static func pushUps(_ frame: PoseFrame, minConfidence c: Double) -> Result {
        guard let leftShoulder = frame.point(.leftShoulder, minConfidence: c),
              let rightShoulder = frame.point(.rightShoulder, minConfidence: c) else {
            return .missing(.bodyNotVisible)
        }
        let width = abs(leftShoulder.x - rightShoulder.x)
        guard width > 0.03 else { return .missing(.bodyNotVisible) }
        var values: [Double] = []
        if let wrist = frame.point(.leftWrist, minConfidence: c) {
            values.append(max(0, (wrist.y - leftShoulder.y) / width))
        }
        if let wrist = frame.point(.rightWrist, minConfidence: c) {
            values.append(max(0, (wrist.y - rightShoulder.y) / width))
        }
        if values.isEmpty { return .missing(.moveBack) }
        return .value(values.reduce(0, +) / Double(values.count))
    }
}
