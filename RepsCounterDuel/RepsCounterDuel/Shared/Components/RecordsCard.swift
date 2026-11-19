import SwiftUI
import DesignSystem

/// FIGMA "Your records" card: two columns (icon, big number, label, weekly change) split by a
/// thin divider. Used on the onboarding explanation slide; meant for reuse on Home.
struct RecordsCard: View {
    struct Item: Identifiable {
        let systemImage: String
        let value: Int
        let label: String
        /// e.g. "+4 this week"; nil hides the line.
        let weeklyChange: String?
        var id: String { label }
    }

    let items: [Item]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(RCColor.cardDivider)
                        .frame(width: 1, height: 44)
                }
                column(item)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
    }

    private func column(_ item: Item) -> some View {
        VStack(spacing: 2) {
            Image(systemName: item.systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(RCColor.accent)
                // Fixed height so columns line up whatever the symbol's proportions.
                .frame(height: 22)
                .padding(.bottom, 2)
            Text("\(item.value)")
                .font(.system(size: 28, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(RCColor.textPrimary)
            Text(item.label)
                .font(.system(size: 12))
                .foregroundStyle(RCColor.textSecondary)
                .padding(.top, 2)
            if let weeklyChange = item.weeklyChange {
                Text(weeklyChange)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(RCColor.win)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
