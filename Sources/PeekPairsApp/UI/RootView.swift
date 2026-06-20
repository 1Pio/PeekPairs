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
        .background(AppBackgroundView())
        .preferredColorScheme(.dark)
        .onReceive(timer) { now in
            viewModel.tick(now: now)
        }
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            SettingsSheetView(viewModel: viewModel)
        }
    }
}

private struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.025, blue: 0.034)
            RadialGradient(
                colors: [
                    Color(red: 0.18, green: 0.42, blue: 0.50).opacity(0.24),
                    .clear
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 560
            )
            RadialGradient(
                colors: [
                    Color(red: 0.54, green: 0.20, blue: 0.28).opacity(0.16),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 620
            )
        }
        .ignoresSafeArea()
    }
}
