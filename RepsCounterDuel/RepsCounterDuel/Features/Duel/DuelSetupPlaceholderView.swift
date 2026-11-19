import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// PROVISIONAL Duel Setup: exercise + 30/60/90 s. Friend invitation and the rest of the flow arrive in stage 4.
struct DuelSetupPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exercise: Exercise = .squats
    @State private var duration: DuelDuration = .sixty

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    Picker("Exercise", selection: $exercise) {
                        ForEach(Exercise.allCases) { exercise in
                            Label(exercise.displayName, systemImage: exercise.systemImage).tag(exercise)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Duration") {
                    Picker("Duration", selection: $duration) {
                        ForEach(DuelDuration.allCases) { duration in
                            Text(duration.displayName).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Button("Invite a friend") {}
                        .disabled(true)
                } footer: {
                    Text("Friend invitations arrive in a later build.")
                }
            }
            .navigationTitle("New Duel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    DuelSetupPlaceholderView()
}
