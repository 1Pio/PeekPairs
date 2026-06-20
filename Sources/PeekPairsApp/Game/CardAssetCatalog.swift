import Foundation

enum CardAssetCatalog {
    static let names: [String] = (1...32).map { index in
        "figure-\(String(format: "%02d", index))"
    }
}
