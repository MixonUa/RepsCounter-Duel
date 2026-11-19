import SwiftUI

public extension View {
    /// FIGMA: white capsule text field (57 pt high), semibold text.
    func rcCapsuleField() -> some View {
        font(RCFont.fieldText)
            .foregroundStyle(RCColor.textPrimary)
            .padding(.horizontal, RCSpacing.m + 1)
            .frame(maxWidth: .infinity, minHeight: RCSize.field)
            .background(.white, in: Capsule())
    }
}
