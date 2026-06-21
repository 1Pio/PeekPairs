import SwiftUI

struct ProgressCounterView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack {
            StopwatchPillView(elapsed: viewModel.formattedElapsed)

            Spacer(minLength: 20)

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
        .padding(.vertical, 8)
        .glassEffect(.regular.tint(Color.white.opacity(0.06)), in: Capsule())
        .accessibilityIdentifier("stopwatch")
    }
}

private struct PairCounterPillView: View {
    let progressText: String
    let foundPairs: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(progressText)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .frame(width: 74)
            Text("pairs")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.56))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.tint(Color.white.opacity(0.055)), in: Capsule())
        .animation(.bouncy(duration: 0.36, extraBounce: 0.22), value: foundPairs)
        .accessibilityIdentifier("pair-counter")
    }
}
