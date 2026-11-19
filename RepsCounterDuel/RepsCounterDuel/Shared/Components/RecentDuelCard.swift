import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA "Recent duels" card: my avatar (blue ring + ⚡ badge) and nickname on the left, score,
/// outcome and exercise in the middle, opponent on the right. Meant for reuse on Home.
struct RecentDuelCard: View {
    let me: PlayerProfile
    let duel: DuelSummary

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            player(me, isMe: true)
                .frame(width: 110)
            VStack(spacing: 0) {
                Text("\(duel.myReps)-\(duel.opponentReps)")
                    // FIGMA: ≈ 41 pt heavy italic.
                    .font(.system(size: 41, weight: .heavy).italic())
                    .monospacedDigit()
                    .foregroundStyle(RCColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(outcomeTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(outcomeColor)
                    .padding(.top, RCSpacing.xs)
                Text(duel.exercise.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(RCColor.textSecondary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            player(duel.opponent, isMe: false)
                .frame(width: 110)
        }
        .padding(.horizontal, RCSpacing.s)
        .padding(.top, RCSpacing.xl)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(me.nickname) \(duel.myReps), \(duel.opponent.nickname) \(duel.opponentReps), \(outcomeTitle), \(duel.exercise.displayName)")
    }

    private func player(_ profile: PlayerProfile, isMe: Bool) -> some View {
        VStack(spacing: 6) {
            Text(profile.emoji)
                .font(.system(size: 40))
                .frame(width: 64, height: 64)
                .background(RCColor.avatarFill, in: Circle())
                .overlay {
                    if isMe {
                        Circle().strokeBorder(RCColor.accent, lineWidth: 3).padding(-2)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if isMe {
                        // FIGMA: accent badge with a white bolt and a white border.
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(RCColor.accent, in: Circle())
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                            .offset(x: 8, y: -8)
                    }
                }
            Text(profile.nickname)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(RCColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var outcomeTitle: String {
        switch duel.outcome {
        case .win: "Win"
        case .loss: "Loss"
        case .draw: "Draw"
        }
    }

    private var outcomeColor: Color {
        switch duel.outcome {
        case .win: RCColor.win
        case .loss: RCColor.loss
        case .draw: RCColor.draw
        }
    }
}
