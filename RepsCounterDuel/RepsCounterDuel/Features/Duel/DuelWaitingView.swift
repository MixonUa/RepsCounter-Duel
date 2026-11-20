import SwiftUI
import OSLog
import Backend
import DesignSystem

/// FIGMA "Waiting..." (host, after Send Challenge): hourglass, "<friend> must accept the
/// challenge in 3:00 minutes" with a live countdown to the server's expiry, Cancel Challenge, ✕.
/// Polls the server duel every 2 s: accepted → the lobby opens.
/// PROVISIONAL (no Figma frames): ✕ also withdraws the invitation; "Time's up" after expiry and
/// "<friend> declined" after a refusal, both with Close.
struct DuelWaitingView: View {
    let duel: DuelSnapshot
    let service: any DuelServicing
    let onCancel: () -> Void
    /// The friend accepted the challenge (opens the lobby).
    let onAccepted: (DuelSnapshot) -> Void

    private enum Outcome { case expired, declined }

    @State private var outcome: Outcome?

    private var friend: PlayerProfile { duel.opponent }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                ActivityCloseButton(action: cancel)
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.m)

            Spacer(minLength: RCSpacing.l)

            Image("DuelWaiting")
                .resizable()
                .scaledToFit()
                .frame(width: 242)
                .opacity(outcome == nil ? 1 : 0.5)
                .accessibilityHidden(true)

            Text(title)
                .font(RCFont.homeTitle)
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, RCSpacing.xxl + RCSpacing.xs)

            subtitle
                .font(.system(size: 17))
                .tracking(-0.4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RCSpacing.m)
                .padding(.top, RCSpacing.xs)

            Spacer(minLength: RCSpacing.l)

            if outcome != nil {
                Button("Close", action: onCancel)
                    .buttonStyle(.rcPrimaryLarge)
                    .padding(.horizontal, RCSpacing.l)
                    .padding(.bottom, RCSpacing.xxs)
            } else {
                Button("Cancel Challenge", action: cancel)
                    .buttonStyle(.rcDestructiveLarge)
                    .padding(.horizontal, RCSpacing.l)
                    .padding(.bottom, RCSpacing.xxs)
            }
        }
        .background(RCColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .interactiveDismissDisabled(outcome == nil)
        .task { await watch() }
    }

    private var title: String {
        switch outcome {
        case .none: "Waiting..."
        case .expired: "Time's up"
        case .declined: "Declined"
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        switch outcome {
        case .expired:
            (Text(friend.nickname).foregroundStyle(RCColor.accent)
             + Text(" didn't accept the challenge").foregroundStyle(RCColor.textSecondary))
        case .declined:
            (Text(friend.nickname).foregroundStyle(RCColor.accent)
             + Text(" declined the challenge").foregroundStyle(RCColor.textSecondary))
        case .none:
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let left = max(0, Int(duel.expiresAt.timeIntervalSince(context.date).rounded(.up)))
                (Text(friend.nickname).foregroundStyle(RCColor.accent)
                 + Text("  must accept the challenge in ").foregroundStyle(RCColor.textSecondary)
                 + Text(String(format: "%d:%02d", left / 60, left % 60)).foregroundStyle(RCColor.accent).monospacedDigit()
                 + Text(" minutes").foregroundStyle(RCColor.textSecondary))
                    .accessibilityLabel("\(friend.nickname) must accept the challenge in \(left / 60) minutes \(left % 60) seconds")
            }
        }
    }

    /// Polls the server until the friend answers or the invitation expires.
    private func watch() async {
        while !Task.isCancelled, outcome == nil {
            do {
                if let current = try await service.view(duel.id) {
                    switch current.phase {
                    case .lobby, .countdown, .live:
                        onAccepted(current)
                        return
                    case .expired:
                        withAnimation(.snappy) { outcome = .expired }
                    case .declined, .cancelled:
                        withAnimation(.snappy) { outcome = .declined }
                    default:
                        break
                    }
                }
            } catch {
                AppLog.backend.error("Duel status failed: \(String(describing: error), privacy: .public)")
                if Date.now >= duel.expiresAt { withAnimation(.snappy) { outcome = .expired } }
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }

    private func cancel() {
        let id = duel.id
        Task { _ = try? await service.leave(id) }
        onCancel()
    }
}
