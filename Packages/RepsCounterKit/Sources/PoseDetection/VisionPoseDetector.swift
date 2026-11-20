import CoreVideo
import ImageIO
import Vision
import ExerciseAnalyzer

/// Apple Vision 2D body pose → `PoseFrame` (CLAUDE.md §3: on-device only, nothing leaves the
/// phone). Not thread-safe: call `detect` from one serial queue (the camera's video queue),
/// never from the main actor.
public final class VisionPoseDetector: @unchecked Sendable {
    private let request = VNDetectHumanBodyPoseRequest()

    private static let jointNames: [BodyJoint: VNHumanBodyPoseObservation.JointName] = [
        .nose: .nose,
        .leftShoulder: .leftShoulder, .rightShoulder: .rightShoulder,
        .leftElbow: .leftElbow, .rightElbow: .rightElbow,
        .leftWrist: .leftWrist, .rightWrist: .rightWrist,
        .leftHip: .leftHip, .rightHip: .rightHip,
        .leftKnee: .leftKnee, .rightKnee: .rightKnee,
        .leftAnkle: .leftAnkle, .rightAnkle: .rightAnkle,
    ]

    public init() {}

    /// - Parameters:
    ///   - pixelBuffer: an upright (already rotated / mirrored as on screen) camera frame.
    ///   - timestamp: monotonic seconds for the rep counter.
    /// - Returns: the most confident person, or a frame without joints when nobody is found.
    public func detect(in pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, orientation: CGImagePropertyOrientation = .up) -> PoseFrame {
        let width = Double(CVPixelBufferGetWidth(pixelBuffer))
        let height = Double(CVPixelBufferGetHeight(pixelBuffer))
        let aspect = height > 0 ? width / height : 9.0 / 16.0
        let empty = PoseFrame(timestamp: timestamp, joints: [:], imageAspectRatio: aspect)

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        guard (try? handler.perform([request])) != nil,
              let observations = request.results, !observations.isEmpty else { return empty }

        let best = observations.max { Self.meanConfidence($0) < Self.meanConfidence($1) }
        guard let best, let points = try? best.recognizedPoints(.all) else { return empty }

        var joints: [BodyJoint: PosePoint] = [:]
        for (joint, name) in Self.jointNames {
            guard let point = points[name], point.confidence > 0 else { continue }
            // Vision: origin bottom-left → PoseFrame: origin top-left.
            joints[joint] = PosePoint(x: Double(point.location.x), y: 1 - Double(point.location.y), confidence: Double(point.confidence))
        }
        return PoseFrame(timestamp: timestamp, joints: joints, imageAspectRatio: aspect)
    }

    private static func meanConfidence(_ observation: VNHumanBodyPoseObservation) -> Float {
        guard let points = try? observation.recognizedPoints(.all), !points.isEmpty else { return 0 }
        return points.values.map(\.confidence).reduce(0, +) / Float(points.count)
    }
}
