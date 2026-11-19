import SwiftUI
import Backend
import DesignSystem

/// FIGMA "Set a duel time" (duel flow, after Choose a Friend): − / + change the time in 10-second
/// steps; the "Time" card holds single-choice presets (1 / 2 / 3 / 5 / 10 min). A value that is
/// not a preset deselects the card, and Send Challenge stays enabled.
struct DuelTimeView: View {
    let onBack: () -> Void
    let onClose: () -> Void
    let onSend: (DuelDuration) -> Void

    @State private var duration = DuelDuration.default

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                RCBackButton(action: onBack)
                Spacer()
                ActivityCloseButton(action: onClose)
            }
            .padding(.horizontal, RCSpacing.m)
            .padding(.top, RCSpacing.m)

            Text("Set a duel time")
                .font(RCFont.homeTitle)
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, RCSpacing.l)
            Text("The timer will show when the competition ends")
                .font(.system(size: 17))
                .tracking(-0.4)
                .foregroundStyle(RCColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RCSpacing.m)
                .padding(.top, RCSpacing.xs)

            Spacer(minLength: RCSpacing.l)

            stepper

            Spacer(minLength: RCSpacing.l)

            presets
                .padding(.horizontal, RCSpacing.l)

            Spacer(minLength: RCSpacing.l)

            Button("Send Challenge") { onSend(duration) }
                .buttonStyle(.rcPrimaryLarge)
                .padding(.horizontal, RCSpacing.l)
                .padding(.bottom, RCSpacing.xxs)
        }
        .background(RCColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: duration)
    }

    // MARK: - Seconds stepper

    /// FIGMA: gray "Seconds", big black number between 65 pt accent − / + circles.
    private var stepper: some View {
        VStack(spacing: RCSpacing.l) {
            Text("Seconds")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(RCColor.textSecondary)
            HStack(spacing: 0) {
                stepButton("minus", label: "Decrease by 10 seconds", isEnabled: duration.canDecrement) {
                    duration = duration.decremented()
                }
                Text("\(duration.seconds)")
                    .font(.system(size: 90, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(RCColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: Double(duration.seconds)))
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(duration.displayName)
                stepButton("plus", label: "Increase by 10 seconds", isEnabled: duration.canIncrement) {
                    duration = duration.incremented()
                }
            }
            .padding(.horizontal, 40)
        }
        .animation(.snappy, value: duration)
    }

    private func stepButton(_ symbol: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 65, height: 65)
                .background(RCColor.accent, in: Circle())
                .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }

    // MARK: - Presets

    /// FIGMA "Time": white card with 51 pt gray circles; the selected one is light blue with an
    /// accent ring and accent text.
    private var presets: some View {
        VStack(alignment: .leading, spacing: RCSpacing.s) {
            Text("Time")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(RCColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 0) {
                ForEach(DuelDuration.presets) { preset in
                    presetButton(preset)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, RCSpacing.xs)
            .padding(.vertical, RCSpacing.m)
            .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private func presetButton(_ preset: DuelDuration) -> some View {
        let isSelected = preset == duration
        return Button {
            withAnimation(.snappy) { duration = preset }
        } label: {
            VStack(spacing: RCSpacing.xs) {
                Text("\(preset.wholeMinutes ?? 0)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? RCColor.accent : RCColor.textSecondary)
                    .frame(width: 51, height: 51)
                    .background(isSelected ? RCColor.friendAvatarFill : RCColor.pendingFill, in: Circle())
                    .overlay {
                        if isSelected { Circle().strokeBorder(RCColor.accent, lineWidth: 2) }
                    }
                Text(preset.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? RCColor.accent : RCColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preset.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    DuelTimeView(onBack: {}, onClose: {}, onSend: { _ in })
}
