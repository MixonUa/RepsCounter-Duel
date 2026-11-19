import SwiftUI
import Backend
import DesignSystem

/// FIGMA "Waiting..." (host, after Send Challenge): hourglass, "<friend> must accept the
/// challenge in 3:00 minutes" with a live countdown, Cancel Challenge, ✕ only (no back).
/// - ✕ and Cancel Challenge both withdraw the invitation and close the flow (PROVISIONAL:
///   there is no screen to return to a pending invitation).
/// - When the countdown ends the invitation expires: PROVISIONAL "Time's up" state (no Figma frame).
/// UI stage: nobody accepts the mock invitation, except DEBUG `-debugAutoAccept YES` (the friend
/// accepts after 3 s); stage 4 listens to the server.
struct DuelWaitingView: View {
    let friend: PlayerProfile
    /// Invitation expiry from Figma (3:00). Configurable; the server owns the real deadline.
    var expiresIn: Duration = .seconds(180)
    let onCancel: () -> Void
    /// The friend accepted the challenge (opens the lobby).
    var onAccepted: () -> Void = {}

    @State private var deadline: Date?
    @State private var isExpired = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                ActivityCloseButton(action: onCancel)
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.m)

            Spacer(minLength: RCSpacing.l)

            Image("DuelWaiting")
                .resizable()
                .scaledToFit()
                .frame(width: 242)
                .opacity(isExpired ? 0.5 : 1)
                .accessibilityHidden(true)

            Text(isExpired ? "Time's up" : "Waiting...")
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

            if isExpired {
                Button("Close", action: onCancel)
                    .buttonStyle(.rcPrimaryLarge)
                    .padding(.horizontal, RCSpacing.l)
                    .padding(.bottom, RCSpacing.xxs)
            } else {
                Button("Cancel Challenge", action: onCancel)
                    .buttonStyle(.rcDestructiveLarge)
                    .padding(.horizontal, RCSpacing.l)
                    .padding(.bottom, RCSpacing.xxs)
            }
        }
        .background(RCColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .interactiveDismissDisabled(!isExpired)
        .onAppear {
            if deadline == nil { deadline = .now.addingTimeInterval(TimeInterval(expiresIn.components.seconds)) }
        }
        .task(id: deadline) {
            guard let deadline else { return }
            try? await Task.sleep(for: .seconds(max(0, deadline.timeIntervalSinceNow)))
            if !Task.isCancelled { withAnimation(.snappy) { isExpired = true } }
        }
        .task {
            #if DEBUG
            guard UserDefaults.standard.bool(forKey: "debugAutoAccept") else { return }
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled, !isExpired { onAccepted() }
            #endif
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        if isExpired {
            (Text(friend.nickname).foregroundStyle(RCColor.accent)
             + Text(" didn't accept the challenge").foregroundStyle(RCColor.textSecondary))
        } else if let deadline {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let left = max(0, Int(deadline.timeIntervalSince(context.date).rounded(.up)))
                (Text(friend.nickname).foregroundStyle(RCColor.accent)
                 + Text("  must accept the challenge in ").foregroundStyle(RCColor.textSecondary)
                 + Text(String(format: "%d:%02d", left / 60, left % 60)).foregroundStyle(RCColor.accent).monospacedDigit()
                 + Text(" minutes").foregroundStyle(RCColor.textSecondary))
                    .accessibilityLabel("\(friend.nickname) must accept the challenge in \(left / 60) minutes \(left % 60) seconds")
            }
        }
    }
}

#Preview {
    NavigationStack {
        DuelWaitingView(friend: PlayerProfile(nickname: "Lena", emoji: "🐱"), onCancel: {})
    }
}
