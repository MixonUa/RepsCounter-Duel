import SwiftUI
import DesignSystem

/// FIGMA "Choose Your Avatar": large preview of the selected emoji and a scrollable 3-column grid.
/// One emoji is always selected (the first by default); tapping another one switches the
/// selection, there is no way to clear it.
struct AvatarStepView: View {
    @Binding var selection: AvatarEmoji
    let onContinue: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: RCSpacing.s), count: 3)

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
        ScrollView {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(AvatarEmoji.all) { avatar in
                    AvatarCell(avatar: avatar, isSelected: avatar == selection) {
                        selection = avatar
                    }
                }
            }
            .padding(.horizontal, RCSpacing.xs)
            .padding(.top, RCSpacing.s + 2)
        }
        .scrollIndicators(.hidden)
        // Leave room so the last row can scroll above the Continue button.
        .contentMargins(.bottom, RCSize.buttonLarge + RCSpacing.l, for: .scrollContent)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
    }
}

private struct AvatarCell: View {
    let avatar: AvatarEmoji
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(avatar.emoji)
                .font(.system(size: 64))
                .frame(width: 90, height: 90)
                .background(RCColor.avatarFill, in: Circle())
                .padding(7)
                .overlay {
                    // FIGMA: accent ring with a white gap around the selected avatar.
                    Circle()
                        .strokeBorder(RCColor.accent, lineWidth: 2.5)
                        .opacity(isSelected ? 1 : 0)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
        .accessibilityLabel(avatar.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection = AvatarEmoji.default
    AvatarStepView(selection: $selection, onContinue: {})
        .rcGradientBackground()
}
