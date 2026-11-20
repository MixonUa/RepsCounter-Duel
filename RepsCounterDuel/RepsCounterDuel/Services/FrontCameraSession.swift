import AVFoundation

/// Front camera capture session for the workout / duel screens (CLAUDE.md §3: front camera,
/// portrait, on-device only — nothing is recorded or uploaded).
/// Session configuration and start/stop run on a private serial queue, off the main actor.
/// With `frameDelegate` set, upright mirrored frames (as on screen) are delivered on
/// `videoQueue` for pose detection; late frames are dropped.
nonisolated final class FrontCameraSession: @unchecked Sendable {
    enum State: Equatable, Sendable {
        case idle
        case running
        /// No front camera (e.g. Simulator) or it could not be configured.
        case unavailable
        /// Camera permission is not granted.
        case denied
        /// iOS paused the camera (another app, phone call, multitasking).
        case interrupted
    }

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "RepsCounter.FrontCameraSession")
    private var isConfigured = false
    private var observers: [NSObjectProtocol] = []

    /// Receives camera frames on `videoQueue` (set before `start()`).
    var frameDelegate: (any AVCaptureVideoDataOutputSampleBufferDelegate)?
    let videoQueue = DispatchQueue(label: "RepsCounter.FrontCameraSession.video", qos: .userInitiated)

    /// Called on the main actor whenever the state changes.
    var onStateChange: (@MainActor @Sendable (State) -> Void)?

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func start() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            report(.denied)
            return
        }
        queue.async { [self] in
            if !isConfigured {
                guard configure() else { return report(.unavailable) }
            }
            if !session.isRunning { session.startRunning() }
            report(session.isRunning ? .running : .unavailable)
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
            report(.idle)
        }
    }

    /// Runs on `queue`.
    private func configure() -> Bool {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return false }
        session.beginConfiguration()
        session.sessionPreset = .high
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            return false
        }
        session.addInput(input)
        if let frameDelegate {
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            output.setSampleBufferDelegate(frameDelegate, queue: videoQueue)
            if session.canAddOutput(output) {
                session.addOutput(output)
                if let connection = output.connection(with: .video) {
                    // Portrait and mirrored like the preview, so joints match what the user sees.
                    if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
                    if connection.isVideoMirroringSupported {
                        connection.automaticallyAdjustsVideoMirroring = false
                        connection.isVideoMirrored = true
                    }
                }
            }
        }
        session.commitConfiguration()
        isConfigured = true

        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVCaptureSession.wasInterruptedNotification, object: session, queue: nil) { [weak self] _ in
            self?.report(.interrupted)
        })
        observers.append(center.addObserver(forName: AVCaptureSession.interruptionEndedNotification, object: session, queue: nil) { [weak self] _ in
            self?.report(.running)
        })
        return true
    }

    private func report(_ state: State) {
        guard let onStateChange else { return }
        Task { @MainActor in onStateChange(state) }
    }
}
