import SwiftUI
import DesignSystem

/// FIGMA: back button on the left, progress bar centered on the screen.
struct OnboardingProgressHeader: View {
    let progress: Double
    let onBack: () -> Void

    var body: some View {
        ZStack {
            RCProgressBar(progress: progress)
            HStack {
                RCBackButton(action: onBack)
                Spacer()
            }
        }
        .padding(.horizontal, RCSpacing.m)
        .padding(.top, 3)
    }
}
