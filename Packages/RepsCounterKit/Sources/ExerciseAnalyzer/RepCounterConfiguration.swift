import Foundation

/// Tunable rep-counting thresholds. **All values are PROVISIONAL** (CLAUDE.md §5): they must be
/// calibrated with real device recordings and testers before any accuracy claim.
///
/// Each exercise is reduced to one scale-free "extension" signal (high at the start position,
/// low at the bottom); thresholds are fractions of the player's own start-position value
/// (`baseline`), so camera distance and body size cancel out.
public struct RepCounterConfiguration: Sendable, Hashable {
    /// Joints below this confidence are treated as not visible.
    public var minJointConfidence: Double
    /// Exponential smoothing of the signal per frame (0…1, higher = less smoothing).
    public var smoothing: Double
    /// How long the start position must be held still before counting starts.
    public var calibrationDuration: TimeInterval
    /// Allowed relative spread of the signal while calibrating.
    public var calibrationTolerance: Double
    /// The start position must give at least this signal (rejects calibrating at the bottom).
    public var minimumBaseline: Double
    /// Below `baseline × descentStartRatio` a rep has started.
    public var descentStartRatio: Double
    /// The rep only counts after reaching `baseline × bottomRatio` (required range of motion).
    public var bottomRatio: Double
    /// Rising this far (× baseline) above the lowest point means the way up has begun.
    public var ascentHysteresis: Double
    /// Back above `baseline × topRatio` completes the rep.
    public var topRatio: Double
    /// Faster cycles are rejected as noise / bouncing.
    public var minRepDuration: TimeInterval
    /// Slower cycles are dropped (stuck or lost track).
    public var maxRepDuration: TimeInterval
    /// Losing the body for longer than this cancels the rep in progress.
    public var trackingLossTimeout: TimeInterval
    /// How fast the baseline follows the player at the start position (0…1 per frame).
    public var baselineAdaptation: Double
    /// Shoulders wider than this share of the image width → "Move back".
    public var maxShoulderWidth: Double
    /// How long "Go lower" stays after a too-shallow rep.
    public var partialRepFeedbackDuration: TimeInterval

    public static func standard(for exercise: Exercise) -> RepCounterConfiguration {
        switch exercise {
        case .squats:
            // Signal: vertical hip→knee distance / knee→ankle distance (≈1 standing, ≈0 at parallel).
            RepCounterConfiguration(
                minJointConfidence: 0.3, smoothing: 0.5,
                calibrationDuration: 0.6, calibrationTolerance: 0.15, minimumBaseline: 0.5,
                descentStartRatio: 0.85, bottomRatio: 0.4, ascentHysteresis: 0.1, topRatio: 0.85,
                minRepDuration: 0.5, maxRepDuration: 10,
                trackingLossTimeout: 0.5, baselineAdaptation: 0.05,
                maxShoulderWidth: 0.6, partialRepFeedbackDuration: 1.5
            )
        case .pushUps:
            // Signal: vertical shoulder→wrist distance / shoulder width (high at the top, low when
            // the chest is down). Front camera on the floor; validate on real devices.
            RepCounterConfiguration(
                minJointConfidence: 0.3, smoothing: 0.5,
                calibrationDuration: 0.6, calibrationTolerance: 0.15, minimumBaseline: 0.4,
                descentStartRatio: 0.85, bottomRatio: 0.5, ascentHysteresis: 0.1, topRatio: 0.85,
                minRepDuration: 0.5, maxRepDuration: 10,
                trackingLossTimeout: 0.5, baselineAdaptation: 0.05,
                maxShoulderWidth: 0.7, partialRepFeedbackDuration: 1.5
            )
        }
    }
}
