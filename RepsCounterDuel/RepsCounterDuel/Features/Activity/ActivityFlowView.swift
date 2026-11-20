import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// What the user is starting: solo training or a duel. Choose Exercise and every screen after it
/// are built differently for each mode.
enum ActivityMode: String, Hashable, Identifiable {
    case training
    case duel

    var id: String { rawValue }
}

/// Where the activity sheet opens:
/// - `.chooseActivity` — the VS button in the tab bar (Choose Activity → Choose Exercise);
/// - `.chooseExercise(mode)` — Home "Start Train" / "Challenge a Friend" (straight to Choose Exercise).
enum ActivityFlowStart: Hashable, Identifiable {
    case chooseActivity
    case chooseExercise(ActivityMode)

    var id: String {
        switch self {
        case .chooseActivity: "activity"
        case .chooseExercise(let mode): "exercise-\(mode.rawValue)"
        }
    }
}

/// The activity sheet: one navigation stack for Choose Activity → Choose Exercise → the
/// mode-specific screens. ✕ closes the whole flow; ‹ goes back one screen.
struct ActivityFlowView: View {
    let start: ActivityFlowStart
    let me: PlayerProfile
    /// My friends and sent requests (from the server via `FriendsStore`).
    let friends: [FriendListItem]
    /// My stats for the lobby's HEAD TO HEAD.
    var myStats: PlayerStats = .empty
    /// The friend accepted: the sheet closes and the full-screen lobby opens.
    var onDuelAccepted: (DuelLobby) -> Void = { _ in }
    /// Training exercise chosen: the sheet closes and the full-screen training opens.
    var onTrainingStart: (Exercise) -> Void = { _ in }
    var friendsService: any FriendsServicing = AppServices.friendsService
    /// My friends changed here (request sent / accepted from a player card).
    var onFriendsChanged: () -> Void = {}

    private enum Route: Hashable {
        case chooseExercise(ActivityMode)
        case chooseFriend(Exercise)
        case duelTime(Exercise, FriendListItem)
        case challengeSent(Exercise, FriendListItem, DuelDuration)
        case player(PlayerCard)
        case playerFriends(PlayerCard)
    }

    @State private var path: [Route] = []
    @State private var isAddFriendPresented = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack(path: $path) {
            root
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .chooseExercise(let mode):
                        ChooseExerciseView(mode: mode, onBack: { path.removeLast() }, onClose: { dismiss() }) { exercise in
                            choose(exercise, in: mode)
                        }
                    case .chooseFriend(let exercise):
                        ChooseFriendView(
                            friends: friends,
                            onBack: { path.removeLast() },
                            onClose: { dismiss() },
                            onAddFriend: { isAddFriendPresented = true },
                            onSelect: { path.append(.duelTime(exercise, $0)) }
                        )
                    case .duelTime(let exercise, let friend):
                        DuelTimeView(
                            onBack: { path.removeLast() },
                            onClose: { dismiss() },
                            onSend: { path.append(.challengeSent(exercise, friend, $0)) }
                        )
                    case .challengeSent(let exercise, let friend, let duration):
                        DuelWaitingView(friend: friend.profile, onCancel: { dismiss() }, onAccepted: {
                            onDuelAccepted(DuelLobby(me: me, opponent: friend.profile, exercise: exercise, duration: duration, myStats: myStats))
                            dismiss()
                        })
                    case .player(let card):
                        PlayerCardView(
                            card: card,
                            service: friendsService,
                            onSeeAllFriends: { path.append(.playerFriends(card)) },
                            onRelationshipChanged: onFriendsChanged
                        )
                    case .playerFriends(let card):
                        PlayerFriendsListView(
                            player: card.profile,
                            service: friendsService,
                            onOpenFriend: { item in
                                Task {
                                    let card = (try? await friendsService.findPlayer(nickname: item.profile.nickname)) ?? .mock(for: item)
                                    path.append(.player(card))
                                }
                            }
                        )
                    }
                }
        }
        .sheet(isPresented: $isAddFriendPresented) {
            AddFriendSheet(service: friendsService, myNickname: me.nickname) { card in
                isAddFriendPresented = false
                path.append(.player(card))
            }
        }
    }

    /// Training goes to its setup; a duel first needs a friend.
    private func choose(_ exercise: Exercise, in mode: ActivityMode) {
        switch mode {
        case .training:
            onTrainingStart(exercise)
            dismiss()
        case .duel: path.append(.chooseFriend(exercise))
        }
    }

    @ViewBuilder
    private var root: some View {
        switch start {
        case .chooseActivity:
            ChooseActivityView(onClose: { dismiss() }) { mode in
                path.append(.chooseExercise(mode))
            }
        case .chooseExercise(let mode):
            ChooseExerciseView(mode: mode, onBack: nil, onClose: { dismiss() }) { exercise in
                choose(exercise, in: mode)
            }
        }
    }
}

// MARK: - Shared layout

/// FIGMA: ‹ (optional) and ✕ glass buttons, a centered 34 bold title and a gray subtitle, then
/// two large blue cards.
struct ActivityChoiceLayout<Cards: View>: View {
    let title: String
    let subtitle: String
    let onBack: (() -> Void)?
    let onClose: () -> Void
    @ViewBuilder let cards: Cards

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    if let onBack { RCBackButton(action: onBack) }
                    Spacer()
                    ActivityCloseButton(action: onClose)
                }
                .padding(.horizontal, RCSpacing.m)
                .padding(.top, RCSpacing.m)

                Text(title)
                    .font(RCFont.homeTitle)
                    .foregroundStyle(RCColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, RCSpacing.l)

                Text(subtitle)
                    .font(.system(size: 17))
                    .tracking(-0.4)
                    .foregroundStyle(RCColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, RCSpacing.xs)
                    .padding(.horizontal, RCSpacing.m)

                VStack(spacing: RCSpacing.m) { cards }
                    .padding(.horizontal, RCSpacing.l)
                    .padding(.top, 36)
                    .padding(.bottom, RCSpacing.l)
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(RCColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// ✕ in the same glass circle as `RCBackButton`.
struct ActivityCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(RCColor.textPrimary)
                .frame(width: RCSize.backButton, height: RCSize.backButton)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .rcGlass(in: Circle(), interactive: true)
        .accessibilityLabel("Close")
    }
}

/// FIGMA: 345 × 270 pt blue gradient card, icon circle (139 pt) top-right, 34 bold white title
/// and a light-blue description bottom-left.
struct ActivityChoiceCard: View {
    let title: String
    let description: String
    let iconImageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(LinearGradient(
                        stops: [
                            .init(color: RCColor.activityCardTop, location: 0),
                            .init(color: RCColor.activityCardMiddle, location: 0.35),
                            .init(color: RCColor.goalCardBottom, location: 0.7),
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottom
                    ))

                // Figma export as is (no extra rim): its circle fills ~89% of the transparent
                // image, so the image is drawn at 156 pt to give a 139 pt circle.
                Image(iconImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 156, height: 156)
                    .frame(width: 139, height: 139)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 22)
                    .padding(.trailing, 20)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: RCSpacing.xs) {
                    Text(title)
                        .font(RCFont.homeTitle)
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RCColor.activityCardText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                .padding(.horizontal, RCSpacing.l)
                .padding(.bottom, 26)
            }
            .frame(maxWidth: .infinity, minHeight: 230, idealHeight: 270, maxHeight: 270)
        }
        .buttonStyle(ActivityCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityAddTraits(.isButton)
    }
}

private struct ActivityCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview("From VS") {
    ActivityFlowView(start: .chooseActivity, me: MockData.me, friends: MockData.profileFilled.friends)
}

#Preview("Training") {
    ActivityFlowView(start: .chooseExercise(.training), me: MockData.me, friends: [])
}
