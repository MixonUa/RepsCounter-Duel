/// "What Is Your Main Goal?" options. The choice is engagement only: it is not stored on the
/// server and does not change app logic (CLAUDE.md §8.1).
enum MotivationGoal: CaseIterable, Identifiable {
    case getStronger
    case maintainDiscipline
    case challengeFriends

    var id: Self { self }

    /// FIGMA: two lines.
    var titleLines: (String, String) {
        switch self {
        case .getStronger: ("Get", "Stronger")
        case .maintainDiscipline: ("Maintain", "Discipline")
        case .challengeFriends: ("Challenge", "Friends")
        }
    }

    var accessibilityTitle: String { "\(titleLines.0) \(titleLines.1)" }

    /// FIGMA: exported icon (gradient circle with a white glyph).
    var iconImageName: String {
        switch self {
        case .getStronger: "GoalGetStronger"
        case .maintainDiscipline: "GoalMaintainDiscipline"
        case .challengeFriends: "GoalChallengeFriends"
        }
    }
}
