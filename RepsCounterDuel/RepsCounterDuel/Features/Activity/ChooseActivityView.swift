import SwiftUI
import DesignSystem

/// FIGMA "Choose Activity" (opened by the VS button): Duel or Train, ✕ only.
struct ChooseActivityView: View {
    let onClose: () -> Void
    let onSelect: (ActivityMode) -> Void

    var body: some View {
        ActivityChoiceLayout(
            title: "Choose Activity",
            subtitle: "Practice along or challenge a friend",
            onBack: nil,
            onClose: onClose
        ) {
            ActivityChoiceCard(
                title: "Duel",
                description: "Compete with your friends\nin the number of repetitions",
                iconImageName: "ActivityDuel",
                action: { onSelect(.duel) }
            )
            ActivityChoiceCard(
                title: "Train",
                description: "Train reps along without a\ntimer or opponent",
                iconImageName: "ActivityTrain",
                action: { onSelect(.training) }
            )
        }
    }
}

#Preview {
    ChooseActivityView(onClose: {}, onSelect: { _ in })
}
