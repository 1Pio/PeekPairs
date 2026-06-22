import PeekPairsCore
import SwiftUI

struct MemoryCardView: View {
    let card: MemoryCard
    let appearanceToken: Int
    let appearanceDelay: TimeInterval
    let onSelect: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isHovering = false
    @State private var isPressing = false
    @State private var hasAppeared = false
    @State private var appearanceTask: Task<Void, Never>?
    @State private var keepsFaceContentVisible = false
    @State private var faceContentTask: Task<Void, Never>?
    @State private var lastVisibility: CardVisibility?
    @State private var flipProgress: CGFloat = 0
    @State private var entranceLift = false
    @State private var revealLift = false
    @State private var revealGlintProgress: CGFloat = 1
    @State private var mismatchImpulse: CGFloat = 0
    @State private var matchFlourishProgress: CGFloat = 1
    @State private var revealTask: Task<Void, Never>?
    @State private var matchTask: Task<Void, Never>?

    private var isRemoved: Bool {
        card.visibility == .removed
    }

    var body: some View {
        Button {
            onSelect()
        } label: {
            ZStack {
                CardBackView()
                    .opacity(showsFace ? 0 : 1)
                    .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.66)

                CardFaceView(
                    assetName: card.assetName,
                    isMatched: card.visibility == .matched,
                    rendersFigure: rendersFaceContent
                )
                    .opacity(showsFace ? 1 : 0)
                    .rotation3DEffect(.degrees(flipAngle - 180), axis: (x: 0, y: 1, z: 0), perspective: 0.66)
            }
            .overlay {
                if revealGlintProgress < 1 {
                    CardRevealGlintView(progress: revealGlintProgress)
                }
            }
            .overlay {
                if matchFlourishProgress < 1 {
                    CardMatchedFlourishView(progress: matchFlourishProgress)
                }
            }
            .scaleEffect(currentScale)
            .rotationEffect(.degrees(currentRotation))
            .modifier(CardRecoilEffect(impulse: mismatchImpulse))
            .opacity(isRemoved ? 0 : (hasAppeared ? 1 : 0))
            .offset(x: currentOffset.width, y: currentOffset.height)
            .animation(CardMotionTiming.remove, value: card.visibility)
            .animation(CardMotionTiming.quickSettle, value: isHovering)
            .animation(CardMotionTiming.quickSettle, value: isPressing)
            .animation(CardMotionTiming.depthPulse, value: revealLift)
        }
        .buttonStyle(.plain)
        .disabled(!card.isSelectable)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard card.isSelectable else { return }
                    isPressing = true
                }
                .onEnded { _ in
                    isPressing = false
                }
        )
        .onHover { isInside in
            isHovering = isInside && card.isSelectable
        }
        .onAppear {
            lastVisibility = card.visibility
            flipProgress = faceUpProgress(for: card.visibility)
            resetFaceContentRetention()
            playAppearanceAnimation()
        }
        .onChange(of: appearanceToken) {
            lastVisibility = card.visibility
            flipProgress = faceUpProgress(for: card.visibility)
            resetTransientMotion()
            resetFaceContentRetention()
            playAppearanceAnimation()
        }
        .onChange(of: card.visibility) {
            let previousVisibility = lastVisibility
            lastVisibility = card.visibility
            updateFaceContentRetention(for: card.visibility)
            playMotion(from: previousVisibility, to: card.visibility)
            if !card.isSelectable {
                isHovering = false
                isPressing = false
            }
        }
        .onDisappear {
            appearanceTask?.cancel()
            appearanceTask = nil
            faceContentTask?.cancel()
            faceContentTask = nil
            revealTask?.cancel()
            revealTask = nil
            matchTask?.cancel()
            matchTask = nil
        }
        .accessibilityIdentifier("card-\(card.id)")
    }

    private var removedScale: CGFloat {
        isRemoved ? 0.34 : 1
    }

    private var currentScale: CGFloat {
        let pressScale = isPressing ? 0.965 : 1
        let hoverScale = isHovering ? 1.018 : 1
        let revealScale = revealLift ? 1.045 : 1
        let entranceBaseScale = hasAppeared ? 1 : 0.72
        let entranceLiftScale = entranceLift ? 1.045 : 1
        return removedScale * pressScale * hoverScale * revealScale * entranceBaseScale * entranceLiftScale
    }

    private var rendersFaceContent: Bool {
        card.isFaceUp || keepsFaceContentVisible || flipProgress > 0.001
    }

    private var clampedFlipProgress: CGFloat {
        min(max(flipProgress, 0), 1)
    }

    private var flipAngle: Double {
        Double(clampedFlipProgress) * 180
    }

    private var showsFace: Bool {
        clampedFlipProgress >= 0.5
    }

    private var currentRotation: CGFloat {
        if isRemoved {
            return CGFloat((card.id % 5) - 2) * 4.5
        }

        if isPressing {
            return CGFloat((card.id % 3) - 1) * 0.9
        }

        return 0
    }

    private var currentOffset: CGSize {
        if isRemoved {
            return CGSize(width: 0, height: 5)
        }

        return .zero
    }

    private func playAppearanceAnimation() {
        appearanceTask?.cancel()
        hasAppeared = false
        entranceLift = false

        appearanceTask = Task { @MainActor in
            await sleepForAppearanceDelay()
            guard !Task.isCancelled else { return }

            withAnimation(reduceMotion ? .smooth(duration: 0.16) : CardMotionTiming.entrance) {
                hasAppeared = true
                entranceLift = !reduceMotion
            }

            guard !reduceMotion else { return }
            try? await Task.sleep(nanoseconds: 140_000_000)
            guard !Task.isCancelled else { return }

            withAnimation(CardMotionTiming.depthPulse) {
                entranceLift = false
            }
        }
    }

    private func sleepForAppearanceDelay() async {
        guard appearanceDelay > 0 else { return }
        let nanoseconds = UInt64(appearanceDelay * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    private func updateFaceContentRetention(for visibility: CardVisibility) {
        faceContentTask?.cancel()

        switch visibility {
        case .revealed, .matched:
            keepsFaceContentVisible = true
        case .hidden:
            clearFaceContent(after: 0.26)
        case .removed:
            clearFaceContent(after: 0.46)
        }
    }

    private func resetFaceContentRetention() {
        faceContentTask?.cancel()
        faceContentTask = nil
        keepsFaceContentVisible = card.isFaceUp
    }

    private func resetTransientMotion() {
        revealTask?.cancel()
        revealTask = nil
        matchTask?.cancel()
        matchTask = nil
        isHovering = false
        isPressing = false
        entranceLift = false
        revealLift = false
        revealGlintProgress = 1
        matchFlourishProgress = 1
    }

    private func playMotion(from oldVisibility: CardVisibility?, to newVisibility: CardVisibility) {
        updateFlipProgress(to: newVisibility)

        guard !reduceMotion else { return }

        if oldVisibility == .hidden && (newVisibility == .revealed || newVisibility == .matched) {
            playRevealMotion()
        }

        if oldVisibility == .revealed && newVisibility == .hidden {
            playMismatchMotion()
        }

        if newVisibility == .matched {
            playMatchMotion()
        }
    }

    private func updateFlipProgress(to visibility: CardVisibility) {
        let targetProgress = faceUpProgress(for: visibility)
        guard abs(flipProgress - targetProgress) > 0.001 else { return }

        let isRevealing = targetProgress > flipProgress
        let animation: Animation = if reduceMotion {
            .smooth(duration: 0.12)
        } else {
            isRevealing ? CardMotionTiming.revealFlip : CardMotionTiming.hideFlip
        }

        withAnimation(animation) {
            flipProgress = targetProgress
        }
    }

    private func faceUpProgress(for visibility: CardVisibility) -> CGFloat {
        switch visibility {
        case .revealed, .matched:
            return 1
        case .hidden, .removed:
            return 0
        }
    }

    private func playRevealMotion() {
        revealTask?.cancel()
        revealLift = true
        revealGlintProgress = 0

        withAnimation(.smooth(duration: 0.28)) {
            revealGlintProgress = 1
        }

        revealTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 130_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(CardMotionTiming.depthPulse) {
                revealLift = false
            }
        }
    }

    private func playMismatchMotion() {
        withAnimation(.smooth(duration: 0.34)) {
            mismatchImpulse += 1
        }
    }

    private func playMatchMotion() {
        matchTask?.cancel()
        matchFlourishProgress = 0

        matchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 70_000_000)
            guard !Task.isCancelled else { return }

            withAnimation(CardMotionTiming.matchSettle) {
                matchFlourishProgress = 1
            }
        }
    }

    private func clearFaceContent(after delay: TimeInterval) {
        keepsFaceContentVisible = true
        faceContentTask = Task { @MainActor in
            let nanoseconds = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            keepsFaceContentVisible = false
        }
    }
}

extension MemoryCardView: Equatable {
    nonisolated static func == (lhs: MemoryCardView, rhs: MemoryCardView) -> Bool {
        lhs.card == rhs.card
            && lhs.appearanceToken == rhs.appearanceToken
            && lhs.appearanceDelay == rhs.appearanceDelay
    }
}

private struct CardBackView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.13, green: 0.18, blue: 0.22),
                        Color(red: 0.08, green: 0.10, blue: 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.11),
                                Color.white.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            }
            .overlay {
                CardBackMark()
            }
    }
}

private struct CardBackMark: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                .frame(width: 20, height: 20)

            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.25))
                .frame(width: 3, height: 13)

            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.25))
                .frame(width: 13, height: 3)
        }
    }
}

private struct CardFaceView: View {
    let assetName: String
    let isMatched: Bool
    let rendersFigure: Bool

    var body: some View {
        if rendersFigure {
            faceContent
        } else {
            Color.clear
        }
    }

    private var faceContent: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.095, blue: 0.11),
                        Color(red: 0.045, green: 0.055, blue: 0.07)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isMatched ? 0.13 : 0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .blendMode(.screen)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isMatched ? Color.mint.opacity(0.74) : Color.white.opacity(0.18), lineWidth: isMatched ? 2 : 1)
            }
            .overlay {
                CardFigureImage(assetName: assetName)
                    .padding(8)
                    .shadow(color: .white.opacity(0.16), radius: 4)
            }
    }
}

private struct CardFigureImage: View {
    let assetName: String
    @ObservedObject private var store = CardFigureImageStore.shared

    var body: some View {
        if let image = store.image(named: assetName) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "sparkle")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white.opacity(0.74))
        }
    }
}
