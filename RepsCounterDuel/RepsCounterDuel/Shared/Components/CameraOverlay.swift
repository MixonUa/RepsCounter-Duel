import SwiftUI
import DesignSystem

// Shared overlay pieces for the camera screens (live duel, training).

/// FIGMA: 37 pt circle with "YOU" or the opponent's initials; outlined (dark fill + colored ring)
/// during the countdown and for the opponent.
struct DuelBadge: View {
    let text: String
    let color: Color
    let isOutlined: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: 37, height: 37)
            .background(color.opacity(isOutlined ? 0.3 : 0.45), in: Circle())
            .overlay {
                if isOutlined { Circle().strokeBorder(color, lineWidth: 2) }
            }
            .accessibilityHidden(true)
    }
}

/// FIGMA: 179 pt dark circle with an accent ring, the big number and "GET READY".
struct CountdownCircle: View {
    let value: Int

    var body: some View {
        VStack(spacing: RCSpacing.xxs) {
            Text("\(value)")
                .font(.system(size: 80, weight: .black))
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
            Text("GET READY")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RCColor.accent)
        }
        .offset(y: 8)
        .frame(width: 179, height: 179)
        .background(.black.opacity(0.6), in: Circle())
        .overlay(Circle().strokeBorder(RCColor.accent, lineWidth: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Get ready, \(value)")
    }
}

extension View {
    /// FIGMA: dark translucent rounded panel at the bottom of the camera.
    func duelPanelBackground() -> some View {
        background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 38, style: .continuous))
            .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 38, style: .continuous))
    }
}
