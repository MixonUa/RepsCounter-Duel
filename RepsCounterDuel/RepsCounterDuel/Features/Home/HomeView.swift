import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// Home tab. PROVISIONAL layout (Figma not inspected yet), mock data until stage 5.
struct HomeView: View {
    var stats: PlayerStats = MockData.myStats
    var daily: [DailyDuelReps] = MockData.dailyDuelReps
    var lastDuel: DuelSummary? = MockData.lastDuel
    var ratingPlace: Int? = MockData.leaderboard(.global).first { $0.player == MockData.me }?.rank
    var onChallenge: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RCSpacing.m) {
                    statsCard
                    chartCard
                    trainingCard
                    recentDuelCard
                    ratingPlaceCard
                }
                .padding(.horizontal, RCSpacing.m)
                .padding(.vertical, RCSpacing.xs)
            }
            .background(RCColor.background)
            .navigationTitle("Home")
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            RCSectionHeader("Statistics")
            HStack {
                RCStatTile(value: "\(stats.totalDuelReps)", label: "Duel reps")
                RCStatTile(value: "\(stats.duelsWon)", label: "Wins")
                RCStatTile(value: stats.winRate.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—", label: "Win rate")
            }
        }
        .rcCard()
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            RCSectionHeader("Duel reps per day")
            DailyDuelRepsChart(data: daily)
        }
        .rcCard()
    }

    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            RCSectionHeader("Training record")
            HStack {
                RCStatTile(value: "\(stats.trainingRecord(for: .pushUps))", label: "Push-ups")
                RCStatTile(value: "\(stats.trainingRecord(for: .squats))", label: "Squats")
            }
            Button("Start training") {
                // Training flow arrives in stage 3.
            }
            .buttonStyle(.rcPrimary)
        }
        .rcCard()
    }

    @ViewBuilder
    private var recentDuelCard: some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            RCSectionHeader("Recent Duels")
            if let lastDuel {
                RecentDuelRow(duel: lastDuel)
            } else {
                Text("No duels yet")
                    .foregroundStyle(RCColor.textSecondary)
                Button("Challenge to a duel", action: onChallenge)
                    .buttonStyle(.rcPrimary)
            }
        }
        .rcCard()
    }

    private var ratingPlaceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: RCSpacing.xxs) {
                Text("Your place in the rating")
                    .font(RCFont.statLabel)
                    .foregroundStyle(RCColor.textSecondary)
                Text(ratingPlace.map { "#\($0)" } ?? "—")
                    .font(RCFont.statValue)
            }
            Spacer()
            Image(systemName: "trophy.fill")
                .font(.title)
                .foregroundStyle(RCColor.accent)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .rcCard()
    }
}

private struct RecentDuelRow: View {
    let duel: DuelSummary

    var body: some View {
        HStack(spacing: RCSpacing.s) {
            RCEmojiAvatar(duel.opponent.emoji)
            VStack(alignment: .leading, spacing: 2) {
                Text("vs \(duel.opponent.nickname)")
                    .font(.headline)
                Text("\(duel.exercise.displayName) · \(duel.duration.displayName)")
                    .font(RCFont.caption)
                    .foregroundStyle(RCColor.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(duel.myReps) : \(duel.opponentReps)")
                    .font(.headline.monospacedDigit())
                Text(outcomeTitle)
                    .font(RCFont.caption.weight(.semibold))
                    .foregroundStyle(outcomeColor)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var outcomeTitle: String {
        switch duel.outcome {
        case .win: "Win"
        case .loss: "Loss"
        case .draw: "Draw"
        }
    }

    private var outcomeColor: Color {
        switch duel.outcome {
        case .win: RCColor.win
        case .loss: RCColor.loss
        case .draw: RCColor.draw
        }
    }
}

#Preview("With data") {
    HomeView()
}

#Preview("Empty") {
    HomeView(stats: .empty, daily: [], lastDuel: nil, ratingPlace: nil)
}
