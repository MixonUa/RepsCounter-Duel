import SwiftUI
import DesignSystem

/// FIGMA "Choose Your Avatar": large preview of the selected emoji and a scrollable 3-column grid.
/// One emoji is always selected (the first by default); tapping another one switches the
/// selection, there is no way to clear it.
struct AvatarStepView: View {
    @Binding var selection: AvatarEmoji
    let onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                OnboardingTitle("Choose Your", accent: "Avatar")
                    .padding(.top, RCSpacing.xxl)

                preview
                    .padding(.top, RCSpacing.xxl)

                grid
                    .padding(.top, RCSpacing.xxl)
                    .padding(.horizontal, RCSpacing.m)
                    .padding(.bottom, RCSpacing.l)
            }

            Button("Continue", action: onContinue)
                .buttonStyle(.rcPrimaryLarge)
                .padding(.horizontal, RCSpacing.xl)
                .padding(.bottom, RCSpacing.xxs)
        }
    }

    /// FIGMA: 140 pt circle with a soft white glow.
    private var preview: some View {
        OnboardingAvatarCircle(emoji: selection.emoji, diameter: 140)
            .animation(.snappy, value: selection)
            .accessibilityElement()
            .accessibilityLabel("Selected avatar: \(selection.name)")
    }

    /// FIGMA: white card (radius 22) that runs under the Continue button; content scrolls inside.
    private var grid: some View {
        // Leave room so the last row can scroll above the Continue button.
        AvatarGrid(selection: $selection, bottomInset: RCSize.buttonLarge + RCSpacing.l)
    }
}

#Preview {
    @Previewable @State var selection = AvatarEmoji.default
    AvatarStepView(selection: $selection, onContinue: {})
        .rcGradientBackground()
}
