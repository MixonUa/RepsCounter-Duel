import SwiftUI
import Backend
import DesignSystem

/// FIGMA Profile: blue header with the emoji avatar, Edit and Settings buttons, nickname with a
/// copy button and the weekly place ("Top 11"); stats card (Duels Won, Win Rate, Total Reps);
/// Top Friends of the week with "see all" → Friends. Data is mock until stages 2 and 5.
struct ProfileView: View {
    let me: PlayerProfile
    let overview: ProfileOverview

    /// Pushed screens inside the Profile tab.
    private enum Route: Hashable {
        case friends
        case player(PlayerCard)
        case playerFriends(PlayerCard)
    }

    private enum Screen: String, Identifiable {
        case edit, settings
        var id: String { rawValue }
    }

    var friendsService: any FriendsServicing = MockFriendsService()

    @State private var screen: Screen?
    @State private var path: [Route] = []
    @State private var isAddFriendPresented = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    statsCard
                        .padding(.top, RCSpacing.xl)
                    topFriends
                        .padding(.top, RCSpacing.xxl + RCSpacing.xs)
                }
                .padding(.horizontal, RCSpacing.m)
                .padding(.bottom, RCSpacing.l)
            }
            .scrollIndicators(.hidden)
            .background(alignment: .top) { headerBackground }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .friends:
                    FriendsListView(
                        friends: overview.friends,
                        onOpenFriend: { path.append(.player(Self.card(for: $0))) },
                        onAddFriend: { isAddFriendPresented = true }
                    )
                case .player(let card):
                    PlayerCardView(
                        card: card,
                        service: friendsService,
                        onSeeAllFriends: { path.append(.playerFriends(card)) }
                    )
                case .playerFriends(let card):
                    FriendsListView(
                        title: "\(card.profile.nickname)'s Friends",
                        friends: card.allFriends,
                        onOpenFriend: { path.append(.player(Self.card(for: $0))) },
                        onAddFriend: nil
                    )
                }
            }
            .sheet(isPresented: $isAddFriendPresented) {
                AddFriendSheet(service: friendsService, myNickname: me.nickname) { card in
                    isAddFriendPresented = false
                    path.append(.player(card))
                }
            }
            .fullScreenCover(item: $screen) { screen in
                switch screen {
                case .edit: EditProfileView()
                case .settings: SettingsView()
                }
            }
        }
    }

    // MARK: - Header

    /// FIGMA: #278BFB at the top, deepest blue at ~175 pt, fading into the gray background at ~390 pt.
    private var headerBackground: some View {
        ProfileHeaderBackground()
    }

    private var header: some View {
        PlayerHeader(profile: me, weeklyRank: overview.weeklyRank) {
            EmptyView()
        } trailing: {
            HeaderGlassButton(systemImage: "square.and.pencil", label: "Edit profile") { screen = .edit }
            HeaderGlassButton(systemImage: "gearshape", label: "Settings") { screen = .settings }
        }
    }

    /// Card for a friend row: the mock search data when known, otherwise a minimal card.
    private static func card(for item: FriendListItem) -> PlayerCard {
        MockData.searchablePlayers.first { $0.profile.nickname.lowercased() == item.profile.nickname.lowercased() }
            ?? PlayerCard(profile: item.profile, stats: .empty, weeklyRank: item.weeklyRank, friends: [], relationship: .friends)
    }

    // MARK: - Stats

    private var statsCard: some View {
        RecordsCard(items: [
            .init(systemImage: "bolt.fill", value: "\(overview.stats.duelsWon)", label: "Duels Won", weeklyChange: nil),
            .init(
                systemImage: "flame.fill",
                value: overview.stats.winRate.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—",
                label: "Win Rate",
                weeklyChange: nil
            ),
            .init(systemImage: "dumbbell.fill", value: "\(overview.stats.totalDuelReps)", label: "Total Reps", weeklyChange: nil),
        ])
    }

    // MARK: - Top Friends

    private var topFriends: some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("Top Friends")
                    .font(RCFont.homeHeading)
                    .tracking(-0.8)
                    .foregroundStyle(RCColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !overview.friends.isEmpty {
                    Button("see all") { path.append(.friends) }
                        .font(.system(size: 17))
                        .foregroundStyle(RCColor.accent)
                }
            }

            if overview.topFriends.isEmpty {
                noFriendsCard
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(overview.topFriends.enumerated()), id: \.element.id) { index, friend in
                        TopFriendRow(place: index + 1, friend: friend)
                    }
                }
                .padding(.vertical, RCSpacing.m - 1)
                .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
            }
        }
    }

    /// PROVISIONAL: no Figma frame for a player without friends yet.
    private var noFriendsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("No friends yet")
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.6)
            Text("Add friends to see their weekly results")
                .font(.system(size: 13))
                .foregroundStyle(RCColor.textSecondary)
                .padding(.top, RCSpacing.xxs)
            Button("Add Friend") { isAddFriendPresented = true }
                .buttonStyle(.rcPrimary)
                .padding(.top, RCSpacing.s + 1)
        }
        .padding(RCSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
    }
}

/// FIGMA Top Friends row (64 pt): gray italic place, emoji avatar, nickname + win rate,
/// joint reps on the right; a divider under the text part.
private struct TopFriendRow: View {
    let place: Int
    let friend: TopFriend

    var body: some View {
        HStack(spacing: 0) {
            Text("\(place)")
                .font(.system(size: 24, weight: .heavy).italic())
                .foregroundStyle(RCColor.rankNumber)
                .frame(width: 36)
            Text(friend.profile.emoji)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(RCColor.friendAvatarFill, in: Circle())
                .padding(.leading, RCSpacing.xxs)
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(friend.profile.nickname)
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.4)
                        .lineLimit(1)
                    Text("\(friend.winRate.formatted(.percent.precision(.fractionLength(0)))) win rate")
                        .font(.system(size: 14))
                        .foregroundStyle(RCColor.textSecondary)
                }
                Spacer(minLength: RCSpacing.xs)
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(friend.jointReps)")
                        .font(.system(size: 17, weight: .semibold))
                        .monospacedDigit()
                    Text("joint reps")
                        .font(.system(size: 14))
                        .foregroundStyle(RCColor.textSecondary)
                }
                .padding(.trailing, RCSpacing.l - 1)
            }
            .frame(maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                Rectangle().fill(RCColor.cardDivider.opacity(0.6)).frame(height: 1)
            }
            .padding(.leading, RCSpacing.s)
        }
        .padding(.leading, RCSpacing.xs)
        .frame(height: 64)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Place \(place), \(friend.profile.nickname), \(friend.jointReps) joint reps")
    }
}

#Preview("Filled") {
    ProfileView(me: PlayerProfile(nickname: "Nova_07", emoji: "🐧"), overview: MockData.profileFilled)
}

#Preview("Empty") {
    ProfileView(me: PlayerProfile(nickname: "Nova_07", emoji: "🐧"), overview: MockData.profileEmpty)
}
