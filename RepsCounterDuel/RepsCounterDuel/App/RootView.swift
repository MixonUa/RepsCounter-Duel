import SwiftUI
import DesignSystem

/// App shell: current tab + custom bottom bar with the separate Duel action.
/// Onboarding will be placed in front of this in stage 1.
struct RootView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isDuelSetupPresented = false

    var body: some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                RCTabBar(
                    items: AppTab.allCases.map(\.tabBarItem),
                    selection: $selectedTab,
                    actionTitle: "Duel",
                    actionSystemImage: "bolt.fill",
                    action: { isDuelSetupPresented = true }
                )
            }
            .sheet(isPresented: $isDuelSetupPresented) {
                DuelSetupPlaceholderView()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .home:
            HomeView(onChallenge: { isDuelSetupPresented = true })
        case .rating:
            RatingView()
        case .profile:
            ProfileView()
        }
    }
}

#Preview {
    RootView()
}
