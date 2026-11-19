import SwiftUI

/// FIGMA: round glass back button (44 pt) with a chevron.
public struct RCBackButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(RCColor.textPrimary)
                .frame(width: RCSize.backButton, height: RCSize.backButton)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .rcGlass(in: Circle(), interactive: true)
        .accessibilityLabel("Back")
    }
}
