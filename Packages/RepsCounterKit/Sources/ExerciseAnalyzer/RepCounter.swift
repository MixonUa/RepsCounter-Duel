import Foundation

/// Deterministic rep counter for one exercise (CLAUDE.md §5):
/// `calibrating → ready → descending → bottomReached → ascending → (rep) → ready`.
///
/// - A rep counts **exactly once**, only for a full cycle: start position → required depth →
///   back to the start position, within `minRepDuration…maxRepDuration`.
/// - Shallow movements give "Go lower" and no rep; noise at the top is absorbed by smoothing
///   and hysteresis.
/// - Losing the body for longer than `trackingLossTimeout` cancels the rep in progress, and
///   counting resumes only after the player is back at the start position.
/// Pure value type: feed frames in time order from one thread.
public struct RepCounter: Sendable {
    public enum Phase: Equatable, Sendable {
        case calibrating
        case ready
        case descending
        case bottomReached
        case ascending
    }

    public struct CompletedRep: Equatable, Sendable {
        /// When the descent started and when the start position was reached again.
        public let start: TimeInterval
        public let end: TimeInterval
    }

    public struct Update: Equatable, Sendable {
        /// Completed reps since the counter was created (the caller decides which ones score).
        public let reps: Int
        public let phase: Phase
        public let feedback: PoseFeedback?
        /// Set on the frame that completed a rep.
        public let completedRep: CompletedRep?
    }

    public let exercise: Exercise
    public let configuration: RepCounterConfiguration

    public private(set) var reps = 0
    public private(set) var phase: Phase = .calibrating
    /// Start-position signal of this player (nil until calibrated).
    public private(set) var baseline: Double?

    private var smoothed: Double?
    private var lastValidTime: TimeInterval?
    private var calibrationSamples: [(time: TimeInterval, value: Double)] = []
    private var repStart: TimeInterval?
    private var lowest = 0.0
    /// After a tracking loss the player must be seen at the start position again.
    private var awaitingTop = false
    private var goLowerUntil: TimeInterval?

    public init(exercise: Exercise, configuration: RepCounterConfiguration? = nil) {
        self.exercise = exercise
        self.configuration = configuration ?? .standard(for: exercise)
    }

    public mutating func process(_ frame: PoseFrame) -> Update {
        let time = frame.timestamp
        switch ExerciseSignal.measure(frame, exercise: exercise, configuration: configuration) {
        case .missing(let feedback):
            if let last = lastValidTime, time - last > configuration.trackingLossTimeout {
                loseTracking()
            }
            return update(feedback: feedback)
        case .value(let raw):
            lastValidTime = time
            let value = smoothed.map { $0 + configuration.smoothing * (raw - $0) } ?? raw
            smoothed = value
            let completed = advance(value: value, time: time)
            return update(feedback: currentFeedback(time: time), completedRep: completed)
        }
    }

    // MARK: - State machine

    private mutating func advance(value: Double, time: TimeInterval) -> CompletedRep? {
        guard let baseline else {
            calibrate(value: value, time: time)
            return nil
        }
        let c = configuration

        if let start = repStart, time - start > c.maxRepDuration {
            cancelRep()
            awaitingTop = true
        }

        switch phase {
        case .calibrating:
            phase = .ready
            return nil
        case .ready:
            if value >= baseline * c.topRatio {
                awaitingTop = false
                self.baseline = baseline + c.baselineAdaptation * (value - baseline)
            } else if !awaitingTop, value < baseline * c.descentStartRatio {
                phase = .descending
                repStart = time
                lowest = value
            }
        case .descending:
            lowest = min(lowest, value)
            if value <= baseline * c.bottomRatio {
                phase = .bottomReached
            } else if value >= baseline * c.topRatio {
                // Came back up without the required depth.
                cancelRep()
                goLowerUntil = time + c.partialRepFeedbackDuration
            }
        case .bottomReached:
            lowest = min(lowest, value)
            if value >= lowest + baseline * c.ascentHysteresis {
                phase = .ascending
            }
        case .ascending:
            if value <= baseline * c.bottomRatio {
                phase = .bottomReached
                lowest = min(lowest, value)
            } else if value >= baseline * c.topRatio, let start = repStart {
                cancelRep()
                let duration = time - start
                guard duration >= c.minRepDuration, duration <= c.maxRepDuration else { return nil }
                reps += 1
                goLowerUntil = nil
                return CompletedRep(start: start, end: time)
            }
        }
        return nil
    }

    private mutating func calibrate(value: Double, time: TimeInterval) {
        let c = configuration
        calibrationSamples.append((time, value))
        calibrationSamples.removeAll { time - $0.time > c.calibrationDuration }
        guard let first = calibrationSamples.first, time - first.time >= c.calibrationDuration * 0.9 else { return }
        let values = calibrationSamples.map(\.value)
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean >= c.minimumBaseline,
              let low = values.min(), let high = values.max(),
              (high - low) / mean <= c.calibrationTolerance else { return }
        baseline = mean
        phase = .ready
        calibrationSamples = []
    }

    private mutating func cancelRep() {
        repStart = nil
        phase = baseline == nil ? .calibrating : .ready
    }

    private mutating func loseTracking() {
        smoothed = nil
        lastValidTime = nil
        calibrationSamples = []
        // Whatever happened off-camera, the next rep must start from the start position.
        awaitingTop = baseline != nil
        cancelRep()
    }

    private func currentFeedback(time: TimeInterval) -> PoseFeedback? {
        if baseline == nil { return .getIntoStartPosition }
        if let until = goLowerUntil, time < until { return .goLower }
        return nil
    }

    private func update(feedback: PoseFeedback?, completedRep: CompletedRep? = nil) -> Update {
        Update(reps: reps, phase: phase, feedback: feedback, completedRep: completedRep)
    }
}
