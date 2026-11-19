import SwiftUI
import DesignSystem

/// Swipeable slides with fixed page dots and Continue button at the bottom.
/// Continue moves to the next slide; on the last slide it calls `onFinish`.
struct IntroPagerView: View {
    let slides: [IntroSlide]
    /// Owned by the flow so that Back from the next step returns to the last slide.
    @Binding var page: Int
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(slides) { slide in
                    IntroSlideView(slide: slide)
                        .tag(slide.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            RCPageIndicator(count: slides.count, current: page)
                .padding(.top, RCSpacing.xxl)
                .padding(.bottom, RCSpacing.m)

            Button("Continue") {
                if page < slides.count - 1 {
                    withAnimation(.snappy) { page += 1 }
                } else {
                    onFinish()
                }
            }
            .buttonStyle(.rcPrimaryLarge)
            .padding(.horizontal, RCSpacing.xl)
            .padding(.bottom, RCSpacing.xxs)
        }
    }
}

#Preview {
    @Previewable @State var page = 0
    IntroPagerView(slides: [.introPushUp, .introSetUpPath], page: $page, onFinish: {})
        .rcGradientBackground()
}
