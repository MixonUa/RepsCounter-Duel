import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA "Ready to duel?" (full screen, dark blue backdrop from Figma): both avatars with VS,
/// HEAD TO HEAD (exercise PR, duels won, win rate), I'm Ready and the opponent's ready status.
/// - ‹ leaves the lobby: before the countdown that cancels the match without rating impact (§6).
/// - The countdown starts only when both players are ready (`onBothReady`).
/// PROVISIONAL (no Figma variants): "Waiting for <name>…" status, the button after I'm ready.
/// Readiness lives on the server: I'm Ready → `set_duel_ready`; the lobby polls the duel every
/// second for the opponent's status and the server-fixed start (countdown).
/// PROVISIONAL: if the duel is cancelled meanwhile (opponent left, lobby idle 5 min) the lobby
/// shows "<name> left the duel" with Close.
struct DuelLobbyView: View {
    let lobby: DuelLobby
    let service: any DuelServicing
    let onLeave: () -> Void
    /// Both are ready: the server snapshot carries `startsAt` / `endsAt`.
    let onBothReady: (DuelSnapshot) -> Void

    @State private var isMeReady = false
    @State private var isOpponentReady = false
    @State private var isSendingReady = false
    @State private var isCancelled = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                LobbyBackButton(action: leave)
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
        .task { await watch() }
        .sensoryFeedback(.success, trigger: isOpponentReady)
        .alert("Duel cancelled", isPresented: $isCancelled) {
            Button("Close", action: onLeave)
        } message: {
            Text("\(lobby.opponent.nickname) left the duel.")
        }
    }

    // MARK: - Server

    private func watch() async {
        while !Task.isCancelled, !isCancelled {
            if let snapshot = try? await service.heartbeat(lobby.id) { apply(snapshot) }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func apply(_ snapshot: DuelSnapshot) {
        isMeReady = snapshot.myReady
        isOpponentReady = snapshot.opponentReady
        switch snapshot.phase {
        case .countdown, .live:
            onBothReady(snapshot)
        case .cancelled, .expired, .declined, .forfeited, .completed, .interrupted:
            isCancelled = true
        default:
            break
        }
    }

    private func setReady() {
        guard !isSendingReady else { return }
        isSendingReady = true
        isMeReady = true
        Task {
            defer { isSendingReady = false }
            do { apply(try await service.setReady(lobby.id)) } catch { isMeReady = false }
        }
    }

    private func leave() {
        let id = lobby.id
        Task { _ = try? await service.leave(id) }
        onLeave()
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
            let known = lobby.hasServerStats
            statRow(
                label: "\(lobby.exercise == .pushUps ? "Push-up" : "Squat") PR",
                mine: ("\(myRecord)", Double(myRecord)),
                theirs: (known ? "\(theirRecord)" : "—", Double(theirRecord))
            )
            statRow(
                label: "Duels Won",
                mine: (known ? "\(lobby.myStats.duelsWon)" : "—", Double(lobby.myStats.duelsWon)),
                theirs: (known ? "\(lobby.opponentStats.duelsWon)" : "—", Double(lobby.opponentStats.duelsWon))
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
            Button("I'm Ready", action: setReady)
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
struct LobbyBackButton: View {
    var systemImage = "chevron.left"
    var accessibilityLabel = "Leave the duel"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: RCSize.backButton, height: RCSize.backButton)
                .background(.white.opacity(0.18), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Lobby → (both ready) → countdown + live duel → results → Play Again (a new challenge to the
/// same friend with the same exercise and time: Waiting... → a fresh lobby once accepted).
struct DuelLobbyFlow: View {
    let lobby: DuelLobby
    /// Resuming an unfinished duel after relaunch: starts on Waiting..., the lobby or the duel.
    var resume: DuelSnapshot?
    var service: any DuelServicing = AppServices.duelService
    @Environment(\.dismiss) private var dismiss

    private enum Stage: Equatable {
        case lobby(DuelLobby)
        case live(DuelLobby, DuelSnapshot)
        case result(DuelLobby, my: Int, opponent: Int)
        case waiting(DuelSnapshot)
    }

    @State private var stage: Stage?
    @State private var playAgainError: String?
    /// Both players' real stats for the current duel (loaded once per duel, before it starts).
    @State private var headToHead: (duel: UUID, stats: DuelHeadToHead)?

    private var initialStage: Stage {
        guard let resume else { return .lobby(lobby) }
        switch resume.phase {
        case .invited: return .waiting(resume)
        case .countdown, .live, .finishing: return .live(lobby, resume)
        default: return .lobby(lobby)
        }
    }

    private var currentDuelID: UUID {
        switch stage ?? initialStage {
        case .lobby(let l), .live(let l, _), .result(let l, _, _): l.id
        case .waiting(let duel): duel.id
        }
    }

    private func enriched(_ lobby: DuelLobby) -> DuelLobby {
        guard let headToHead, headToHead.duel == lobby.id else { return lobby }
        return lobby.withServerStats(headToHead.stats)
    }

    var body: some View {
        Group {
            switch stage ?? initialStage {
            case .lobby(let current):
                DuelLobbyView(lobby: enriched(current), service: service, onLeave: { dismiss() }, onBothReady: { stage = .live(current, $0) })
            case .live(let current, let start):
                LiveDuelView(
                    lobby: enriched(current),
                    start: start,
                    service: service,
                    onFinish: { my, opponent in stage = .result(current, my: my, opponent: opponent) },
                    onGiveUp: { dismiss() }
                )
            case .result(let current, let my, let opponent):
                DuelResultView(
                    lobby: enriched(current),
                    myReps: my,
                    opponentReps: opponent,
                    onPlayAgain: { playAgain(current) },
                    onExit: { dismiss() }
                )
            case .waiting(let duel):
                DuelWaitingView(duel: duel, service: service, onCancel: { dismiss() }, onAccepted: { accepted in
                    stage = .lobby(DuelLobby(snapshot: accepted, me: lobby.me, myStats: lobby.myStats))
                })
            }
        }
        .transition(.opacity)
        .animation(.snappy, value: stage)
        .task(id: currentDuelID) { await loadHeadToHead() }
        .alert("Challenge not sent", isPresented: Binding(get: { playAgainError != nil }, set: { if !$0 { playAgainError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(playAgainError ?? "")
        }
    }

    private func loadHeadToHead() async {
        guard case .lobby(let current) = stage ?? initialStage, headToHead?.duel != current.id else { return }
        if let stats = try? await service.headToHead(current.id, exercise: current.exercise) {
            headToHead = (current.id, stats)
        }
    }

    private func playAgain(_ previous: DuelLobby) {
        Task {
            do {
                stage = .waiting(try await service.create(friend: previous.opponent, exercise: previous.exercise, duration: previous.duration))
            } catch {
                // PROVISIONAL copy: the friend may have challenged me already (busy).
                playAgainError = (error as? DuelServiceError) == .busy
                    ? "\(previous.opponent.nickname) is already in a duel — maybe they challenged you. Check your invitations."
                    : "Couldn't send the challenge. Check your internet connection and try again."
            }
        }
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
        service: MockDuelService(),
        onLeave: {},
        onBothReady: { _ in }
    )
}
