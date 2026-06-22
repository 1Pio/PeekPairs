import Combine
import Foundation
import PeekPairsCore
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published private(set) var history: RoundHistory
    @Published var isSettingsPresented = false
    @Published private(set) var hotkeyStatuses: [HotkeyAction: HotkeyRegistrationStatus] = [:]

    private(set) var game: MemoryGameEngine
    let boardState: BoardRenderState
    let stopwatchState: StopwatchRenderState
    let pairProgressState: PairProgressRenderState
    let controlsState: GameControlsRenderState

    private let store: AppFileStore
    private let cardImageStore: CardFigureImageStore
    private var boardAnimationToken = 0
    private var lastTickDate: Date?
    private var shouldResumeAfterActivation = false
    private var hasSavedCurrentRound = false

    init(
        store: AppFileStore = AppFileStore(),
        cardImageStore: CardFigureImageStore = .shared
    ) {
        self.store = store
        self.cardImageStore = cardImageStore
        let loadedSettings = store.load(AppSettings.self, from: .settings, fallback: .defaults)
        let loadedHistory = store.load(RoundHistory.self, from: .history, fallback: RoundHistory())
        let initialGame = MemoryGameEngine(
            boardSize: loadedSettings.boardSize,
            seed: Self.nextSeed(),
            assetNames: CardAssetCatalog.names,
            startsRunning: false
        )
        self.settings = loadedSettings
        self.history = loadedHistory
        self.game = initialGame
        self.boardState = BoardRenderState(game: initialGame, appearanceToken: 0)
        self.stopwatchState = StopwatchRenderState(elapsed: initialGame.elapsed)
        self.pairProgressState = PairProgressRenderState(game: initialGame)
        self.controlsState = GameControlsRenderState(game: initialGame)
        cardImageStore.preload(CardAssetCatalog.names)
    }

    var statsSummary: RoundStatsSummary {
        history.summary
    }

    var isBoardPaused: Bool {
        game.phase == .idle || game.phase == .paused
    }

    func tick(now: Date) {
        guard game.phase == .running || game.hasPendingVisualEvents else {
            lastTickDate = nil
            return
        }

        guard let lastTickDate else {
            self.lastTickDate = now
            return
        }

        let delta = max(0, now.timeIntervalSince(lastTickDate))
        self.lastTickDate = now

        game.advance(by: min(delta, 0.25))
        syncRenderState()
        saveRoundIfNeeded()
    }

    func select(cardID: Int) {
        withAnimation(.snappy(duration: 0.2)) {
            _ = game.selectCard(id: cardID)
            syncRenderState()
        }
        saveRoundIfNeeded()
    }

    func startNewGame() {
        resetGame(startsRunning: true)
        shouldResumeAfterActivation = true
        lastTickDate = Date()
    }

    func openPausedBoard() {
        if game.phase == .completed {
            resetGame(startsRunning: false)
        } else if game.phase == .running {
            game.pause()
            syncRenderState()
        } else {
            game.setIdle()
            syncRenderState()
        }

        shouldResumeAfterActivation = false
        lastTickDate = nil
    }

    func resumeOrStartGame() {
        if game.phase == .completed {
            startNewGame()
            return
        }

        shouldResumeAfterActivation = true
        game.startOrResume()
        syncRenderState()
        lastTickDate = Date()
    }

    func togglePauseResume() {
        if game.phase == .running {
            pauseCurrentGame(shouldResumeOnActivation: false)
        } else {
            resumeOrStartGame()
        }
    }

    func resumeFromBoardTap() {
        guard isBoardPaused else { return }
        resumeOrStartGame()
    }

    func pauseForManualDismissal() {
        pauseCurrentGame(shouldResumeOnActivation: false)
        isSettingsPresented = false
    }

    func showSettings() {
        pauseCurrentGame(shouldResumeOnActivation: false)
        isSettingsPresented = true
    }

    func update(boardSize: BoardSize) {
        settings.boardSize = boardSize
        persistSettings()
    }

    func update(minimizeOnFocusLoss: Bool) {
        settings.minimizeOnFocusLoss = minimizeOnFocusLoss
        persistSettings()
    }

    func update(defaultWindowWidth: Double) {
        settings.defaultWindowWidth = AppSettings.clampedDefaultWindowWidth(defaultWindowWidth)
        persistSettings()
    }

    func updateHotkey(_ binding: HotkeyBinding, for action: HotkeyAction) {
        settings.hotkeys[action] = binding
        persistSettings()
    }

    func updateHotkeyStatuses(_ statuses: [HotkeyAction: HotkeyRegistrationStatus]) {
        hotkeyStatuses = statuses
    }

    func applicationWillResignActive() {
        guard game.phase == .running else { return }
        pauseCurrentGame(shouldResumeOnActivation: true)
    }

    func applicationDidBecomeActive() {
        guard shouldResumeAfterActivation, game.phase == .paused || game.phase == .idle else { return }
        game.startOrResume()
        syncRenderState()
        lastTickDate = Date()
    }

    private func saveRoundIfNeeded() {
        guard game.phase == .completed, !hasSavedCurrentRound else { return }

        history.add(
            RoundResult(
                boardDimension: game.boardSize.dimension,
                seed: game.seed,
                duration: game.elapsed
            )
        )
        hasSavedCurrentRound = true
        shouldResumeAfterActivation = false
        lastTickDate = nil
        store.save(history, to: .history)
    }

    private func persistSettings() {
        store.save(settings, to: .settings)
    }

    private func resetGame(startsRunning: Bool) {
        game = MemoryGameEngine(
            boardSize: settings.boardSize,
            seed: Self.nextSeed(),
            assetNames: CardAssetCatalog.names,
            startsRunning: startsRunning
        )
        boardAnimationToken &+= 1
        hasSavedCurrentRound = false
        syncRenderState()
    }

    private func pauseCurrentGame(shouldResumeOnActivation: Bool) {
        guard game.phase == .running else { return }
        shouldResumeAfterActivation = shouldResumeOnActivation
        game.pause()
        syncRenderState()
        lastTickDate = nil
    }

    private func syncRenderState() {
        boardState.update(from: game, appearanceToken: boardAnimationToken)
        stopwatchState.update(elapsed: game.elapsed)
        pairProgressState.update(from: game)
        controlsState.update(from: game)
    }

    private static func nextSeed() -> UInt64 {
        ProcessInfo.processInfo.environment["PEEKPAIRS_SEED"].flatMap(UInt64.init) ?? RandomSeed.make()
    }
}
