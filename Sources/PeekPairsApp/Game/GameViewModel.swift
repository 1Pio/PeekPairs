import Combine
import Foundation
import PeekPairsCore
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var game: MemoryGameEngine
    @Published var settings: AppSettings
    @Published private(set) var history: RoundHistory
    @Published var isSettingsPresented = false
    @Published private(set) var hotkeyStatuses: [HotkeyAction: HotkeyRegistrationStatus] = [:]

    private let store: AppFileStore
    private var lastTickDate: Date?
    private var shouldResumeAfterActivation = false
    private var hasSavedCurrentRound = false

    init(store: AppFileStore = AppFileStore()) {
        self.store = store
        let loadedSettings = store.load(AppSettings.self, from: .settings, fallback: .defaults)
        self.settings = loadedSettings
        self.history = store.load(RoundHistory.self, from: .history, fallback: RoundHistory())
        self.game = MemoryGameEngine(
            boardSize: loadedSettings.boardSize,
            seed: RandomSeed.make(),
            assetNames: CardAssetCatalog.names,
            startsRunning: false
        )
    }

    var statsSummary: RoundStatsSummary {
        history.summary
    }

    var formattedElapsed: String {
        TimeFormatter.stopwatch.string(from: game.elapsed)
    }

    var progressText: String {
        "\(game.foundPairs) / \(game.totalPairs)"
    }

    var isBoardPaused: Bool {
        game.phase == .idle || game.phase == .paused
    }

    func tick(now: Date) {
        guard game.phase == .running else {
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
        saveRoundIfNeeded()
    }

    func select(cardID: Int) {
        withAnimation(.snappy(duration: 0.2)) {
            _ = game.selectCard(id: cardID)
        }
        saveRoundIfNeeded()
    }

    func startNewGame() {
        game = MemoryGameEngine(
            boardSize: settings.boardSize,
            seed: RandomSeed.make(),
            assetNames: CardAssetCatalog.names,
            startsRunning: true
        )
        hasSavedCurrentRound = false
        shouldResumeAfterActivation = true
        lastTickDate = Date()
    }

    func openPausedBoard() {
        if game.phase == .completed {
            game = MemoryGameEngine(
                boardSize: settings.boardSize,
                seed: RandomSeed.make(),
                assetNames: CardAssetCatalog.names,
                startsRunning: false
            )
            hasSavedCurrentRound = false
        } else if game.phase == .running {
            game.pause()
        } else {
            game.setIdle()
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
        lastTickDate = Date()
    }

    func showSettings() {
        isSettingsPresented = true
    }

    func update(boardSize: BoardSize) {
        settings.boardSize = boardSize
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
        shouldResumeAfterActivation = true
        game.pause()
        lastTickDate = nil
    }

    func applicationDidBecomeActive() {
        guard shouldResumeAfterActivation, game.phase == .paused || game.phase == .idle else { return }
        game.startOrResume()
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
}
