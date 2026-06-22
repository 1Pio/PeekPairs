import AppKit
import Combine
import Foundation
import ImageIO

@MainActor
final class CardFigureImageStore: ObservableObject, @unchecked Sendable {
    static let shared = CardFigureImageStore()
    private static let decodePublishBatchSize = 4

    @Published private(set) var revision = 0

    private let decoder = CardFigureImageDecoder()
    private var imagesByName: [String: NSImage] = [:]
    private var missingNames: Set<String> = []
    private var queuedNames: [String] = []
    private var queuedNameSet: Set<String> = []
    private var decodingNames: Set<String> = []
    private var decodeTask: Task<Void, Never>?

    func image(named name: String) -> NSImage? {
        if let image = imagesByName[name] {
            return image
        }

        guard !missingNames.contains(name) else {
            return nil
        }

        preload([name])
        return nil
    }

    func preload(_ names: some Sequence<String>) {
        var didQueueName = false
        for name in names where shouldQueue(name) {
            queuedNames.append(name)
            queuedNameSet.insert(name)
            didQueueName = true
        }

        guard didQueueName else { return }
        startNextDecodeBatchIfNeeded()
    }

    private func shouldQueue(_ name: String) -> Bool {
        !imagesByName.keys.contains(name)
            && !missingNames.contains(name)
            && !decodingNames.contains(name)
            && !queuedNameSet.contains(name)
    }

    private func startNextDecodeBatchIfNeeded() {
        guard decodeTask == nil, !queuedNames.isEmpty else { return }

        let names = queuedNames
        queuedNames.removeAll()
        queuedNameSet.removeAll()
        decodingNames.formUnion(names)
        let publishBatchSize = Self.decodePublishBatchSize

        decodeTask = Task.detached(priority: .utility) { [decoder, names, weak self] in
            var decodedImages: [DecodedCardFigureImage] = []
            var missingNames: [String] = []
            var completedNames: [String] = []

            for name in names {
                guard !Task.isCancelled else { return }

                if let image = await decoder.decode(name: name) {
                    decodedImages.append(image)
                } else {
                    missingNames.append(name)
                }
                completedNames.append(name)

                if completedNames.count >= publishBatchSize {
                    await self?.apply(
                        CardFigureDecodeBatch(images: decodedImages, missingNames: missingNames),
                        completedNames: completedNames,
                        isFinalBatch: false
                    )
                    decodedImages.removeAll(keepingCapacity: true)
                    missingNames.removeAll(keepingCapacity: true)
                    completedNames.removeAll(keepingCapacity: true)
                }
            }

            guard !Task.isCancelled else { return }
            await self?.apply(
                CardFigureDecodeBatch(images: decodedImages, missingNames: missingNames),
                completedNames: completedNames,
                isFinalBatch: true
            )
        }
    }

    private func apply(
        _ batch: CardFigureDecodeBatch,
        completedNames: [String],
        isFinalBatch: Bool
    ) {
        decodingNames.subtract(completedNames)

        var didLoadImage = false
        for decodedImage in batch.images {
            let image = NSImage(
                cgImage: decodedImage.image,
                size: NSSize(width: decodedImage.image.width, height: decodedImage.image.height)
            )
            image.cacheMode = .always
            imagesByName[decodedImage.name] = image
            didLoadImage = true
        }

        missingNames.formUnion(batch.missingNames)
        if didLoadImage {
            revision &+= 1
        }

        if isFinalBatch {
            decodeTask = nil
            startNextDecodeBatchIfNeeded()
        }
    }
}

private actor CardFigureImageDecoder {
    private static let maximumRenderedPixelSize = 320

    func decode(name: String) -> DecodedCardFigureImage? {
        guard let image = loadImage(named: name) else {
            return nil
        }
        return DecodedCardFigureImage(name: name, image: image)
    }

    private func loadImage(named name: String) -> CGImage? {
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

        return downsampledImage(from: url)
    }

    private func downsampledImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.maximumRenderedPixelSize
        ]

        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}

private struct CardFigureDecodeBatch: Sendable {
    let images: [DecodedCardFigureImage]
    let missingNames: [String]
}

private struct DecodedCardFigureImage: @unchecked Sendable {
    let name: String
    let image: CGImage
}
