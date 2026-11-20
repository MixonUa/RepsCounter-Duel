import SwiftUI
import Backend
import DesignSystem

/// FIGMA Rating / Leaderboard: weekly single total of duel reps (CLAUDE.md §2), Global / Friends.
/// - Empty: "?" podium, gray skeleton rows, a caption per scope.
/// - Filled: my place + avatar chip in the header, podium for places 1–3, the list from place 4;
///   the full list from place 1 (Figma starts it at 4 — a design bug, decided 2026-11-19);
///   my row is highlighted and pinned above the tab bar until it scrolls into view.
/// UI stage: mock data (stage 5 loads paginated server totals).
struct RatingView: View {
    let me: PlayerProfile
    let overview: RatingOverview

    @State private var scope: LeaderboardScope = .global
    @State private var isMyRowVisible = false

    private var entries: [LeaderboardEntry] { overview.entries(for: scope) }
    private var myEntry: LeaderboardEntry? { entries.first { $0.player.id == me.id } }
    private var podium: [LeaderboardEntry] { Array(entries.prefix(3)) }

    private var showsPinnedRow: Bool { myEntry != nil && !isMyRowVisible }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, RCSpacing.m)
                    .padding(.top, RCSpacing.xs)

                RatingPodium(entries: podium)
                    .padding(.top, RCSpacing.l)

                caption
                    .padding(.top, RCSpacing.l)

                RatingScopePicker(selection: $scope)
                    .padding(.top, entries.isEmpty ? RCSpacing.l : RCSpacing.m)

                list
                    .padding(.horizontal, RCSpacing.m)
                    .padding(.top, RCSpacing.l)
                    .padding(.bottom, RCSpacing.m)
            }
        }
        .scrollIndicators(.hidden)
        .background { RatingRaysBackground() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsPinnedRow, let myEntry {
                PinnedMyRow(entry: myEntry, me: me)
                    .padding(.horizontal, 18)
                    .padding(.bottom, RCSpacing.xs)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: showsPinnedRow)
        .onChange(of: scope) { isMyRowVisible = false }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Rating")
                .font(RCFont.homeTitle)
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let myEntry {
                HStack(spacing: RCSpacing.xs) {
                    Text("\(myEntry.rank)")
                        .font(.system(size: 30, weight: .heavy).italic())
                        .foregroundStyle(RCColor.rankNumber)
                    Text(me.emoji)
                        .font(.system(size: 20))
                        .frame(width: 36, height: 36)
                        .background(RCColor.accent, in: Circle())
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Your place this week: \(myEntry.rank)")
            }
        }
        .frame(minHeight: 44)
    }

    private var caption: some View {
        let second: String? = switch (entries.isEmpty, scope) {
        case (true, .global): "Become FIRST in the top!"
        case (true, .friends): "Add friends to start your own top"
        case (false, _): nil
        }
        return VStack(spacing: 2) {
            Text("Data is updated weekly")
            if let second { Text(second) }
        }
        .font(.system(size: 17))
        .foregroundStyle(RCColor.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, RCSpacing.m)
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        VStack(spacing: 0) {
            if entries.isEmpty {
                ForEach(0..<4, id: \.self) { index in
                    SkeletonRow(place: index + 1, showsSeparator: index < 3)
                        .opacity([1, 0.7, 0.45, 0.2][index])
                }
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    let isMe = entry.player.id == me.id
                    LeaderboardRow(entry: entry, isMe: isMe, showsSeparator: index < entries.count - 1)
                        .onScrollVisibilityChange(threshold: 0.9) { visible in
                            if isMe { isMyRowVisible = visible }
                        }
                }
            }
        }
        .padding(.vertical, RCSpacing.xxs)
        .background(RCColor.leaderboardCard, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .id(scope)
    }
}

// MARK: - Scope picker

/// FIGMA: 278 × 37 gray track, the selected scope on a white pill, 17 semibold.
private struct RatingScopePicker: View {
    @Binding var selection: LeaderboardScope
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardScope.allCases) { scope in
                let isSelected = scope == selection
                Button {
                    withAnimation(.snappy) { selection = scope }
                } label: {
                    Text(scope.displayName)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(RCColor.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 33)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(2)
        .frame(width: 278)
        .background(RCColor.segmentTrack, in: Capsule())
    }
}

// MARK: - Rows

/// "130 ⚡": the weekly total with the accent bolt.
private struct RepsScore: View {
    let value: Int

    var body: some View {
        HStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 17, weight: .semibold).monospacedDigit())
                .foregroundStyle(RCColor.textPrimary)
            Image(systemName: "bolt.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RCColor.accent)
        }
    }
}

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isMe: Bool
    let showsSeparator: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text("\(entry.rank)")
                .font(.system(size: 20, weight: .heavy).italic().monospacedDigit())
                .foregroundStyle(RCColor.rankNumber)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 56, alignment: .center)
            Text(entry.player.emoji)
                .font(.system(size: 28))
                .frame(width: 40)
            Text(isMe ? "You (\(entry.player.nickname))" : entry.player.nickname)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(RCColor.textPrimary)
                .lineLimit(1)
                .padding(.leading, RCSpacing.xs)
            Spacer(minLength: RCSpacing.s)
            RepsScore(value: entry.totalDuelReps)
                .padding(.trailing, RCSpacing.m)
        }
        .frame(minHeight: 56)
        .background {
            if isMe {
                Capsule().fill(RCColor.myRow).padding(.horizontal, 2)
            }
        }
        .overlay(alignment: .bottom) {
            if showsSeparator && !isMe {
                Rectangle()
                    .fill(RCColor.cardDivider)
                    .frame(height: 0.5)
                    .padding(.leading, 104)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Place \(entry.rank), \(isMe ? "you, " : "")\(entry.player.nickname), \(entry.totalDuelReps) reps")
    }
}

/// FIGMA: my row pinned above the tab bar while my place in the list is off-screen.
private struct PinnedMyRow: View {
    let entry: LeaderboardEntry
    let me: PlayerProfile

    var body: some View {
        HStack(spacing: 0) {
            Text("\(entry.rank)")
                .font(.system(size: 17).monospacedDigit())
                .foregroundStyle(RCColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 48)
            Text(me.emoji)
                .font(.system(size: 22))
                .frame(width: 40, height: 40)
                .background(RCColor.podiumAvatar, in: Circle())
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            Text("You (\(me.nickname))")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(RCColor.textPrimary)
                .lineLimit(1)
                .padding(.leading, RCSpacing.s)
            Spacer(minLength: RCSpacing.s)
            RepsScore(value: entry.totalDuelReps)
                .padding(.trailing, RCSpacing.m)
        }
        .frame(height: 57)
        .background(RCColor.myRow, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your place: \(entry.rank), \(entry.totalDuelReps) reps")
    }
}

/// Empty state placeholder row: gray avatar circle and name bar.
private struct SkeletonRow: View {
    let place: Int
    let showsSeparator: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text("\(place)")
                .font(.system(size: 20, weight: .heavy).italic())
                .foregroundStyle(RCColor.rankNumber)
                .frame(width: 56)
            Circle()
                .fill(RCColor.skeleton)
                .frame(width: 40, height: 40)
            Capsule()
                .fill(RCColor.skeletonBar)
                .frame(width: 120, height: 22)
                .padding(.leading, RCSpacing.s)
            Spacer()
        }
        .frame(height: 56)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle()
                    .fill(RCColor.cardDivider)
                    .frame(height: 0.5)
                    .padding(.leading, 104)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Empty") {
    RatingView(me: MockData.me, overview: .empty)
}

#Preview("Filled") {
    RatingView(me: MockData.me, overview: MockData.ratingFilled(me: MockData.me))
}
