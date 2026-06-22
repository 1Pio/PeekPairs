import AppKit
import Foundation
import ImageIO

@MainActor
final class CardFigureImageStore {
    static let shared = CardFigureImageStore()
    private static let maximumRenderedPixelSize = 320

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

        guard let url else {
            return nil
        }

        let image = downsampledImage(from: url) ?? NSImage(contentsOf: url)
        guard let image else { return nil }

        image.cacheMode = .always
        return image
    }

    private func downsampledImage(from url: URL) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.maximumRenderedPixelSize
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return NSImage(
            cgImage: image,
            size: NSSize(width: image.width, height: image.height)
        )
    }
}
