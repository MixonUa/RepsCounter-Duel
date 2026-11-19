import SwiftUI
import DesignSystem

/// Top part of an intro slide: title, subtitle, illustration and tips. The page dots and
/// Continue button live in `IntroPagerView` so they stay fixed while slides swipe.
struct IntroSlideView: View {
    let slide: IntroSlide

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, RCSpacing.xxl + RCSpacing.xxs)
            Spacer(minLength: RCSpacing.m)
            illustration
            Spacer(minLength: RCSpacing.m)
            if !slide.tips.isEmpty {
                tipsCard
                    .padding(.horizontal, RCSpacing.m)
            }
        }
    }

    private var header: some View {
        VStack(spacing: RCSpacing.xs + 2) {
            OnboardingTitle(slide.titleLine, accent: slide.accentTitleLine)

            Text(slide.subtitle)
                .font(RCFont.onboardingSubtitle)
                .foregroundStyle(RCColor.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, RCSpacing.xl)
    }

    @ViewBuilder
    private var illustration: some View {
        switch slide.illustration {
        case .viewfinder(let imageName):
            viewfinderIllustration(imageName)
        case .plain(let imageName, let width):
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: width, maxHeight: width)
                .padding(.horizontal, RCSpacing.xxl)
                .accessibilityLabel(slide.imageAccessibilityLabel)
        }
    }

    /// FIGMA: 320×260 viewfinder, illustration ≈ 81% of its width, aligned to the top.
    private func viewfinderIllustration(_ imageName: String) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                RCViewfinderCorners()
                    .stroke(RCColor.viewfinder, style: StrokeStyle(lineWidth: 5, lineJoin: .round))
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width * 0.81)
                    .accessibilityLabel(slide.imageAccessibilityLabel)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(320 / 260, contentMode: .fit)
        .frame(maxWidth: 320, maxHeight: 260)
        .padding(.horizontal, RCSpacing.xxl)
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(slide.tips) { tip in
                HStack(spacing: RCSpacing.s) {
                    Image(systemName: tip.systemImage)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(RCColor.accent)
                        .frame(width: 22)
                        .accessibilityHidden(true)
                    Text(tip.text)
                        .font(RCFont.tip)
                        .foregroundStyle(RCColor.textPrimary)
                }
                .frame(minHeight: RCSize.minTouchTarget)
            }
        }
        .padding(.horizontal, RCSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: RCRadius.card, style: .continuous))
    }
}

#Preview {
    IntroSlideView(slide: .introPushUp)
        .rcGradientBackground()
}

#Preview("Slide 2") {
    IntroSlideView(slide: .introSetUpPath)
        .rcGradientBackground()
}
