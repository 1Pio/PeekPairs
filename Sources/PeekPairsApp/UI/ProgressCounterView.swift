import SwiftUI

struct ProgressCounterView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(viewModel.progressText)
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
        .animation(.bouncy(duration: 0.36, extraBounce: 0.22), value: viewModel.game.foundPairs)
        .accessibilityIdentifier("pair-counter")
    }
}
