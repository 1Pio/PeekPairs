import PeekPairsCore
import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: GameViewModel

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let boardInset: CGFloat = 64
    private let chromeInset: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                BoardView(viewModel: viewModel)
                    .padding(boardInset)

                TopBarView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, chromeInset)

                ProgressCounterView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, boardInset)
                    .padding(.bottom, chromeInset)

                if viewModel.isSettingsPresented {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)

                    SettingsSheetView(viewModel: viewModel)
                        .frame(width: min(520, side - 40))
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        .zIndex(2)
                }
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .frame(minWidth: 520, minHeight: 520)
        .background(Color.clear)
        .preferredColorScheme(.dark)
        .onReceive(timer) { now in
            viewModel.tick(now: now)
        }
        .animation(.smooth(duration: 0.24), value: viewModel.isSettingsPresented)
    }
}
