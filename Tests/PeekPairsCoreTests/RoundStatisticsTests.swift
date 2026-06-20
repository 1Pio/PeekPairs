import Testing
@testable import PeekPairsCore

@Suite("Round statistics")
struct RoundStatisticsTests {
    @Test("summary calculates shortest, average, median, last, and longest")
    func summary() {
        var history = RoundHistory()
        history.add(RoundResult(boardDimension: 4, seed: 1, duration: 10))
        history.add(RoundResult(boardDimension: 4, seed: 2, duration: 40))
        history.add(RoundResult(boardDimension: 6, seed: 3, duration: 25))

        let summary = history.summary

        #expect(summary.shortest == 10)
        #expect(summary.average == 25)
        #expect(summary.mean == 25)
        #expect(summary.median == 25)
        #expect(summary.last == 25)
        #expect(summary.longest == 40)
        #expect(summary.gamesPlayed == 3)
    }
}
