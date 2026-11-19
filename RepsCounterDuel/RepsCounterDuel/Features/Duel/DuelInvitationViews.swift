import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA incoming duel (page sheet): "3:00 LEFT" countdown, ✕, big glowing VS, "New Duel !",
/// "<host> invited you to a <exercise> competition", Start Duel ! and Refuse.
struct DuelInvitationSheet: View {
    let invitation: DuelInvitation
    @Environment(DuelInvitationCenter.self) private var center
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let left = invitation.secondsLeft(at: context.date)
                    VStack(spacing: 0) {
                        Text(DuelInvitation.countdownText(seconds: left))
                            .font(.system(size: 22, weight: .bold).monospacedDigit())
                            .foregroundStyle(RCColor.textPrimary)
                        Text("LEFT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(RCColor.textSecondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(left / 60) minutes \(left % 60) seconds left")
                }
                .padding(.top, RCSpacing.xxl)
                HStack {
                    Spacer()
                    ActivityCloseButton { dismiss() }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.m)

            Spacer(minLength: RCSpacing.m)

            // Cut from the Figma frame (glow on the sheet background); replace with an export.
            Image("DuelInviteVS")
                .resizable()
                .scaledToFit()
                .frame(width: 230)
                .accessibilityHidden(true)

            Spacer(minLength: RCSpacing.m)

            Text("New Duel !")
                .font(RCFont.homeTitle)
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            DuelInvitationLine(invitation: invitation)
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .padding(.horizontal, RCSpacing.xxl)
                .padding(.top, RCSpacing.xs)

            Spacer(minLength: RCSpacing.xl)

            VStack(spacing: RCSpacing.s) {
                Button("Start Duel !") { center.accept(invitation) }
                    .buttonStyle(.rcPrimaryLarge)
                Button("Refuse") { center.refuse(invitation) }
                    .buttonStyle(.rcDestructiveLarge)
            }
            .padding(.horizontal, RCSpacing.l)
            .padding(.bottom, RCSpacing.xxs)
        }
        .background(RCColor.background.ignoresSafeArea())
    }
}

/// "<host> invited you to a <exercise> competition" with the nickname and exercise in accent.
struct DuelInvitationLine: View {
    let invitation: DuelInvitation

    var body: some View {
        (Text(invitation.host.nickname).foregroundStyle(RCColor.accent)
         + Text("  invited you to a ").foregroundStyle(RCColor.textSecondary)
         + Text(invitation.exercise.displayName.lowercased()).fontWeight(.semibold).foregroundStyle(RCColor.accent)
         + Text(" competition").foregroundStyle(RCColor.textSecondary))
            .tracking(-0.4)
    }
}

/// FIGMA pinned banner (after the modal was closed): "New Duel" + countdown, the invitation
/// line and side-by-side Start Duel ! / Refuse, on top of every tab.
struct DuelInvitationBanner: View {
    let invitation: DuelInvitation
    @Environment(DuelInvitationCenter.self) private var center

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("New Duel")
                    .font(.system(size: 20, weight: .semibold))
                    .tracking(-0.4)
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(DuelInvitation.countdownText(seconds: invitation.secondsLeft(at: context.date)))
                        .font(.system(size: 20, weight: .bold).monospacedDigit())
                }
            }
            .foregroundStyle(RCColor.textPrimary)

            DuelInvitationLine(invitation: invitation)
                .font(.system(size: 15))
                .padding(.top, RCSpacing.xxs)

            HStack(spacing: RCSpacing.s) {
                Button("Start Duel !") { center.accept(invitation) }
                    .buttonStyle(.rcPrimaryCompact)
                Button("Refuse") { center.refuse(invitation) }
                    .buttonStyle(.rcDestructive)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.top, RCSpacing.m)
        }
        .padding(RCSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Duel invitation from \(invitation.host.nickname)")
    }
}

#Preview("Sheet") {
    let invitation = DuelInvitation(
        host: PlayerProfile(nickname: "Nova_07", emoji: "🐧"),
        exercise: .pushUps,
        duration: .default,
        expiresAt: .now.addingTimeInterval(DuelInvitation.defaultLifetime)
    )
    DuelInvitationSheet(invitation: invitation)
        .environment(DuelInvitationCenter())
}
