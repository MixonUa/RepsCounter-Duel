import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA training result on the dark blue backdrop: ‹ and share, "Great Job!" (or "Don't Give
/// Up !" with 0 reps), the subtitle, my avatar, "<N> Reps", a card with Total Reps (all training
/// reps kept on the phone, "+N" for this session) and the weekly rank, Continue Practice and Exit.
///
/// CLAUDE.md §2: training never changes the rating, so the rank card always reads "Your Rank"
/// (Figma's "New Rank" would suggest it changed) and the "top N" hint talks about duel reps.
/// Decided 2026-11-20: "Your Rank" and the duel-reps hint. PROVISIONAL: ‹ = Exit, share text.
struct TrainingResultView: View {
    let me: PlayerProfile
    let exercise: Exercise
    let reps: Int
    /// All training reps on this device, including this session.
    let totalReps: Int
    let isNewRecord: Bool
    /// Weekly duel rank; nil before the first ranked duel.
    let rank: WeeklyRank?
    let onContinue: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                LobbyBackButton(accessibilityLabel: "Close", action: onExit)
                Spacer()
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: RCSize.backButton, height: RCSize.backButton)
                        .background(.white.opacity(0.18), in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                }
                .accessibilityLabel("Share")
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.xs)

            Text(reps > 0 ? "Great Job!" : "Don't Give Up !")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, RCSpacing.s)
            Text(subtitle)
                .font(.system(size: 17))
                .tracking(-0.4)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RCSpacing.m)
                .padding(.top, RCSpacing.xxs)

            Spacer(minLength: RCSpacing.l)

            Text(me.emoji)
                .font(.system(size: 96))
                .frame(width: 169, height: 169)
                .background(.white.opacity(0.4), in: Circle())
                .accessibilityHidden(true)

            Spacer(minLength: RCSpacing.l)

            Text("\(reps) \(reps == 1 ? "Rep" : "Reps")")
                .font(.system(size: 64, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer(minLength: RCSpacing.l)

            statsCard
                .padding(.horizontal, RCSpacing.m)

            Spacer(minLength: RCSpacing.l)

            Button("Continue Practice", action: onContinue)
                .buttonStyle(.rcPrimaryLarge)
                .padding(.horizontal, RCSpacing.l)
            Button("Exit", action: onExit)
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.6))
                .frame(minWidth: 120, minHeight: 44)
                .padding(.top, RCSpacing.s)
                .padding(.bottom, RCSpacing.xxs)
        }
        .background {
            ZStack {
                Color.black
                Image("DuelLobbyBackground")
                    .resizable()
                    .scaledToFill()
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.success, trigger: isNewRecord)
    }

    private var subtitle: String {
        guard reps > 0 else { return "Do an exercise to continue your streak" }
        if isNewRecord { return "New \(exercise.displayName.lowercased()) record!" }
        if let rank, let milestone = rank.milestone, let missing = rank.repsToNextMilestone {
            return "Do \(missing) more duel reps to break into the top \(milestone)"
        }
        return "Keep it up — every rep counts"
    }

    private var shareText: String {
        "I just did \(reps) \(exercise.displayName.lowercased()) in Reps Counter! 💪"
    }

    /// Same dark card as the duel results: Total Reps (+ this session) | Your Rank.
    private var statsCard: some View {
        HStack(spacing: 0) {
            ResultStat(
                systemImage: "dumbbell.fill",
                value: "\(totalReps)",
                unit: nil,
                change: reps > 0 ? ("+\(reps)", RCColor.win) : nil,
                label: "Total Reps"
            )
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1, height: 44)
            ResultStat(
                systemImage: "trophy.fill",
                value: rank.map { "#\($0.position)" } ?? "—",
                unit: nil,
                change: nil,
                label: "Your Rank"
            )
        }
        .padding(.vertical, RCSpacing.l)
        .background(RCColor.resultCard.opacity(0.85), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(.white.opacity(0.15), lineWidth: 1))
    }
}

/// Training → result → Continue Practice (a fresh session) or Exit. Saves every finished session
/// (total reps + per-exercise record) on the phone. ✕ during training leaves without a result.
struct TrainingFlow: View {
    let me: PlayerProfile
    let exercise: Exercise
    let rank: WeeklyRank?
    let store: TrainingProgressStore
    @Environment(\.dismiss) private var dismiss

    private struct Result: Equatable {
        let reps: Int
        let isNewRecord: Bool
    }

    @State private var result: Result?
    @State private var session = 0

    var body: some View {
        Group {
            if let result {
                TrainingResultView(
                    me: me,
                    exercise: exercise,
                    reps: result.reps,
                    totalReps: store.progress.totalReps,
                    isNewRecord: result.isNewRecord,
                    rank: rank,
                    onContinue: {
                        session += 1
                        self.result = nil
                    },
                    onExit: { dismiss() }
                )
            } else {
                TrainingSessionView(
                    exercise: exercise,
                    onFinish: { reps in
                        result = Result(reps: reps, isNewRecord: store.add(reps: reps, of: exercise))
                    },
                    onClose: { dismiss() }
                )
                .id(session)
            }
        }
        .transition(.opacity)
        .animation(.snappy, value: result)
    }
}

#Preview {
    TrainingResultView(
        me: PlayerProfile(nickname: "Nova_07", emoji: "🐧"),
        exercise: .squats,
        reps: 20,
        totalReps: 100,
        isNewRecord: false,
        rank: WeeklyRank(position: 24, repsToNextMilestone: 6),
        onContinue: {},
        onExit: {}
    )
}
