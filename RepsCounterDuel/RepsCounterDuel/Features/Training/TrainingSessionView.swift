import SwiftUI
import DesignSystem
import ExerciseAnalyzer

/// FIGMA training ("<Exercise> · Practice"): overlays on the full-screen front camera, no timer.
/// - Setup: top bar with the YOU badge and "No timer — stop when you want"; bottom panel
///   "GET IN FRAME / <Exercise> / Step back so your whole body fits" with Start.
/// - Start hides the button, a 3 · 2 · 1 counter appears in the middle and the panels switch:
///   top bar with ✕ and the centered title, bottom panel "REPS", the count and Finish.
/// PROVISIONAL (not in Figma): ✕ in the setup bar to leave before starting; ✕ leaves without a
/// result (Finish opens the result); Finish is disabled during the countdown.
/// UI stage: reps are not counted yet (stage 3; DEBUG: tap the number) and there is no pose
/// skeleton.
struct TrainingSessionView: View {
    let exercise: Exercise
    /// Finish: `reps` is the session's count (the result screen follows).
    let onFinish: (_ reps: Int) -> Void
    /// ✕: leave without a result.
    let onClose: () -> Void

    private enum Phase: Equatable {
        case setup
        case countdown(Int)
        case active
    }

    @State private var phase: Phase = .setup
    @State private var reps = 0

    private var isStarted: Bool { phase != .setup }

    var body: some View {
        ZStack {
            CameraPreview()

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }
            .padding(.horizontal, isStarted ? 12 : 6)
            .padding(.vertical, 6)
            .ignoresSafeArea()

            if case .countdown(let value) = phase {
                CountdownCircle(value: value)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .animation(.snappy, value: phase)
        .sensoryFeedback(.impact(weight: .heavy), trigger: phase)
    }

    // MARK: - Top bar

    private var title: String { "\(exercise.displayName) · Practice" }

    @ViewBuilder
    private var topBar: some View {
        Group {
            if isStarted {
                ZStack {
                    titleBlock(alignment: .center)
                    HStack {
                        closeButton
                        Spacer()
                    }
                }
            } else {
                HStack(spacing: RCSpacing.s) {
                    DuelBadge(text: "YOU", color: RCColor.accent, isOutlined: true)
                    titleBlock(alignment: .leading)
                    Spacer(minLength: 0)
                    // PROVISIONAL: Figma has no way out before Start.
                    closeButton
                }
            }
        }
        .padding(.horizontal, RCSpacing.m)
        .padding(.top, 48)
        .padding(.bottom, RCSpacing.l)
        .frame(maxWidth: .infinity)
        .background(.black, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
    }

    private func titleBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            Text("No timer — stop when you want")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.75))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .multilineTextAlignment(alignment == .center ? .center : .leading)
        .padding(.horizontal, isStarted ? RCSpacing.xxl : 0)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close training")
    }

    // MARK: - Bottom panel

    @ViewBuilder
    private var bottomPanel: some View {
        if isStarted {
            VStack(spacing: 0) {
                Text("REPS")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RCColor.accent)
                Text("\(reps)")
                    .font(.system(size: 96, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(reps)))
                    .accessibilityLabel("Reps: \(reps)")
                    .onTapGesture { debugAddRep() }
                Button("Finish") { onFinish(reps) }
                    .buttonStyle(.rcPrimaryLarge)
                    .disabled(phase != .active)
                    .padding(.horizontal, RCSpacing.m)
                    .padding(.top, RCSpacing.s)
            }
            .padding(.top, RCSpacing.l)
            .padding(.bottom, RCSpacing.xl)
            .frame(maxWidth: .infinity)
            .duelPanelBackground()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            VStack(spacing: RCSpacing.xxs) {
                Text("GET IN FRAME")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RCColor.accent)
                Text(exercise.displayName)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                Text("Step back so your whole body fits")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                Button("Start", action: start)
                    .buttonStyle(.rcPrimaryLarge)
                    .padding(.horizontal, RCSpacing.m)
                    .padding(.top, RCSpacing.m)
            }
            .padding(.top, RCSpacing.l)
            .padding(.bottom, RCSpacing.xl)
            .frame(maxWidth: .infinity)
            .duelPanelBackground()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Timeline

    private func start() {
        guard phase == .setup else { return }
        Task {
            for value in stride(from: 3, through: 1, by: -1) {
                phase = .countdown(value)
                try? await Task.sleep(for: .seconds(1))
            }
            phase = .active
        }
    }

    private func debugAddRep() {
        #if DEBUG
        guard phase == .active else { return }
        reps += 1
        #endif
    }
}

#Preview {
    TrainingSessionView(exercise: .squats, onFinish: { _ in }, onClose: {})
}
