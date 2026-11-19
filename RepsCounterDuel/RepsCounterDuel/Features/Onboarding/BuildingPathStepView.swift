import SwiftUI
import DesignSystem

/// FIGMA explanation slide 2 "Building Your Personal Path": a short staged "preparing" animation.
/// Items finish one after another (pending → in progress → done); when all are done the flow
/// moves on by itself (there is no Continue button in Figma). Purely presentational.
struct BuildingPathStepView: View {
    let onFinished: () -> Void

    /// PROVISIONAL timing.
    static let stepDuration: Duration = .milliseconds(1100)
    static let finishDelay: Duration = .milliseconds(600)

    private struct Item: Identifiable {
        let systemImage: String
        let title: String
        var id: String { title }
    }

    private let items = [
        Item(systemImage: "person.crop.circle", title: "Analyzing Your Data"),
        Item(systemImage: "dot.viewfinder", title: "Preparing AI Tracking"),
        // Figma reads "Persanolising"; fixed spelling.
        Item(systemImage: "dumbbell.fill", title: "Personalising Your Plan"),
        Item(systemImage: "bolt.fill", title: "Creating Challenges"),
    ]

    /// Number of finished items; the item at this index is in progress.
    @State private var completed = 0

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: RCSpacing.xs + 2) {
                OnboardingTitle("Building Your", accent: "Personal Path")
                Text("Preparing your training plan,\nplease wait ...")
                    .font(RCFont.onboardingSubtitle)
                    .foregroundStyle(RCColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, RCSpacing.xxl)
            .padding(.horizontal, RCSpacing.m)

            Spacer(minLength: RCSpacing.m).frame(maxHeight: 53)

            BoltShape()
                .fill(LinearGradient(colors: [RCColor.boltTop, RCColor.boltBottom], startPoint: .top, endPoint: .bottom))
                // FIGMA: 132 × 147 visible; the frame is larger because rounded tips end short.
                .frame(width: 140, height: 164)
                .frame(width: 132, height: 147)
                .accessibilityHidden(true)

            Spacer(minLength: RCSpacing.m).frame(maxHeight: 48)

            checklist
                .padding(.horizontal, RCSpacing.m)

            Spacer(minLength: RCSpacing.m)
        }
        .task { await run() }
    }

    private var checklist: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: RCSpacing.s) {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(RCColor.accent)
                        .frame(width: 32)
                        .accessibilityHidden(true)
                    Text(item.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RCColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: RCSpacing.xs)
                    ChecklistStatus(number: index + 1, state: state(of: index))
                }
                .frame(height: 52)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(item.title), \(state(of: index).accessibilityName)")
            }
        }
        .padding(.leading, RCSpacing.xl - 4)
        .padding(.trailing, RCSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
    }

    private func state(of index: Int) -> ChecklistStatus.State {
        if index < completed { return .done }
        if index == completed { return .inProgress }
        return .pending
    }

    private func run() async {
        // Restarts from the beginning each time the slide appears (e.g. after Back).
        completed = 0
        for _ in items {
            try? await Task.sleep(for: Self.stepDuration)
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) { completed += 1 }
        }
        try? await Task.sleep(for: Self.finishDelay)
        guard !Task.isCancelled else { return }
        onFinished()
    }
}

/// FIGMA: 28 pt status circle — gray with a number (pending), gray with a spinning accent arc
/// (in progress), accent with a white check (done).
private struct ChecklistStatus: View {
    enum State {
        case pending, inProgress, done

        var accessibilityName: String {
            switch self {
            case .pending: "waiting"
            case .inProgress: "in progress"
            case .done: "done"
            }
        }
    }

    let number: Int
    let state: State
    @SwiftUI.State private var isSpinning = false

    var body: some View {
        ZStack {
            if state == .done {
                Circle().fill(RCColor.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Circle().fill(RCColor.statusPendingFill)
                Text("\(number)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(RCColor.statusPendingText)
                if state == .inProgress {
                    Circle()
                        .trim(from: 0, to: 0.6)
                        .stroke(RCColor.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .padding(-1)
                        .rotationEffect(.degrees(isSpinning ? 360 : 0))
                        .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: isSpinning)
                        .onAppear { isSpinning = true }
                        .onDisappear { isSpinning = false }
                }
            }
        }
        .frame(width: 28, height: 28)
    }
}

/// FIGMA: rounded lightning bolt (traced from the export, coordinates in a unit square).
private struct BoltShape: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [CGPoint] = [
            CGPoint(x: 0.597, y: 0.006),  // top tip
            CGPoint(x: 0.006, y: 0.559),  // left point
            CGPoint(x: 0.490, y: 0.603),  // inner lower-left
            CGPoint(x: 0.400, y: 0.994),  // bottom tip
            CGPoint(x: 0.994, y: 0.455),  // right point
            CGPoint(x: 0.497, y: 0.386),  // inner upper-right
        ].map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }

        // Rounded corners: each corner is replaced by a tangent arc.
        var path = Path()
        // Small radius: a large one cuts the sharp tips short.
        let radius = min(rect.width, rect.height) * 0.025
        let count = points.count
        let start = CGPoint(
            x: (points[count - 1].x + points[0].x) / 2,
            y: (points[count - 1].y + points[0].y) / 2
        )
        path.move(to: start)
        for index in 0..<count {
            let corner = points[index]
            let next = points[(index + 1) % count]
            path.addArc(tangent1End: corner, tangent2End: next, radius: radius)
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    BuildingPathStepView(onFinished: {})
        .rcGradientBackground()
}
