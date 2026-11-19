import SwiftUI
import DesignSystem

/// FIGMA: large emoji avatar in a light-blue circle with a soft white glow
/// (140 pt on "Choose Your Avatar", 170 pt on "Your Profile Is Ready!").
struct OnboardingAvatarCircle: View {
    let emoji: String
    let diameter: CGFloat

    var body: some View {
        Text(emoji)
            .font(.system(size: diameter * 0.715))
            .contentTransition(.opacity)
            .frame(width: diameter, height: diameter)
            .background(RCColor.avatarFillLarge, in: Circle())
            .shadow(color: .white.opacity(0.9), radius: diameter * 0.13)
            .accessibilityHidden(true)
    }
}
