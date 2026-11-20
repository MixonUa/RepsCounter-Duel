import Foundation
import Observation
import OSLog
import Backend
import ExerciseAnalyzer

/// `TrainingProgress` in UserDefaults (survives relaunches, wiped with the app; SwiftData later).
/// Records are also sent to the server (shown to opponents as "PR"): right after a new record and
/// on every app activation (`syncRecords`), so an offline record is uploaded later.
@Observable
final class TrainingProgressStore {
    private(set) var progress: TrainingProgress
    private let defaults: UserDefaults
    @ObservationIgnored private let sync: (any TrainingRecordSyncing)?

    init(defaults: UserDefaults = .standard, sync: (any TrainingRecordSyncing)? = AppServices.trainingRecordSync) {
        self.defaults = defaults
        self.sync = sync
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
        if isRecord, let sync {
            Task { try? await sync.saveTrainingRecord(reps, for: exercise) }
        }
        return isRecord
    }

    /// Uploads every local record (the server keeps the greatest value).
    func syncRecords() async {
        guard let sync else { return }
        for (exercise, reps) in progress.records where reps > 0 {
            do {
                try await sync.saveTrainingRecord(reps, for: exercise)
            } catch {
                AppLog.backend.error("Syncing the training record failed: \(String(describing: error), privacy: .public)")
            }
        }
    }
}
