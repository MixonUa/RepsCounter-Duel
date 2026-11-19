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

/// Custom bottom bar: a capsule with the main tabs plus a visually separate
/// round action button on the right (the Duel action). PROVISIONAL layout until checked against Figma.
public struct RCTabBar<Tab: Hashable>: View {
    private let items: [RCTabBarItem<Tab>]
    @Binding private var selection: Tab
    private let actionTitle: String
    private let actionSystemImage: String
    private let action: () -> Void

    public init(
        items: [RCTabBarItem<Tab>],
        selection: Binding<Tab>,
        actionTitle: String,
        actionSystemImage: String,
        action: @escaping () -> Void
    ) {
        self.items = items
        self._selection = selection
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
    }

    public var body: some View {
        HStack(spacing: RCSpacing.s) {
            tabs
            actionButton
        }
        .padding(.horizontal, RCSpacing.m)
        .padding(.bottom, RCSpacing.xxs)
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, RCSpacing.xxs)
        .frame(height: RCSize.tabBarHeight)
        .rcGlass(in: Capsule())
    }

    private func tabButton(_ item: RCTabBarItem<Tab>) -> some View {
        let isSelected = item.tab == selection
        return Button {
            selection = item.tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(item.title)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(isSelected ? RCColor.accent : RCColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: RCSize.minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var actionButton: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: actionSystemImage)
                    .font(.system(size: 22, weight: .bold))
                Text(actionTitle)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(width: RCSize.tabBarHeight, height: RCSize.tabBarHeight)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .rcProminentGlass(in: Circle())
        .accessibilityLabel(actionTitle)
    }
}
