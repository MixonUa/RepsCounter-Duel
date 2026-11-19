import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA duel results — three variants on a black base with the Figma backdrop on top
/// (green win, red loss, blue draw):
/// "You Won!" / "You Lost" / "Draw", "<Exercise> competition", both avatars with the score
/// between them (the winner gets the crown, the loser is dimmed), PR under each name, a chip
/// ("Won by N reps" / "N Reps were not enough" / "Equal result"), Total Reps and Win Rate with
/// the change, Play Again and Exit.
/// UI stage: the result is computed on the device; stage 5 shows it only after the server
/// finalizes the duel (CLAUDE.md §6) and adds "under review" / interrupted states.
struct DuelResultView: View {
    let lobby: DuelLobby
    let myReps: Int
    let opponentReps: Int
    let onPlayAgain: () -> Void
    let onExit: () -> Void

    private var outcome: DuelSummary.Outcome {
        myReps > opponentReps ? .win : myReps < opponentReps ? .loss : .draw
    }

    private var statsAfter: PlayerStats { lobby.myStats.applying(outcome, reps: myReps) }

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 72)
            (Text(lobby.exercise.displayName).fontWeight(.semibold) + Text(" competition"))
                .font(.system(size: 17))
                .tracking(-0.4)
                .foregroundStyle(.white)
                .padding(.top, RCSpacing.xxs)

            Spacer(minLength: RCSpacing.l)

            players

            Spacer(minLength: RCSpacing.l)

            chip

            Spacer(minLength: RCSpacing.l)

            statsCard
                .padding(.horizontal, RCSpacing.m)

            Spacer(minLength: RCSpacing.l)

            Button("Play Again", action: onPlayAgain)
                .buttonStyle(.rcPrimaryLarge)
                .padding(.horizontal, RCSpacing.l)
            Button("Exit", action: onExit)
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(minWidth: 120, minHeight: 44)
                .padding(.top, RCSpacing.s)
                .padding(.bottom, RCSpacing.xxs)
        }
        .background {
            ZStack(alignment: .top) {
                Color.black
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(outcome == .win ? .success : .impact(weight: .medium), trigger: true)
    }

    private var title: String {
        switch outcome {
        case .win: "You Won!"
        case .loss: "You Lost"
        case .draw: "Draw"
        }
    }

    private var backgroundImageName: String {
        switch outcome {
        case .win: "DuelResultWinBackground"
        case .loss: "DuelResultLossBackground"
        case .draw: "DuelResultDrawBackground"
        }
    }

    // MARK: - Players

    private var players: some View {
        HStack(alignment: .top, spacing: 0) {
            ResultPlayer(
                player: lobby.me,
                personalRecord: lobby.myStats.trainingRecord(for: lobby.exercise),
                isWinner: outcome == .win,
                isDimmed: outcome == .loss,
                tint: avatarTint
            )
            Spacer(minLength: 0)
            Text("\(myReps)-\(opponentReps)")
                .font(.system(size: 64, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 34)
                .accessibilityLabel("You \(myReps), \(lobby.opponent.nickname) \(opponentReps)")
            Spacer(minLength: 0)
            ResultPlayer(
                player: lobby.opponent,
                personalRecord: lobby.opponentStats.trainingRecord(for: lobby.exercise),
                isWinner: outcome == .loss,
                isDimmed: outcome == .win,
                tint: avatarTint
            )
        }
        .padding(.horizontal, RCSpacing.m)
    }

    /// FIGMA: avatar fill follows the backdrop (blue / teal-green / purple-red).
    private var avatarTint: Color {
        switch outcome {
        case .win: RCColor.resultWinAvatar
        case .loss: RCColor.resultLossAvatar
        case .draw: RCColor.lobbyAvatar
        }
    }

    // MARK: - Chip

    private var chip: some View {
        HStack(spacing: RCSpacing.xs) {
            if outcome == .win {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(RCColor.win)
            }
            Text(chipText)
        }
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(.white)
        .padding(.horizontal, RCSpacing.l)
        .frame(height: 40)
        .background(.white.opacity(0.08), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
    }

    private var chipText: String {
        let difference = abs(myReps - opponentReps)
        switch outcome {
        case .win: return "Won by \(difference) \(difference == 1 ? "rep" : "reps")"
        case .loss: return "\(difference) \(difference == 1 ? "Rep was" : "Reps were") not enough"
        case .draw: return "Equal result"
        }
    }

    // MARK: - Stats

    /// FIGMA: dark card, Total Reps (+ this duel's reps) | Win Rate (+/- percentage points).
    private var statsCard: some View {
        HStack(spacing: 0) {
            ResultStat(
                systemImage: "dumbbell.fill",
                value: "\(statsAfter.totalDuelReps)",
                unit: nil,
                change: myReps > 0 ? ("+\(myReps)", RCColor.win) : nil,
                label: "Total Reps"
            )
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1, height: 44)
            ResultStat(
                systemImage: "flame.fill",
                value: "\(statsAfter.winRatePercent ?? 0)",
                unit: "%",
                change: winRateChange,
                label: "Win Rate"
            )
        }
        .padding(.vertical, RCSpacing.l)
        .background(RCColor.resultCard, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
    }

    private var winRateChange: (String, Color)? {
        let before = lobby.myStats.winRatePercent ?? 0
        let delta = (statsAfter.winRatePercent ?? 0) - before
        guard delta != 0, lobby.myStats.duelsPlayed > 0 else { return nil }
        return delta > 0 ? ("+\(delta)%", RCColor.win) : ("\(delta)%", RCColor.duelRed)
    }
}

/// FIGMA: 105 pt avatar with a white ring; the winner wears the crown, the loser is faded.
private struct ResultPlayer: View {
    let player: PlayerProfile
    let personalRecord: Int
    let isWinner: Bool
    let isDimmed: Bool
    let tint: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(player.emoji)
                .font(.system(size: 56))
                .frame(width: 105, height: 105)
                .background(tint, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(isDimmed ? 0.35 : 1), lineWidth: 3))
                .shadow(color: .white.opacity(isDimmed ? 0 : 0.35), radius: 10)
                .overlay(alignment: .top) {
                    if isWinner {
                        Image("DuelResultCrown")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50)
                            .offset(y: -22)
                            .accessibilityHidden(true)
                    }
                }
            Text(player.nickname)
                .font(.system(size: 22, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: 130)
                .padding(.top, RCSpacing.m)
            Text("PR \(personalRecord)")
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(.white)
        .opacity(isDimmed ? 0.5 : 1)
        .saturation(isDimmed ? 0.6 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isWinner ? "Winner" : "")
    }
}

/// One column of the stats card: accent icon, big value with a small unit and colored change.
struct ResultStat: View {
    let systemImage: String
    let value: String
    let unit: String?
    let change: (String, Color)?
    let label: String

    var body: some View {
        VStack(spacing: RCSpacing.xs) {
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundStyle(RCColor.accent)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 40, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 2) {
                        if let unit {
                            Text(unit).foregroundStyle(.white)
                        }
                        if let change {
                            Text(change.0).foregroundStyle(change.1)
                        }
                    }
                    .font(.system(size: 17, weight: .medium))
                    Spacer(minLength: 0)
                }
                .fixedSize()
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)\(unit ?? "")\(change.map { ", \($0.0)" } ?? "")")
    }
}

#Preview("Win") {
    DuelResultView(
        lobby: DuelLobby(
            me: PlayerProfile(nickname: "Nova_07", emoji: "🐧"),
            opponent: PlayerProfile(nickname: "Lena_v", emoji: "🐱"),
            exercise: .pushUps,
            duration: .default,
            myStats: PlayerStats(totalDuelReps: 80, duelsWon: 16, duelsLost: 9, duelsTied: 0, trainingRecords: [.pushUps: 55])
        ),
        myReps: 20,
        opponentReps: 17,
        onPlayAgain: {},
        onExit: {}
    )
}
