import PeekPairsCore
import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: GameViewModel

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 14) {
            TopBarView(viewModel: viewModel)

            BoardView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ProgressCounterView(viewModel: viewModel)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .frame(minWidth: 480, minHeight: 560)
        .background(Color.clear)
        .preferredColorScheme(.dark)
        .onReceive(timer) { now in
            viewModel.tick(now: now)
        }
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            SettingsSheetView(viewModel: viewModel)
        }
    }
}
