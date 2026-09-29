import Foundation

/// A named set of GIFs, like "Work" or "Mondays".
struct GifCollection: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var gifs: [Gif]
}

/// Favorites, recents, recent searches, favorite slots and collections. All small, so they live in UserDefaults as JSON.
final class Library: ObservableObject {
    private static let favoritesKey = "favorites"
    private static let recentsKey = "recents"
    private static let searchesKey = "recentSearches"
    private static let slotsKey = "favoriteSlots"
    private static let collectionsKey = "collections"
    static let recentsLimit = 60
    static let searchesLimit = 8
    static let slotNumbers = 1...9

    @Published private(set) var favorites: [Gif]
    @Published private(set) var recents: [Gif]
    @Published private(set) var recentSearches: [String]
    /// Slot number to GIF; each copies from any app with its own shortcut.
    @Published private(set) var slots: [Int: Gif]
    @Published private(set) var collections: [GifCollection]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favorites = Self.load(Self.favoritesKey, from: defaults) ?? []
        recents = Self.load(Self.recentsKey, from: defaults) ?? []
        recentSearches = Self.load(Self.searchesKey, from: defaults) ?? []
        let storedSlots: [String: Gif] = Self.load(Self.slotsKey, from: defaults) ?? [:]
        slots = Dictionary(uniqueKeysWithValues: storedSlots.compactMap { key, gif in Int(key).map { ($0, gif) } })
        collections = Self.load(Self.collectionsKey, from: defaults) ?? []
    }

    var favoriteIDs: Set<String> { Set(favorites.map(\.id)) }

    // MARK: Favorites and recents

    func toggleFavorite(_ gif: Gif) {
        if favorites.contains(where: { $0.id == gif.id }) {
            favorites.removeAll { $0.id == gif.id }
        } else {
            favorites.insert(gif, at: 0)
        }
        save(favorites, Self.favoritesKey)
    }

    func addRecent(_ gif: Gif) {
        recents.removeAll { $0.id == gif.id }
        recents.insert(gif, at: 0)
        recents = Array(recents.prefix(Self.recentsLimit))
        save(recents, Self.recentsKey)
    }

    func clearRecents() {
        recents = []
        save(recents, Self.recentsKey)
    }

    // MARK: Recent searches

    /// Recorded when a GIF from the search gets used, so abandoned half-typed searches don't pile up.
    func addSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        recentSearches = Array(recentSearches.prefix(Self.searchesLimit))
        save(recentSearches, Self.searchesKey)
    }

    func removeSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        save(recentSearches, Self.searchesKey)
    }

    func clearSearches() {
        recentSearches = []
        save(recentSearches, Self.searchesKey)
    }

    // MARK: Favorite slots

    func slot(of gif: Gif) -> Int? {
        slots.first { $0.value.id == gif.id }?.key
    }

    /// A GIF lives in one slot at most, and pinning to a taken slot replaces what was there.
    func pin(_ gif: Gif, to slot: Int) {
        guard Self.slotNumbers.contains(slot) else { return }
        if let current = self.slot(of: gif) { slots[current] = nil }
        slots[slot] = gif
        saveSlots()
    }

    func unpin(_ gif: Gif) {
        guard let current = slot(of: gif) else { return }
        slots[current] = nil
        saveSlots()
    }

    private func saveSlots() {
        save(Dictionary(uniqueKeysWithValues: slots.map { (String($0.key), $0.value) }), Self.slotsKey)
    }

    // MARK: Collections

    func collection(_ id: UUID) -> GifCollection? {
        collections.first { $0.id == id }
    }

    @discardableResult
    func createCollection(named name: String, with gif: Gif? = nil) -> UUID {
        let collection = GifCollection(id: UUID(), name: name, gifs: gif.map { [$0] } ?? [])
        collections.append(collection)
        save(collections, Self.collectionsKey)
        return collection.id
    }

    func renameCollection(_ id: UUID, to name: String) {
        guard let index = collections.firstIndex(where: { $0.id == id }) else { return }
        collections[index].name = name
        save(collections, Self.collectionsKey)
    }

    func deleteCollection(_ id: UUID) {
        collections.removeAll { $0.id == id }
        save(collections, Self.collectionsKey)
    }

    func toggle(_ gif: Gif, in id: UUID) {
        guard let index = collections.firstIndex(where: { $0.id == id }) else { return }
        if collections[index].gifs.contains(where: { $0.id == gif.id }) {
            collections[index].gifs.removeAll { $0.id == gif.id }
        } else {
            collections[index].gifs.insert(gif, at: 0)
        }
        save(collections, Self.collectionsKey)
    }

    // MARK: Storage

    /// Unreadable data (say, from a future format) starts the list over rather than blocking the app.
    private static func load<Value: Decodable>(_ key: String, from defaults: UserDefaults) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    private func save<Value: Encodable>(_ value: Value, _ key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return } // plain value types; encoding cannot fail
        defaults.set(data, forKey: key)
    }
}
