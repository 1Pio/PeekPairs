import Foundation

public enum RoundPhase: String, Codable, Equatable, Sendable {
    case idle
    case running
    case paused
    case completed
}

public enum CardVisibility: String, Codable, Equatable, Sendable {
    case hidden
    case revealed
    case matched
    case removed
}

public struct MemoryCard: Identifiable, Codable, Equatable, Sendable {
    public let id: Int
    public let pairID: Int
    public let assetName: String
    public var visibility: CardVisibility

    public var isFaceUp: Bool {
        visibility == .revealed || visibility == .matched
    }

    public var isSelectable: Bool {
        visibility == .hidden
    }
}

public enum SelectionFeedback: Equatable, Sendable {
    case ignored
    case revealed(cardID: Int)
    case mismatch(firstID: Int, secondID: Int)
    case match(pairID: Int, cardIDs: [Int])
}

public struct MemoryGameEngine: Equatable, Sendable {
    public static let mismatchVisibilityDuration: TimeInterval = 0.78
    public static let matchedVisibilityDuration: TimeInterval = 2.4

    public private(set) var boardSize: BoardSize
    public private(set) var seed: UInt64
    public private(set) var phase: RoundPhase
    public private(set) var elapsed: TimeInterval
    public private(set) var cards: [MemoryCard]

    private var animationElapsed: TimeInterval
    private var revealedCardIDs: [Int]
    private var mismatchHideAt: TimeInterval?
    private var matchedPairRemovalDueAt: [Int: TimeInterval]
    private var foundPairIDs: Set<Int>

    public var totalPairs: Int { boardSize.pairCount }
    public var foundPairs: Int { foundPairIDs.count }
    public var progressText: String { "\(foundPairs)/\(totalPairs)" }
    public var isBoardPaused: Bool { phase == .idle || phase == .paused }
    public var hasPendingVisualEvents: Bool { !matchedPairRemovalDueAt.isEmpty }

    public init(
        boardSize: BoardSize,
        seed: UInt64,
        assetNames: [String],
        startsRunning: Bool
    ) {
        precondition(assetNames.count >= boardSize.pairCount, "Not enough assets for board size.")

        self.boardSize = boardSize
        self.seed = seed
        self.phase = startsRunning ? .running : .idle
        self.elapsed = 0
        self.animationElapsed = 0
        self.revealedCardIDs = []
        self.mismatchHideAt = nil
        self.matchedPairRemovalDueAt = [:]
        self.foundPairIDs = []

        var pairDeck = (0..<boardSize.pairCount).flatMap { pairID in
            [
                MemoryCard(id: pairID * 2, pairID: pairID, assetName: assetNames[pairID], visibility: .hidden),
                MemoryCard(id: pairID * 2 + 1, pairID: pairID, assetName: assetNames[pairID], visibility: .hidden)
            ]
        }
        var generator = SeededRandomNumberGenerator(seed: seed)
        pairDeck.shuffle(using: &generator)
        self.cards = pairDeck.enumerated().map { index, card in
            MemoryCard(id: index, pairID: card.pairID, assetName: card.assetName, visibility: .hidden)
        }
    }

    public mutating func startOrResume() {
        guard phase == .idle || phase == .paused else { return }
        phase = .running
    }

    public mutating func pause() {
        guard phase == .running else { return }
        phase = .paused
    }

    public mutating func setIdle() {
        guard phase != .completed else { return }
        phase = .idle
    }

    public mutating func advance(by delta: TimeInterval) {
        guard delta > 0 else { return }

        switch phase {
        case .running:
            elapsed += delta
            animationElapsed += delta
        case .completed:
            animationElapsed += delta
        case .idle, .paused:
            return
        }

        processDueEvents()
    }

    @discardableResult
    public mutating func selectCard(id: Int) -> SelectionFeedback {
        guard phase == .running else { return .ignored }
        processDueEvents()

        guard let selectedIndex = cards.firstIndex(where: { $0.id == id }),
              cards[selectedIndex].isSelectable
        else {
            return .ignored
        }

        if revealedCardIDs.count == 2 {
            hideVisibleMismatch()
        }

        cards[selectedIndex].visibility = .revealed
        revealedCardIDs.append(id)

        guard revealedCardIDs.count == 2 else {
            return .revealed(cardID: id)
        }

        let firstID = revealedCardIDs[0]
        let secondID = revealedCardIDs[1]
        let firstIndex = cards.firstIndex(where: { $0.id == firstID })!
        let secondIndex = cards.firstIndex(where: { $0.id == secondID })!

        if cards[firstIndex].pairID == cards[secondIndex].pairID {
            let pairID = cards[firstIndex].pairID
            cards[firstIndex].visibility = .matched
            cards[secondIndex].visibility = .matched
            revealedCardIDs.removeAll()
            mismatchHideAt = nil
            foundPairIDs.insert(pairID)
            matchedPairRemovalDueAt[pairID] = animationElapsed + Self.matchedVisibilityDuration
            if foundPairs == totalPairs {
                phase = .completed
            }
            return .match(pairID: pairID, cardIDs: [firstID, secondID])
        } else {
            mismatchHideAt = animationElapsed + Self.mismatchVisibilityDuration
            return .mismatch(firstID: firstID, secondID: secondID)
        }
    }

    private mutating func processDueEvents() {
        if let mismatchHideAt, animationElapsed >= mismatchHideAt {
            hideVisibleMismatch()
        }

        let duePairIDs = matchedPairRemovalDueAt
            .filter { animationElapsed >= $0.value }
            .map(\.key)

        for pairID in duePairIDs {
            removeMatchedPair(pairID: pairID)
        }
    }

    private mutating func hideVisibleMismatch() {
        for cardID in revealedCardIDs {
            guard let index = cards.firstIndex(where: { $0.id == cardID }),
                  cards[index].visibility == .revealed
            else { continue }
            cards[index].visibility = .hidden
        }
        revealedCardIDs.removeAll()
        mismatchHideAt = nil
    }

    private mutating func removeMatchedPair(pairID: Int) {
        matchedPairRemovalDueAt[pairID] = nil

        for index in cards.indices where cards[index].pairID == pairID {
            cards[index].visibility = .removed
        }
    }
}
