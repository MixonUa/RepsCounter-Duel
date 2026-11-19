import SwiftUI
import Backend
import DesignSystem

/// FIGMA blue-header block shared by Profile and the player card: 141 pt emoji avatar, header
/// buttons on the sides, nickname with a copy button and the weekly place ("🏆 Top 11").
/// Draw it over `ProfileHeaderBackground()`.
struct PlayerHeader<Leading: View, Trailing: View>: View {
    let profile: PlayerProfile
    let weeklyRank: Int?
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                OnboardingAvatarCircle(emoji: profile.emoji, diameter: 141, fill: RCColor.profileAvatarFill)
                HStack(spacing: RCSpacing.s - 2) {
                    leading()
                    Spacer()
                    trailing()
                }
            }
            .padding(.top, RCSpacing.xxs)

            HStack(spacing: RCSpacing.s) {
                Text(profile.nickname)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                NicknameCopyButton(nickname: profile.nickname)
            }
            .padding(.top, RCSpacing.xs)

            if let weeklyRank {
                HStack(spacing: RCSpacing.xxs) {
                    Image(systemName: "trophy.fill")
                    Text("Top \(weeklyRank)")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, RCSpacing.xxs)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Top \(weeklyRank) this week")
            }
        }
    }
}

/// FIGMA 44 pt clear-glass circle button on the blue header (Edit, Settings, Back).
struct HeaderGlassButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: RCSize.backButton, height: RCSize.backButton)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .rcClearGlass(in: Circle())
        .accessibilityLabel(label)
    }
}

/// Copies the nickname; the icon turns into a checkmark for 1.5 s.
struct NicknameCopyButton: View {
    let nickname: String
    @State private var didCopy = false

    var body: some View {
        Button {
            UIPasteboard.general.string = nickname
            withAnimation(.snappy) { didCopy = true }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.snappy) { didCopy = false }
            }
        } label: {
            Image(systemName: didCopy ? "checkmark" : "square.on.square")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .rcClearGlass(in: Circle())
        .accessibilityLabel(didCopy ? "Nickname copied" : "Copy nickname")
    }
}
