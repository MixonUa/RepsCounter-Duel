import SwiftUI
import AVFoundation
import DesignSystem

/// Full-screen live front camera (mirrored like a selfie) with a dark fallback when the camera
/// is unavailable (Simulator), denied or paused. Starts on appear and stops on disappear.
struct CameraPreview: View {
    @State private var camera = FrontCameraSession()
    @State private var state: FrontCameraSession.State = .idle

    var body: some View {
        ZStack {
            Color.black
            PreviewLayerView(session: camera.session)
                .opacity(state == .running ? 1 : 0)
            if let message {
                VStack(spacing: RCSpacing.s) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 34))
                    Text(message)
                        .font(.system(size: 17, weight: .medium))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, RCSpacing.xxl)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            camera.onStateChange = { newState in state = newState }
            camera.start()
        }
        .onDisappear { camera.stop() }
    }

    /// PROVISIONAL copy (no Figma frames for these states).
    private var message: String? {
        switch state {
        case .idle, .running: nil
        case .unavailable: "Camera is not available"
        case .denied: "Camera access is off. Allow it in Settings."
        case .interrupted: "Camera paused"
        }
    }
}

/// `AVCaptureVideoPreviewLayer` filling the view (aspect fill, portrait).
private struct PreviewLayerView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> LayerView {
        let view = LayerView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: LayerView, context: Context) {}

    final class LayerView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
