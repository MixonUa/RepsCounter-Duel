import SwiftUI
import Backend
import DesignSystem

/// FIGMA podium: places 2 · 1 · 3, 101 pt wide translucent cards with bottoms aligned
/// (heights 242 / 270 / 229). A missing place shows the "?" avatar.
struct RatingPodium: View {
    /// Places 1–3 in rank order (may be shorter, or empty).
    let entries: [LeaderboardEntry]

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            card(place: 2, height: 242)
            card(place: 1, height: 270)
            card(place: 3, height: 229)
        }
        .frame(maxWidth: .infinity)
    }

    private func card(place: Int, height: CGFloat) -> some View {
        PodiumCard(place: place, entry: entries.indices.contains(place - 1) ? entries[place - 1] : nil)
            .frame(width: 101, height: height)
    }
}

private struct PodiumCard: View {
    let place: Int
    let entry: LeaderboardEntry?

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.75), RCColor.podiumCard], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(.white, lineWidth: 1.5))

            VStack(spacing: 6) {
                avatar
                if let entry {
                    Text(entry.player.nickname)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RCColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, RCSpacing.xs)
                    HStack(spacing: 2) {
                        Text("\(entry.totalDuelReps)")
                            .font(.system(size: 15, weight: .semibold).monospacedDigit())
                            .foregroundStyle(RCColor.textPrimary)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(RCColor.accent)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white, in: Capsule())
                }
            }
            .padding(.top, 8)

            Text("\(place)")
                .font(.system(size: 60, weight: .black).italic())
                .foregroundStyle(LinearGradient(colors: [RCColor.placeNumberTop, RCColor.placeNumberBottom], startPoint: .top, endPoint: .bottom))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var avatar: some View {
        ZStack {
            Circle().fill(RCColor.podiumAvatar)
            if let entry {
                Text(entry.player.emoji).font(.system(size: 44))
            } else {
                Circle()
                    .fill(RCColor.accent)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text("?")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
        }
        .frame(width: 84, height: 84)
        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
    }

    private var accessibilityText: String {
        guard let entry else { return "Place \(place), free" }
        return "Place \(place), \(entry.player.nickname), \(entry.totalDuelReps) reps"
    }
}

/// FIGMA: rays artwork (exported image) at the top of the screen over the light background.
struct RatingRaysBackground: View {
    var body: some View {
        RCColor.background
            .overlay(alignment: .top) {
                Image("RatingRays")
                    .resizable()
                    .scaledToFit()
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}
