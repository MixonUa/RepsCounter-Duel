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
    /// Server snapshot when the lobby cover resumes an unfinished duel.
    @State private var resumedDuel: DuelSnapshot?
    /// Unfinished duel found on launch: Resume / Leave.
    @State private var unfinishedDuel: DuelSnapshot?
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
        // Same identity as on the server boards (derived from the nickname).
        PlayerProfile(
            serverNickname: nickname.isEmpty ? "Nova_07" : nickname,
            emoji: emoji.isEmpty ? "🐧" : emoji
        )
    }

    @State private var isTabBarHidden = false
    @State private var friendRequests = FriendRequestCenter()
    @State private var friendsStore = FriendsStore()
    @State private var statsStore = StatsStore()
    @Environment(\.scenePhase) private var scenePhase
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
        // Server: duel reps per day, last duel, weekly place; phone: training records and their
        // growth since the start of the same week as the chart ("+N this week").
        let week = WeekSummary.make(today: .now, dailyReps: statsStore.dailyReps(), firstWeekday: firstWeekday)
        return HomeOverview(
            week: week,
            trainingRecords: trainingStore.progress.records,
            trainingRecordGains: trainingStore.progress.gains(since: week.start),
            lastDuel: statsStore.recentDuels.first,
            rank: LeaderboardEntry.weeklyRank(for: me, in: statsStore.global)
        )
    }

    /// What this phone knows before the server stats arrive: my training records.
    private var localDuelStats: PlayerStats {
        var stats = profileOverview.stats
        for (exercise, reps) in trainingStore.progress.records {
            stats.trainingRecords[exercise] = max(stats.trainingRecord(for: exercise), reps)
        }
        return stats
    }

    /// Server: my all-time duel stats, weekly place, Top Friends of the week and my friends.
    private var profileOverview: ProfileOverview {
        if showsFilledData { return MockData.profileFilled }
        return ProfileOverview(
            stats: statsStore.myStats,
            weeklyRank: LeaderboardEntry.weeklyRank(for: me, in: statsStore.global)?.position,
            topFriends: statsStore.topFriends,
            friends: friendsStore.friends
        )
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
        .environment(friendsStore)
        // Incoming requests and my friends: fetched while the app is active.
        .task(id: scenePhase == .active) {
            guard scenePhase == .active else { return }
            friendRequests.onFriendsChanged = { [friendsStore] in Task { await friendsStore.refresh() } }
            await friendsStore.refresh()
            await checkUnfinishedDuel()
            await trainingStore.syncRecords()
            await statsStore.refresh()
            async let requests: Void = friendRequests.keepUpdated()
            async let duels: Void = duelInvitations.keepUpdated()
            _ = await (requests, duels)
        }
        .sheet(item: $duelInvitations.modalInvitation, onDismiss: duelInvitations.modalDidDismiss) { invitation in
            DuelInvitationSheet(invitation: invitation)
                .environment(duelInvitations)
        }
        .onChange(of: duelInvitations.acceptedDuel) { _, accepted in
            guard let accepted else { return }
            duelInvitations.acceptedDuel = nil
            lobby = DuelLobby(snapshot: accepted, me: me, myStats: localDuelStats)
        }
        .alert(
            "Challenge",
            isPresented: Binding(
                get: { duelInvitations.errorMessage != nil },
                set: { if !$0 { duelInvitations.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(duelInvitations.errorMessage ?? "")
        }
        .onChange(of: lobby == nil) { _, closed in
            // A duel just ended (or was left): new totals, history and places.
            if closed { Task { await statsStore.refresh() } }
        }
        .fullScreenCover(item: $lobby, onDismiss: { resumedDuel = nil }) { lobby in
            DuelLobbyFlow(lobby: lobby, resume: resumedDuel)
        }
        // PROVISIONAL (no Figma frame): an unfinished duel after the app was closed.
        .alert("Unfinished duel", isPresented: Binding(get: { unfinishedDuel != nil }, set: { if !$0 { unfinishedDuel = nil } }), presenting: unfinishedDuel) { duel in
            Button("Resume") { resume(duel) }
            Button("Leave", role: .destructive) { leave(duel) }
        } message: { duel in
            Text(Self.unfinishedMessage(duel))
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
                myStats: localDuelStats,
                onDuelAccepted: { lobbyAfterSheet = $0 },
                onTrainingStart: { trainingAfterSheet = $0 },
                friendsService: friendsStore.service,
                onFriendsChanged: { Task { await friendsStore.refresh() } }
            )
            .task { await friendsStore.refresh() }
        }
    }

    /// After a relaunch the app may have left a duel on the server (waiting, lobby, live): it keeps
    /// blocking new challenges ("busy") until it expires, so offer Resume or Leave.
    private func checkUnfinishedDuel() async {
        guard lobby == nil, activityFlow == nil, unfinishedDuel == nil,
              let duel = try? await AppServices.duelService.activeDuel() else { return }
        unfinishedDuel = duel
    }

    private func resume(_ duel: DuelSnapshot) {
        resumedDuel = duel
        lobby = DuelLobby(snapshot: duel, me: me, myStats: localDuelStats)
    }

    private func leave(_ duel: DuelSnapshot) {
        Task {
            _ = try? await AppServices.duelService.leave(duel.id)
            await statsStore.refresh()
        }
    }

    private static func unfinishedMessage(_ duel: DuelSnapshot) -> String {
        let name = duel.opponent.nickname
        switch duel.phase {
        case .invited: return "Your challenge to \(name) is still waiting for an answer."
        case .lobby: return "Your duel with \(name) is waiting in the lobby."
        default: return "Your duel with \(name) is still running. Leaving now counts as giving up."
        }
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
            .task { await statsStore.refresh() }
        case .rating:
            RatingView(me: me, overview: showsFilledData ? MockData.ratingFilled(me: me) : statsStore.rating)
                .task { await statsStore.refresh() }
                .refreshable { await statsStore.refresh() }
        case .profile:
            ProfileView(me: me, overview: profileOverview)
                .task { await statsStore.refresh() }
        }
    }
}

#Preview {
    RootView()
}
