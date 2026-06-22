import SwiftUI

enum CardMotionTiming {
    static let revealFlip = Animation.interactiveSpring(response: 0.19, dampingFraction: 0.74, blendDuration: 0.01)
    static let hideFlip = Animation.interactiveSpring(response: 0.31, dampingFraction: 0.82, blendDuration: 0.02)
    static let quickSettle = Animation.interactiveSpring(response: 0.18, dampingFraction: 0.72, blendDuration: 0.01)
    static let matchSettle = Animation.bouncy(duration: 0.38, extraBounce: 0.16)
    static let remove = Animation.timingCurve(0.18, 0.88, 0.24, 1, duration: 0.34)
    static let entrance = Animation.bouncy(duration: 0.48, extraBounce: 0.16)
}

struct CardDepthLiftEffect: GeometryEffect {
    var progress: CGFloat
    var maxDepth: CGFloat = 34

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard progress > 0.001 else { return ProjectionTransform(.identity) }

        var transform = CATransform3DIdentity
        transform.m34 = -1 / 760
        transform = CATransform3DTranslate(transform, 0, -progress * 2.4, progress * maxDepth)

        return ProjectionTransform(transform)
    }
}

struct CardRecoilEffect: GeometryEffect {
    var impulse: CGFloat
    var distance: CGFloat = 5

    var animatableData: CGFloat {
        get { impulse }
        set { impulse = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let progress = impulse.truncatingRemainder(dividingBy: 1)
        guard progress > 0.001 else { return ProjectionTransform(.identity) }

        let falloff = max(0, 1 - progress)
        let x = sin(progress * .pi * 4) * distance * falloff
        let y = sin(progress * .pi * 2) * distance * 0.28 * falloff

        return ProjectionTransform(CGAffineTransform(translationX: x, y: y))
    }
}

struct CardRevealGlintView: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let travel = side * 1.7

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.58),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: max(5, side * 0.11), height: side * 1.55)
                .rotationEffect(.degrees(28))
                .offset(x: -travel / 2 + (travel * progress), y: -side * 0.28)
                .opacity(progress < 1 ? 0.55 : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .allowsHitTesting(false)
    }
}

struct CardMatchedFlourishView: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.mint.opacity(0.62 * (1 - progress)), lineWidth: max(0.8, 2 - progress))
                .scaleEffect(0.94 + (progress * 0.22))

            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(dotOpacity))
                    .frame(width: 4, height: 4)
                    .offset(dotOffset(for: index))
                    .scaleEffect(0.24 + (0.76 * dotOpacity))
            }
        }
        .allowsHitTesting(false)
    }

    private var dotOpacity: CGFloat {
        max(0, sin(progress * .pi)) * 0.72
    }

    private func dotOffset(for index: Int) -> CGSize {
        let distance: CGFloat = 4 + (progress * 20)
        switch index {
        case 0:
            return CGSize(width: -distance, height: -distance * 0.72)
        case 1:
            return CGSize(width: distance, height: -distance * 0.72)
        case 2:
            return CGSize(width: -distance * 0.78, height: distance)
        default:
            return CGSize(width: distance * 0.78, height: distance)
        }
    }
}
