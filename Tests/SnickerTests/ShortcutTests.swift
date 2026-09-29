import Carbon.HIToolbox
import Testing
@testable import Snicker

struct ShortcutTests {
    @Test func openSnickerDefaultsToCommandOptionV() {
        #expect(ShortcutAction.openSnicker.defaultShortcut.displayString == "⌥⌘V")
    }

    @Test func modifiersShowInMenuOrder() {
        let all = Shortcut(keyCode: kVK_ANSI_G, modifiers: cmdKey | shiftKey | optionKey | controlKey, keyName: "G")
        #expect(all.displayString == "⌃⌥⇧⌘G")
    }

    @Test func noTwoActionsShareADefault() {
        let defaults = ShortcutAction.allCases.map(\.defaultShortcut)
        for (index, shortcut) in defaults.enumerated() {
            #expect(!defaults[(index + 1)...].contains { $0.matches(shortcut) })
        }
    }

    @Test func plainLettersDontWorkWhileTyping() {
        #expect(!Shortcut(keyCode: kVK_ANSI_J, keyName: "J").worksWhileTyping)
        #expect(Shortcut(keyCode: kVK_ANSI_J, modifiers: controlKey, keyName: "J").worksWhileTyping)
        #expect(Shortcut(keyCode: kVK_DownArrow, keyName: "↓").worksWhileTyping)
    }
}
