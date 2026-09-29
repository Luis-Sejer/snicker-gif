import AppKit
import Carbon.HIToolbox

/// A key plus modifiers, stored in Carbon's terms because that is what `RegisterEventHotKey` takes.
struct Shortcut: Codable, Equatable {
    let keyCode: UInt32
    let carbonModifiers: UInt32
    /// Captured when recorded, because turning a key code back into a character depends on the keyboard layout.
    let keyName: String

    private static let specialKeyNames: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    /// Keys that don't type anything in the search field, so they work in Snicker without a modifier.
    private static let plainKeys: Set<Int> = [
        kVK_Return, kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow, kVK_Home, kVK_End, kVK_PageUp, kVK_PageDown,
        kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12,
    ]

    init(keyCode: Int, modifiers: Int = 0, keyName: String) {
        self.keyCode = UInt32(keyCode)
        self.carbonModifiers = UInt32(modifiers)
        self.keyName = keyName
    }

    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers = 0
        if flags.contains(.command) { modifiers |= cmdKey }
        if flags.contains(.option) { modifiers |= optionKey }
        if flags.contains(.control) { modifiers |= controlKey }
        if flags.contains(.shift) { modifiers |= shiftKey }
        let name = Self.specialKeyNames[Int(event.keyCode)] ?? event.charactersIgnoringModifiers?.uppercased() ?? ""
        guard !name.isEmpty else { return nil }
        self.init(keyCode: Int(event.keyCode), modifiers: modifiers, keyName: name)
    }

    var hasCommandOptionOrControl: Bool {
        carbonModifiers & UInt32(cmdKey | optionKey | controlKey) != 0
    }

    /// A plain letter would stop that letter from typing in the search field.
    var worksWhileTyping: Bool {
        hasCommandOptionOrControl || Self.plainKeys.contains(Int(keyCode))
    }

    func matches(_ other: Shortcut) -> Bool {
        keyCode == other.keyCode && carbonModifiers == other.carbonModifiers
    }

    /// In the order macOS menus use: ⌃⌥⇧⌘, then the key.
    var displayString: String {
        let symbols: [(Int, String)] = [(controlKey, "⌃"), (optionKey, "⌥"), (shiftKey, "⇧"), (cmdKey, "⌘")]
        return symbols.filter { carbonModifiers & UInt32($0.0) != 0 }.map(\.1).joined() + keyName
    }
}

/// Everything the keyboard can do in Snicker. Every one is remappable, for keyboards without arrow keys and friends.
enum ShortcutAction: String, CaseIterable {
    case openSnicker, selectNext, selectPrevious, copyGif, copyLink, toggleFavorite, saveToDownloads, surpriseMe, switchMediaKind
    case showFavorites, showRecent, showTrending
    case favoriteSlot1, favoriteSlot2, favoriteSlot3, favoriteSlot4, favoriteSlot5
    case favoriteSlot6, favoriteSlot7, favoriteSlot8, favoriteSlot9

    /// Digit key codes aren't in order on the keyboard, hence the table.
    private static let digitKeyCodes = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9]

    static let favoriteSlots: [ShortcutAction] = [
        .favoriteSlot1, .favoriteSlot2, .favoriteSlot3, .favoriteSlot4, .favoriteSlot5,
        .favoriteSlot6, .favoriteSlot7, .favoriteSlot8, .favoriteSlot9,
    ]

    static func favoriteSlot(_ number: Int) -> ShortcutAction { favoriteSlots[number - 1] }

    var slotNumber: Int? {
        Self.favoriteSlots.firstIndex(of: self).map { $0 + 1 }
    }

    var title: String {
        if let slotNumber { return "Favorite Slot \(slotNumber)" }
        switch self {
        case .openSnicker: return "Open Snicker"
        case .selectNext: return "Next GIF"
        case .selectPrevious: return "Previous GIF"
        case .copyGif: return "Copy GIF"
        case .copyLink: return "Copy Link"
        case .toggleFavorite: return "Add to or Remove from Favorites"
        case .saveToDownloads: return "Save to Downloads"
        case .surpriseMe: return "Surprise Me"
        case .switchMediaKind: return "Switch GIFs and Stickers"
        case .showFavorites: return "Show Favorites"
        case .showRecent: return "Show Recent"
        case .showTrending: return "Show Trending"
        default: return rawValue
        }
    }

    /// Opening Snicker and the favorite slots work from any app; the rest work while Snicker is open.
    var isGlobal: Bool { self == .openSnicker || slotNumber != nil }

    var defaultShortcut: Shortcut {
        // ⌃⌥ rather than ⌥ alone: ⌥ with a digit types characters like | [ ] on many keyboard layouts.
        if let slotNumber {
            return Shortcut(keyCode: Self.digitKeyCodes[slotNumber - 1], modifiers: controlKey | optionKey, keyName: "\(slotNumber)")
        }
        switch self {
        case .openSnicker: return Shortcut(keyCode: kVK_ANSI_V, modifiers: cmdKey | optionKey, keyName: "V")
        case .selectNext: return Shortcut(keyCode: kVK_DownArrow, keyName: "↓")
        case .selectPrevious: return Shortcut(keyCode: kVK_UpArrow, keyName: "↑")
        case .copyGif: return Shortcut(keyCode: kVK_Return, keyName: "↩")
        case .copyLink: return Shortcut(keyCode: kVK_Return, modifiers: shiftKey, keyName: "↩")
        case .toggleFavorite: return Shortcut(keyCode: kVK_ANSI_D, modifiers: cmdKey, keyName: "D")
        case .saveToDownloads: return Shortcut(keyCode: kVK_ANSI_S, modifiers: cmdKey, keyName: "S")
        case .surpriseMe: return Shortcut(keyCode: kVK_ANSI_R, modifiers: cmdKey, keyName: "R")
        case .switchMediaKind: return Shortcut(keyCode: kVK_ANSI_T, modifiers: cmdKey, keyName: "T")
        case .showFavorites: return Shortcut(keyCode: kVK_ANSI_1, modifiers: cmdKey, keyName: "1")
        case .showRecent: return Shortcut(keyCode: kVK_ANSI_2, modifiers: cmdKey, keyName: "2")
        case .showTrending: return Shortcut(keyCode: kVK_ANSI_3, modifiers: cmdKey, keyName: "3")
        default: return Shortcut(keyCode: kVK_F12, keyName: "F12") // unreachable: every slot is handled above
        }
    }
}

/// The user's shortcuts: stored, recorded in Settings, and the global ones registered with the system.
@MainActor
final class ShortcutStore: ObservableObject {
    private static let defaultsKey = "shortcuts"

    @Published private(set) var custom: [ShortcutAction: Shortcut]
    @Published private(set) var recording: ShortcutAction?
    @Published private(set) var error: String?

    private let performGlobal: (ShortcutAction) -> Void
    private let defaults: UserDefaults
    private var hotKeys: [ShortcutAction: HotKey] = [:]
    private var keyMonitor: Any?

    init(defaults: UserDefaults = .standard, performGlobal: @escaping (ShortcutAction) -> Void) {
        self.defaults = defaults
        self.performGlobal = performGlobal
        let saved = defaults.data(forKey: Self.defaultsKey).flatMap { try? JSONDecoder().decode([String: Shortcut].self, from: $0) } ?? [:]
        custom = Dictionary(uniqueKeysWithValues: saved.compactMap { key, value in ShortcutAction(rawValue: key).map { ($0, value) } })
        registerGlobals()
        // If another app took the saved shortcut meanwhile, fall back rather than leave Snicker unreachable.
        if hotKeys[.openSnicker] == nil, custom[.openSnicker] != nil {
            custom[.openSnicker] = nil
            save()
            register(.openSnicker)
        }
    }

    func shortcut(for action: ShortcutAction) -> Shortcut {
        custom[action] ?? action.defaultShortcut
    }

    /// The in-Snicker action a key press maps to, if any.
    func action(for event: NSEvent) -> ShortcutAction? {
        guard let pressed = Shortcut(event: event) else { return nil }
        return ShortcutAction.allCases.first { !$0.isGlobal && shortcut(for: $0).matches(pressed) }
    }

    /// All global shortcuts are paused while recording, so pressing one records it instead of running it.
    func startRecording(_ action: ShortcutAction) {
        stopMonitoring()
        error = nil
        recording = action
        hotKeys = [:]
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleRecording(event)
            return nil
        }
    }

    func cancelRecording() {
        guard recording != nil else { return }
        finishRecording()
    }

    func reset(_ action: ShortcutAction) {
        cancelRecording()
        assign(action.defaultShortcut, to: action)
    }

    func resetAll() {
        cancelRecording()
        custom = [:]
        save()
        registerGlobals()
        let taken = ShortcutAction.allCases.filter { $0.isGlobal && hotKeys[$0] == nil }
        error = taken.isEmpty ? nil : "Used by another app: " + taken.map { shortcut(for: $0).displayString }.joined(separator: ", ")
    }

    private func handleRecording(_ event: NSEvent) {
        guard let action = recording else { return }
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if event.keyCode == UInt16(kVK_Escape) && modifiers.isEmpty {
            cancelRecording()
            return
        }
        guard let pressed = Shortcut(event: event) else { return }
        if let problem = problem(with: pressed, for: action) {
            error = problem
            return
        }
        assign(pressed, to: action)
    }

    private func problem(with shortcut: Shortcut, for action: ShortcutAction) -> String? {
        if action.isGlobal && !shortcut.hasCommandOptionOrControl {
            return "Include ⌘, ⌥ or ⌃, so it doesn’t get in the way of typing in other apps."
        }
        if !action.isGlobal && !shortcut.worksWhileTyping {
            return "Include ⌘, ⌥ or ⌃, so it doesn’t get in the way of typing a search."
        }
        if let other = ShortcutAction.allCases.first(where: { $0 != action && self.shortcut(for: $0).matches(shortcut) }) {
            return "\(shortcut.displayString) is already used for \(other.title)."
        }
        return nil
    }

    private func assign(_ shortcut: Shortcut, to action: ShortcutAction) {
        if action.isGlobal {
            hotKeys[action] = nil // release the old registration first, or registering the same keys again fails
            guard let registered = HotKey(shortcut, action: { [weak self] in self?.performGlobal(action) }) else {
                error = "\(shortcut.displayString) is already used by another app. Try another."
                if recording == nil { register(action) }
                return
            }
            hotKeys[action] = registered
        }
        custom[action] = shortcut == action.defaultShortcut ? nil : shortcut
        save()
        finishRecording()
    }

    private func finishRecording() {
        stopMonitoring()
        recording = nil
        error = nil
        for action in ShortcutAction.allCases where action.isGlobal && hotKeys[action] == nil {
            register(action)
        }
    }

    private func stopMonitoring() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    private func registerGlobals() {
        hotKeys = [:] // release the old registrations first, or registering the same keys again fails
        for action in ShortcutAction.allCases where action.isGlobal {
            register(action)
        }
    }

    private func register(_ action: ShortcutAction) {
        hotKeys[action] = HotKey(shortcut(for: action), action: { [weak self] in self?.performGlobal(action) })
    }

    private func save() {
        let stored = Dictionary(uniqueKeysWithValues: custom.map { ($0.key.rawValue, $0.value) })
        defaults.set(try? JSONEncoder().encode(stored), forKey: Self.defaultsKey)
    }
}
