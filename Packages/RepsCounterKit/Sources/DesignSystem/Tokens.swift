import SwiftUI

// PROVISIONAL tokens: system iOS values until the Figma variables can be read via Figma MCP.
// Replace values here only — views must use these tokens, never raw numbers or colors.

public enum RCSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let s: CGFloat = 12
    public static let m: CGFloat = 16
    public static let l: CGFloat = 20
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

public enum RCRadius {
    public static let card: CGFloat = 20
    public static let control: CGFloat = 14
}

public enum RCSize {
    /// Minimum accessible touch target (HIG).
    public static let minTouchTarget: CGFloat = 44
    public static let tabBarHeight: CGFloat = 64
}

public enum RCColor {
    #if os(iOS)
    public static let background = Color(uiColor: .systemGroupedBackground)
    public static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    public static let separator = Color(uiColor: .separator)
    #else
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let surface = Color(nsColor: .controlBackgroundColor)
    public static let separator = Color(nsColor: .separatorColor)
    #endif
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let accent = Color.accentColor
    public static let win = Color.green
    public static let loss = Color.red
    public static let draw = Color.orange
}

public enum RCFont {
    public static let screenTitle = Font.largeTitle.weight(.bold)
    public static let sectionTitle = Font.title3.weight(.semibold)
    public static let statValue = Font.system(.title, design: .rounded).weight(.bold)
    public static let statLabel = Font.footnote
    public static let body = Font.body
    public static let caption = Font.caption
    /// Distance-readable live counter for training / duel screens.
    public static let liveCounter = Font.system(size: 120, weight: .heavy, design: .rounded)
}
