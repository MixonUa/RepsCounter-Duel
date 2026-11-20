import Foundation
import Backend

/// Backend services for the whole app (stage 1: Supabase `dev` project).
/// Only the public project URL and anon key are in the client (CLAUDE.md §3); privileges come
/// from the signed-in anonymous user and Row Level Security on the server.
/// DEBUG: `-useMockBackend YES` swaps in the offline UI-stage mocks (admin = taken, offline = no
/// network).
enum AppServices {
    /// `reps-counter-dev` (eu-central-1). `prod` is created before beta.
    static let configuration = BackendConfiguration(
        projectURL: URL(string: "https://kreicqgbbrxeerzquiue.supabase.co")!,
        anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtyZWljcWdiYnJ4ZWVyenF1aXVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUxMzY4MDIsImV4cCI6MjExMDcxMjgwMn0.9EvCr1i-jCZORwYgirrYNNeU-xYQ3o5BW-pAVxsIdg0"
    )

    static let backend = SupabaseBackend(configuration: configuration, isFreshInstall: consumeFreshInstallMarker())

    static var nicknameChecker: any NicknameAvailabilityChecking {
        usesMocks ? MockNicknameAvailabilityService() : SupabaseNicknameAvailabilityService(backend: backend)
    }

    static var registrar: any ProfileRegistering {
        usesMocks ? MockProfileRegistrationService() : SupabaseProfileService(backend: backend)
    }

    static var profileUpdater: any ProfileUpdating {
        usesMocks ? MockProfileUpdateService() : SupabaseProfileService(backend: backend)
    }

    private static var usesMocks: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "useMockBackend")
        #else
        false
        #endif
    }

    /// iOS keeps Keychain items after the app is deleted, but wipes UserDefaults: a missing
    /// marker means a fresh install, so a leftover session must not restore the old account
    /// (CLAUDE.md §3 "Reinstall = new profile").
    private static func consumeFreshInstallMarker() -> Bool {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: LocalStorageKeys.installMarker) else { return false }
        defaults.set(true, forKey: LocalStorageKeys.installMarker)
        return true
    }
}
