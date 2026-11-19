import SwiftUI

/// Full-width primary action ("Start training", "Challenge to a duel").
public struct RCPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RCColor.accent, in: RoundedRectangle(cornerRadius: RCRadius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Secondary action with a tinted background ("Add friend").
public struct RCSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(RCColor.accent)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RCColor.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: RCRadius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public extension ButtonStyle where Self == RCPrimaryButtonStyle {
    static var rcPrimary: RCPrimaryButtonStyle { RCPrimaryButtonStyle() }
}

public extension ButtonStyle where Self == RCSecondaryButtonStyle {
    static var rcSecondary: RCSecondaryButtonStyle { RCSecondaryButtonStyle() }
}
