import SwiftUI
import DesignSystem

/// PROVISIONAL Terms of Use / Privacy Policy sheet until the real documents and their URLs exist
/// (the privacy policy is required before release, see CLAUDE.md §3).
struct LegalDocumentView: View {
    enum Document: String, Identifiable {
        case terms = "Terms of Use"
        case privacy = "Privacy Policy"
        var id: String { rawValue }
    }

    let document: Document
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("The \(document.rawValue) will be published here before release.")
                    .font(RCFont.body)
                    .foregroundStyle(RCColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(RCSpacing.m)
            }
            .navigationTitle(document.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
