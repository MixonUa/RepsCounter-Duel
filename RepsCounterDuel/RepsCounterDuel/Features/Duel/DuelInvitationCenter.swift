import SwiftUI
import OSLog
import Backend

/// Incoming duel invitations for the whole tab area — same pattern as `FriendRequestCenter`:
/// a new invitation opens the modal; closing it (✕ or swipe) leaves a banner pinned on top of
/// every tab until I answer or the invitation expires.
/// Invitations come from the server (`incoming_duel_invitations`), fetched when the app becomes
/// active and every `pollInterval` while it stays active (PROVISIONAL: polling, realtime / push
/// later). Start Duel ! / Refuse go to the server; an accepted duel opens the lobby.
@Observable
final class DuelInvitationCenter {
    private(set) var invitations: [DuelInvitation] = []
    /// The invitation shown in the modal sheet.
    var modalInvitation: DuelInvitation?
    /// Accepted duel (server snapshot): the root opens the lobby.
    var acceptedDuel: DuelSnapshot?
    private(set) var respondingTo: UUID?
    var errorMessage: String?

    @ObservationIgnored private let service: any DuelServicing
    @ObservationIgnored private var shownInvitations: Set<UUID> = []
    /// Accepted from the modal: handed over once the modal has finished closing.
    @ObservationIgnored private var acceptedAfterModal: DuelSnapshot?
    static let pollInterval: Duration = .seconds(5)

    init(service: any DuelServicing = AppServices.duelService) {
        self.service = service
    }

    /// Shown when an invitation is pending and its modal was closed.
    var bannerInvitation: DuelInvitation? {
        modalInvitation == nil ? invitations.first : nil
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
            let incoming = try await service.incomingInvitations().map(\.invitation)
            apply(incoming.filter { !$0.isExpired(at: .now) })
        } catch {
            AppLog.backend.error("Loading duel invitations failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func apply(_ incoming: [DuelInvitation]) {
        withAnimation(.snappy) {
            invitations = incoming
            if let modal = modalInvitation, !incoming.contains(where: { $0.id == modal.id }) { modalInvitation = nil }
            if modalInvitation == nil, let new = incoming.first(where: { !shownInvitations.contains($0.id) }) {
                modalInvitation = new
            }
        }
        shownInvitations.formUnion(incoming.map(\.id))
        // Expired invitations disappear on their own (PROVISIONAL: no Figma frame).
        for invitation in incoming {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(max(0, invitation.expiresAt.timeIntervalSinceNow)))
                self?.remove(invitation.id)
            }
        }
    }

    func accept(_ invitation: DuelInvitation) { respond(invitation, accept: true) }
    func refuse(_ invitation: DuelInvitation) { respond(invitation, accept: false) }

    private func respond(_ invitation: DuelInvitation, accept: Bool) {
        guard respondingTo == nil else { return }
        respondingTo = invitation.id
        Task {
            defer { respondingTo = nil }
            do {
                let snapshot = try await service.respond(to: invitation.id, accept: accept)
                let wasModal = modalInvitation?.id == invitation.id
                remove(invitation.id)
                guard accept else { return }
                if wasModal { acceptedAfterModal = snapshot } else { acceptedDuel = snapshot }
            } catch {
                AppLog.backend.error("Answering a duel failed: \(String(describing: error), privacy: .public)")
                if (error as? DuelServiceError) == .noLongerAvailable {
                    remove(invitation.id)
                    errorMessage = "This challenge is no longer available."
                } else if (error as? DuelServiceError) == .busy {
                    errorMessage = "Finish your current duel first."
                } else {
                    errorMessage = "Couldn't answer the challenge. Check your internet connection and try again."
                }
            }
        }
    }

    func modalDidDismiss() {
        guard let snapshot = acceptedAfterModal else { return }
        acceptedAfterModal = nil
        acceptedDuel = snapshot
    }

    private func remove(_ id: UUID) {
        withAnimation(.snappy) {
            invitations.removeAll { $0.id == id }
            if modalInvitation?.id == id { modalInvitation = nil }
        }
    }
}
