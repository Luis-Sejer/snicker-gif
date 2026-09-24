import AppKit
import UniformTypeIdentifiers

/// Codable so favorites and recents can be kept between launches.
struct Gif: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let previewURL: URL
    /// The full-size GIF; also what "Copy Link" copies, since chat apps unfurl it inline.
    let fullURL: URL
    /// The GIF's page on KLIPY.
    let pageURL: URL?
    /// Width over height, so the grid can lay tiles out at their real shape.
    let aspectRatio: CGFloat

    /// A readable name from the title, or with `random` a stable name that gives nothing away.
    func fileName(random: Bool) -> String {
        guard !random else { return "GIF-\(Self.stableHash(id)).gif" }
        let slug = title.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(6)
            .joined(separator: "-")
        return (slug.isEmpty ? "gif" : slug) + ".gif"
    }

    /// FNV-1a, so the same GIF always gets the same name and hits the download cache.
    private static func stableHash(_ text: String) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100_0000_01b3
        }
        return String(String(hash, radix: 16, uppercase: true).suffix(8))
    }
}

/// Klipy's Tenor-compatible v2 API (Tenor itself shut down in June 2026).
enum Klipy {
    static let apiKeyDefaultsKey = "klipyApiKey"
    private static let baseURL = "https://api.klipy.com/v2/"
    private static let resultLimit = "40"

    private static let suggestionLimit = "8"

    /// Trending when the query is empty, otherwise search results.
    static func fetch(query: String, apiKey: String) async throws -> [Gif] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let data = try await request(
            trimmed.isEmpty ? "featured" : "search",
            apiKey: apiKey,
            parameters: ["limit": resultLimit, "media_filter": "gif,tinygif"].merging(trimmed.isEmpty ? [:] : ["q": trimmed]) { $1 }
        )
        return try decodeGifs(from: data)
    }

    /// Results without a GIF rendition are skipped rather than failing the whole page.
    static func decodeGifs(from data: Data) throws -> [Gif] {
        try JSONDecoder().decode(SearchResponse.self, from: data).results.compactMap(\.gif)
    }

    /// Completions for a partly typed query, like "hap" → "happy", "happy birthday".
    static func autocomplete(query: String, apiKey: String) async throws -> [String] {
        let data = try await request("autocomplete", apiKey: apiKey, parameters: ["q": query, "limit": suggestionLimit])
        return try JSONDecoder().decode(TermsResponse.self, from: data).results
    }

    private static func request(_ endpoint: String, apiKey: String, parameters: [String: String]) async throws -> Data {
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "client_key", value: "snicker"),
        ] + parameters.map { URLQueryItem(name: $0.key, value: $0.value) }

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard statusCode == 200 else {
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.errors.message.first
            throw KlipyError(statusCode: statusCode, message: message)
        }
        return data
    }
}

/// Klipy answers an invalid key with a 404 and a readable message, so prefer the message over the code.
struct KlipyError: LocalizedError {
    let statusCode: Int
    let message: String?
    var errorDescription: String? { message ?? "Klipy returned HTTP \(statusCode)" }
}

private struct ErrorResponse: Decodable {
    let errors: Errors
    struct Errors: Decodable { let message: [String] }
}

private struct TermsResponse: Decodable {
    let results: [String]
}

private struct SearchResponse: Decodable {
    let results: [Item]

    struct Item: Decodable {
        let id: String
        let title: String?
        let contentDescription: String?
        let itemURL: URL?
        let mediaFormats: [String: Media]

        /// Keeps a panorama or a sliver from wrecking the masonry columns.
        private static let aspectRatioRange: ClosedRange<CGFloat> = 0.5...2.2

        struct Media: Decodable {
            let url: URL
            let dims: [Int]?

            var aspectRatio: CGFloat? {
                guard let dims, dims.count == 2, dims[0] > 0, dims[1] > 0 else { return nil }
                return CGFloat(dims[0]) / CGFloat(dims[1])
            }
        }

        enum CodingKeys: String, CodingKey {
            case id, title
            case contentDescription = "content_description"
            case itemURL = "itemurl"
            case mediaFormats = "media_formats"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let stringID = try? container.decode(String.self, forKey: .id) {
                id = stringID
            } else {
                id = String(try container.decode(Int.self, forKey: .id))
            }
            title = try container.decodeIfPresent(String.self, forKey: .title)
            contentDescription = try container.decodeIfPresent(String.self, forKey: .contentDescription)
            itemURL = try? container.decodeIfPresent(URL.self, forKey: .itemURL)
            mediaFormats = try container.decodeIfPresent([String: Media].self, forKey: .mediaFormats) ?? [:]
        }

        var gif: Gif? {
            guard let full = mediaFormats["gif"] else { return nil }
            let preview = mediaFormats["tinygif"] ?? full
            let aspectRatio = preview.aspectRatio ?? full.aspectRatio ?? 1
            return Gif(
                id: id,
                title: title ?? contentDescription ?? "",
                previewURL: preview.url,
                fullURL: full.url,
                pageURL: itemURL,
                aspectRatio: min(max(aspectRatio, Self.aspectRatioRange.lowerBound), Self.aspectRatioRange.upperBound)
            )
        }
    }
}

enum GifFile {
    private static let cacheDirectory = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Snicker")

    /// Downloads once per GIF; the per-id folder keeps a readable file name without collisions.
    static func download(_ gif: Gif, randomName: Bool) async throws -> URL {
        let folder = cacheDirectory.appendingPathComponent(gif.id)
        let file = folder.appendingPathComponent(gif.fileName(random: randomName))
        if FileManager.default.fileExists(atPath: file.path) { return file }

        let (temporaryFile, _) = try await URLSession.shared.download(from: gif.fullURL)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: temporaryFile, to: file)
        return file
    }

    /// Teams only pastes a file URL; Slack, Discord and Messages also take the raw GIF data. Write both.
    static func copyToPasteboard(_ file: URL) throws {
        let data = try Data(contentsOf: file)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([file as NSURL])
        pasteboard.setData(data, forType: NSPasteboard.PasteboardType(UTType.gif.identifier))
    }

    static func copyLinkToPasteboard(_ gif: Gif) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(gif.fullURL.absoluteString, forType: .string)
    }

    /// Copies into ~/Downloads, numbering the name if a file is already there.
    static func saveToDownloads(_ file: URL) throws -> URL {
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let stem = file.deletingPathExtension().lastPathComponent
        var destination = downloads.appendingPathComponent(file.lastPathComponent)
        var number = 2
        while FileManager.default.fileExists(atPath: destination.path) {
            destination = downloads.appendingPathComponent("\(stem) \(number).gif")
            number += 1
        }
        try FileManager.default.copyItem(at: file, to: destination)
        return destination
    }

    static func dragProvider(for gif: Gif, randomName: Bool) -> NSItemProvider {
        let provider = NSItemProvider()
        provider.suggestedName = gif.fileName(random: randomName)
        provider.registerFileRepresentation(forTypeIdentifier: UTType.gif.identifier, fileOptions: [], visibility: .all) { completion in
            Task {
                do { completion(try await download(gif, randomName: randomName), false, nil) } catch { completion(nil, false, error) }
            }
            return nil
        }
        return provider
    }
}
