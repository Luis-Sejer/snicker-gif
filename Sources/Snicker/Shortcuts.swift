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
    case openSnicker, selectNext, selectPrevious, copyGif, copyLink, toggleFavorite, saveToDownloads
    case showFavorites, showRecent, showTrending

    var title: String {
        switch self {
        case .openSnicker: "Open Snicker"
        case .selectNext: "Next GIF"
        case .selectPrevious: "Previous GIF"
        case .copyGif: "Copy GIF"
        case .copyLink: "Copy Link"
        case .toggleFavorite: "Add to or Remove from Favorites"
        case .saveToDownloads: "Save to Downloads"
        case .showFavorites: "Show Favorites"
        case .showRecent: "Show Recent"
        case .showTrending: "Show Trending"
        }
    }

    /// Only opening Snicker works from other apps; the rest work while Snicker is open.
    var isGlobal: Bool { self == .openSnicker }

    var defaultShortcut: Shortcut {
        switch self {
        case .openSnicker: Shortcut(keyCode: kVK_ANSI_V, modifiers: cmdKey | optionKey, keyName: "V")
        case .selectNext: Shortcut(keyCode: kVK_DownArrow, keyName: "↓")
        case .selectPrevious: Shortcut(keyCode: kVK_UpArrow, keyName: "↑")
        case .copyGif: Shortcut(keyCode: kVK_Return, keyName: "↩")
        case .copyLink: Shortcut(keyCode: kVK_Return, modifiers: shiftKey, keyName: "↩")
        case .toggleFavorite: Shortcut(keyCode: kVK_ANSI_D, modifiers: cmdKey, keyName: "D")
        case .saveToDownloads: Shortcut(keyCode: kVK_ANSI_S, modifiers: cmdKey, keyName: "S")
        case .showFavorites: Shortcut(keyCode: kVK_ANSI_1, modifiers: cmdKey, keyName: "1")
        case .showRecent: Shortcut(keyCode: kVK_ANSI_2, modifiers: cmdKey, keyName: "2")
        case .showTrending: Shortcut(keyCode: kVK_ANSI_3, modifiers: cmdKey, keyName: "3")
        }
    }
}

/// The user's shortcuts: stored, recorded in Settings, and the global one registered with the system.
@MainActor
final class ShortcutStore: ObservableObject {
    private static let defaultsKey = "shortcuts"

    @Published private(set) var custom: [ShortcutAction: Shortcut]
    @Published private(set) var recording: ShortcutAction?
    @Published private(set) var error: String?

    private let openSnicker: () -> Void
    private let defaults: UserDefaults
    private var hotKey: HotKey?
    private var keyMonitor: Any?

    init(defaults: UserDefaults = .standard, openSnicker: @escaping () -> Void) {
        self.defaults = defaults
        self.openSnicker = openSnicker
        let saved = defaults.data(forKey: Self.defaultsKey).flatMap { try? JSONDecoder().decode([String: Shortcut].self, from: $0) } ?? [:]
        custom = Dictionary(uniqueKeysWithValues: saved.compactMap { key, value in ShortcutAction(rawValue: key).map { ($0, value) } })
        registerGlobal()
        // If another app took the saved shortcut meanwhile, fall back rather than leave Snicker unreachable.
        if hotKey == nil, custom[.openSnicker] != nil {
            custom[.openSnicker] = nil
            save()
            registerGlobal()
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

    /// All shortcuts are paused while recording, so pressing the current one records it instead of opening Snicker.
    func startRecording(_ action: ShortcutAction) {
        stopMonitoring()
        error = nil
        recording = action
        hotKey = nil
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
        registerGlobal()
        error = hotKey == nil ? "\(ShortcutAction.openSnicker.defaultShortcut.displayString) is used by another app." : nil
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
            hotKey = nil // release the old registration first, or registering the same keys again fails
            guard let registered = HotKey(shortcut, action: openSnicker) else {
                error = "\(shortcut.displayString) is already used by another app. Try another."
                if recording == nil { registerGlobal() }
                return
            }
            hotKey = registered
        }
        custom[action] = shortcut == action.defaultShortcut ? nil : shortcut
        save()
        finishRecording()
    }

    private func finishRecording() {
        stopMonitoring()
        recording = nil
        error = nil
        if hotKey == nil { registerGlobal() }
    }

    private func stopMonitoring() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    private func registerGlobal() {
        hotKey = nil // release the old registration first, or registering the same keys again fails
        hotKey = HotKey(shortcut(for: .openSnicker), action: openSnicker)
    }

    private func save() {
        let stored = Dictionary(uniqueKeysWithValues: custom.map { ($0.key.rawValue, $0.value) })
        defaults.set(try? JSONEncoder().encode(stored), forKey: Self.defaultsKey)
    }
}
