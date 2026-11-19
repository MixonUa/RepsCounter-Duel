import SwiftUI
import Backend

/// Incoming friend requests for the whole tab area (CLAUDE.md §6 "Incoming friend request UI"):
/// a new request opens the modal; closing it (✕ or swipe) leaves a banner pinned on top of every
/// tab until the request is accepted or rejected. Stage 2 fills `requests` from the server
/// (pending `friend_requests` + realtime); until then nothing creates requests in the app.
@Observable
final class FriendRequestCenter {
    private(set) var requests: [PlayerProfile] = []
    /// The request shown in the modal sheet.
    var modalRequest: PlayerProfile?
    private(set) var respondingTo: PlayerProfile.ID?
    var errorMessage: String?

    private let service: any FriendsServicing

    init(service: any FriendsServicing = MockFriendsService()) {
        self.service = service
    }

    /// Shown when a request is pending and its modal was closed.
    var bannerRequest: PlayerProfile? {
        modalRequest == nil ? requests.first : nil
    }

    func receive(from player: PlayerProfile) {
        guard !requests.contains(where: { $0.nickname.lowercased() == player.nickname.lowercased() }) else { return }
        requests.append(player)
        if modalRequest == nil { modalRequest = player }
    }

    func respond(to player: PlayerProfile, accept: Bool) {
        guard respondingTo == nil else { return }
        respondingTo = player.id
        Task {
            defer { respondingTo = nil }
            do {
                try await service.respondToFriendRequest(from: player, accept: accept)
                withAnimation(.snappy) {
                    requests.removeAll { $0.id == player.id }
                    if modalRequest?.id == player.id { modalRequest = nil }
                }
            } catch {
                // PROVISIONAL copy: no Figma frame for this error.
                errorMessage = "Couldn't answer the request. Check your internet connection and try again."
            }
        }
    }
}
