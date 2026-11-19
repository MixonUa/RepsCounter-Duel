import SwiftUI

/// One tab of `RCTabBar`.
public struct RCTabBarItem<Tab: Hashable>: Identifiable {
    public let tab: Tab
    public let title: String
    public let systemImage: String

    public var id: Tab { tab }

    public init(_ tab: Tab, title: String, systemImage: String) {
        self.tab = tab
        self.title = title
        self.systemImage = systemImage
    }
}

/// FIGMA bottom bar: a capsule with the main tabs (gray pill behind the selected one, accent icon
/// and label) plus a separate round accent "VS" button on the right (the Duel action).
public struct RCTabBar<Tab: Hashable>: View {
    private let items: [RCTabBarItem<Tab>]
    @Binding private var selection: Tab
    private let actionText: String
    private let actionAccessibilityLabel: String
    private let action: () -> Void

    public init(
        items: [RCTabBarItem<Tab>],
        selection: Binding<Tab>,
        actionText: String,
        actionAccessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.items = items
        self._selection = selection
        self.actionText = actionText
        self.actionAccessibilityLabel = actionAccessibilityLabel
        self.action = action
    }

    public var body: some View {
        HStack(spacing: RCSpacing.xs) {
            tabs
            actionButton
        }
        .padding(.horizontal, RCSpacing.l)
        .padding(.bottom, RCSpacing.xxs)
    }

    /// FIGMA: 66 pt capsule; tabs are 73 pt pills (inset 7 pt), the outer ones at the edges.
    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 { Spacer(minLength: RCSpacing.xxs) }
                tabButton(item)
            }
        }
        .padding(7)
        .frame(height: 66)
        .rcGlass(in: Capsule())
    }

    private func tabButton(_ item: RCTabBarItem<Tab>) -> some View {
        let isSelected = item.tab == selection
        return Button {
            selection = item.tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 21, weight: .semibold))
                    .frame(height: 24)
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSelected ? RCColor.accent : RCColor.textPrimary)
            .frame(width: 73)
            .frame(maxHeight: .infinity)
            .background {
                if isSelected {
                    Capsule().fill(RCColor.tabSelectedPill)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// FIGMA: 62 pt accent circle with heavy italic "VS" and a soft accent glow.
    private var actionButton: some View {
        Button(action: action) {
            Text(actionText)
                .font(.system(size: 27, weight: .black).italic())
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .rcProminentGlass(in: Circle())
        .shadow(color: RCColor.accent.opacity(0.35), radius: 12, y: 4)
        .accessibilityLabel(actionAccessibilityLabel)
    }
}
