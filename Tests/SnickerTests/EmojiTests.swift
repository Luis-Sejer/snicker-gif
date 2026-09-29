import Testing
@testable import Snicker

struct EmojiTests {
    private let table = """
    @Smileys & People
    😂|face with tears of joy|funny lol laugh|
    👋|waving hand|bye hello|👋🏻 👋🏿
    @Flags
    🇩🇰|flag: Denmark||
    """

    @Test func parsesCategoriesInOrder() {
        let sections = EmojiCatalog.parse(table)
        #expect(sections.map(\.title) == ["Smileys & People", "Flags"])
        #expect(sections[0].emoji.map(\.character) == ["😂", "👋"])
        #expect(sections[0].emoji[1].variants == ["👋🏻", "👋🏿"])
        #expect(sections[0].systemImage == "face.smiling")
    }

    @Test func hiddenEmojiAndVariantsAreLeftOut() {
        let sections = EmojiCatalog.parse(table) { $0 != "😂" && $0 != "👋🏿" }
        #expect(sections[0].emoji.map(\.character) == ["👋"])
        #expect(sections[0].emoji[0].variants == ["👋🏻"])
    }

    @Test func searchMatchesTheStartOfNameAndKeywordWords() {
        let emoji = EmojiCatalog.parse(table)[0].emoji[0]
        #expect(emoji.matches(Emoji.words(in: "lol")))
        #expect(emoji.matches(Emoji.words(in: "Tears JO")))
        #expect(!emoji.matches(Emoji.words(in: "ears")))
        #expect(!emoji.matches(Emoji.words(in: "tears dog")))
    }

    @Test func skinTonesAreNamedTheWayUnicodeNamesThem() {
        #expect(Emoji.toneDescription(of: "👋🏽") == "medium skin tone")
        #expect(Emoji.toneDescription(of: "🧑🏻‍🤝‍🧑🏻") == "light skin tone")
        #expect(Emoji.toneDescription(of: "🧑🏻‍🤝‍🧑🏿") == "light skin tone, dark skin tone")
    }

    @Test func theBundledListCoversEveryCategory() {
        let sections = EmojiCatalog.parse(EmojiData.table)
        #expect(sections.map(\.title) == ["Smileys & People", "Animals & Nature", "Food & Drink", "Activity", "Travel & Places", "Objects", "Symbols", "Flags"])
        #expect(sections.flatMap(\.emoji).count > 1_900)
        #expect(sections[0].emoji.first?.character == "😀")
    }

    @Test func theSystemFontDrawsCommonEmojiButNotLoosePieces() {
        #expect(EmojiCatalog.canDraw("😀"))
        #expect(EmojiCatalog.canDraw("👩‍❤️‍👨")) // drawn as two glyphs, but as one picture
        #expect(EmojiCatalog.canDraw("🇩🇰"))
        #expect(!EmojiCatalog.canDraw("😀\u{200D}🐶")) // not a real sequence
    }

    @Test func recentlyUsedComesFirstAndSearchReplacesTheCategories() {
        let browsing = EmojiCatalog.sections(query: "", recent: ["👋🏽"])
        #expect(browsing.first?.id == EmojiCatalog.recentID)
        #expect(browsing.first?.emoji.first?.name == "waving hand: medium skin tone")

        let searching = EmojiCatalog.sections(query: "thumbs up", recent: ["👋🏽"])
        #expect(searching.map(\.id) == [EmojiCatalog.resultsID])
        #expect(searching.first?.emoji.first?.character == "👍")
        #expect(EmojiCatalog.sections(query: "zzqx", recent: []).isEmpty)
    }

    @Test func itemIDsAreUniquePerSection() {
        let sections = EmojiCatalog.sections(query: "", recent: ["😀"])
        let ids = sections.flatMap(\.items).map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
