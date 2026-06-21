import SwiftUI

struct TopBarView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.showSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.glass)
            .help("Settings")
            .accessibilityIdentifier("settings-button")

            Button {
                viewModel.togglePauseResume()
            } label: {
                Image(systemName: viewModel.pauseResumeIconName)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 15, height: 15)
            }
            .buttonStyle(.glass)
            .help(viewModel.pauseResumeHelpText)
            .accessibilityIdentifier("pause-resume-button")

            Button {
                viewModel.startNewGame()
            } label: {
                Image(systemName: "plus.square")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.glass)
            .help("Start a new game")
            .accessibilityIdentifier("new-game-button")
        }
        .frame(maxWidth: .infinity)
    }
}
