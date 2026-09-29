import Foundation
import Testing
@testable import Snicker

struct BrowseModeTests {
    @Test func everyModeSurvivesStorage() {
        let modes: [BrowseMode] = [.klipy, .favorites, .recents, .emoji, .collection(UUID())]
        for mode in modes {
            #expect(BrowseMode(storageKey: mode.storageKey) == mode)
        }
    }

    @Test func unknownStorageIsIgnored() {
        #expect(BrowseMode(storageKey: "collection:not-a-uuid") == nil)
        #expect(BrowseMode(storageKey: "stickers") == nil)
    }
}
