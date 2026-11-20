import AVFoundation
import Observation
import QuartzCore
import ExerciseAnalyzer
import PoseDetection

/// Front camera → Vision pose → `RepCounter` for one training / duel screen (CLAUDE.md §5).
/// Detection and counting run on the camera's video queue; the main actor only receives the
/// latest pose (for the skeleton), the feedback and the scored reps.
/// A rep scores only when its whole cycle (start → end) lies inside the scoring window
/// (`startScoring`), so reps begun during the countdown or finished after the time is up don't
/// count. Device time only; stage 4 adds server-owned duel windows.
@Observable
final class WorkoutTracker {
    let exercise: Exercise
    let camera = FrontCameraSession()

    private(set) var cameraState: FrontCameraSession.State = .idle
    /// Latest detected pose (nil until the first frame).
    private(set) var pose: PoseFrame?
    private(set) var feedback: PoseFeedback?
    /// Reps scored inside the window.
    private(set) var reps = 0

    @ObservationIgnored private let processor: PoseFrameProcessor

    init(exercise: Exercise) {
        self.exercise = exercise
        processor = PoseFrameProcessor(exercise: exercise)
        camera.frameDelegate = processor
        processor.onResult = { [weak self] result in
            Task { @MainActor in self?.apply(result) }
        }
        camera.onStateChange = { [weak self] state in self?.cameraState = state }
    }

    func start() { camera.start() }
    func stop() { camera.stop() }

    /// Starts scoring now; `duration` nil = until `stopScoring()` (training).
    func startScoring(duration: TimeInterval? = nil) {
        let now = CACurrentMediaTime()
        processor.setScoringWindow(start: now, end: duration.map { now + $0 } ?? .infinity)
    }

    func stopScoring() {
        processor.setScoringWindow(start: .infinity, end: .infinity)
    }

    /// DEBUG builds: add a rep by tapping the counter (Simulator has no camera).
    func debugAddRep() {
        #if DEBUG
        reps += 1
        #endif
    }

    private func apply(_ result: PoseFrameProcessor.Result) {
        pose = result.frame
        if feedback != result.feedback { feedback = result.feedback }
        if result.scoredRep { reps += 1 }
    }
}

/// Runs Vision + the rep counter on the video queue. All mutable state is touched only on that
/// queue, except the scoring window (guarded by a lock).
nonisolated final class PoseFrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    struct Result: Sendable {
        let frame: PoseFrame
        let feedback: PoseFeedback?
        let scoredRep: Bool
    }

    var onResult: (@Sendable (Result) -> Void)?

    private let detector = VisionPoseDetector()
    private var counter: RepCounter
    private let lock = NSLock()
    private var window: (start: TimeInterval, end: TimeInterval) = (.infinity, .infinity)

    init(exercise: Exercise) {
        counter = RepCounter(exercise: exercise)
    }

    func setScoringWindow(start: TimeInterval, end: TimeInterval) {
        lock.withLock { window = (start, end) }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let frame = detector.detect(in: pixelBuffer, timestamp: CACurrentMediaTime())
        let update = counter.process(frame)
        var scored = false
        if let rep = update.completedRep {
            let window = lock.withLock { self.window }
            scored = rep.start >= window.start && rep.end <= window.end
        }
        onResult?(Result(frame: frame, feedback: update.feedback, scoredRep: scored))
    }
}
