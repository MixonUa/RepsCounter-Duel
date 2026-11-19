import AVFoundation

/// Camera access state as the app needs it.
enum CameraPermissionStatus: Equatable {
    case notDetermined
    case authorized
    /// Denied by the user or restricted (e.g. Screen Time) — only Settings can change it.
    case denied
}

/// Reads and requests camera permission. Part of the future CameraService (CLAUDE.md §4).
protocol CameraPermissionProviding: Sendable {
    var status: CameraPermissionStatus { get }
    /// Shows the system alert when the status is not determined yet.
    /// - Returns: `true` when access is granted.
    func requestAccess() async -> Bool
}

struct SystemCameraPermission: CameraPermissionProviding {
    var status: CameraPermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .authorized
        case .notDetermined: .notDetermined
        case .denied, .restricted: .denied
        @unknown default: .denied
        }
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
