import DesignSystem

/// Main tabs. Duel is not a tab: it is a separate action on the right of the bar.
enum AppTab: Hashable, CaseIterable {
    case home, rating, profile

    var tabBarItem: RCTabBarItem<AppTab> {
        switch self {
        case .home: RCTabBarItem(.home, title: "Home", systemImage: "house.fill")
        case .rating: RCTabBarItem(.rating, title: "Rating", systemImage: "trophy.fill")
        case .profile: RCTabBarItem(.profile, title: "Profile", systemImage: "person.fill")
        }
    }
}
