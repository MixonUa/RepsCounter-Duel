import SwiftUI
import DesignSystem

/// FIGMA "Choose Your Avatar" grid: 3 columns of emoji circles inside a white card that scrolls;
/// the selected one gets an accent ring. Used by onboarding and Edit Profile.
struct AvatarGrid: View {
    @Binding var selection: AvatarEmoji
    /// Extra scroll room at the bottom (e.g. for a button drawn over the card).
    var bottomInset: CGFloat = RCSpacing.l

    private let columns = Array(repeating: GridItem(.flexible(), spacing: RCSpacing.s), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(AvatarEmoji.all) { avatar in
                    AvatarCell(avatar: avatar, isSelected: avatar == selection) {
                        selection = avatar
                    }
                }
            }
            .padding(.horizontal, RCSpacing.xs)
            .padding(.top, RCSpacing.s + 2)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, bottomInset, for: .scrollContent)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
    }
}

private struct AvatarCell: View {
    let avatar: AvatarEmoji
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(avatar.emoji)
                .font(.system(size: 64))
                .frame(width: 90, height: 90)
                .background(RCColor.avatarFill, in: Circle())
                .padding(7)
                .overlay {
                    // FIGMA: accent ring with a white gap around the selected avatar.
                    Circle()
                        .strokeBorder(RCColor.accent, lineWidth: 2.5)
                        .opacity(isSelected ? 1 : 0)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
        .accessibilityLabel(avatar.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
