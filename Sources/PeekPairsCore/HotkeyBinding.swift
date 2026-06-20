import Foundation

public enum HotkeyAction: String, CaseIterable, Codable, Equatable, Hashable, Sendable, Identifiable {
    case openPausedBoard
    case startNewGame
    case resumeOrStartGame

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .openPausedBoard:
            "Open paused board"
        case .startNewGame:
            "Open new game"
        case .resumeOrStartGame:
            "Resume or start"
        }
    }
}

public struct HotkeyBinding: Codable, Equatable, Hashable, Sendable {
    public var keyCode: UInt32
    public var carbonModifiers: UInt32
    public var displayText: String

    public init(keyCode: UInt32, carbonModifiers: UInt32, displayText: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.displayText = displayText
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var boardSize: BoardSize
    public var hotkeys: [HotkeyAction: HotkeyBinding]

    public init(boardSize: BoardSize, hotkeys: [HotkeyAction: HotkeyBinding]) {
        self.boardSize = boardSize
        self.hotkeys = hotkeys
    }

    public static let defaults = AppSettings(
        boardSize: BoardSize(uncheckedDimension: 6),
        hotkeys: [
            .openPausedBoard: HotkeyBinding(keyCode: 46, carbonModifiers: 0x1900, displayText: "⌃⌥⌘M"),
            .startNewGame: HotkeyBinding(keyCode: 45, carbonModifiers: 0x1900, displayText: "⌃⌥⌘N"),
            .resumeOrStartGame: HotkeyBinding(keyCode: 35, carbonModifiers: 0x1900, displayText: "⌃⌥⌘P")
        ]
    )
}
