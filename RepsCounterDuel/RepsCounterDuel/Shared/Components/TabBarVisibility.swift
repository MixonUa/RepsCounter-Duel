import SwiftUI

/// Pushed screens that Figma draws without the bottom bar (e.g. Friends) set this to `true`;
/// `MainTabsView` hides the floating bar while any such screen is on screen.
struct TabBarHiddenPreference: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    func hidesTabBar() -> some View {
        preference(key: TabBarHiddenPreference.self, value: true)
    }
}
