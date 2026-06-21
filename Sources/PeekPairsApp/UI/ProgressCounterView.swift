import SwiftUI

struct ProgressCounterView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 0) {
            StopwatchPillView(elapsed: viewModel.formattedElapsed)

            Spacer(minLength: 10)

            GameControlsView(viewModel: viewModel)

            Spacer(minLength: 10)

            PairCounterPillView(
                progressText: viewModel.progressText,
                foundPairs: viewModel.game.foundPairs
            )
        }
    }
}

private struct StopwatchPillView: View {
    let elapsed: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "stopwatch")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
            Text(elapsed)
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
    let progressText: String
    let foundPairs: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(progressText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .frame(minWidth: 58, alignment: .trailing)
            Text("pairs")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.56))
        }
        .padding(.horizontal, 12)
        .frame(height: PeekPairsLayout.bottomChromeHeight)
        .glassEffect(.regular.tint(Color.white.opacity(0.055)), in: Capsule())
        .animation(.bouncy(duration: 0.36, extraBounce: 0.22), value: foundPairs)
        .accessibilityIdentifier("pair-counter")
    }
}
