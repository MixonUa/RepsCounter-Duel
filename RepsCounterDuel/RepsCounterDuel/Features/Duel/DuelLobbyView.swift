import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA "Ready to duel?" (full screen, dark blue backdrop from Figma): both avatars with VS,
/// HEAD TO HEAD (exercise PR, duels won, win rate), I'm Ready and the opponent's ready status.
/// - ‹ leaves the lobby: before the countdown that cancels the match without rating impact (§6).
/// - The countdown starts only when both players are ready (`onBothReady`).
/// PROVISIONAL (no Figma variants): "Waiting for <name>…" status, the button after I'm ready.
/// UI stage: the opponent becomes ready after a short delay; stage 4 uses server readiness.
struct DuelLobbyView: View {
    let lobby: DuelLobby
    let onLeave: () -> Void
    let onBothReady: () -> Void
    /// Mock opponent readiness delay.
    var opponentReadyDelay: Duration = .seconds(3)

    @State private var isMeReady = false
    @State private var isOpponentReady = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                LobbyBackButton(action: onLeave)
                Spacer()
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.xs)

            Text("Ready to duel?")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, RCSpacing.s)
            (Text(lobby.exercise.displayName).fontWeight(.semibold) + Text(" competition"))
                .font(.system(size: 17))
                .tracking(-0.4)
                .foregroundStyle(.white)
                .padding(.top, RCSpacing.xxs)

            Spacer(minLength: RCSpacing.l)

            players

            Spacer(minLength: RCSpacing.l)

            headToHead
                .padding(.horizontal, RCSpacing.m)

            Spacer(minLength: RCSpacing.l)

            readyButton
                .padding(.horizontal, RCSpacing.l)
            status
                .padding(.top, RCSpacing.m)
                .padding(.bottom, RCSpacing.xs)
        }
        .background {
            Image("DuelLobbyBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
        .environment(\.colorScheme, .dark)
        .animation(.snappy, value: isMeReady)
        .animation(.snappy, value: isOpponentReady)
        .task {
            try? await Task.sleep(for: opponentReadyDelay)
            isOpponentReady = true
        }
        .onChange(of: isMeReady && isOpponentReady) { _, bothReady in
            if bothReady { onBothReady() }
        }
        .sensoryFeedback(.success, trigger: isOpponentReady)
    }

    // MARK: - Players

    private var players: some View {
        HStack(alignment: .top, spacing: 0) {
            LobbyPlayer(player: lobby.me)
            Spacer(minLength: 0)
            // Drawn as text with a gradient and glow (no Figma export yet).
            Text("VS")
                .font(.system(size: 76, weight: .black).italic())
                .foregroundStyle(LinearGradient(colors: [.white, RCColor.lobbyVS], startPoint: .top, endPoint: .bottom))
                .shadow(color: RCColor.accent.opacity(0.8), radius: 16)
                .padding(.top, 38)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            LobbyPlayer(player: lobby.opponent)
        }
        .padding(.horizontal, RCSpacing.m)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(lobby.me.nickname) versus \(lobby.opponent.nickname)")
    }

    // MARK: - Head to head

    /// FIGMA: dark translucent card with a thin border. In each row the bigger value is fully
    /// opaque and the smaller one at 50%, whichever side it is on; equal values are both opaque.
    private var headToHead: some View {
        VStack(spacing: RCSpacing.m) {
            HStack {
                Text(lobby.me.nickname)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("HEAD TO HEAD")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(RCColor.accent)
                    .fixedSize()
                Text(lobby.opponent.nickname)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.white)

            let myRecord = lobby.myStats.trainingRecord(for: lobby.exercise)
            let theirRecord = lobby.opponentStats.trainingRecord(for: lobby.exercise)
            statRow(
                label: "\(lobby.exercise == .pushUps ? "Push-up" : "Squat") PR",
                mine: ("\(myRecord)", Double(myRecord)),
                theirs: ("\(theirRecord)", Double(theirRecord))
            )
            statRow(
                label: "Duels Won",
                mine: ("\(lobby.myStats.duelsWon)", Double(lobby.myStats.duelsWon)),
                theirs: ("\(lobby.opponentStats.duelsWon)", Double(lobby.opponentStats.duelsWon))
            )
            statRow(
                label: "Win Rate",
                mine: (Self.percent(lobby.myStats.winRate), lobby.myStats.winRate ?? 0),
                theirs: (Self.percent(lobby.opponentStats.winRate), lobby.opponentStats.winRate ?? 0)
            )
        }
        .padding(.horizontal, RCSpacing.m)
        .padding(.vertical, RCSpacing.m + 2)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(.white.opacity(0.25), lineWidth: 1))
    }

    private func statRow(label: String, mine: (text: String, value: Double), theirs: (text: String, value: Double)) -> some View {
        HStack {
            Text(mine.text)
                .foregroundStyle(.white.opacity(mine.value < theirs.value ? 0.5 : 1))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.55))
                .fixedSize()
            Text(theirs.text)
                .foregroundStyle(.white.opacity(theirs.value < mine.value ? 0.5 : 1))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 28, weight: .medium).monospacedDigit())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): you \(mine.text), \(lobby.opponent.nickname) \(theirs.text)")
    }

    private static func percent(_ value: Double?) -> String {
        value.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—"
    }

    // MARK: - Ready

    @ViewBuilder
    private var readyButton: some View {
        if isMeReady {
            Button {} label: {
                Label("You're ready", systemImage: "checkmark")
            }
            .buttonStyle(.rcPrimaryLarge)
            .disabled(true)
        } else {
            Button("I'm Ready") { isMeReady = true }
                .buttonStyle(.rcPrimaryLarge)
        }
    }

    /// FIGMA: green dot + "<name> is ready"; PROVISIONAL gray dot + "Waiting for <name>…".
    private var status: some View {
        HStack(spacing: RCSpacing.xs) {
            Circle()
                .fill(isOpponentReady ? RCColor.win : .white.opacity(0.4))
                .frame(width: 10, height: 10)
            Text(isOpponentReady ? "\(lobby.opponent.nickname) is ready" : "Waiting for \(lobby.opponent.nickname)…")
                .font(.system(size: 17))
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
    }
}

/// FIGMA: 105 pt avatar circle (accent fill, white ring, soft glow) with the nickname below.
private struct LobbyPlayer: View {
    let player: PlayerProfile

    var body: some View {
        VStack(spacing: RCSpacing.m) {
            Text(player.emoji)
                .font(.system(size: 56))
                .frame(width: 105, height: 105)
                .background(RCColor.lobbyAvatar, in: Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                .shadow(color: .white.opacity(0.35), radius: 10)
            Text(player.nickname)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: 130)
        }
    }
}

/// FIGMA: translucent white glass circle with a white chevron (on the dark backdrop).
private struct LobbyBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: RCSize.backButton, height: RCSize.backButton)
                .background(.white.opacity(0.18), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Leave the duel")
    }
}

/// Lobby → (both ready) → countdown + live duel → results.
/// Play Again returns to a fresh lobby with the same friend, exercise and time (PROVISIONAL:
/// stage 4 sends a new challenge the friend must accept).
struct DuelLobbyFlow: View {
    let lobby: DuelLobby
    @Environment(\.dismiss) private var dismiss
    @State private var isStarting = false
    @State private var result: (my: Int, opponent: Int)?
    /// New id per round so the lobby and the live duel start from scratch.
    @State private var round = 0

    var body: some View {
        Group {
            if let result {
                DuelResultView(
                    lobby: lobby,
                    myReps: result.my,
                    opponentReps: result.opponent,
                    onPlayAgain: {
                        round += 1
                        self.result = nil
                        isStarting = false
                    },
                    onExit: { dismiss() }
                )
            } else if isStarting {
                LiveDuelView(
                    lobby: lobby,
                    onFinish: { my, opponent in result = (my, opponent) },
                    onGiveUp: { dismiss() }
                )
            } else {
                DuelLobbyView(lobby: lobby, onLeave: { dismiss() }, onBothReady: { isStarting = true })
            }
        }
        .id(round)
        .transition(.opacity)
        .animation(.snappy, value: isStarting)
        .animation(.snappy, value: result == nil)
    }
}

#Preview {
    DuelLobbyView(
        lobby: DuelLobby(
            me: PlayerProfile(nickname: "Sophie", emoji: "🐧"),
            opponent: PlayerProfile(nickname: "Lena_v", emoji: "🐱"),
            exercise: .pushUps,
            duration: .default,
            myStats: PlayerStats(totalDuelReps: 300, duelsWon: 24, duelsLost: 8, duelsTied: 0, trainingRecords: [.pushUps: 55])
        ),
        onLeave: {},
        onBothReady: {}
    )
}
