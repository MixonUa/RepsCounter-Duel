import SwiftUI
import DesignSystem
import ExerciseAnalyzer

// Shared overlay pieces for the camera screens (live duel, training).

/// FIGMA: 37 pt circle with "YOU" or the opponent's initials; outlined (dark fill + colored ring)
/// during the countdown and for the opponent.
struct DuelBadge: View {
    let text: String
    let color: Color
    let isOutlined: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: 37, height: 37)
            .background(color.opacity(isOutlined ? 0.3 : 0.45), in: Circle())
            .overlay {
                if isOutlined { Circle().strokeBorder(color, lineWidth: 2) }
            }
            .accessibilityHidden(true)
    }
}

/// FIGMA: 179 pt dark circle with an accent ring, the big number and "GET READY".
struct CountdownCircle: View {
    let value: Int

    var body: some View {
        VStack(spacing: RCSpacing.xxs) {
            Text("\(value)")
                .font(.system(size: 80, weight: .black))
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
            Text("GET READY")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RCColor.accent)
        }
        .offset(y: 8)
        .frame(width: 179, height: 179)
        .background(.black.opacity(0.6), in: Circle())
        .overlay(Circle().strokeBorder(RCColor.accent, lineWidth: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Get ready, \(value)")
    }
}

extension View {
    /// FIGMA: dark translucent rounded panel at the bottom of the camera.
    func duelPanelBackground() -> some View {
        background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 38, style: .continuous))
            .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 38, style: .continuous))
    }
}

/// FIGMA skeleton over the camera: white bones (4 pt) and black joints with a white ring, only
/// for the joints the exercise uses. Coordinates follow the preview's aspect-fill crop.
struct PoseSkeletonOverlay: View {
    let pose: PoseFrame?
    let exercise: Exercise
    var minConfidence = 0.3

    var body: some View {
        Canvas { context, size in
            guard let pose, !pose.joints.isEmpty else { return }
            let aspect = CGFloat(pose.imageAspectRatio)
            // Aspect fill: the image (aspect × 1) scaled to cover the view, centered.
            let scale = max(size.width / aspect, size.height)
            let offset = CGPoint(x: (size.width - aspect * scale) / 2, y: (size.height - scale) / 2)
            func point(_ joint: BodyJoint) -> CGPoint? {
                guard let p = pose.point(joint, minConfidence: minConfidence) else { return nil }
                return CGPoint(x: offset.x + CGFloat(p.x) * aspect * scale, y: offset.y + CGFloat(p.y) * scale)
            }
            var bones = Path()
            for (a, b) in exercise.skeletonBones {
                guard let start = point(a), let end = point(b) else { continue }
                bones.move(to: start)
                bones.addLine(to: end)
            }
            context.stroke(bones, with: .color(.white), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            for joint in exercise.skeletonJoints {
                guard let center = point(joint) else { continue }
                let outer = CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)
                context.fill(Path(ellipseIn: outer), with: .color(.white))
                context.fill(Path(ellipseIn: outer.insetBy(dx: 4, dy: 4)), with: .color(.black))
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// PROVISIONAL (no Figma frame): distance-readable tracking hint above the bottom panel
/// ("Move back", "Full body not visible", …). Never shown as a rep.
struct PoseFeedbackBadge: View {
    let feedback: PoseFeedback?

    var body: some View {
        if let feedback {
            Label(feedback.message, systemImage: feedback == .goLower ? "arrow.down" : "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, RCSpacing.l)
                .padding(.vertical, RCSpacing.s)
                .background(.black.opacity(0.65), in: Capsule())
                .transition(.scale.combined(with: .opacity))
                .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
