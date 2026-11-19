import SwiftUI

/// FIGMA Settings two-option switch ("On | Off", "Mon | Sun"): gray capsule track, the selected
/// option on a white pill with a soft shadow.
public struct RCSegmentedToggle<Value: Hashable>: View {
    private let options: [(value: Value, title: String)]
    @Binding private var selection: Value
    @Namespace private var pill

    public init(_ options: [(value: Value, title: String)], selection: Binding<Value>) {
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection
                Button {
                    withAnimation(.snappy) { selection = option.value }
                } label: {
                    Text(option.title)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(RCColor.textPrimary)
                        .frame(width: 48, height: 30)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(2)
        .background(RCColor.segmentTrack, in: Capsule())
    }
}
