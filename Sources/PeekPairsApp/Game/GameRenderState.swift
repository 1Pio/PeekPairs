import Combine
import Foundation
import PeekPairsCore

struct BoardRenderSnapshot: Equatable {
    let boardSize: BoardSize
    let cards: [MemoryCard]
    let isPaused: Bool
    let appearanceToken: Int

    init(game: MemoryGameEngine, appearanceToken: Int) {
        self.boardSize = game.boardSize
        self.cards = game.cards
        self.isPaused = game.isBoardPaused
        self.appearanceToken = appearanceToken
    }
}

@MainActor
final class BoardRenderState: ObservableObject {
    @Published private(set) var snapshot: BoardRenderSnapshot

    init(game: MemoryGameEngine, appearanceToken: Int) {
        self.snapshot = BoardRenderSnapshot(game: game, appearanceToken: appearanceToken)
    }

    func update(from game: MemoryGameEngine, appearanceToken: Int) {
        let nextSnapshot = BoardRenderSnapshot(game: game, appearanceToken: appearanceToken)
        guard snapshot != nextSnapshot else { return }
        snapshot = nextSnapshot
    }
}

@MainActor
final class StopwatchRenderState: ObservableObject {
    @Published private(set) var elapsedText: String

    init(elapsed: TimeInterval) {
        self.elapsedText = TimeFormatter.stopwatch.string(from: elapsed)
    }

    func update(elapsed: TimeInterval) {
        let nextText = TimeFormatter.stopwatch.string(from: elapsed)
        guard elapsedText != nextText else { return }
        elapsedText = nextText
    }
}

struct PairProgressSnapshot: Equatable {
    let progressText: String
    let foundPairs: Int

    init(game: MemoryGameEngine) {
        self.progressText = "\(game.foundPairs) / \(game.totalPairs)"
        self.foundPairs = game.foundPairs
    }
}

@MainActor
final class PairProgressRenderState: ObservableObject {
    @Published private(set) var snapshot: PairProgressSnapshot

    init(game: MemoryGameEngine) {
        self.snapshot = PairProgressSnapshot(game: game)
    }

    func update(from game: MemoryGameEngine) {
        let nextSnapshot = PairProgressSnapshot(game: game)
        guard snapshot != nextSnapshot else { return }
        snapshot = nextSnapshot
    }
}

struct GameControlsSnapshot: Equatable {
    let isRunning: Bool

    var pauseResumeIconName: String {
        isRunning ? "pause.fill" : "play.fill"
    }

    var pauseResumeHelpText: String {
        isRunning ? "Pause game" : "Resume game"
    }

    init(game: MemoryGameEngine) {
        self.isRunning = game.phase == .running
    }
}

@MainActor
final class GameControlsRenderState: ObservableObject {
    @Published private(set) var snapshot: GameControlsSnapshot

    init(game: MemoryGameEngine) {
        self.snapshot = GameControlsSnapshot(game: game)
    }

    func update(from game: MemoryGameEngine) {
        let nextSnapshot = GameControlsSnapshot(game: game)
        guard snapshot != nextSnapshot else { return }
        snapshot = nextSnapshot
    }
}
