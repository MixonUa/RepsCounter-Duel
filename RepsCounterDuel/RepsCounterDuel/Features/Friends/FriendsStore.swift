import Foundation
import SwiftUI
import Observation
import OSLog
import Backend

/// My friends list for the whole tab area (Profile, Friends, Choose a Friend), loaded from the
/// server and refreshed after every change I make (request sent / answered).
@Observable
final class FriendsStore {
    private(set) var friends: [FriendListItem] = []
    private(set) var isLoaded = false

    @ObservationIgnored let service: any FriendsServicing

    init(service: any FriendsServicing = AppServices.friendsService) {
        self.service = service
    }

    var acceptedFriends: [FriendListItem] { friends.filter { $0.status == .friend } }

    /// Long-press "Remove from Friends" on my list.
    func remove(_ item: FriendListItem) async {
        withAnimation(.snappy) { friends.removeAll { $0.id == item.id } }
        do { try await service.removeFriend(item.profile) } catch {
            AppLog.backend.error("Removing a friend failed: \(String(describing: error), privacy: .public)")
        }
        await refresh()
    }

    /// Long-press "Cancel Request" on my list.
    func cancelRequest(_ item: FriendListItem) async {
        withAnimation(.snappy) { friends.removeAll { $0.id == item.id } }
        do { try await service.cancelFriendRequest(to: item.profile) } catch {
            AppLog.backend.error("Cancelling a friend request failed: \(String(describing: error), privacy: .public)")
        }
        await refresh()
    }

    func refresh() async {
        do {
            friends = try await service.fetchFriends()
            isLoaded = true
        } catch {
            AppLog.backend.error("Loading friends failed: \(String(describing: error), privacy: .public)")
        }
    }
}

/// Another player's full friends list (player card → see all), loaded on open.
struct PlayerFriendsListView: View {
    let player: PlayerProfile
    let service: any FriendsServicing
    let onOpenFriend: (FriendListItem) -> Void

    @State private var friends: [FriendListItem]?
    @State private var didFail = false

    var body: some View {
        FriendsListView(
            title: "\(player.nickname)'s Friends",
            friends: friends ?? [],
            onOpenFriend: onOpenFriend,
            onAddFriend: nil
        )
        .overlay {
            if friends == nil && !didFail {
                ProgressView()
            } else if didFail {
                // PROVISIONAL: no Figma frame for this error.
                Text("Couldn't load friends.\nCheck your internet connection.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .task {
            do {
                friends = try await service.fetchFriends(of: player)
            } catch {
                AppLog.backend.error("Loading player friends failed: \(String(describing: error), privacy: .public)")
                didFail = true
            }
        }
    }
}
