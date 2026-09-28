import Testing
@testable import Snicker

struct UpdaterTests {
    @Test func newerPatchMinorAndMajorVersionsCount() {
        #expect(Updater.isVersion("1.0.2", newerThan: "1.0.1"))
        #expect(Updater.isVersion("1.1.0", newerThan: "1.0.9"))
        #expect(Updater.isVersion("2.0.0", newerThan: "1.9.9"))
    }

    @Test func versionsCompareNumberByNumber() {
        #expect(Updater.isVersion("1.10.0", newerThan: "1.9.0"))
    }

    @Test func theSameOrAnOlderVersionIsNotAnUpdate() {
        #expect(!Updater.isVersion("1.1.0", newerThan: "1.1.0"))
        #expect(!Updater.isVersion("1.0.1", newerThan: "1.1.0"))
    }
}
