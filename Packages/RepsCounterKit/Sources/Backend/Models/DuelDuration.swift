/// Duel length chosen by the host before inviting a friend.
public enum DuelDuration: Int, CaseIterable, Codable, Sendable, Identifiable {
    case thirty = 30
    case sixty = 60
    case ninety = 90

    public var id: Int { rawValue }
    public var seconds: Int { rawValue }
    public var displayName: String { "\(rawValue) s" }
}
