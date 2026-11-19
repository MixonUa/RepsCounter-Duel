import SwiftUI

/// Full-width primary action ("Continue", "Start training").
/// FIGMA: blue vertical gradient capsule with a light rim, white semibold label;
/// disabled — flat light gray with the same white label.
public struct RCPrimaryButtonStyle: ButtonStyle {
    public enum Size: Sendable {
        /// 64 pt, onboarding and full-screen flows.
        case large
        /// 50 pt, inside cards (FIGMA Home "Start Train", "Challenge a Friend").
        case regular
        /// 48 pt, two buttons in a row (friend-request banner).
        case compact
    }

    @Environment(\.isEnabled) private var isEnabled
    private let size: Size

    public init(size: Size = .regular) {
        self.size = size
    }

    private var height: CGFloat {
        switch size {
        case .large: RCSize.buttonLarge
        case .regular: RCSize.button
        case .compact: 48
        }
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size == .large ? RCFont.buttonLarge : .title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: height)
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
    /// 48 pt, side-by-side buttons in the friend-request banner.
    static var rcPrimaryCompact: RCPrimaryButtonStyle { RCPrimaryButtonStyle(size: .compact) }
    static var rcPrimaryLarge: RCPrimaryButtonStyle { RCPrimaryButtonStyle(size: .large) }
}

/// FIGMA "Reject": light pink capsule with red semibold text.
public struct RCDestructiveButtonStyle: ButtonStyle {
    private let height: CGFloat

    public init(height: CGFloat = RCSize.buttonLarge) {
        self.height = height
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RCFont.buttonLarge)
            .foregroundStyle(RCColor.error)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(RCColor.rejectFill, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == RCDestructiveButtonStyle {
    static var rcDestructiveLarge: RCDestructiveButtonStyle { RCDestructiveButtonStyle() }
    static var rcDestructive: RCDestructiveButtonStyle { RCDestructiveButtonStyle(height: 48) }
}

public extension ButtonStyle where Self == RCSecondaryButtonStyle {
    static var rcSecondary: RCSecondaryButtonStyle { RCSecondaryButtonStyle() }
}
