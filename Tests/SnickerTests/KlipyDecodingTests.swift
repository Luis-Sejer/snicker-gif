import Foundation
import Testing
@testable import Snicker

/// Fixtures follow the shape of KLIPY's Tenor-compatible v2 responses.
struct KlipyDecodingTests {
    private func decode(_ json: String) throws -> [Gif] {
        try Klipy.decodeGifs(from: Data(json.utf8))
    }

    @Test func decodesAResult() throws {
        let gifs = try decode("""
        {"results": [{
            "id": "2484942301552561",
            "title": "Chatty Cat",
            "itemurl": "https://klipy.com/gifs/chatty-cat",
            "media_formats": {
                "gif": {"url": "https://static.klipy.com/full.gif", "dims": [480, 360]},
                "tinygif": {"url": "https://static.klipy.com/tiny.gif", "dims": [220, 165]}
            }
        }]}
        """)
        let gif = try #require(gifs.first)
        #expect(gif.id == "2484942301552561")
        #expect(gif.title == "Chatty Cat")
        #expect(gif.fullURL.absoluteString == "https://static.klipy.com/full.gif")
        #expect(gif.previewURL.absoluteString == "https://static.klipy.com/tiny.gif")
        #expect(gif.pageURL?.absoluteString == "https://klipy.com/gifs/chatty-cat")
        #expect(abs(gif.aspectRatio - 220.0 / 165.0) < 0.001)
    }

    @Test func acceptsNumericIDsAndFallsBackToTheDescription() throws {
        let gif = try #require(try decode("""
        {"results": [{"id": 7, "content_description": "A wave",
            "media_formats": {"gif": {"url": "https://static.klipy.com/wave.gif"}}}]}
        """).first)
        #expect(gif.id == "7")
        #expect(gif.title == "A wave")
        #expect(gif.previewURL == gif.fullURL, "without a tinygif the full GIF is the preview")
        #expect(gif.aspectRatio == 1, "without dimensions the tile is square")
    }

    @Test func skipsResultsWithoutAGif() throws {
        let gifs = try decode("""
        {"results": [
            {"id": "1", "media_formats": {"mp4": {"url": "https://static.klipy.com/1.mp4"}}},
            {"id": "2", "media_formats": {"gif": {"url": "https://static.klipy.com/2.gif"}}}
        ]}
        """)
        #expect(gifs.map(\.id) == ["2"])
    }

    @Test func clampsExtremeShapes() throws {
        let gifs = try decode("""
        {"results": [
            {"id": "wide", "media_formats": {"gif": {"url": "https://static.klipy.com/w.gif", "dims": [1000, 100]}}},
            {"id": "tall", "media_formats": {"gif": {"url": "https://static.klipy.com/t.gif", "dims": [100, 1000]}}}
        ]}
        """)
        #expect(gifs.map(\.aspectRatio) == [2.2, 0.5])
    }
}
