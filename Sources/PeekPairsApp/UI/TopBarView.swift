import SwiftUI

struct TopBarView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "stopwatch")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
                Text(viewModel.formattedElapsed)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .contentTransition(.numericText())
                    .frame(width: 76, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular.tint(Color.white.opacity(0.06)), in: Capsule())
            .accessibilityIdentifier("stopwatch")

            Spacer()

            Button {
                viewModel.startNewGame()
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.glass)
            .help("Start a new game")
            .accessibilityIdentifier("new-game-button")

            Button {
                viewModel.showSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.glass)
            .help("Settings")
            .accessibilityIdentifier("settings-button")
        }
    }
}
