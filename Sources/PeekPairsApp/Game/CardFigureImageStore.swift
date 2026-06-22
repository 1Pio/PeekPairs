import AppKit
import Foundation

@MainActor
final class CardFigureImageStore {
    static let shared = CardFigureImageStore()

    private var imagesByName: [String: NSImage] = [:]
    private var missingNames: Set<String> = []

    func image(named name: String) -> NSImage? {
        if let image = imagesByName[name] {
            return image
        }

        guard !missingNames.contains(name) else {
            return nil
        }

        guard let image = loadImage(named: name) else {
            missingNames.insert(name)
            return nil
        }

        imagesByName[name] = image
        return image
    }

    func preload(_ names: some Sequence<String>) {
        for name in names {
            _ = image(named: name)
        }
    }

    private func loadImage(named name: String) -> NSImage? {
        let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "CardFigures")
            ?? Bundle.module.url(forResource: name, withExtension: "png")
            ?? Bundle.module.url(
                forResource: name,
                withExtension: "png",
                subdirectory: "CardFigures"
            )

        guard let url, let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.cacheMode = .always
        return image
    }
}
