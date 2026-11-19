import SwiftUI
import DesignSystem
import ExerciseAnalyzer

/// FIGMA "Choose Exercise": Push-Ups or Squats. Same screen for training and duel; the `mode`
/// decides which screens follow. ‹ only when opened from Choose Activity.
struct ChooseExerciseView: View {
    let mode: ActivityMode
    let onBack: (() -> Void)?
    let onClose: () -> Void
    let onSelect: (Exercise) -> Void

    var body: some View {
        ActivityChoiceLayout(
            title: "Choose Exercise",
            subtitle: "Choose the type of exercise for duel or training",
            onBack: onBack,
            onClose: onClose
        ) {
            ActivityChoiceCard(
                title: "Push-Ups",
                description: "Classic push-ups with hands on the\nfloor, only full repetitions count",
                iconImageName: "ExercisePushUps",
                action: { onSelect(.pushUps) }
            )
            ActivityChoiceCard(
                title: "Squats",
                description: "Classic full squats, only\nclean repetitions count",
                iconImageName: "ExerciseSquats",
                action: { onSelect(.squats) }
            )
        }
    }
}

#Preview {
    ChooseExerciseView(mode: .training, onBack: {}, onClose: {}, onSelect: { _ in })
}
