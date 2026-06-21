import PeekPairsCore
import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: GameViewModel

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let availableSide = max(0, side - (PeekPairsLayout.contentPadding * 2))
            let boardSide = max(
                0,
                availableSide - PeekPairsLayout.bottomChromeHeight - PeekPairsLayout.boardToControlsSpacing
            )

            ZStack {
                WindowDragSurface()
                    .frame(width: side, height: side)

                VStack(spacing: PeekPairsLayout.boardToControlsSpacing) {
                    BoardView(viewModel: viewModel)
                        .frame(width: boardSide, height: boardSide)

                    ProgressCounterView(viewModel: viewModel)
                        .frame(width: availableSide, height: PeekPairsLayout.bottomChromeHeight)
                }
                .padding(PeekPairsLayout.contentPadding)

                if viewModel.isSettingsPresented {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)

                    SettingsSheetView(viewModel: viewModel)
                        .frame(width: min(520, side - (PeekPairsLayout.contentPadding * 2)))
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .zIndex(2)
                }
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .frame(minWidth: PeekPairsLayout.minimumWindowSide, minHeight: PeekPairsLayout.minimumWindowSide)
        .background(Color.clear)
        .preferredColorScheme(.dark)
        .onReceive(timer) { now in
            viewModel.tick(now: now)
        }
        .animation(.smooth(duration: 0.24), value: viewModel.isSettingsPresented)
    }
}
