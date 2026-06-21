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
    private enum CodingKeys: String, CodingKey {
        case boardSize
        case defaultWindowWidth
        case hotkeys
        case minimizeOnFocusLoss
    }

    public static let minimumDefaultWindowWidth = 520.0
    public static let maximumDefaultWindowWidth = 980.0
    public static let defaultWindowWidth = 760.0
    public static let defaultMinimizeOnFocusLoss = true

    public var boardSize: BoardSize
    public var defaultWindowWidth: Double
    public var hotkeys: [HotkeyAction: HotkeyBinding]
    public var minimizeOnFocusLoss: Bool

    public init(
        boardSize: BoardSize,
        defaultWindowWidth: Double = Self.defaultWindowWidth,
        hotkeys: [HotkeyAction: HotkeyBinding],
        minimizeOnFocusLoss: Bool = Self.defaultMinimizeOnFocusLoss
    ) {
        self.boardSize = boardSize
        self.defaultWindowWidth = Self.clampedDefaultWindowWidth(defaultWindowWidth)
        self.hotkeys = hotkeys
        self.minimizeOnFocusLoss = minimizeOnFocusLoss
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        boardSize = try container.decode(BoardSize.self, forKey: .boardSize)
        defaultWindowWidth = Self.clampedDefaultWindowWidth(
            try container.decodeIfPresent(Double.self, forKey: .defaultWindowWidth) ?? Self.defaultWindowWidth
        )
        hotkeys = try container.decode([HotkeyAction: HotkeyBinding].self, forKey: .hotkeys)
        minimizeOnFocusLoss = try container.decodeIfPresent(Bool.self, forKey: .minimizeOnFocusLoss)
            ?? Self.defaultMinimizeOnFocusLoss
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boardSize, forKey: .boardSize)
        try container.encode(defaultWindowWidth, forKey: .defaultWindowWidth)
        try container.encode(hotkeys, forKey: .hotkeys)
        try container.encode(minimizeOnFocusLoss, forKey: .minimizeOnFocusLoss)
    }

    public static var defaultWindowWidthRange: ClosedRange<Double> {
        minimumDefaultWindowWidth...maximumDefaultWindowWidth
    }

    public static func clampedDefaultWindowWidth(_ width: Double) -> Double {
        min(max(width, minimumDefaultWindowWidth), maximumDefaultWindowWidth)
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
