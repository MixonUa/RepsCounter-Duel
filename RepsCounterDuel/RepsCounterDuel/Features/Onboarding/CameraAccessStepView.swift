import SwiftUI
import DesignSystem

/// FIGMA "Allow Access To Your Camera" → system camera alert.
/// Granted → onboarding ends. Denied → the same screen switches to "Access to the Camera is
/// Restricted" with Open Settings; the user can't continue without camera access (CLAUDE.md §3).
/// Returning from Settings re-checks the permission (iOS usually relaunches the app after a
/// permission change; onboarding then resumes on this step).
struct CameraAccessStepView: View {
    let permission: any CameraPermissionProviding
    let onGranted: () -> Void

    @State private var isDenied = false
    @State private var isRequesting = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, RCSpacing.xxl + RCSpacing.xxs)
                .padding(.horizontal, RCSpacing.m)

            // Illustrations are 3x exports at their natural size, drawn over this flexible area
            // so they never push the dots and button.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) { illustration }

            RCPageIndicator(count: 3, current: 2)
                .opacity(isDenied ? 0 : 1)
                .padding(.top, RCSpacing.xxl)
                .padding(.bottom, RCSpacing.m)

            button
                .padding(.horizontal, RCSpacing.xl)
                .padding(.bottom, RCSpacing.xxs)
        }
        .animation(.snappy, value: isDenied)
        .onAppear(perform: refresh)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() }
        }
    }

    private var header: some View {
        VStack(spacing: RCSpacing.xs + 2) {
            if isDenied {
                OnboardingTitle("Access to the", accent: "Camera is Restricted", accentColor: RCColor.textPrimary)
                subtitle("Please allow access to the camera, this is\nnecessary for the application to work")
            } else {
                OnboardingTitle("Allow Access", accent: "To Your Camera")
                subtitle("Required to activate smart\ntracker of your training.")
            }
        }
        .transition(.opacity)
        .id(isDenied)
    }

    private func subtitle(_ text: String) -> some View {
        Text(text)
            .font(RCFont.onboardingSubtitle)
            .foregroundStyle(RCColor.textSecondary)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// FIGMA offsets below the subtitle: phone 15 pt, alert card 74 pt; restricted phone 29 pt.
    @ViewBuilder
    private var illustration: some View {
        if isDenied {
            Image("CameraAccessDeniedPhone")
                .padding(.top, 29)
                .accessibilityLabel("Settings with the camera switch turned on for Reps Counter")
                .transition(.opacity)
        } else {
            ZStack(alignment: .top) {
                Image("CameraAccessPhone")
                    .padding(.top, 15)
                Image("CameraAccessAlert")
                    .padding(.top, 74)
            }
            .accessibilityElement()
            .accessibilityLabel("Camera access alert with the Allow button")
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var button: some View {
        if isDenied {
            Button(action: openSettings) {
                HStack(spacing: RCSpacing.s) {
                    // Generic gear tile (the Settings app icon itself is Apple's artwork).
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            LinearGradient(colors: [Color(white: 0.62), Color(white: 0.42)], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                        )
                        .accessibilityHidden(true)
                    Text("Open Settings")
                }
            }
            .buttonStyle(.rcPrimaryLarge)
        } else {
            Button(action: request) {
                if isRequesting {
                    ProgressView().tint(.white)
                } else {
                    Text("Continue")
                }
            }
            .buttonStyle(.rcPrimaryLarge)
            .disabled(isRequesting)
        }
    }

    private func refresh() {
        switch permission.status {
        case .authorized: onGranted()
        case .denied: isDenied = true
        case .notDetermined: isDenied = false
        }
    }

    private func request() {
        guard !isRequesting else { return }
        switch permission.status {
        case .authorized:
            onGranted()
        case .denied:
            isDenied = true
        case .notDetermined:
            isRequesting = true
            Task {
                let granted = await permission.requestAccess()
                isRequesting = false
                if granted { onGranted() } else { isDenied = true }
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

#Preview {
    struct PreviewPermission: CameraPermissionProviding {
        var status: CameraPermissionStatus { .notDetermined }
        func requestAccess() async -> Bool { false }
    }
    return CameraAccessStepView(permission: PreviewPermission(), onGranted: {})
        .rcGradientBackground()
}
