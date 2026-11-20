import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA live duel: everything is an overlay on the full-screen front camera.
/// - Countdown 3 · 2 · 1: top bar "<Exercise> · <N> seconds / Both of you start together", a
///   round "GET READY" counter in the middle, bottom panel "GET IN FRAME".
/// - Live: top bar with both scores and the time left, the green/red score bar; bottom panel
///   "YOUR REPS", "<opponent> is on N" and Give up.
/// Server-timed (CLAUDE.md §6): the countdown runs to the server's `starts_at`, scoring is open
/// until `ends_at` (both converted to this device's clock). My reps are counted on the device
/// (Vision + `RepCounter`) and each one is sent to the server in order; the server decides which
/// count. The opponent's score comes from polling the duel every second. After the end (+ grace)
/// the duel is finalized on the server and the result uses the server's counts.
/// DEBUG: tapping the big number adds one of my reps (Simulator has no camera).
struct LiveDuelView: View {
    let lobby: DuelLobby
    /// The server snapshot with `startsAt` / `endsAt`.
    let start: DuelSnapshot
    let service: any DuelServicing
    /// Finalized by the server: accepted reps of both players.
    let onFinish: (_ myReps: Int, _ opponentReps: Int) -> Void
    /// Give up was confirmed (forfeit), or the opponent left.
    let onGiveUp: () -> Void

    @State private var phase: LiveDuelPhase = .countdown(3)
    @State private var tracker: WorkoutTracker
    @State private var opponentReps = 0
    /// Reps the server has accepted for me.
    @State private var serverReps = 0
    /// Local reps already sent (accepted or rejected).
    @State private var handledReps = 0
    @State private var isSendingReps = false
    @State private var didOpponentLeave = false

    init(
        lobby: DuelLobby,
        start: DuelSnapshot,
        service: any DuelServicing,
        onFinish: @escaping (_ myReps: Int, _ opponentReps: Int) -> Void,
        onGiveUp: @escaping () -> Void
    ) {
        self.lobby = lobby
        self.start = start
        self.service = service
        self.onFinish = onFinish
        self.onGiveUp = onGiveUp
        _tracker = State(initialValue: WorkoutTracker(exercise: lobby.exercise))
    }

    private var myReps: Int { tracker.reps }
    @State private var isGiveUpConfirmationPresented = false

    var body: some View {
        ZStack {
            CameraPreview(camera: tracker.camera, state: tracker.cameraState)
            PoseSkeletonOverlay(pose: tracker.pose, exercise: lobby.exercise)

            VStack(spacing: 0) {
                DuelScoreBar(
                    lobby: lobby,
                    phase: phase,
                    myReps: myReps,
                    opponentReps: opponentReps
                )
                Spacer()
                PoseFeedbackBadge(feedback: tracker.feedback)
                    .padding(.bottom, RCSpacing.s)
                bottomPanel
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .ignoresSafeArea()

            if case .countdown(let value) = phase {
                CountdownCircle(value: value)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .animation(.snappy, value: phase)
        .task { await run() }
        .onChange(of: tracker.reps) { Task { await sendPendingReps() } }
        .alert("Duel over", isPresented: $didOpponentLeave) {
            Button("Close", action: onGiveUp)
        } message: {
            // PROVISIONAL copy (no Figma frame): forfeit = no rating reps for anyone.
            Text("\(lobby.opponent.nickname) left the duel. No reps are added to the rating.")
        }
        .onAppear { tracker.start() }
        .onDisappear { tracker.stop() }
        .sensoryFeedback(.increase, trigger: myReps)
        .animation(.snappy, value: tracker.feedback)
        .sensoryFeedback(.impact(weight: .heavy), trigger: phase)
        .confirmationDialog("Give up the duel?", isPresented: $isGiveUpConfirmationPresented, titleVisibility: .visible) {
            Button("Give up", role: .destructive, action: giveUp)
            Button("Keep going", role: .cancel) {}
        } message: {
            // PROVISIONAL copy; CLAUDE.md §6: leaving during live = forfeit, no rating reps.
            Text("The duel ends as a forfeit and no reps are added to the rating.")
        }
    }

    // MARK: - Bottom panel

    @ViewBuilder
    private var bottomPanel: some View {
        switch phase {
        case .countdown:
            VStack(spacing: RCSpacing.xxs) {
                Text("GET IN FRAME")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RCColor.accent)
                Text(lobby.exercise.displayName)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                Text("Step back so your whole body fits")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, RCSpacing.m)
            .padding(.bottom, RCSpacing.l)
            .padding(.horizontal, RCSpacing.m)
            .frame(maxWidth: .infinity)
            .duelPanelBackground()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        case .live, .finished:
            VStack(spacing: 0) {
                Text("YOUR REPS")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RCColor.accent)
                Text("\(myReps)")
                    .font(.system(size: 96, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(myReps)))
                    .accessibilityLabel("Your reps: \(myReps)")
                    .onTapGesture { debugAddRep() }
                Text("\(lobby.opponent.nickname) is on \(opponentReps)")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.6))
                    .contentTransition(.numericText(value: Double(opponentReps)))
                Button { isGiveUpConfirmationPresented = true } label: {
                    Label("Give up", systemImage: "flag.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(RCColor.duelRed)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(RCColor.giveUpFill, in: Capsule())
                        .overlay(Capsule().strokeBorder(.black.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(phase == .finished)
                .padding(.horizontal, RCSpacing.l)
                .padding(.top, RCSpacing.l)
            }
            .padding(.top, RCSpacing.l)
            .padding(.bottom, RCSpacing.xl)
            .frame(maxWidth: .infinity)
            .duelPanelBackground()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Timeline

    private func run() async {
        guard let startsAt = start.startsAt, let endsAt = start.endsAt else { return }
        // Countdown to the server start: 3 · 2 · 1.
        while Date.now < startsAt, !Task.isCancelled {
            let left = Int(startsAt.timeIntervalSinceNow.rounded(.up))
            phase = .countdown(min(3, max(1, left)))
            try? await Task.sleep(for: .milliseconds(200))
        }
        if Task.isCancelled { return }
        phase = .live(endsAt: endsAt)
        // Only full cycles inside the server window score on the device too.
        tracker.startScoring(duration: max(0, endsAt.timeIntervalSinceNow))

        while Date.now < endsAt, !Task.isCancelled, !didOpponentLeave {
            await poll()
            try? await Task.sleep(for: .seconds(1))
        }
        if Task.isCancelled || didOpponentLeave { return }
        phase = .finished
        tracker.stopScoring()
        await sendPendingReps()
        await finalize()
    }

    /// Opponent's score (and a forfeit) from the server.
    private func poll() async {
        guard let snapshot = try? await service.view(start.id) else { return }
        opponentReps = snapshot.opponentReps
        serverReps = max(serverReps, snapshot.myReps)
        if snapshot.phase == .forfeited || snapshot.phase == .cancelled, !snapshot.forfeitedByMe {
            tracker.stopScoring()
            didOpponentLeave = true
        }
    }

    /// Sends my new local reps one by one as "accepted so far + 1"; a rep the server rejects
    /// (too fast, out of the window) is dropped, a network error is retried.
    private func sendPendingReps() async {
        guard !isSendingReps else { return }
        isSendingReps = true
        defer { isSendingReps = false }
        var failures = 0
        while handledReps < tracker.reps, failures < 5 {
            do {
                let snapshot = try await service.submitRep(start.id, sequence: serverReps + 1)
                serverReps = snapshot.myReps
                opponentReps = snapshot.opponentReps
                handledReps += 1
                failures = 0
            } catch {
                failures += 1
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    /// After the end + the server's 2 s grace, finalize (idempotent, retried) and report.
    private func finalize() async {
        guard let endsAt = start.endsAt else { return }
        let finalizeAt = endsAt.addingTimeInterval(2.5)
        if Date.now < finalizeAt { try? await Task.sleep(for: .seconds(finalizeAt.timeIntervalSinceNow)) }
        for attempt in 0..<10 {
            if let snapshot = try? await service.finish(start.id), snapshot.phase == .completed {
                onFinish(snapshot.myReps, snapshot.opponentReps)
                return
            }
            try? await Task.sleep(for: .seconds(attempt < 3 ? 1 : 3))
        }
        // PROVISIONAL: could not confirm with the server — show the last known numbers.
        onFinish(serverReps, opponentReps)
    }

    private func giveUp() {
        let id = start.id
        tracker.stopScoring()
        Task { _ = try? await service.leave(id) }
        onGiveUp()
    }

    private func debugAddRep() {
        #if DEBUG
        guard case .live = phase else { return }
        tracker.debugAddRep()
        #endif
    }
}

// MARK: - Top bar

/// FIGMA: black rounded bar over the camera: avatars, the title or the scores and time left, and
/// a bar split by the share of reps. Green = the leader (me at the start and on a tie), red = the
/// other player; badges and bar segments swap colors when the lead changes.
private struct DuelScoreBar: View {
    let lobby: DuelLobby
    let phase: LiveDuelPhase
    let myReps: Int
    let opponentReps: Int

    /// Green marks whoever leads: me at the start and on a tie, the opponent while ahead.
    private var isOpponentLeading: Bool { opponentReps > myReps }
    private var myColor: Color { isOpponentLeading ? RCColor.duelRed : RCColor.win }
    private var opponentColor: Color { isOpponentLeading ? RCColor.win : RCColor.duelRed }

    private var myShare: CGFloat {
        let total = myReps + opponentReps
        return total == 0 ? 0.5 : CGFloat(myReps) / CGFloat(total)
    }

    var body: some View {
        VStack(spacing: RCSpacing.m) {
            HStack(spacing: RCSpacing.s) {
                DuelBadge(text: "YOU", color: myColor, isOutlined: phase.isCountdown)
                if !phase.isCountdown {
                    score(myReps)
                }
                Spacer(minLength: 0)
                center
                Spacer(minLength: 0)
                if !phase.isCountdown {
                    score(opponentReps)
                }
                DuelBadge(text: lobby.opponent.initials, color: opponentColor, isOutlined: true)
            }
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    myColor.frame(width: proxy.size.width * myShare)
                    opponentColor
                }
                .clipShape(Capsule())
                .animation(.snappy, value: myShare)
                .animation(.snappy, value: isOpponentLeading)
            }
            .frame(height: 8)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, RCSpacing.m)
        .padding(.top, 48)
        .padding(.bottom, RCSpacing.l)
        .background(.black, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
    }

    @ViewBuilder
    private var center: some View {
        if let endsAt = phase.endsAt {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let left = max(0, Int(endsAt.timeIntervalSince(context.date).rounded(.up)))
                VStack(spacing: 0) {
                    Text(DuelInvitation.countdownText(seconds: left))
                        .font(.system(size: 24, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("LEFT")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(left) seconds left")
            }
        } else if phase.isFinished {
            Text("Time's up")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
        } else {
            VStack(spacing: 2) {
                Text("\(lobby.exercise.displayName) · \(lobby.duration.spokenName)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Both of you start together")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
        }
    }

    private func score(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 26, weight: .bold).monospacedDigit())
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: Double(value)))
    }
}

/// Countdown 3 · 2 · 1 → live until `endsAt` → finished.
fileprivate enum LiveDuelPhase: Equatable {
    case countdown(Int)
    case live(endsAt: Date)
    case finished

    var isCountdown: Bool { if case .countdown = self { true } else { false } }
    var isFinished: Bool { self == .finished }
    var endsAt: Date? { if case .live(let date) = self { date } else { nil } }
}

extension PlayerProfile {
    /// "Lena_v" → "LV", "Nova07" → "NO": first letters of the first two words, or two letters.
    var initials: String {
        let words = nickname.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let letters = words.count >= 2
            ? words.prefix(2).compactMap(\.first).map(String.init).joined()
            : String(nickname.filter { $0.isLetter || $0.isNumber }.prefix(2))
        return letters.uppercased()
    }
}

extension DuelDuration {
    /// "60 seconds", "2 minutes", "1 min 30 s" for the countdown title.
    var spokenName: String {
        if seconds < 60 || seconds == 60 { return "\(seconds) seconds" }
        if let minutes = wholeMinutes { return "\(minutes) minutes" }
        return displayName
    }
}

#Preview {
    let lobby = DuelLobby(
        me: PlayerProfile(nickname: "Sophie", emoji: "🐧"),
        opponent: PlayerProfile(nickname: "Lena_v", emoji: "🐱"),
        exercise: .pushUps,
        duration: .default,
        myStats: .empty
    )
    LiveDuelView(
        lobby: lobby,
        start: DuelSnapshot(
            id: lobby.id, phase: .countdown, role: .host, opponent: lobby.opponent, exercise: .pushUps,
            duration: .default, expiresAt: .now, myReady: true, opponentReady: true,
            startsAt: .now.addingTimeInterval(4), endsAt: .now.addingTimeInterval(64),
            myReps: 0, opponentReps: 0, forfeitedByMe: false
        ),
        service: MockDuelService(),
        onFinish: { _, _ in },
        onGiveUp: {}
    )
}
