import PeekPairsCore
import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: GameViewModel

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(0, proxy.size.width - (PeekPairsLayout.contentPadding * 2))
            let availableBoardHeight = max(
                0,
                proxy.size.height
                    - (PeekPairsLayout.contentPadding * 2)
                    - PeekPairsLayout.boardToControlsSpacing
                    - PeekPairsLayout.bottomChromeHeight
            )
            let boardSide = max(
                0,
                min(availableWidth, availableBoardHeight)
            )

            ZStack {
                WindowDragSurface()
                    .frame(width: proxy.size.width, height: proxy.size.height)

                VStack(spacing: PeekPairsLayout.boardToControlsSpacing) {
                    BoardView(viewModel: viewModel)
                        .frame(width: boardSide, height: boardSide)

                    ProgressCounterView(viewModel: viewModel)
                        .frame(width: availableWidth, height: PeekPairsLayout.bottomChromeHeight)
                }
                .frame(width: availableWidth)
                .padding(.horizontal, PeekPairsLayout.contentPadding)
                .padding(.top, PeekPairsLayout.contentPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if viewModel.isSettingsPresented {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)

                    SettingsSheetView(viewModel: viewModel)
                        .frame(width: min(520, proxy.size.width - (PeekPairsLayout.contentPadding * 2)))
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .zIndex(2)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .frame(
            minWidth: PeekPairsLayout.minimumWindowWidth,
            minHeight: PeekPairsLayout.windowHeight(forWidth: PeekPairsLayout.minimumWindowWidth)
        )
        .background(Color.clear)
        .preferredColorScheme(.dark)
        .onReceive(timer) { now in
            viewModel.tick(now: now)
        }
        .animation(.smooth(duration: 0.24), value: viewModel.isSettingsPresented)
    }
}
