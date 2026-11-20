import SwiftUI

@main
struct RepsCounter_DuelApp: App {
    init() {
        // Creates the backend early so the fresh-install check runs before any network call.
        _ = AppServices.backend
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
