import SwiftUI
import OSLog
import Backend

/// Incoming friend requests for the whole tab area (CLAUDE.md §6 "Incoming friend request UI"):
/// a new request opens the modal; closing it (✕ or swipe) leaves a banner pinned on top of every
/// tab until the request is accepted or rejected.
/// Requests come from the server (`incoming_friend_requests`), fetched when the app becomes active
/// and every `pollInterval` while it stays active. PROVISIONAL: polling instead of realtime (the
/// server hides account IDs, realtime arrives with duel invitations in stage 4).
@Observable
final class FriendRequestCenter {
    private(set) var requests: [PlayerProfile] = []
    /// The request shown in the modal sheet.
    var modalRequest: PlayerProfile?
    private(set) var respondingTo: PlayerProfile.ID?
    var errorMessage: String?
    /// Called after I accepted a request (my friends list changed).
    @ObservationIgnored var onFriendsChanged: () -> Void = {}

    @ObservationIgnored private let service: any FriendsServicing
    /// Requests already shown as a modal (a closed modal is not reopened, the banner stays).
    @ObservationIgnored private var shownRequests: Set<PlayerProfile.ID> = []
    static let pollInterval: Duration = .seconds(20)

    init(service: any FriendsServicing = AppServices.friendsService) {
        self.service = service
    }

    /// Shown when a request is pending and its modal was closed.
    var bannerRequest: PlayerProfile? {
        modalRequest == nil ? requests.first : nil
    }

    /// Fetches now and then every `pollInterval` until the task is cancelled (app inactive).
    func keepUpdated() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: Self.pollInterval)
        }
    }

    func refresh() async {
        guard respondingTo == nil else { return }
        do {
            apply(try await service.fetchIncomingRequests())
        } catch {
            AppLog.backend.error("Loading friend requests failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func apply(_ incoming: [PlayerProfile]) {
        withAnimation(.snappy) {
            requests = incoming
            if let modal = modalRequest, !incoming.contains(modal) { modalRequest = nil }
            if modalRequest == nil, let new = incoming.first(where: { !shownRequests.contains($0.id) }) {
                modalRequest = new
            }
        }
        shownRequests.formUnion(incoming.map(\.id))
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
                if accept { onFriendsChanged() }
            } catch {
                AppLog.backend.error("Answering a friend request failed: \(String(describing: error), privacy: .public)")
                // PROVISIONAL copy: no Figma frame for this error.
                errorMessage = "Couldn't answer the request. Check your internet connection and try again."
            }
        }
    }
}
