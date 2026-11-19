import Foundation
import Supabase

/// Connection settings for the Supabase project.
///
/// Only the project URL and the public anon (publishable) key may ever live in the client —
/// never a service-role key. No project is configured yet (stage 1 adds the `dev` project).
public struct BackendConfiguration: Sendable {
    public let projectURL: URL
    public let anonKey: String

    public init(projectURL: URL, anonKey: String) {
        self.projectURL = projectURL
        self.anonKey = anonKey
    }

    public func makeClient() -> SupabaseClient {
        SupabaseClient(supabaseURL: projectURL, supabaseKey: anonKey)
    }
}
