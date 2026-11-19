import SwiftUI

public extension View {
    /// Liquid Glass on iOS 26+, a material fallback on iOS 18–25.
    @ViewBuilder
    func rcGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self
                .background(.regularMaterial, in: shape)
                .overlay(shape.stroke(RCColor.separator.opacity(0.4), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        }
    }

    /// Tinted Liquid Glass on iOS 26+, a solid accent fallback on iOS 18–25.
    @ViewBuilder
    func rcProminentGlass<S: Shape>(in shape: S, tint: Color = RCColor.accent) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else {
            self
                .background(tint, in: shape)
                .shadow(color: tint.opacity(0.35), radius: 10, y: 4)
        }
    }
}
