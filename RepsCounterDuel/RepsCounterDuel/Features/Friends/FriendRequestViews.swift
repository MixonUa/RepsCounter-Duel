import SwiftUI
import Backend
import DesignSystem

/// FIGMA incoming friend request (page sheet): glass ✕, big 👋, "New Friend !",
/// "<nickname> sent you a request", "Add to Friends" and "Reject".
struct FriendRequestSheet: View {
    let player: PlayerProfile
    @Environment(FriendRequestCenter.self) private var center
    @Environment(\.dismiss) private var dismiss

    private var isResponding: Bool { center.respondingTo == player.id }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(RCColor.textPrimary)
                        .frame(width: RCSize.backButton, height: RCSize.backButton)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .rcGlass(in: Circle(), interactive: true)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.m)

            Spacer(minLength: RCSpacing.m)

            Text("👋")
                .font(.system(size: 150))
                .accessibilityHidden(true)

            Spacer(minLength: RCSpacing.m)

            Text("New Friend !")
                .font(RCFont.onboardingTitle)
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            requestLine
                .font(RCFont.onboardingSubtitle)
                .padding(.top, RCSpacing.xs)

            Spacer(minLength: RCSpacing.xl)

            VStack(spacing: RCSpacing.s) {
                Button { center.respond(to: player, accept: true) } label: {
                    if isResponding { ProgressView().tint(.white) } else { Text("Add to Friends") }
                }
                .buttonStyle(.rcPrimaryLarge)
                Button("Reject") { center.respond(to: player, accept: false) }
                    .buttonStyle(.rcDestructiveLarge)
            }
            .disabled(isResponding)
            .padding(.horizontal, RCSpacing.xl)
            .padding(.bottom, RCSpacing.xxs)
        }
        .background(RCColor.background.ignoresSafeArea())
    }

    private var requestLine: some View {
        (Text(player.nickname).foregroundStyle(RCColor.accent)
         + Text("  sent you a request").foregroundStyle(RCColor.textSecondary))
            .tracking(-0.4)
    }
}

/// FIGMA pinned banner (after the modal was closed): white card at the top of every tab with
/// "New Friend", "<nickname> sent you a request" and side-by-side "Add to Friends" / "Reject".
struct FriendRequestBanner: View {
    let player: PlayerProfile
    @Environment(FriendRequestCenter.self) private var center

    private var isResponding: Bool { center.respondingTo == player.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("New Friend")
                .font(.system(size: 20, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(RCColor.textPrimary)
            (Text(player.nickname).foregroundStyle(RCColor.accent)
             + Text("  sent you a request").foregroundStyle(RCColor.textSecondary))
                .font(.system(size: 15))
                .tracking(-0.3)
                .padding(.top, RCSpacing.xxs)

            HStack(spacing: RCSpacing.s) {
                Button { center.respond(to: player, accept: true) } label: {
                    if isResponding { ProgressView().tint(.white) } else { Text("Add to Friends") }
                }
                .buttonStyle(.rcPrimaryCompact)
                Button("Reject") { center.respond(to: player, accept: false) }
                    .buttonStyle(.rcDestructive)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .disabled(isResponding)
            .padding(.top, RCSpacing.m)
        }
        .padding(RCSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Friend request from \(player.nickname)")
    }
}
