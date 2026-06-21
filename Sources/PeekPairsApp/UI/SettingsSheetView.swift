import PeekPairsCore
import SwiftUI

struct SettingsSheetView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var recordingAction: HotkeyAction?

    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .topTrailing) {
                StatsCardView(summary: viewModel.statsSummary)

                Button {
                    viewModel.isSettingsPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.glass)
                .help("Close settings")
                .padding(10)
                .accessibilityIdentifier("close-settings-button")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Default board")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))

                Picker("Default board", selection: boardSizeBinding) {
                    ForEach(BoardSize.presets) { size in
                        Text(size.label).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("board-size-picker")
            }
            .settingsSectionGlass()

            VStack(alignment: .leading, spacing: 10) {
                Text("Global shortcuts")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))

                ForEach(HotkeyAction.allCases) { action in
                    HotkeyRowView(
                        action: action,
                        binding: viewModel.settings.hotkeys[action],
                        status: viewModel.hotkeyStatuses[action],
                        isRecording: recordingAction == action
                    ) {
                        recordingAction = action
                    }
                }
            }
            .settingsSectionGlass()
        }
        .padding(20)
        .frame(width: 520)
        .background {
            Color(red: 0.035, green: 0.04, blue: 0.05)
                .opacity(0.95)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .overlay {
            if let recordingAction {
                ShortcutCaptureOverlay(
                    action: recordingAction,
                    onCapture: { binding in
                        viewModel.updateHotkey(binding, for: recordingAction)
                        self.recordingAction = nil
                    },
                    onCancel: {
                        self.recordingAction = nil
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    private var boardSizeBinding: Binding<BoardSize> {
        Binding(
            get: { viewModel.settings.boardSize },
            set: { viewModel.update(boardSize: $0) }
        )
    }
}

private struct StatsCardView: View {
    let summary: RoundStatsSummary

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stats")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(summary.gamesPlayed) games")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.56))
                    .padding(.trailing, 30)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                StatCell(title: "Shortest", value: TimeFormatter.short.string(from: summary.shortest))
                StatCell(title: "Average", value: TimeFormatter.short.string(from: summary.average))
                StatCell(title: "Median / Mean", value: medianMeanText)
                StatCell(title: "Last", value: TimeFormatter.short.string(from: summary.last))
                StatCell(title: "Longest", value: TimeFormatter.short.string(from: summary.longest))
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(Color.white.opacity(0.06)), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var medianMeanText: String {
        "\(TimeFormatter.short.string(from: summary.median)) / \(TimeFormatter.short.string(from: summary.mean))"
    }
}

private struct StatCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.52))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HotkeyRowView: View {
    let action: HotkeyAction
    let binding: HotkeyBinding?
    let status: HotkeyRegistrationStatus?
    let isRecording: Bool
    let onRecord: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.system(size: 13, weight: .semibold))
                Text(status?.displayText ?? "Not set")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(status == .registered ? Color.mint.opacity(0.78) : Color.orange.opacity(0.78))
            }

            Spacer()

            Button {
                onRecord()
            } label: {
                Text(isRecording ? "Recording" : (binding?.displayText ?? "Set"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .frame(minWidth: 92)
            }
            .buttonStyle(.glass)
            .accessibilityIdentifier("hotkey-\(action.rawValue)")
        }
        .padding(.vertical, 4)
    }
}

private struct ShortcutCaptureOverlay: View {
    let action: HotkeyAction
    let onCapture: (HotkeyBinding) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.52)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .font(.system(size: 22, weight: .semibold))
                Text(action.title)
                    .font(.system(size: 15, weight: .bold))
                Text("Press a shortcut with Command, Option, Control, or Shift.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
            .frame(width: 360)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.04, green: 0.045, blue: 0.055).opacity(0.96))
                    .glassEffect(.regular.tint(Color.white.opacity(0.08)), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            ShortcutRecorderView(onCapture: onCapture, onCancel: onCancel)
                .frame(width: 1, height: 1)
                .opacity(0.01)
        }
        .accessibilityIdentifier("shortcut-capture-overlay")
    }
}

private extension View {
    func settingsSectionGlass() -> some View {
        padding(14)
            .glassEffect(.regular.tint(Color.white.opacity(0.045)), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
