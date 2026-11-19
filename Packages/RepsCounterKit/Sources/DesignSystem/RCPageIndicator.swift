import SwiftUI

/// FIGMA: page dots — active page is a short accent capsule, others are small gray dots.
public struct RCPageIndicator: View {
    private let count: Int
    private let current: Int

    public init(count: Int, current: Int) {
        self.count = count
        self.current = current
    }

    public var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? RCColor.accent : RCColor.indicatorInactive)
                    .frame(width: index == current ? 14 : 6, height: 6)
            }
        }
        .animation(.snappy, value: current)
        .accessibilityElement()
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}
