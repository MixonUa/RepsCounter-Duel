import SwiftUI

// Tokens. Values marked FIGMA were measured from exported Figma frames (2026-11-19);
// the rest are PROVISIONAL system values until Figma variables can be read via Figma MCP.
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
    /// FIGMA: tips card ≈ 22.
    public static let card: CGFloat = 22
    public static let control: CGFloat = 14
}

public enum RCSize {
    /// Minimum accessible touch target (HIG).
    public static let minTouchTarget: CGFloat = 44
    public static let tabBarHeight: CGFloat = 64
    /// FIGMA: large primary button height.
    public static let buttonLarge: CGFloat = 64
    public static let button: CGFloat = 52
    /// FIGMA: capsule text field height.
    public static let field: CGFloat = 57
    /// FIGMA: round back button.
    public static let backButton: CGFloat = 44
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
    /// FIGMA: onboarding subtitle gray.
    public static let textSecondary = Color(rgb: 0x7C808B)
    /// FIGMA #2A8DFD (the app's AccentColor asset has the same value).
    public static let accent = Color(rgb: 0x2A8DFD)
    /// FIGMA: top of the light-blue screen gradient (fades into `background` at ~53% height).
    public static let backgroundGradientTop = Color(rgb: 0xB6D3F7)
    /// FIGMA: primary button gradient, top → bottom.
    public static let buttonGradientTop = Color(rgb: 0x2284F5)
    public static let buttonGradientBottom = Color(rgb: 0x3495FF)
    /// FIGMA: inactive page indicator dot.
    public static let indicatorInactive = Color(rgb: 0xDADADE)
    /// FIGMA: camera viewfinder corner brackets.
    public static let viewfinder = Color(rgb: 0xBABDC5)
    /// FIGMA: onboarding progress bar track.
    public static let progressTrack = Color(rgb: 0xA9CBF8)
    /// FIGMA: disabled primary button fill.
    public static let buttonDisabled = Color(rgb: 0xE3E3E5)
    /// FIGMA: inline error text.
    public static let error = Color(rgb: 0xEB4148)
    /// FIGMA: circle behind an emoji avatar (grid cell / large preview).
    public static let avatarFill = Color(rgb: 0xC1DBFE)
    public static let avatarFillLarge = Color(rgb: 0xB1CFF9)
    /// FIGMA: deep-blue goal card gradient (top highlight → body → bottom).
    public static let goalCardTop = Color(rgb: 0x1D71E4)
    public static let goalCardMiddle = Color(rgb: 0x043EB7)
    public static let goalCardBottom = Color(rgb: 0x0237B3)
    /// FIGMA: light rim around the icon circle on a goal card.
    public static let goalIconRim = Color(rgb: 0xCFD8F3)
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
    /// FIGMA: onboarding title (two lines, second line in accent).
    public static let onboardingTitle = Font.largeTitle.weight(.bold)
    /// FIGMA: 17 pt on all onboarding screens (unified 2026-11-19).
    public static let onboardingSubtitle = Font.body
    /// FIGMA: text typed into a capsule field.
    public static let fieldText = Font.body.weight(.semibold)
    /// FIGMA: inline error under a field.
    public static let fieldError = Font.subheadline
    public static let tip = Font.callout.weight(.semibold)
    /// FIGMA: large primary button label.
    public static let buttonLarge = Font.title2.weight(.semibold)
    /// Distance-readable live counter for training / duel screens.
    public static let liveCounter = Font.system(size: 120, weight: .heavy, design: .rounded)
}

extension Color {
    /// sRGB color from a 0xRRGGBB literal.
    init(rgb: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: opacity
        )
    }
}

public extension View {
    /// FIGMA: light-blue → gray screen background used on onboarding screens.
    func rcGradientBackground() -> some View {
        background(
            LinearGradient(
                stops: [
                    .init(color: RCColor.backgroundGradientTop, location: 0),
                    .init(color: RCColor.background, location: 0.53),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
