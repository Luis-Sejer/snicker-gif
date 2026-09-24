import Foundation
import Testing
@testable import Snicker

struct GifTests {
    private func gif(id: String = "123", title: String) -> Gif {
        let url = URL(string: "https://static.klipy.com/a.gif")!
        return Gif(id: id, title: title, previewURL: url, fullURL: url, pageURL: nil, aspectRatio: 1)
    }

    @Test func fileNameIsASlugOfTheTitle() {
        #expect(gif(title: "Happy Birthday, Friend!").fileName(random: false) == "happy-birthday-friend.gif")
    }

    @Test func fileNameKeepsAtMostSixWords() {
        #expect(gif(title: "one two three four five six seven").fileName(random: false) == "one-two-three-four-five-six.gif")
    }

    @Test func fileNameFallsBackWhenTheTitleHasNoLetters() {
        #expect(gif(title: "").fileName(random: false) == "gif.gif")
        #expect(gif(title: "🎉!!").fileName(random: false) == "gif.gif")
    }

    @Test func randomFileNameHidesTheTitleAndIsStable() {
        let party = gif(id: "42", title: "Party time")
        let name = party.fileName(random: true)
        #expect(!name.contains("party"))
        #expect(name.hasPrefix("GIF-") && name.hasSuffix(".gif"))
        #expect(name == party.fileName(random: true), "the same GIF must reuse its cached download")
        #expect(name != gif(id: "43", title: "Party time").fileName(random: true))
    }
}
