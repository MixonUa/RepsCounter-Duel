/// Exercises supported by Reps Counter. Rep-counting state machines are added in stage 3.
public enum Exercise: String, CaseIterable, Codable, Sendable, Identifiable {
    case squats
    case pushUps = "push_ups"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .squats: "Squats"
        case .pushUps: "Push-ups"
        }
    }

    /// SF Symbol used for the exercise in lists and pickers.
    public var systemImage: String {
        switch self {
        case .squats: "figure.cross.training"
        case .pushUps: "figure.strengthtraining.functional"
        }
    }
}
