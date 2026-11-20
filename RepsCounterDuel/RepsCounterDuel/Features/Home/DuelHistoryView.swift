import SwiftUI
import OSLog
import Backend
import DesignSystem
import ExerciseAnalyzer

/// FIGMA "Duels History" (Home → Recent duels → See all): back chevron + title, All / Wins /
/// Losses switch, completed duels grouped by local day ("Today", "31 Aug"), newest first.
/// Each card: me (left) vs opponent (right), the score, Win / Loss / Draw and the exercise. The
/// winner's avatar is highlighted (blue fill, accent ring, bolt badge); on a draw both are
/// highlighted without the badge. Draws appear only under All.
/// Data: `my_duel_history` (completed duels only; interrupted / forfeited never appear).
struct DuelHistoryView: View {
    let me: PlayerProfile
    var service: any StatsServicing = AppServices.statsService

    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All", wins = "Wins", losses = "Losses"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var filter: Filter = .all
    @State private var duels: [DuelSummary]?
    @State private var didFail = false

    private var visible: [DuelSummary] {
        (duels ?? []).filter {
            switch filter {
            case .all: true
            case .wins: $0.outcome == .win
            case .losses: $0.outcome == .loss
            }
        }
    }

    /// Local calendar days, newest first.
    private var sections: [(day: Date, duels: [DuelSummary])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: visible) { calendar.startOfDay(for: $0.finishedAt) }
        return groups.keys.sorted(by: >).map { day in
            (day, groups[day]!.sorted { $0.finishedAt > $1.finishedAt })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            HistoryFilterPicker(selection: $filter)
                .padding(.horizontal, RCSpacing.m)
                .padding(.top, RCSpacing.s)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: RCSpacing.s) {
                    ForEach(sections, id: \.day) { section in
                        Text(Self.title(for: section.day))
                            .font(.system(size: 22, weight: .semibold))
                            .tracking(-0.6)
                            .foregroundStyle(RCColor.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, RCSpacing.l)
                            .padding(.bottom, RCSpacing.xxs)
                        ForEach(section.duels) { duel in
                            DuelHistoryCard(me: me, duel: duel)
                        }
                    }
                }
                .padding(.horizontal, RCSpacing.m)
                .padding(.bottom, RCSpacing.l)
            }
            .scrollIndicators(.hidden)
            .overlay { emptyState }
            .refreshable { await load() }
        }
        .background(RCColor.background.ignoresSafeArea())
        .task { await load() }
    }

    /// FIGMA: plain chevron on the left, centered title (like Friends).
    private var header: some View {
        ZStack {
            Text("Duels History")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(RCColor.textPrimary)
                        .frame(width: RCSize.minTouchTarget, height: RCSize.minTouchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.leading, RCSpacing.xxs)
        }
        .padding(.top, RCSpacing.xs)
    }

    /// PROVISIONAL (no Figma frames): loading, error and empty states.
    @ViewBuilder
    private var emptyState: some View {
        if duels == nil && !didFail {
            ProgressView()
        } else if visible.isEmpty {
            Text(didFail ? "Couldn't load your duels.\nCheck your internet connection." : emptyText)
                .font(.system(size: 17))
                .foregroundStyle(RCColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RCSpacing.xl)
        }
    }

    private var emptyText: String {
        switch filter {
        case .all: "No finished duels yet.\nChallenge a friend to get started!"
        case .wins: "No wins yet"
        case .losses: "No losses yet"
        }
    }

    private func load() async {
        do {
            duels = try await service.duelHistory(since: .distantPast, limit: 200)
            didFail = false
        } catch {
            AppLog.backend.error("Loading duel history failed: \(String(describing: error), privacy: .public)")
            if duels == nil { didFail = true }
        }
    }

    /// "Today", "Yesterday", "31 Aug" (+ year when not this year).
    static func title(for day: Date, calendar: Calendar = .current, now: Date = .now) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        let sameYear = calendar.component(.year, from: day) == calendar.component(.year, from: now)
        return day.formatted(sameYear ? .dateTime.day().month(.abbreviated) : .dateTime.day().month(.abbreviated).year())
    }
}

/// FIGMA: 3-option capsule switch (gray track, white selected pill).
private struct HistoryFilterPicker<Value: Hashable & Identifiable & RawRepresentable & CaseIterable>: View where Value.RawValue == String, Value.AllCases: RandomAccessCollection {
    @Binding var selection: Value
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Value.allCases) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.snappy) { selection = option }
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? RCColor.textPrimary : RCColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(RCColor.segmentTrack, in: Capsule())
    }
}

/// FIGMA history card: me vs opponent with the score, outcome and exercise.
private struct DuelHistoryCard: View {
    let me: PlayerProfile
    let duel: DuelSummary

    var body: some View {
        HStack(spacing: 0) {
            HistoryAvatar(player: me, isHighlighted: duel.outcome != .loss, showsBolt: duel.outcome == .win)
            Spacer(minLength: RCSpacing.xs)
            VStack(spacing: RCSpacing.xxs) {
                Text("\(duel.myReps)-\(duel.opponentReps)")
                    .font(.system(size: 40, weight: .black).italic())
                    .monospacedDigit()
                    .foregroundStyle(RCColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(outcomeText)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(outcomeColor)
                Text(duel.exercise.displayName)
                    .font(.system(size: 15))
                    .foregroundStyle(RCColor.textSecondary)
            }
            Spacer(minLength: RCSpacing.xs)
            HistoryAvatar(player: duel.opponent, isHighlighted: duel.outcome != .win, showsBolt: duel.outcome == .loss)
        }
        .padding(.horizontal, RCSpacing.l)
        .padding(.vertical, RCSpacing.l)
        .background(.white, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(outcomeText), \(duel.myReps) to \(duel.opponentReps) against \(duel.opponent.nickname), \(duel.exercise.displayName)")
    }

    private var outcomeText: String {
        switch duel.outcome {
        case .win: "Win"
        case .loss: "Loss"
        case .draw: "Draw"
        }
    }

    private var outcomeColor: Color {
        switch duel.outcome {
        case .win: RCColor.win
        case .loss: RCColor.duelRed
        case .draw: RCColor.accent
        }
    }
}

/// FIGMA: 67 pt emoji circle; highlighted = blue fill + accent ring (+ bolt badge for the winner),
/// otherwise a light blue fill.
private struct HistoryAvatar: View {
    let player: PlayerProfile
    let isHighlighted: Bool
    let showsBolt: Bool

    var body: some View {
        VStack(spacing: RCSpacing.xs) {
            Text(player.emoji)
                .font(.system(size: 36))
                .frame(width: 67, height: 67)
                .background(isHighlighted ? RCColor.historyWinnerFill : RCColor.friendAvatarFill, in: Circle())
                .overlay {
                    if isHighlighted { Circle().strokeBorder(RCColor.accent, lineWidth: 2.5) }
                }
                .overlay(alignment: .topTrailing) {
                    if showsBolt {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(RCColor.accent, in: Circle())
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                            .offset(x: 6, y: -6)
                    }
                }
            Text(player.nickname)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(RCColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 96)
    }
}

#Preview {
    DuelHistoryView(me: PlayerProfile(serverNickname: "Nova_07", emoji: "🐧"), service: MockStatsService())
}
