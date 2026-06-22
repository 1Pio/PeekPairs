import SwiftUI

struct GameControlsView: View {
    @ObservedObject var state: GameControlsRenderState
    let onShowSettings: () -> Void
    let onTogglePauseResume: () -> Void
    let onStartNewGame: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button {
                onShowSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(GlassCircleButtonStyle())
            .help("Settings")
            .accessibilityIdentifier("settings-button")

            Button {
                onTogglePauseResume()
            } label: {
                Image(systemName: state.snapshot.pauseResumeIconName)
            }
            .buttonStyle(GlassCircleButtonStyle())
            .help(state.snapshot.pauseResumeHelpText)
            .accessibilityIdentifier("pause-resume-button")

            Button {
                onStartNewGame()
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
