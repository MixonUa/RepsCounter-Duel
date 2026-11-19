/// Length of a duel, chosen by the host on "Set a duel time" (Figma, 2026-11-19): presets
/// 1 / 2 / 3 / 5 / 10 min, or any value in 10-second steps with − / +.
/// Bounds 10 s … 10 min (confirmed 2026-11-19; the server must enforce the same).
public struct DuelDuration: Hashable, Codable, Sendable, Identifiable {
    public let seconds: Int

    public static let step = 10
    public static let minimumSeconds = 10
    public static let maximumSeconds = 600

    /// "Time" presets on the setup screen.
    public static let presets: [DuelDuration] = [60, 120, 180, 300, 600].map(DuelDuration.init(seconds:))
    /// Selected when the setup screen opens.
    public static let `default` = DuelDuration(seconds: 60)

    public static let thirty = DuelDuration(seconds: 30)
    public static let sixty = DuelDuration(seconds: 60)

    /// Rounds to the nearest 10-second step and clamps to the allowed range.
    public init(seconds: Int) {
        let rounded = Int((Double(seconds) / Double(Self.step)).rounded()) * Self.step
        self.seconds = min(max(rounded, Self.minimumSeconds), Self.maximumSeconds)
    }

    public var id: Int { seconds }
    public var canDecrement: Bool { seconds > Self.minimumSeconds }
    public var canIncrement: Bool { seconds < Self.maximumSeconds }
    public func decremented() -> DuelDuration { DuelDuration(seconds: seconds - Self.step) }
    public func incremented() -> DuelDuration { DuelDuration(seconds: seconds + Self.step) }

    /// Whole minutes for a preset ("1", "10"); nil for other values.
    public var wholeMinutes: Int? { seconds.isMultiple(of: 60) ? seconds / 60 : nil }

    /// "1 min", "90 s", "2 min 30 s".
    public var displayName: String {
        let minutes = seconds / 60, rest = seconds % 60
        switch (minutes, rest) {
        case (0, _): return "\(rest) s"
        case (_, 0): return "\(minutes) min"
        default: return "\(minutes) min \(rest) s"
        }
    }

    // Stored and sent as a plain number of seconds.
    public init(from decoder: any Decoder) throws {
        self.init(seconds: try decoder.singleValueContainer().decode(Int.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(seconds)
    }
}
