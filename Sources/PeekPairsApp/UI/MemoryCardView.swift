import PeekPairsCore
import SwiftUI

struct MemoryCardView: View {
    let card: MemoryCard
    let appearanceToken: Int
    let appearanceDelay: TimeInterval
    let onSelect: () -> Void

    @State private var isPressing = false
    @State private var hasAppeared = false
    @State private var appearanceTask: Task<Void, Never>?
    @State private var keepsFaceContentVisible = false
    @State private var faceContentTask: Task<Void, Never>?

    private var isRemoved: Bool {
        card.visibility == .removed
    }

    var body: some View {
        Button {
            onSelect()
        } label: {
            ZStack {
                CardBackView()
                    .opacity(card.isFaceUp ? 0 : 1)
                    .rotation3DEffect(.degrees(card.isFaceUp ? -180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.64)

                CardFaceView(
                    assetName: card.assetName,
                    isMatched: card.visibility == .matched,
                    rendersFigure: card.isFaceUp || keepsFaceContentVisible
                )
                    .opacity(card.isFaceUp ? 1 : 0)
                    .rotation3DEffect(.degrees(card.isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0), perspective: 0.64)
            }
            .scaleEffect(currentScale)
            .opacity(isRemoved ? 0 : (hasAppeared ? 1 : 0))
            .offset(x: hasAppeared ? 0 : -16, y: hasAppeared ? 0 : -10)
            .animation(.smooth(duration: 0.23), value: card.isFaceUp)
            .animation(.bouncy(duration: 0.42, extraBounce: 0.2), value: card.visibility)
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
        .onAppear {
            resetFaceContentRetention()
            playAppearanceAnimation()
        }
        .onChange(of: appearanceToken) {
            resetFaceContentRetention()
            playAppearanceAnimation()
        }
        .onChange(of: card.visibility) {
            updateFaceContentRetention(for: card.visibility)
        }
        .onDisappear {
            appearanceTask?.cancel()
            appearanceTask = nil
            faceContentTask?.cancel()
            faceContentTask = nil
        }
        .accessibilityIdentifier("card-\(card.id)")
    }

    private var removedScale: CGFloat {
        isRemoved ? 0.34 : 1
    }

    private var currentScale: CGFloat {
        let pressScale = isPressing ? 0.965 : 1
        let entranceScale = hasAppeared ? 1 : 0.82
        return removedScale * pressScale * entranceScale
    }

    private func playAppearanceAnimation() {
        appearanceTask?.cancel()
        hasAppeared = false

        appearanceTask = Task { @MainActor in
            await sleepForAppearanceDelay()
            guard !Task.isCancelled else { return }

            withAnimation(.bouncy(duration: 0.46, extraBounce: 0.18)) {
                hasAppeared = true
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
