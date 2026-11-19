import SwiftUI
import DesignSystem

/// FIGMA "What Is Your Main Goal?": three large cards; tapping any card moves on.
struct MotivationStepView: View {
    let onSelect: (MotivationGoal) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Figma reads "What Is You"; fixed to "Your".
            OnboardingTitle("What Is Your", accent: "Main Goal ?")
                .padding(.top, RCSpacing.xxl)

            VStack(spacing: 17) {
                ForEach(MotivationGoal.allCases) { goal in
                    Button { onSelect(goal) } label: {
                        GoalCard(goal: goal)
                    }
                    .buttonStyle(GoalCardButtonStyle())
                    .accessibilityLabel(goal.accessibilityTitle)
                }
            }
            .padding(.horizontal, RCSpacing.xl)
            .padding(.top, RCSpacing.xxl + 2)
            .padding(.bottom, RCSpacing.xs)
        }
    }
}

/// FIGMA: 345 × 174 pt deep-blue card, white two-line title bottom-left, icon circle top-right.
private struct GoalCard: View {
    let goal: MotivationGoal

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(
                    stops: [
                        .init(color: RCColor.goalCardTop, location: 0),
                        .init(color: RCColor.goalCardMiddle, location: 0.45),
                        .init(color: RCColor.goalCardBottom, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))

            VStack(alignment: .leading, spacing: -1) {
                Text(goal.titleLines.0)
                Text(goal.titleLines.1)
            }
            .font(RCFont.onboardingTitle)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.leading, RCSpacing.xl)
            .padding(.bottom, RCSpacing.l + 2)

            iconCircle
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 19)
                .padding(.trailing, 17)
        }
        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 174)
    }

    /// FIGMA: exported 113 pt icon circle plus the light rim drawn around it on the card.
    private var iconCircle: some View {
        Image(goal.iconImageName)
            .resizable()
            .scaledToFit()
            .overlay(Circle().strokeBorder(RCColor.goalIconRim, lineWidth: 1.5))
            .frame(width: 113, height: 113)
            .accessibilityHidden(true)
    }
}

private struct GoalCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    MotivationStepView(onSelect: { _ in })
        .rcGradientBackground()
}
