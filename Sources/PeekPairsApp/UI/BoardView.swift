import PeekPairsCore
import SwiftUI

struct BoardView: View {
    @ObservedObject var state: BoardRenderState
    let onSelect: (Int) -> Void
    let onResumeFromBoardTap: () -> Void

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 18), spacing: 8),
            count: state.snapshot.boardSize.dimension
        )
    }

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

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(state.snapshot.cards.enumerated()), id: \.element.id) { index, card in
                        MemoryCardView(
                            card: card,
                            appearanceToken: state.snapshot.appearanceToken,
                            appearanceDelay: appearanceDelay(for: index)
                        ) {
                            onSelect(card.id)
                        }
                        .equatable()
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityIdentifier("card-\(card.id)")
                    }
                }
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
        .accessibilityIdentifier("game-board")
    }

    private func appearanceDelay(for index: Int) -> TimeInterval {
        let dimension = state.snapshot.boardSize.dimension
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
