import SwiftUI

public extension View {
    /// Standard content card used across Home, Rating and Profile.
    func rcCard() -> some View {
        padding(RCSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RCColor.surface, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
    }
}

/// Section header: title on the left, optional trailing action ("See all").
public struct RCSectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(RCFont.sectionTitle)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(RCFont.body)
            }
        }
    }
}

/// Small statistic: big value + caption.
public struct RCStatTile: View {
    private let value: String
    private let label: String

    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: RCSpacing.xxs) {
            Text(value)
                .font(RCFont.statValue)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(RCFont.statLabel)
                .foregroundStyle(RCColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Emoji avatar in a circle.
public struct RCEmojiAvatar: View {
    private let emoji: String
    private let size: CGFloat

    public init(_ emoji: String, size: CGFloat = 44) {
        self.emoji = emoji
        self.size = size
    }

    public var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background(RCColor.background, in: Circle())
            .accessibilityHidden(true)
    }
}
