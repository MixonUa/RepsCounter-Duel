import SwiftUI

/// FIGMA: thin onboarding progress bar (128 × 6 pt), accent fill on a light-blue track.
public struct RCProgressBar: View {
    private let progress: Double

    public init(progress: Double) {
        self.progress = min(max(progress, 0), 1)
    }

    public var body: some View {
        Capsule()
            .fill(RCColor.progressTrack)
            .frame(width: 128, height: 6)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(RCColor.accent)
                    .frame(width: 128 * progress)
            }
            .animation(.snappy, value: progress)
            .accessibilityElement()
            .accessibilityLabel("Progress")
            .accessibilityValue(progress.formatted(.percent.precision(.fractionLength(0))))
    }
}
