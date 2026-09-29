import AppKit
import CoreText

/// One emoji in the picker. Its skin-tone variants are offered from its right-click menu, like Apple's picker.
struct Emoji: Hashable, Identifiable {
    let character: String
    let name: String
    let variants: [String]
    /// The name's words and CLDR's keywords, lowercased, so "lol" finds 😂.
    let searchWords: [String]

    var id: String { character }

    /// "Grinning face" rather than "grinning face", for tooltips and VoiceOver.
    var title: String { name.prefix(1).uppercased() + name.dropFirst() }

    init(character: String, name: String, keywords: [String] = [], variants: [String] = []) {
        self.character = character
        self.name = name
        self.variants = variants
        searchWords = Self.words(in: name) + keywords
    }

    /// Every word of the query has to start a word of the name or keywords, the way Apple's picker searches.
    func matches(_ queryWords: [String]) -> Bool {
        queryWords.allSatisfy { query in searchWords.contains { $0.hasPrefix(query) } }
    }

    static func words(in text: String) -> [String] {
        text.lowercased().split { $0.isWhitespace || $0 == ":" || $0 == "," }.map(String.init)
    }

    private static let toneNames: [UInt32: String] = [
        0x1F3FB: "light", 0x1F3FC: "medium-light", 0x1F3FD: "medium", 0x1F3FE: "medium-dark", 0x1F3FF: "dark",
    ]

    /// "medium skin tone", or "light skin tone, dark skin tone" for two people, as Unicode names them.
    static func toneDescription(of variant: String) -> String {
        let tones = variant.unicodeScalars.compactMap { toneNames[$0.value] }
        let distinct = Set(tones).count == 1 ? Array(tones.prefix(1)) : tones
        return distinct.map { "\($0) skin tone" }.joined(separator: ", ")
    }
}

/// A group of emoji in the picker: one of Apple's categories, recently used, or search results.
struct EmojiSection: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let emoji: [Emoji]
    /// Built once here rather than on every redraw of the grid.
    let items: [EmojiItem]

    init(id: String, title: String, systemImage: String, emoji: [Emoji]) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.emoji = emoji
        items = emoji.map { EmojiItem(id: "\(id)/\($0.character)", emoji: $0) }
    }
}

/// An emoji where it shows in the picker: the same one can be in Recently Used and in its category.
struct EmojiItem: Identifiable, Equatable {
    let id: String
    let emoji: Emoji
}

/// Every emoji this Mac can draw, in Apple's categories and order. Built once, from `EmojiData`.
enum EmojiCatalog {
    static let recentID = "recent"
    static let resultsID = "results"
    static let recentLimit = 24

    private static let systemImages = [
        "Smileys & People": "face.smiling", "Animals & Nature": "pawprint", "Food & Drink": "fork.knife",
        "Activity": "soccerball", "Travel & Places": "car", "Objects": "lightbulb", "Symbols": "heart", "Flags": "flag",
    ]

    static let categories: [EmojiSection] = parse(EmojiData.table, keeping: canDraw)

    /// Any emoji or skin-tone variant, for showing recently used ones with their names.
    private static let byCharacter: [String: Emoji] = {
        var all: [String: Emoji] = [:]
        for emoji in categories.flatMap(\.emoji) {
            all[emoji.character] = emoji
            for variant in emoji.variants {
                all[variant] = Emoji(character: variant, name: "\(emoji.name): \(Emoji.toneDescription(of: variant))")
            }
        }
        return all
    }()

    static func emoji(for character: String) -> Emoji? { byCharacter[character] }

    /// Recently used first, then every category; or, while searching, one section of matches.
    static func sections(query: String, recent: [String]) -> [EmojiSection] {
        let queryWords = Emoji.words(in: query)
        if !queryWords.isEmpty {
            let matches = categories.flatMap(\.emoji).filter { $0.matches(queryWords) }
            return matches.isEmpty ? [] : [EmojiSection(id: resultsID, title: "Results", systemImage: "magnifyingglass", emoji: matches)]
        }
        let recentEmoji = recent.compactMap(emoji(for:))
        guard !recentEmoji.isEmpty else { return categories }
        return [EmojiSection(id: recentID, title: "Recently Used", systemImage: "clock", emoji: recentEmoji)] + categories
    }

    static func parse(_ table: String, keeping keep: (String) -> Bool = { _ in true }) -> [EmojiSection] {
        var sections: [EmojiSection] = []
        var title: String?
        var emoji: [Emoji] = []
        func finishSection() {
            guard let title else { return }
            sections.append(EmojiSection(id: title, title: title, systemImage: systemImages[title] ?? "circle", emoji: emoji))
        }
        for line in table.split(separator: "\n") {
            if line.hasPrefix("@") {
                finishSection()
                title = String(line.dropFirst())
                emoji = []
                continue
            }
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 4, keep(fields[0]) else { continue }
            emoji.append(Emoji(
                character: fields[0],
                name: fields[1],
                keywords: fields[2].split(separator: " ").map(String.init),
                variants: fields[3].split(separator: " ").map(String.init).filter(keep)
            ))
        }
        finishSection()
        return sections
    }

    // MARK: What this Mac can draw

    /// The list follows the newest Emoji version, which an older macOS draws as a box or as loose pieces
    /// (🧑 🐰 🧑 instead of one picture). Those are hidden rather than shown broken.
    static func canDraw(_ emoji: String) -> Bool {
        let glyphs = glyphs(for: emoji)
        guard !glyphs.isEmpty, !glyphs.contains(0), !glyphs.contains(missingGlyph) else { return false }
        guard glyphs.count > 1 else { return true }
        // Couples are drawn as two glyphs too, so compare with the pieces drawn one by one.
        let pieces = emoji.unicodeScalars.filter { $0 != zeroWidthJoiner && $0 != emojiPresentation }
        return glyphs != pieces.flatMap { self.glyphs(for: String($0)) }
    }

    private static let zeroWidthJoiner: Unicode.Scalar = "\u{200D}"
    private static let emojiPresentation: Unicode.Scalar = "\u{FE0F}"
    private static let font = CTFontCreateWithName("AppleColorEmoji" as CFString, 16, nil)
    /// Apple Color Emoji's own "missing" picture, which it uses for emoji newer than the font.
    private static let missingGlyph = glyphs(for: "\u{10FFFD}").first ?? 0

    private static func glyphs(for text: String) -> [CGGlyph] {
        let string = NSAttributedString(string: text, attributes: [.init(kCTFontAttributeName as String): font])
        let runs = CTLineGetGlyphRuns(CTLineCreateWithAttributedString(string)) as? [CTRun] ?? []
        return runs.flatMap { run in
            var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
            CTRunGetGlyphs(run, CFRange(), &glyphs)
            return glyphs
        }
    }

    // MARK: Clipboard

    static func copyToPasteboard(_ character: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(character, forType: .string)
    }
}
