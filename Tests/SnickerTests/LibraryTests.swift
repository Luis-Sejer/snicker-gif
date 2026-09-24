import Foundation
import Testing
@testable import Snicker

struct LibraryTests {
    /// A throwaway defaults domain, so tests never touch the real app's favorites.
    private let defaults = UserDefaults(suiteName: "SnickerTests-\(UUID().uuidString)")!

    private func gif(_ id: String) -> Gif {
        let url = URL(string: "https://static.klipy.com/\(id).gif")!
        return Gif(id: id, title: id, previewURL: url, fullURL: url, pageURL: nil, aspectRatio: 1)
    }

    @Test func togglingAddsNewestFirstThenRemoves() {
        let library = Library(defaults: defaults)
        library.toggleFavorite(gif("a"))
        library.toggleFavorite(gif("b"))
        #expect(library.favorites.map(\.id) == ["b", "a"])

        library.toggleFavorite(gif("a"))
        #expect(library.favorites.map(\.id) == ["b"])
    }

    @Test func recentsMoveAReusedGifToTheFront() {
        let library = Library(defaults: defaults)
        library.addRecent(gif("a"))
        library.addRecent(gif("b"))
        library.addRecent(gif("a"))
        #expect(library.recents.map(\.id) == ["a", "b"])
    }

    @Test func recentsAreCapped() {
        let library = Library(defaults: defaults)
        for index in 0...Library.recentsLimit {
            library.addRecent(gif("\(index)"))
        }
        #expect(library.recents.count == Library.recentsLimit)
        #expect(library.recents.first?.id == "\(Library.recentsLimit)")
    }

    @Test func survivesARelaunch() {
        let library = Library(defaults: defaults)
        library.toggleFavorite(gif("a"))
        library.addRecent(gif("b"))

        let relaunched = Library(defaults: defaults)
        #expect(relaunched.favorites.map(\.id) == ["a"])
        #expect(relaunched.recents.map(\.id) == ["b"])
    }

    @Test func clearingRecentsKeepsFavorites() {
        let library = Library(defaults: defaults)
        library.toggleFavorite(gif("a"))
        library.addRecent(gif("a"))
        library.clearRecents()
        #expect(library.recents.isEmpty)
        #expect(library.favorites.map(\.id) == ["a"])
    }
}
