/// UserDefaults keys for UI-stage local state (stage 1 moves the profile to the server).
enum LocalStorageKeys {
    /// Nickname / emoji saved after registration and changed in Edit Profile.
    static let nickname = "onboardingRegisteredNickname"
    static let emoji = "onboardingRegisteredEmoji"
    static let onboardingResumeStep = "onboardingResumeStep"
    /// Set on first launch; its absence means a fresh install (Keychain session is dropped).
    static let installMarker = "installMarker"

    /// Settings → Rep sound (Bool, default on).
    static let repSound = "settingsRepSound"
    /// Settings → First day of the week (2 = Monday, 1 = Sunday).
    static let firstWeekday = "settingsFirstWeekday"

    /// Training totals and per-exercise records (JSON `TrainingProgress`), until SwiftData (stage 3).
    static let trainingProgress = "trainingProgress"
}

/// Links used by Settings and the paywall. PROVISIONAL: nil until they exist.
enum AppLinks {
    static let supportEmail: String? = nil
    static let appStoreURL: String? = nil
    static let shareMessage = "Join me in Reps Counter — let's duel in squats and push-ups!"
}
