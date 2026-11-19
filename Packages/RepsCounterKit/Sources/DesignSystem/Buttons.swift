import SwiftUI

/// Full-width primary action ("Continue", "Start training").
/// FIGMA: blue vertical gradient capsule with a light rim, white semibold label;
/// disabled — flat light gray with the same white label.
public struct RCPrimaryButtonStyle: ButtonStyle {
    public enum Size: Sendable {
        /// 64 pt, onboarding and full-screen flows.
        case large
        /// 52 pt, inside cards.
        case regular
    }

    @Environment(\.isEnabled) private var isEnabled
    private let size: Size

    public init(size: Size = .regular) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size == .large ? RCFont.buttonLarge : .headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: size == .large ? RCSize.buttonLarge : RCSize.button)
            // Gray base + gradient on top faded by opacity: swapping one fill style for another
            // would cross-fade through transparent during the enabled/disabled animation.
            .background {
                ZStack {
                    Capsule().fill(RCColor.buttonDisabled)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [RCColor.buttonGradientTop, RCColor.buttonGradientBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .opacity(isEnabled ? 1 : 0)
                }
            }
            .overlay(Capsule().strokeBorder(.white.opacity(isEnabled ? 0.25 : 0.6), lineWidth: 1))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.2), value: isEnabled)
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
            .frame(maxWidth: .infinity, minHeight: RCSize.button)
            .background(RCColor.accent.opacity(0.12), in: Capsule())
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public extension ButtonStyle where Self == RCPrimaryButtonStyle {
    static var rcPrimary: RCPrimaryButtonStyle { RCPrimaryButtonStyle() }
    static var rcPrimaryLarge: RCPrimaryButtonStyle { RCPrimaryButtonStyle(size: .large) }
}

public extension ButtonStyle where Self == RCSecondaryButtonStyle {
    static var rcSecondary: RCSecondaryButtonStyle { RCSecondaryButtonStyle() }
}
