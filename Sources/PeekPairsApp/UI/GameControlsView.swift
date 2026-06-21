import SwiftUI

struct GameControlsView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.showSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(GlassCircleButtonStyle())
            .help("Settings")
            .accessibilityIdentifier("settings-button")

            Button {
                viewModel.togglePauseResume()
            } label: {
                Image(systemName: viewModel.pauseResumeIconName)
            }
            .buttonStyle(GlassCircleButtonStyle())
            .help(viewModel.pauseResumeHelpText)
            .accessibilityIdentifier("pause-resume-button")

            Button {
                viewModel.startNewGame()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(GlassCircleButtonStyle())
            .help("Start a new game")
            .accessibilityIdentifier("new-game-button")
        }
    }
}

private struct GlassCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.92 : 0.8))
            .frame(width: PeekPairsLayout.controlButtonSide, height: PeekPairsLayout.controlButtonSide)
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .glassEffect(.regular.tint(Color.white.opacity(configuration.isPressed ? 0.11 : 0.065)), in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(configuration.isPressed ? 0.2 : 0.12), lineWidth: 1)
            }
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}
