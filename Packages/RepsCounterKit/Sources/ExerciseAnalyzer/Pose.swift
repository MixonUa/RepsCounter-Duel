import Foundation

/// Body joints the rep counters use (a subset of Vision's 2D body pose).
public enum BodyJoint: String, CaseIterable, Sendable, Hashable {
    case nose
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle
}

/// A joint in normalized image coordinates: x to the right, y **down** (0…1, origin top-left,
/// the same orientation as the camera preview on screen).
public struct PosePoint: Hashable, Sendable {
    public var x: Double
    public var y: Double
    /// 0…1 detector confidence.
    public var confidence: Double

    public init(x: Double, y: Double, confidence: Double) {
        self.x = x
        self.y = y
        self.confidence = confidence
    }
}

/// One analyzed camera frame. `joints` is empty when nobody was found.
public struct PoseFrame: Sendable {
    /// Seconds on a monotonic clock (the caller's choice; only differences matter).
    public var timestamp: TimeInterval
    public var joints: [BodyJoint: PosePoint]
    /// Width / height of the analyzed image (portrait camera ≈ 0.5625), for drawing on screen.
    public var imageAspectRatio: Double

    public init(timestamp: TimeInterval, joints: [BodyJoint: PosePoint], imageAspectRatio: Double = 9.0 / 16.0) {
        self.timestamp = timestamp
        self.joints = joints
        self.imageAspectRatio = imageAspectRatio
    }

    /// The joint when it is detected with at least `minConfidence`.
    public func point(_ joint: BodyJoint, minConfidence: Double) -> PosePoint? {
        guard let point = joints[joint], point.confidence >= minConfidence else { return nil }
        return point
    }
}

/// Which joints are drawn and connected for an exercise (Figma skeleton overlay).
public extension Exercise {
    var skeletonJoints: [BodyJoint] {
        switch self {
        case .pushUps: [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist]
        case .squats: [.leftShoulder, .rightShoulder, .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle]
        }
    }

    var skeletonBones: [(BodyJoint, BodyJoint)] {
        switch self {
        case .pushUps:
            [(.leftShoulder, .rightShoulder), (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
             (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist)]
        case .squats:
            [(.leftShoulder, .rightShoulder), (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
             (.leftHip, .leftKnee), (.leftKnee, .leftAnkle), (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)]
        }
    }
}
