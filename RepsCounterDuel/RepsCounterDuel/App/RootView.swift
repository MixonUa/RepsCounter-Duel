import SwiftUI
import DesignSystem

/// Shows onboarding on first launch, then the main tabs.
///
/// UI stage: completion is a local flag. Stage 1 replaces it with "registered profile exists".
/// Reset in the simulator by launching with `-onboardingCompleted NO`.
struct RootView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted {
            MainTabsView()
        } else {
            OnboardingFlowView(onFinish: { onboardingCompleted = true })
        }
    }
}

/// Main tabs + custom bottom bar with the separate Duel action.
struct MainTabsView: View {
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
