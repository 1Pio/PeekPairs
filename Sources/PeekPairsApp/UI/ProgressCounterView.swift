import SwiftUI

struct ProgressCounterView: View {
    let stopwatchState: StopwatchRenderState
    let pairProgressState: PairProgressRenderState
    let controlsState: GameControlsRenderState
    let onShowSettings: () -> Void
    let onTogglePauseResume: () -> Void
    let onStartNewGame: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            StopwatchPillView(state: stopwatchState)

            Spacer(minLength: 10)

            GameControlsView(
                state: controlsState,
                onShowSettings: onShowSettings,
                onTogglePauseResume: onTogglePauseResume,
                onStartNewGame: onStartNewGame
            )

            Spacer(minLength: 10)

            PairCounterPillView(state: pairProgressState)
        }
    }
}

private struct StopwatchPillView: View {
    @ObservedObject var state: StopwatchRenderState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "stopwatch")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
            Text(state.elapsedText)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .contentTransition(.numericText())
                .frame(width: 76, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .frame(height: PeekPairsLayout.bottomChromeHeight)
        .glassEffect(.regular.tint(Color.white.opacity(0.06)), in: Capsule())
        .accessibilityIdentifier("stopwatch")
    }
}

private struct PairCounterPillView: View {
    @ObservedObject var state: PairProgressRenderState

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(state.snapshot.progressText)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .contentTransition(.numericText())
                .monospacedDigit()
            Text("pairs")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.54))
        }
        .padding(.horizontal, 14)
        .frame(width: 124)
        .frame(height: PeekPairsLayout.bottomChromeHeight)
        .glassEffect(.regular.tint(Color.white.opacity(0.055)), in: Capsule())
        .animation(.bouncy(duration: 0.36, extraBounce: 0.22), value: state.snapshot.foundPairs)
        .accessibilityIdentifier("pair-counter")
    }
}
