import SwiftUI
import DesignSystem

/// PROVISIONAL sheet for destinations that exist in Figma flows but are not built yet
/// (Settings, training, duel history).
struct PlaceholderSheet: View {
    let title: String
    let message: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text(message)
                .font(RCFont.body)
                .foregroundStyle(RCColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(RCSpacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RCColor.background)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
