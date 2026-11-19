import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

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
    /// Activity sheet: VS → Choose Activity; Home buttons → Choose Exercise in their mode.
    @State private var activityFlow: ActivityFlowStart?
    /// Full-screen "Ready to duel?" lobby (host: after the friend accepts; invitee: after Start Duel).
    @State private var lobby: DuelLobby?
    /// Host side: the lobby opens once the activity sheet has finished closing.
    @State private var lobbyAfterSheet: DuelLobby?
    /// Full-screen training for the chosen exercise (opens once the activity sheet has closed).
    @State private var training: Exercise?
    @State private var trainingAfterSheet: Exercise?
    /// Training total reps + per-exercise records kept on the phone.
    @State private var trainingStore = TrainingProgressStore()

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
    @State private var duelInvitations = DuelInvitationCenter()

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
        if showsFilledData { return MockData.homeFilled(firstWeekday: firstWeekday) }
        var overview = MockData.homeEmpty(firstWeekday: firstWeekday)
        // Real training records saved on the phone (the rest of Home stays mock until stage 5).
        overview.trainingRecords = trainingStore.progress.records
        return overview
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
                    action: { activityFlow = .chooseActivity }
                )
                // RCTabBar already has 4 pt bottom padding above the safe area.
                .offset(y: safeBottom + RCSpacing.xxs - Self.barBottomGap)
                .offset(y: isTabBarHidden ? 160 : 0)
                .allowsHitTesting(!isTabBarHidden)
            }
            // FIGMA: pinned incoming duel invitation / friend request over every tab (after its
            // modal was closed).
            .overlay(alignment: .top) {
                VStack(spacing: RCSpacing.s) {
                    if let invitation = duelInvitations.bannerInvitation {
                        DuelInvitationBanner(invitation: invitation)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    if let request = friendRequests.bannerRequest {
                        FriendRequestBanner(player: request)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, RCSpacing.m)
                .padding(.top, RCSpacing.xxs)
            }
            .animation(.snappy, value: friendRequests.bannerRequest?.id)
            .animation(.snappy, value: duelInvitations.bannerInvitation?.id)
        }
        .environment(friendRequests)
        .environment(duelInvitations)
        .task { receiveDebugInvitation() }
        .sheet(item: $duelInvitations.modalInvitation, onDismiss: duelInvitations.modalDidDismiss) { invitation in
            DuelInvitationSheet(invitation: invitation)
                .environment(duelInvitations)
        }
        .onChange(of: duelInvitations.acceptedInvitation) { _, invitation in
            guard let invitation else { return }
            duelInvitations.acceptedInvitation = nil
            lobby = DuelLobby(me: me, opponent: invitation.host, exercise: invitation.exercise, duration: invitation.duration, myStats: profileOverview.stats)
        }
        .fullScreenCover(item: $lobby) { lobby in
            DuelLobbyFlow(lobby: lobby)
        }
        .fullScreenCover(item: $training) { exercise in
            TrainingFlow(me: me, exercise: exercise, rank: homeOverview.rank, store: trainingStore)
        }
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
        .sheet(item: $activityFlow, onDismiss: {
            if let pending = lobbyAfterSheet {
                lobbyAfterSheet = nil
                lobby = pending
            }
            if let pending = trainingAfterSheet {
                trainingAfterSheet = nil
                training = pending
            }
        }) { start in
            ActivityFlowView(
                start: start,
                me: me,
                friends: profileOverview.friends,
                myStats: profileOverview.stats,
                onDuelAccepted: { lobbyAfterSheet = $0 },
                onTrainingStart: { trainingAfterSheet = $0 }
            )
        }
    }

    /// DEBUG `-debugIncomingDuel YES`: a mock friend invites me to a push-ups duel on launch.
    private func receiveDebugInvitation() {
        #if DEBUG
        guard UserDefaults.standard.bool(forKey: "debugIncomingDuel") else { return }
        duelInvitations.receive(DuelInvitation(
            host: MockData.friends.first ?? PlayerProfile(nickname: "Nova_07", emoji: "🐧"),
            exercise: .pushUps,
            duration: .default,
            expiresAt: .now.addingTimeInterval(DuelInvitation.defaultLifetime)
        ))
        #endif
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .home:
            HomeView(
                me: me,
                overview: homeOverview,
                onStartTraining: { activityFlow = .chooseExercise(.training) },
                onChallenge: { activityFlow = .chooseExercise(.duel) },
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
