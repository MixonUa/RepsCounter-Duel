import Foundation
import Observation
import Backend
import ExerciseAnalyzer

/// UI-stage storage of `TrainingProgress` in UserDefaults (survives relaunches, wiped with the
/// app). Stage 3 replaces it with SwiftData + sync of the training record.
@Observable
final class TrainingProgressStore {
    private(set) var progress: TrainingProgress
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        progress = defaults.data(forKey: LocalStorageKeys.trainingProgress)
            .flatMap { try? JSONDecoder().decode(TrainingProgress.self, from: $0) } ?? TrainingProgress()
    }

    /// Saves a finished session; returns `true` for a new record.
    @discardableResult
    func add(reps: Int, of exercise: Exercise) -> Bool {
        let isRecord = progress.add(reps: reps, of: exercise)
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: LocalStorageKeys.trainingProgress)
        }
        return isRecord
    }
}
