import SwiftUI
import Backend

/// Incoming duel invitations for the whole tab area — same pattern as `FriendRequestCenter`:
/// a new invitation opens the modal; closing it (✕ or swipe) leaves a banner pinned on top of
/// every tab until the friend answers or the invitation expires.
/// UI stage: invitations are local (DEBUG `-debugIncomingDuel YES`); stage 4 fills them from
/// `duel_invitations` + realtime/push and sends accept/decline to the server.
@Observable
final class DuelInvitationCenter {
    private(set) var invitations: [DuelInvitation] = []
    /// The invitation shown in the modal sheet.
    var modalInvitation: DuelInvitation?
    /// Accepted invitation: opens the next duel screen (lobby).
    var acceptedInvitation: DuelInvitation?
    /// Accepted from the modal: shown once the modal has finished closing.
    private var acceptedAfterModal: DuelInvitation?

    /// Shown when an invitation is pending and its modal was closed.
    var bannerInvitation: DuelInvitation? {
        modalInvitation == nil ? invitations.first : nil
    }

    func receive(_ invitation: DuelInvitation) {
        guard !invitations.contains(where: { $0.id == invitation.id }), !invitation.isExpired(at: .now) else { return }
        invitations.append(invitation)
        if modalInvitation == nil { modalInvitation = invitation }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, invitation.expiresAt.timeIntervalSinceNow)))
            self?.expire(invitation)
        }
    }

    func accept(_ invitation: DuelInvitation) {
        guard remove(invitation) else { return }
        if modalInvitation?.id == invitation.id {
            acceptedAfterModal = invitation
            modalInvitation = nil
        } else {
            acceptedInvitation = invitation
        }
    }

    func refuse(_ invitation: DuelInvitation) {
        remove(invitation)
        if modalInvitation?.id == invitation.id { modalInvitation = nil }
    }

    func modalDidDismiss() {
        guard let invitation = acceptedAfterModal else { return }
        acceptedAfterModal = nil
        acceptedInvitation = invitation
    }

    /// PROVISIONAL: an expired invitation silently disappears (no Figma frame).
    private func expire(_ invitation: DuelInvitation) {
        refuse(invitation)
    }

    @discardableResult
    private func remove(_ invitation: DuelInvitation) -> Bool {
        guard invitations.contains(where: { $0.id == invitation.id }) else { return false }
        withAnimation(.snappy) { invitations.removeAll { $0.id == invitation.id } }
        return true
    }
}
