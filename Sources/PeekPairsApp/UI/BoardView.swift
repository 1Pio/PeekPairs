import PeekPairsCore
import SwiftUI

struct BoardView: View {
    @ObservedObject var viewModel: GameViewModel

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 18), spacing: 8),
            count: viewModel.game.boardSize.dimension
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular.tint(Color.white.opacity(0.025)), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(viewModel.game.cards.enumerated()), id: \.element.id) { index, card in
                        MemoryCardView(
                            card: card,
                            appearanceToken: viewModel.boardAnimationToken,
                            appearanceDelay: appearanceDelay(for: index)
                        ) {
                            viewModel.select(cardID: card.id)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityIdentifier("card-\(card.id)")
                    }
                }
                .padding(16)
                .blur(radius: viewModel.isBoardPaused ? 9 : 0)
                .saturation(viewModel.isBoardPaused ? 0.58 : 1)
                .animation(.smooth(duration: viewModel.isBoardPaused ? 0.18 : 0.54), value: viewModel.isBoardPaused)

                if viewModel.isBoardPaused {
                    Button {
                        viewModel.resumeFromBoardTap()
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
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityIdentifier("game-board")
    }

    private func appearanceDelay(for index: Int) -> TimeInterval {
        let dimension = viewModel.game.boardSize.dimension
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
