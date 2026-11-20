import SwiftUI
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA Home. Two states from the same data:
/// - empty (first launch): today's pill with "0", zero records + "Set a new record!",
///   "Win your first duel" + "Challenge a Friend", rank card;
/// - filled: weekly bars, records with weekly gains, last duel with "See all", rank card.
/// Data is mock until stage 5 (DEBUG: `-debugDataState filled`).
struct HomeView: View {
    let me: PlayerProfile
    let overview: HomeOverview
    var onStartTraining: () -> Void = {}
    var onChallenge: () -> Void = {}
    var onOpenRating: () -> Void = {}

    private enum Sheet: String, Identifiable {
        case duelHistory
        var id: String { rawValue }
    }

    @State private var sheet: Sheet?
    @State private var isSettingsPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                section("This week") { weekCard }
                    .padding(.top, 57)

                section("Your records") { recordsCard }
                    .padding(.top, RCSpacing.xxl + RCSpacing.xxs)

                if !overview.hasTrainingRecords {
                    setRecordCard
                        .padding(.top, RCSpacing.s)
                }

                section(
                    "Recent duels",
                    action: overview.lastDuel == nil ? nil : ("See all", { sheet = .duelHistory })
                ) {
                    if let lastDuel = overview.lastDuel {
                        RecentDuelCard(me: me, duel: lastDuel)
                    } else {
                        firstDuelCard
                    }
                }
                .padding(.top, RCSpacing.xxl + RCSpacing.xs)

                if let rank = overview.rank {
                    rankCard(rank)
                        .padding(.top, RCSpacing.xxl)
                }
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.bottom, RCSpacing.l)
        }
        .scrollIndicators(.hidden)
        .background(RCColor.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $isSettingsPresented) { SettingsView() }
        .fullScreenCover(item: $sheet) { sheet in
            switch sheet {
            case .duelHistory:
                DuelHistoryView(me: me)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello, \(me.nickname)! 👋")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RCColor.accent)
                Text("Reps Counter")
                    .font(RCFont.homeTitle)
                    .foregroundStyle(RCColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer()
            Button { isSettingsPresented = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(RCColor.textPrimary)
                    .frame(width: RCSize.backButton, height: RCSize.backButton)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .rcGlass(in: Circle(), interactive: true)
            .accessibilityLabel("Settings")
        }
        .padding(.top, RCSpacing.xs)
    }

    // MARK: - Sections

    private func section<Content: View>(
        _ title: String,
        action: (String, () -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(RCFont.homeHeading)
                    .tracking(-0.8)
                    .foregroundStyle(RCColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if let action {
                    Button(action.0, action: action.1)
                        .font(.system(size: 17))
                        .foregroundStyle(RCColor.accent)
                }
            }
            content()
        }
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(overview.week.total)")
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(RCColor.textPrimary)
                Text("Reps")
                    .font(.system(size: 15))
                    .foregroundStyle(RCColor.textSecondary)
            }
            Text(WeekRangeFormatter.string(from: overview.week.start, to: overview.week.end))
                .font(.system(size: 12))
                .foregroundStyle(RCColor.textSecondary)
                .padding(.top, 4)

            WeeklyRepsChart(week: overview.week)
                .padding(.horizontal, -RCSpacing.l)
                .padding(.top, RCSpacing.s + 1)
        }
        .padding(.horizontal, RCSpacing.l + 2)
        .padding(.top, RCSpacing.m)
        .padding(.bottom, RCSpacing.s + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
    }

    private var recordsCard: some View {
        RecordsCard(items: [
            .init(
                systemImage: "figure.run",
                value: "\(overview.trainingRecords[.pushUps] ?? 0)",
                label: "Push-ups",
                weeklyChange: gainText(.pushUps)
            ),
            .init(
                systemImage: "figure.step.training",
                value: "\(overview.trainingRecords[.squats] ?? 0)",
                label: "Squats",
                weeklyChange: gainText(.squats)
            ),
        ])
    }

    private func gainText(_ exercise: Exercise) -> String? {
        guard let gain = overview.trainingRecordGains[exercise], gain > 0 else { return nil }
        return "+\(gain) this week"
    }

    // MARK: - Empty-state cards

    private var setRecordCard: some View {
        callToActionCard(
            title: "Set a new record !",
            subtitle: "Start a train to set a reps record",
            button: "Start Train",
            action: onStartTraining
        )
    }

    private var firstDuelCard: some View {
        callToActionCard(
            title: "Win your first duel",
            subtitle: "Compete with friends and track duel history",
            button: "Challenge a Friend",
            action: onChallenge
        )
    }

    private func callToActionCard(title: String, subtitle: String, button: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.6)
                .foregroundStyle(RCColor.textPrimary)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(RCColor.textSecondary)
                .padding(.top, RCSpacing.xxs)
            Button(button, action: action)
                .buttonStyle(.rcPrimary)
                .padding(.horizontal, -RCSpacing.xxs)
                .padding(.top, RCSpacing.s + 1)
        }
        .padding(.horizontal, RCSpacing.l)
        .padding(.top, RCSpacing.s + 2)
        .padding(.bottom, RCSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
    }

    // MARK: - Rank

    /// FIGMA: weekly place; the whole card opens the Rating tab.
    private func rankCard(_ rank: WeeklyRank) -> some View {
        Button(action: onOpenRating) {
            HStack(spacing: RCSpacing.m) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(RCColor.accent)
                    .frame(width: 48, height: 48)
                    .background(RCColor.rankTile, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("You're #\(rank.position) this week")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.6)
                        .foregroundStyle(RCColor.textPrimary)
                    Text(rankSubtitle(rank))
                        .font(.system(size: 14))
                        .tracking(-0.3)
                        .foregroundStyle(RCColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: RCSpacing.xs)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RCColor.textSecondary)
            }
            .padding(.horizontal, RCSpacing.m)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func rankSubtitle(_ rank: WeeklyRank) -> String {
        if let milestone = rank.milestone, let reps = rank.repsToNextMilestone {
            return "\(reps) more reps to break into the top \(milestone)"
        }
        return "You're at the top of the rating!"
    }
}

#Preview("Empty") {
    HomeView(me: PlayerProfile(nickname: "Nova_07", emoji: "🐧"), overview: MockData.homeEmpty())
}

#Preview("Filled") {
    HomeView(me: PlayerProfile(nickname: "Nova_07", emoji: "🐧"), overview: MockData.homeFilled())
}
