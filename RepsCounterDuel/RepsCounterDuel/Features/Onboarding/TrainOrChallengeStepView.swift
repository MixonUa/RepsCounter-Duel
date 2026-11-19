import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA explanation slide 1 "Train Solo Or Challenge Friends": sample records and a sample
/// recent duel featuring the player's own nickname and avatar. The numbers are illustrative only.
struct TrainOrChallengeStepView: View {
    let me: PlayerProfile
    let onContinue: () -> Void

    private let sampleOpponent = PlayerProfile(nickname: "Lena_V", emoji: "🐱")

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: RCSpacing.xs + 2) {
                OnboardingTitle("Train Solo Or", accent: "Challenge Friends")
                Text("Beat your personal records, check\nleaderboard and have a duels with friends")
                    .font(RCFont.onboardingSubtitle)
                    .foregroundStyle(RCColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, RCSpacing.xxl)
            .padding(.horizontal, RCSpacing.m)

            Spacer(minLength: RCSpacing.m)
                .frame(maxHeight: 40)

            section("Your records") {
                RecordsCard(items: [
                    .init(systemImage: "figure.run", value: "74", label: "Push-ups", weeklyChange: "+4 this week"),
                    .init(systemImage: "figure.step.training", value: "82", label: "Squats", weeklyChange: "+2 this week"),
                ])
            }

            Spacer(minLength: RCSpacing.m)
                .frame(maxHeight: 36)

            section("Recent duels") {
                RecentDuelCard(
                    me: me,
                    duel: DuelSummary(
                        opponent: sampleOpponent,
                        exercise: .pushUps,
                        duration: .sixty,
                        myReps: 24,
                        opponentReps: 17,
                        finishedAt: .now
                    )
                )
            }

            Spacer(minLength: RCSpacing.m)

            Button("Continue", action: onContinue)
                .buttonStyle(.rcPrimaryLarge)
                .padding(.horizontal, RCSpacing.xl)
                .padding(.bottom, RCSpacing.xxs)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            Text(title)
                .font(RCFont.cardHeading)
                .tracking(-0.5)
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .padding(.horizontal, RCSpacing.m)
    }
}

#Preview {
    TrainOrChallengeStepView(me: PlayerProfile(nickname: "Nova_07", emoji: "🐧"), onContinue: {})
        .rcGradientBackground()
}
