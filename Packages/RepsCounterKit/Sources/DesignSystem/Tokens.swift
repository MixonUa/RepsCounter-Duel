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
    /// FIGMA Home: primary button inside a card.
    public static let button: CGFloat = 50
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
    /// FIGMA Choose Activity / Choose Exercise cards: lighter top-right, light-blue description.
    public static let activityCardTop = Color(rgb: 0x2B8DFE)
    public static let activityCardMiddle = Color(rgb: 0x1665DA)
    public static let activityCardText = Color(rgb: 0xA4DCFF)
    /// FIGMA "Ready to duel?": avatar circle fill and the light end of the VS gradient.
    public static let lobbyAvatar = Color(rgb: 0x1D72E2)
    public static let lobbyVS = Color(rgb: 0x9FD0FF)
    /// FIGMA live duel: opponent red (score bar, badge, Give up text) and the Give up fill.
    public static let duelRed = Color(rgb: 0xFF2D55)
    public static let giveUpFill = Color(rgb: 0x2A0E10)
    /// FIGMA duel results: avatar fills on the win / loss backdrops and the stats card.
    public static let resultWinAvatar = Color(rgb: 0x1E8494)
    public static let resultLossAvatar = Color(rgb: 0x594C8E)
    public static let resultCard = Color(rgb: 0x0E0E0E)
    /// FIGMA Duels History: highlighted (winner) avatar fill.
    public static let historyWinnerFill = Color(rgb: 0x8EC6FF)
    /// FIGMA: light rim around the icon circle on a goal card.
    public static let goalIconRim = Color(rgb: 0xCFD8F3)
    /// FIGMA: thin divider inside white cards.
    public static let cardDivider = Color(rgb: 0xE0E0E0)
    /// FIGMA: pending / in-progress status circle in a checklist and its number.
    public static let statusPendingFill = Color(rgb: 0xF2F2F2)
    public static let statusPendingText = Color(rgb: 0x8B8B8B)
    /// FIGMA: large bolt illustration gradient, top → bottom.
    public static let boltTop = Color(rgb: 0x56C1FA)
    public static let boltBottom = Color(rgb: 0x0E65EE)
    /// FIGMA Home chart: past-day bar, empty-day pill.
    public static let chartPastBar = Color(rgb: 0xBEDDFE)
    public static let chartEmptyPill = Color(rgb: 0xEFEFEF)
    /// FIGMA Home rank card: light-blue tile behind the trophy.
    public static let rankTile = Color(rgb: 0xDEEEFF)
    /// FIGMA tab bar: pill behind the selected tab.
    public static let tabSelectedPill = Color(rgb: 0xDEDEE2)
    /// FIGMA Profile header gradient (top → deepest blue; fades into `background`).
    public static let profileHeaderTop = Color(rgb: 0x278BFB)
    public static let profileHeaderDeep = Color(rgb: 0x157EF5)
    /// FIGMA Profile: avatar circle on the blue header.
    public static let profileAvatarFill = Color(rgb: 0x8DC1FB)
    /// FIGMA Top Friends rank numbers and pending-request gray.
    public static let rankNumber = Color(rgb: 0xC2C2C4)
    public static let pendingFill = Color(rgb: 0xEBEBEB)
    /// FIGMA Friends: light-blue avatar circle.
    public static let friendAvatarFill = Color(rgb: 0xDDEEFF)
    /// FIGMA Settings: deep-navy PRO card with a diagonal light streak.
    public static let proCardBase = Color(rgb: 0x012186)
    public static let proCardEdge = Color(rgb: 0x01114B)
    public static let proCardStreak = Color(rgb: 0x0D53E1)
    /// FIGMA Settings: grouped rows card, section titles, segmented control track, row arrows.
    public static let settingsGroup = Color(rgb: 0xF7F6F9)
    public static let sectionTitle = Color(rgb: 0x88878E)
    public static let segmentTrack = Color(rgb: 0xE8E7EA)
    public static let rowArrow = Color(rgb: 0xC4C3C6)
    /// FIGMA friend request: light pink "Reject" capsule (text uses `error`).
    public static let rejectFill = Color(rgb: 0xFADDE1)
    /// FIGMA Rating: podium card fill, avatar circle, place-number gradient, list card, my row,
    /// empty-state skeletons.
    public static let podiumCard = Color(rgb: 0xEFF4FD)
    public static let podiumAvatar = Color(rgb: 0xB2D2FB)
    public static let placeNumberTop = Color(rgb: 0x68B1FF)
    public static let placeNumberBottom = Color(rgb: 0x9FCBFE)
    public static let leaderboardCard = Color(rgb: 0xF9F9FB)
    public static let myRow = Color(rgb: 0xB0CFF2)
    public static let skeleton = Color(rgb: 0xC7C7C9)
    public static let skeletonBar = Color(rgb: 0xDBDADD)
    /// FIGMA: "Win" / "+4 this week" green.
    public static let win = Color(rgb: 0x36BF5A)
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
    /// FIGMA: section heading above a card ("Your records", "Recent duels").
    public static let cardHeading = Font.system(size: 23, weight: .bold)
    /// FIGMA Home: section heading ("This week", "Your records"); used with tracking -0.8.
    public static let homeHeading = Font.system(size: 20, weight: .bold)
    /// FIGMA Home: screen title "Reps Counter".
    public static let homeTitle = Font.system(size: 34, weight: .bold)
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
