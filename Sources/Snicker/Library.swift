import Foundation

/// Favorites and recently used GIFs. Both lists are small, so they live in UserDefaults as JSON.
final class Library: ObservableObject {
    private static let favoritesKey = "favorites"
    private static let recentsKey = "recents"
    private static let recentsLimit = 60

    @Published private(set) var favorites: [Gif]
    @Published private(set) var recents: [Gif]

    init() {
        favorites = Self.load(Self.favoritesKey)
        recents = Self.load(Self.recentsKey)
    }

    var favoriteIDs: Set<String> { Set(favorites.map(\.id)) }

    func toggleFavorite(_ gif: Gif) {
        if favorites.contains(where: { $0.id == gif.id }) {
            favorites.removeAll { $0.id == gif.id }
        } else {
            favorites.insert(gif, at: 0)
        }
        Self.save(favorites, Self.favoritesKey)
    }

    func addRecent(_ gif: Gif) {
        recents.removeAll { $0.id == gif.id }
        recents.insert(gif, at: 0)
        recents = Array(recents.prefix(Self.recentsLimit))
        Self.save(recents, Self.recentsKey)
    }

    func clearRecents() {
        recents = []
        Self.save(recents, Self.recentsKey)
    }

    /// Unreadable data (say, from a future format) starts the list over rather than blocking the app.
    private static func load(_ key: String) -> [Gif] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Gif].self, from: data)) ?? []
    }

    private static func save(_ gifs: [Gif], _ key: String) {
        guard let data = try? JSONEncoder().encode(gifs) else { return } // plain value types; encoding cannot fail
        UserDefaults.standard.set(data, forKey: key)
    }
}
