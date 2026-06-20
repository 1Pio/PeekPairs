import Foundation

public struct BoardSize: Codable, Equatable, Hashable, Sendable, Identifiable {
    public static let minimumDimension = 2
    public static let maximumDimension = 8
    public static let presets: [BoardSize] = [
        BoardSize(uncheckedDimension: 4),
        BoardSize(uncheckedDimension: 6),
        BoardSize(uncheckedDimension: 8)
    ]

    public let dimension: Int

    public var id: Int { dimension }
    public var cardCount: Int { dimension * dimension }
    public var pairCount: Int { cardCount / 2 }
    public var label: String { "\(dimension)x\(dimension)" }

    public init(_ dimension: Int) throws {
        guard dimension >= Self.minimumDimension,
              dimension <= Self.maximumDimension,
              dimension.isMultiple(of: 2)
        else {
            throw BoardSizeError.invalidDimension(dimension)
        }
        self.dimension = dimension
    }

    public init(uncheckedDimension dimension: Int) {
        self.dimension = dimension
    }
}

public enum BoardSizeError: Error, Equatable {
    case invalidDimension(Int)
}
