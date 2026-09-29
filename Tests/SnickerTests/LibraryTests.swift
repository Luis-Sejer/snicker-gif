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

    @Test func recentEmojiKeepTheirSkinToneAndStayCapped() {
        let library = Library(defaults: defaults)
        library.addRecentEmoji("😂")
        library.addRecentEmoji("👋🏽")
        library.addRecentEmoji("😂")
        #expect(library.recentEmoji == ["😂", "👋🏽"])
        #expect(Library(defaults: defaults).recentEmoji == ["😂", "👋🏽"])

        for scalar in 0x1F600..<0x1F640 { library.addRecentEmoji(String(UnicodeScalar(scalar)!)) }
        #expect(library.recentEmoji.count == EmojiCatalog.recentLimit)
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

    @Test func recentSearchesDedupeIgnoringCaseAndCap() {
        let library = Library(defaults: defaults)
        library.addSearch("cat")
        library.addSearch("  dog ")
        library.addSearch("Cat")
        #expect(library.recentSearches == ["Cat", "dog"])
        for index in 0...Library.searchesLimit {
            library.addSearch("term \(index)")
        }
        #expect(library.recentSearches.count == Library.searchesLimit)
    }

    @Test func aGifLivesInOneSlotAndATakenSlotIsReplaced() {
        let library = Library(defaults: defaults)
        library.pin(gif("a"), to: 1)
        library.pin(gif("a"), to: 2)
        #expect(library.slots[1] == nil)
        #expect(library.slots[2]?.id == "a")

        library.pin(gif("b"), to: 2)
        #expect(library.slot(of: gif("a")) == nil)
        #expect(Library(defaults: defaults).slots[2]?.id == "b")
    }

    @Test func collectionsToggleGifsAndSurviveARelaunch() {
        let library = Library(defaults: defaults)
        let id = library.createCollection(named: "Work", with: gif("a"))
        library.toggle(gif("b"), in: id)
        library.toggle(gif("a"), in: id)
        #expect(library.collection(id)?.gifs.map(\.id) == ["b"])

        library.renameCollection(id, to: "Mondays")
        #expect(Library(defaults: defaults).collection(id)?.name == "Mondays")
    }
}
