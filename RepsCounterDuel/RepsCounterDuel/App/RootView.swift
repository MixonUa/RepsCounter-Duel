import SwiftUI
import Backend
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

    /// UI stage: the registered nickname/emoji saved by onboarding (stage 1 reads the profile
    /// from the server).
    @AppStorage(LocalStorageKeys.nickname) private var nickname = ""
    @AppStorage(LocalStorageKeys.emoji) private var emoji = ""

    private var me: PlayerProfile {
        PlayerProfile(
            nickname: nickname.isEmpty ? "Nova_07" : nickname,
            emoji: emoji.isEmpty ? "🐧" : emoji
        )
    }

    @State private var isTabBarHidden = false
    @State private var friendRequests = FriendRequestCenter()

    /// Mock data until stages 2–5: a new player sees the empty states.
    /// DEBUG: `-debugDataState filled` shows the filled Home, Rating and Profile.
    private var showsFilledData: Bool {
        #if DEBUG
        UserDefaults.standard.string(forKey: "debugDataState") == "filled"
        #else
        false
        #endif
    }

    @AppStorage(LocalStorageKeys.firstWeekday) private var firstWeekday = 2

    private var homeOverview: HomeOverview {
        showsFilledData
            ? MockData.homeFilled(firstWeekday: firstWeekday)
            : MockData.homeEmpty(firstWeekday: firstWeekday)
    }

    private var profileOverview: ProfileOverview {
        showsFilledData ? MockData.profileFilled : MockData.profileEmpty
    }

    /// FIGMA: the bar (66 pt) floats 22 pt above the physical screen edge — partly inside the
    /// bottom safe area on Face ID iPhones (clear of the home indicator), 22 pt on others.
    private static let barHeight: CGFloat = 66
    private static let barBottomGap: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let safeBottom = proxy.safeAreaInsets.bottom
            ZStack(alignment: .bottom) {
                content
                    // Lets the last card scroll out from under the floating bar.
                    .safeAreaPadding(.bottom, isTabBarHidden ? 0 : max(0, Self.barHeight + Self.barBottomGap - safeBottom) + RCSpacing.s)
                    .onPreferenceChange(TabBarHiddenPreference.self) { hidden in
                        withAnimation(.snappy) { isTabBarHidden = hidden }
                    }

                RCTabBar(
                    items: AppTab.allCases.map(\.tabBarItem),
                    selection: $selectedTab,
                    actionText: "VS",
                    actionAccessibilityLabel: "Duel",
                    action: { isDuelSetupPresented = true }
                )
                // RCTabBar already has 4 pt bottom padding above the safe area.
                .offset(y: safeBottom + RCSpacing.xxs - Self.barBottomGap)
                .offset(y: isTabBarHidden ? 160 : 0)
                .allowsHitTesting(!isTabBarHidden)
            }
            // FIGMA: pinned incoming friend request over every tab (after its modal was closed).
            .overlay(alignment: .top) {
                if let request = friendRequests.bannerRequest {
                    FriendRequestBanner(player: request)
                        .padding(.horizontal, RCSpacing.m)
                        .padding(.top, RCSpacing.xxs)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: friendRequests.bannerRequest?.id)
        }
        .environment(friendRequests)
        .sheet(item: $friendRequests.modalRequest) { request in
            FriendRequestSheet(player: request)
                .environment(friendRequests)
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { friendRequests.errorMessage != nil },
                set: { if !$0 { friendRequests.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(friendRequests.errorMessage ?? "")
        }
        .sheet(isPresented: $isDuelSetupPresented) {
            DuelSetupPlaceholderView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .home:
            HomeView(
                me: me,
                overview: homeOverview,
                onChallenge: { isDuelSetupPresented = true },
                onOpenRating: { selectedTab = .rating }
            )
        case .rating:
            RatingView(me: me, overview: showsFilledData ? MockData.ratingFilled(me: me) : .empty)
        case .profile:
            ProfileView(me: me, overview: profileOverview)
        }
    }
}

#Preview {
    RootView()
}
