import Testing
@testable import PeekPairsCore

@Suite("Memory game engine")
struct MemoryGameEngineTests {
    private let assets = (1...32).map { "figure_\($0)" }

    @Test("shuffle is deterministic for the same seed")
    func deterministicShuffle() throws {
        let boardSize = try BoardSize(4)
        let first = MemoryGameEngine(boardSize: boardSize, seed: 42, assetNames: assets, startsRunning: true)
        let second = MemoryGameEngine(boardSize: boardSize, seed: 42, assetNames: assets, startsRunning: true)

        #expect(first.cards.map(\.pairID) == second.cards.map(\.pairID))
    }

    @Test("mismatch flips back after active time only")
    func mismatchUsesActiveTime() throws {
        let boardSize = try BoardSize(2)
        var game = MemoryGameEngine(boardSize: boardSize, seed: 3, assetNames: assets, startsRunning: true)
        let first = game.cards[0]
        let second = game.cards.first { $0.pairID != first.pairID }!

        _ = game.selectCard(id: first.id)
        _ = game.selectCard(id: second.id)
        game.pause()
        game.advance(by: MemoryGameEngine.mismatchVisibilityDuration + 1)

        #expect(game.cards.first { $0.id == first.id }?.visibility == .revealed)
        #expect(game.cards.first { $0.id == second.id }?.visibility == .revealed)

        game.startOrResume()
        game.advance(by: MemoryGameEngine.mismatchVisibilityDuration + 0.01)

        #expect(game.cards.first { $0.id == first.id }?.visibility == .hidden)
        #expect(game.cards.first { $0.id == second.id }?.visibility == .hidden)
    }

    @Test("third card starts the next try immediately after a mismatch")
    func thirdCardClearsMismatch() throws {
        let boardSize = try BoardSize(4)
        var game = MemoryGameEngine(boardSize: boardSize, seed: 10, assetNames: assets, startsRunning: true)
        let first = game.cards[0]
        let second = game.cards.first { $0.pairID != first.pairID }!
        let third = game.cards.first { $0.id != first.id && $0.id != second.id && $0.pairID != first.pairID && $0.pairID != second.pairID }!

        _ = game.selectCard(id: first.id)
        _ = game.selectCard(id: second.id)
        _ = game.selectCard(id: third.id)

        #expect(game.cards.first { $0.id == first.id }?.visibility == .hidden)
        #expect(game.cards.first { $0.id == second.id }?.visibility == .hidden)
        #expect(game.cards.first { $0.id == third.id }?.visibility == .revealed)
    }

    @Test("matched pair counts immediately but disappears after the cosmetic delay")
    func matchedPairCountsBeforeRemoval() throws {
        let boardSize = try BoardSize(2)
        var game = MemoryGameEngine(boardSize: boardSize, seed: 4, assetNames: assets, startsRunning: true)
        let first = game.cards[0]
        let second = game.cards.first { $0.pairID == first.pairID && $0.id != first.id }!

        _ = game.selectCard(id: first.id)
        _ = game.selectCard(id: second.id)

        #expect(game.foundPairs == 1)
        #expect(game.cards.first { $0.id == first.id }?.visibility == .matched)

        game.advance(by: MemoryGameEngine.matchedVisibilityDuration - 0.01)
        #expect(game.foundPairs == 1)

        game.advance(by: 0.02)
        #expect(game.foundPairs == 1)
        #expect(game.cards.first { $0.id == first.id }?.visibility == .removed)
    }

    @Test("final pair completes the round immediately and keeps removal cosmetic")
    func finalPairCompletesBeforeRemoval() throws {
        let boardSize = try BoardSize(2)
        var game = MemoryGameEngine(boardSize: boardSize, seed: 5, assetNames: assets, startsRunning: true)

        for pairID in 0..<boardSize.pairCount {
            let pairCards = game.cards.filter { $0.pairID == pairID }
            _ = game.selectCard(id: pairCards[0].id)
            _ = game.selectCard(id: pairCards[1].id)
        }

        let completedElapsed = game.elapsed

        #expect(game.phase == .completed)
        #expect(game.foundPairs == game.totalPairs)
        #expect(game.cards.contains { $0.visibility == .matched })

        game.advance(by: MemoryGameEngine.matchedVisibilityDuration + 0.01)

        #expect(game.elapsed == completedElapsed)
        #expect(game.cards.allSatisfy { $0.visibility == .removed })
    }
}
