import Foundation

enum AppStorageFile {
    case settings
    case history

    var filename: String {
        switch self {
        case .settings:
            "settings.json"
        case .history:
            "history.json"
        }
    }
}

struct AppFileStore {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let rootURL: URL

    init(
        fileManager: FileManager = .default,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()

        let supportURL: URL
        if let overridePath = environment["PEEKPAIRS_SUPPORT_DIR"], !overridePath.isEmpty {
            supportURL = URL(fileURLWithPath: overridePath, isDirectory: true)
        } else {
            supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        }

        rootURL = supportURL.appendingPathComponent("PeekPairs", isDirectory: true)

        try? fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    func load<T: Decodable>(_ type: T.Type, from file: AppStorageFile, fallback: T) -> T {
        let url = rootURL.appendingPathComponent(file.filename)
        guard let data = try? Data(contentsOf: url) else { return fallback }
        return (try? decoder.decode(type, from: data)) ?? fallback
    }

    func save<T: Encodable>(_ value: T, to file: AppStorageFile) {
        let url = rootURL.appendingPathComponent(file.filename)
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
