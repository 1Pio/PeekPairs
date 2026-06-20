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
                    .fill(Color.white.opacity(0.03))
                    .glassEffect(.regular.tint(Color.white.opacity(0.045)), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.game.cards) { card in
                        MemoryCardView(card: card) {
                            viewModel.select(cardID: card.id)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityIdentifier("card-\(card.id)")
                    }
                }
                .padding(16)
                .blur(radius: viewModel.isBoardPaused ? 9 : 0)
                .saturation(viewModel.isBoardPaused ? 0.58 : 1)
                .animation(.smooth(duration: 0.18), value: viewModel.isBoardPaused)

                if viewModel.isBoardPaused {
                    PausedOverlayView()
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityIdentifier("game-board")
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
