import AppKit
import UniformTypeIdentifiers

struct Gif: Identifiable {
    let id: String
    let title: String
    let previewURL: URL
    let fullURL: URL
    /// Width over height, so the grid can lay tiles out at their real shape.
    let aspectRatio: CGFloat

    var fileName: String {
        let slug = title.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(6)
            .joined(separator: "-")
        return (slug.isEmpty ? "gif" : slug) + ".gif"
    }
}

/// Klipy's Tenor-compatible v2 API (Tenor itself shut down in June 2026).
enum Klipy {
    static let apiKeyDefaultsKey = "klipyApiKey"
    private static let baseURL = "https://api.klipy.com/v2/"
    private static let resultLimit = "40"

    static func fetch(query: String, apiKey: String) async throws -> [Gif] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        var components = URLComponents(string: baseURL + (trimmed.isEmpty ? "featured" : "search"))!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "client_key", value: "gifbar"),
            URLQueryItem(name: "limit", value: resultLimit),
            URLQueryItem(name: "media_filter", value: "gif,tinygif"),
        ] + (trimmed.isEmpty ? [] : [URLQueryItem(name: "q", value: trimmed)])

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard statusCode == 200 else {
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.errors.message.first
            throw KlipyError(statusCode: statusCode, message: message)
        }
        return try JSONDecoder().decode(SearchResponse.self, from: data).results.compactMap(\.gif)
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

private struct SearchResponse: Decodable {
    let results: [Item]

    struct Item: Decodable {
        let id: String
        let title: String?
        let contentDescription: String?
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
                aspectRatio: min(max(aspectRatio, Self.aspectRatioRange.lowerBound), Self.aspectRatioRange.upperBound)
            )
        }
    }
}

enum GifFile {
    private static let cacheDirectory = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("GifBar")

    /// Downloads once per GIF; the per-id folder keeps a readable file name without collisions.
    static func download(_ gif: Gif) async throws -> URL {
        let folder = cacheDirectory.appendingPathComponent(gif.id)
        let file = folder.appendingPathComponent(gif.fileName)
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

    static func dragProvider(for gif: Gif) -> NSItemProvider {
        let provider = NSItemProvider()
        provider.suggestedName = gif.fileName
        provider.registerFileRepresentation(forTypeIdentifier: UTType.gif.identifier, fileOptions: [], visibility: .all) { completion in
            Task {
                do { completion(try await download(gif), false, nil) } catch { completion(nil, false, error) }
            }
            return nil
        }
        return provider
    }
}
