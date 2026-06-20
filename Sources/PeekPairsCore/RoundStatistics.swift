import Foundation

public struct RoundResult: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let completedAt: Date
    public let boardDimension: Int
    public let seed: UInt64
    public let duration: TimeInterval

    public init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        boardDimension: Int,
        seed: UInt64,
        duration: TimeInterval
    ) {
        self.id = id
        self.completedAt = completedAt
        self.boardDimension = boardDimension
        self.seed = seed
        self.duration = duration
    }
}

public struct RoundStatsSummary: Equatable, Sendable {
    public let shortest: TimeInterval?
    public let average: TimeInterval?
    public let median: TimeInterval?
    public let mean: TimeInterval?
    public let last: TimeInterval?
    public let longest: TimeInterval?
    public let gamesPlayed: Int

    public static let empty = RoundStatsSummary(
        shortest: nil,
        average: nil,
        median: nil,
        mean: nil,
        last: nil,
        longest: nil,
        gamesPlayed: 0
    )
}

public struct RoundHistory: Codable, Equatable, Sendable {
    public private(set) var results: [RoundResult]
    private let limit: Int

    public init(results: [RoundResult] = [], limit: Int = 500) {
        self.results = results
        self.limit = limit
    }

    private enum CodingKeys: String, CodingKey {
        case results
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([RoundResult].self, forKey: .results)
        self.limit = 500
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(results, forKey: .results)
    }

    public mutating func add(_ result: RoundResult) {
        results.append(result)
        if results.count > limit {
            results.removeFirst(results.count - limit)
        }
    }

    public var summary: RoundStatsSummary {
        guard !results.isEmpty else { return .empty }

        let durations = results.map(\.duration)
        let sortedDurations = durations.sorted()
        let total = durations.reduce(0, +)
        let mean = total / Double(durations.count)
        let median: TimeInterval

        if sortedDurations.count.isMultiple(of: 2) {
            let upper = sortedDurations.count / 2
            median = (sortedDurations[upper - 1] + sortedDurations[upper]) / 2
        } else {
            median = sortedDurations[sortedDurations.count / 2]
        }

        return RoundStatsSummary(
            shortest: sortedDurations.first,
            average: mean,
            median: median,
            mean: mean,
            last: results.last?.duration,
            longest: sortedDurations.last,
            gamesPlayed: results.count
        )
    }
}
