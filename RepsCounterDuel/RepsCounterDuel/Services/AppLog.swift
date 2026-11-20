import OSLog

/// Unified logging (Xcode console / Console.app). Never log nicknames or IDs as public data.
enum AppLog {
    static let backend = Logger(subsystem: "com.RepsCounter-Duel", category: "backend")
}

extension Error {
    /// True for transport problems (offline, timeout, DNS), not for server answers.
    var isNetworkError: Bool {
        if let urlError = self as? URLError {
            return [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
                    .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff]
                .contains(urlError.code)
        }
        return (self as NSError).domain == NSURLErrorDomain
    }
}
