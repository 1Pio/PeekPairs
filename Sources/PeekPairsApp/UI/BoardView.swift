import PeekPairsCore
import SwiftUI

struct BoardView: View {
    @ObservedObject var state: BoardRenderState
    let onSelect: (Int) -> Void
    let onResumeFromBoardTap: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let boardShape = RoundedRectangle(cornerRadius: PeekPairsLayout.boardCornerRadius, style: .continuous)

            ZStack {
                boardShape
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular.tint(Color.white.opacity(0.025)), in: boardShape)
                    .overlay {
                        boardShape
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    }

                FixedCardGridView(
                    cards: state.snapshot.cards,
                    dimension: state.snapshot.boardSize.dimension,
                    appearanceToken: state.snapshot.appearanceToken,
                    onSelect: onSelect
                )
                .padding(16)
                .blur(radius: state.snapshot.isPaused ? 9 : 0)
                .saturation(state.snapshot.isPaused ? 0.58 : 1)
                .animation(.smooth(duration: state.snapshot.isPaused ? 0.18 : 0.54), value: state.snapshot.isPaused)

                if state.snapshot.isPaused {
                    Button {
                        onResumeFromBoardTap()
                    } label: {
                        Color.white.opacity(0.001)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Resume game")
                    .accessibilityIdentifier("paused-board-resume-button")
                    .accessibilityLabel("Resume game")

                    PausedOverlayView()
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .contentShape(boardShape)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct FixedCardGridView: View {
    let cards: [MemoryCard]
    let dimension: Int
    let appearanceToken: Int
    let onSelect: (Int) -> Void

    private let spacing: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cardSide = cardSide(for: side)

            ZStack(alignment: .topLeading) {
                ForEach(cards.indices, id: \.self) { index in
                    let card = cards[index]
                    let origin = origin(for: index, cardSide: cardSide)

                    MemoryCardView(
                        card: card,
                        appearanceToken: appearanceToken,
                        appearanceDelay: appearanceDelay(for: index)
                    ) {
                        onSelect(card.id)
                    }
                    .equatable()
                    .frame(width: cardSide, height: cardSide)
                    .position(x: origin.x + (cardSide / 2), y: origin.y + (cardSide / 2))
                }
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private func cardSide(for side: CGFloat) -> CGFloat {
        guard dimension > 0 else { return 0 }
        let totalSpacing = CGFloat(dimension - 1) * spacing
        return max(0, (side - totalSpacing) / CGFloat(dimension))
    }

    private func origin(for index: Int, cardSide: CGFloat) -> CGPoint {
        let row = index / dimension
        let column = index % dimension
        let step = cardSide + spacing
        return CGPoint(x: CGFloat(column) * step, y: CGFloat(row) * step)
    }

    private func appearanceDelay(for index: Int) -> TimeInterval {
        let row = index / dimension
        let column = index % dimension
        return TimeInterval(row + column) * 0.034
    }
}

private struct PausedOverlayView: View {
    var body: some View {
        Image(systemName: "pause.fill")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white.opacity(0.86))
            .frame(width: 58, height: 58)
            .glassEffect(.regular.tint(Color.white.opacity(0.08)), in: Circle())
            .accessibilityIdentifier("pause-overlay")
    }
}
