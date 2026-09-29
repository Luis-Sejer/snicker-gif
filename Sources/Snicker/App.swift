import AppKit
import Carbon.HIToolbox
import SwiftUI

@main
enum Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    /// An invisible window at the text cursor for the popover to point at, when the emoji picker shortcut opens it.
    private lazy var cursorAnchor: NSWindow = {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        return window
    }()
    private var shortcuts: ShortcutStore!
    private var outsideClickMonitor: Any?
    private let state = ViewState()
    private let library = Library()
    private let updater = Updater()
    private lazy var settingsMenu = SettingsMenu(
        openSettings: { [weak self] in self?.openSettings() },
        checkForUpdates: { [weak self] in self?.checkForUpdates() }
    )
    private lazy var settingsWindow = SettingsWindow { [unowned self] in
        [
            ("General", "gearshape", AnyView(GeneralSettingsView(library: library, updater: updater, shortcuts: shortcuts))),
            ("Shortcuts", "keyboard", AnyView(ShortcutSettingsView(store: shortcuts))),
            ("Advanced", "gearshape.2", AnyView(AdvancedSettingsView { [weak self] in self?.editApiKey() })),
        ]
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Nothing from a previous session is still on the clipboard, so no downloaded GIF needs to be kept.
        GifFile.clearDownloads()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = Self.statusIcon()
        statusItem.button?.setAccessibilityLabel("Snicker")
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        shortcuts = ShortcutStore { [weak self] action in self?.performGlobal(action) }
        // Services → Find GIF in Snicker, declared in Info.plist by build.sh.
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()

        let hostingController = NSHostingController(
            rootView: ContentView(
                close: { [weak self] in self?.popover.performClose(nil) },
                settingsMenu: settingsMenu,
                shortcuts: shortcuts,
                state: state,
                library: library,
                updater: updater
            )
        )
        // Size up front: letting SwiftUI report it after showing makes the popover grow up under the menu bar.
        hostingController.sizingOptions = []
        NSApp.mainMenu = mainMenu()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = Layout.popoverSize
        popover.contentViewController = hostingController

        // A transient popover stops closing on outside clicks once a GIF's context menu has been open,
        // so close it ourselves. Global monitors only see clicks in other apps, and need no permission for mouse events.
        if let whatsNew = WhatsNew.pending() {
            state.whatsNew = whatsNew
            // Right after an update, so open straight away. The delay lets the status item appear first.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.showPopover() }
        }

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let popover = self?.popover, popover.isShown else { return }
            popover.performClose(nil)
        }

    }

    private func openSettings() {
        popover.performClose(nil)
        settingsWindow.show()
    }

    private func performGlobal(_ action: ShortcutAction) {
        if let slot = action.slotNumber {
            copyFavoriteSlot(slot)
        } else if action == .openEmojiPicker {
            openAtTextCursor()
        } else {
            togglePopover()
        }
    }

    /// Copies without opening Snicker; the menu bar icon briefly turns into a checkmark to confirm.
    private func copyFavoriteSlot(_ slot: Int) {
        guard let gif = library.slots[slot] else {
            NSSound.beep()
            return
        }
        let randomName = UserDefaults.standard.bool(forKey: SettingKeys.randomFileNames)
        Task {
            do {
                try GifFile.copyToPasteboard(try await GifFile.download(gif, randomName: randomName))
                library.addRecent(gif)
                flashStatusIcon()
                NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [
                    .announcement: "Copied \(gif.title.isEmpty ? "GIF" : gif.title)",
                    .priority: NSAccessibilityPriorityLevel.high.rawValue,
                ])
            } catch {
                NSSound.beep()
            }
        }
    }

    private static let copiedFlash: Duration = .milliseconds(900)

    private func flashStatusIcon() {
        statusItem.button?.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Copied")
        Task {
            try? await Task.sleep(for: Self.copiedFlash)
            statusItem.button?.image = Self.statusIcon()
        }
    }

    /// Services → Find GIF in Snicker: searches whatever text is selected in another app.
    @objc func findGif(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>?) {
        guard let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        state.closedAt = nil // or reopening after a while would clear the search just set
        state.mode = .klipy
        state.query = String(text.prefix(Self.serviceQueryLimit))
        showPopover()
    }

    /// Selections can be whole paragraphs; a GIF search only needs the start.
    private static let serviceQueryLimit = 100

    /// Opens the popover so the answer shows in its banner.
    private func checkForUpdates() {
        showPopover()
        updater.checkNow()
    }

    private func editApiKey() {
        state.apiKeyDraft = UserDefaults.standard.string(forKey: Klipy.apiKeyDefaultsKey) ?? ""
        state.isEditingKey = true
        showPopover()
    }

    /// Menu bar apps get no main menu, and without an Edit menu ⌘V, ⌘C and friends do nothing in text fields.
    /// It is never shown; it only supplies the key equivalents, including ⌘, for Settings and ⌘Q.
    private func mainMenu() -> NSMenu {
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let editItem = NSMenuItem()
        editItem.submenu = edit
        let mainMenu = NSMenu()
        let appMenu = NSMenu()
        let settings = appMenu.addItem(withTitle: "Settings…", action: #selector(SettingsMenu.showSettings), keyEquivalent: ",")
        settings.target = settingsMenu
        appMenu.addItem(withTitle: "Quit Snicker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        mainMenu.addItem(appItem) // the first item is always the app menu
        mainMenu.addItem(editItem)
        return mainMenu
    }

    /// The app icon's two tilted cards as a template image, so it tints with the menu bar like an SF Symbol.
    private static func statusIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 24, height: 18), flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            func card(width: CGFloat, height: CGFloat, dx: CGFloat, dy: CGFloat, degrees: CGFloat) -> NSBezierPath {
                let path = NSBezierPath(roundedRect: NSRect(x: -width / 2, y: -height / 2, width: width, height: height), xRadius: 2.3, yRadius: 2.3)
                var transform = AffineTransform(translationByX: rect.midX + dx, byY: rect.midY + dy)
                transform.rotate(byDegrees: degrees)
                path.transform(using: transform)
                return path
            }
            NSColor.black.withAlphaComponent(0.45).setFill()
            card(width: 13, height: 9, dx: 1.4, dy: 2.1, degrees: 12).fill()
            NSColor.black.setFill()
            card(width: 15, height: 10, dx: -0.4, dy: -1.3, degrees: -6).fill()

            context.saveGState()
            context.setBlendMode(.destinationOut)
            context.translateBy(x: rect.midX - 0.4, y: rect.midY - 1.3)
            context.rotate(by: -6 * .pi / 180)
            let label = NSAttributedString(string: "GIF", attributes: [
                .font: NSFont.systemFont(ofSize: 6.8, weight: .black),
                .foregroundColor: NSColor.black,
                .kern: 0.2,
            ])
            let size = label.size()
            label.draw(at: NSPoint(x: -size.width / 2, y: -size.height / 2 + 0.3))
            context.restoreGState()
            return true
        }
        image.isTemplate = true
        return image
    }

    /// Right-click (or Control-click) opens the settings menu, like other menu bar apps; a click toggles the popover.
    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent, let button = statusItem.button else { return }
        guard event.type == .rightMouseUp || event.modifierFlags.contains(.control) else {
            togglePopover()
            return
        }
        popover.performClose(nil)
        settingsMenu.make().popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY + 5), in: button)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button, !popover.isShown else { return }
        state.insertTarget = nil
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    /// In place of Apple's Emoji & Symbols: opens under the text cursor, and emoji picked there are typed
    /// into the app that was in front. Without Accessibility permission it opens at the pointer and copies.
    private func openAtTextCursor() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        let frontmost = NSWorkspace.shared.frontmostApplication
        let target = frontmost == .current || !TextInsertion.isAllowed ? nil : frontmost
        let pointer = NSEvent.mouseLocation
        let anchor = TextInsertion.caretRect() ?? NSRect(x: pointer.x, y: pointer.y, width: 1, height: 1)
        cursorAnchor.setFrame(NSRect(origin: anchor.origin, size: CGSize(width: max(anchor.width, 1), height: max(anchor.height, 1))), display: false)
        cursorAnchor.orderFrontRegardless()
        guard let view = cursorAnchor.contentView else { return }
        state.insertTarget = target
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        cursorAnchor.orderOut(nil)
    }
}

/// Global shortcut via Carbon — the only public API that works without Accessibility permission.
/// Nil when another app already holds the shortcut.
final class HotKey {
    private static var nextID: UInt32 = 1

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void
    private let id: UInt32

    init?(_ shortcut: Shortcut, action: @escaping () -> Void) {
        self.action = action
        id = Self.nextID
        Self.nextID += 1
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        // Every registration gets every hotkey event, so each passes on the ones that aren't its own.
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            var pressed = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &pressed)
            let hotKey = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
            guard pressed.id == hotKey.id else { return OSStatus(eventNotHandledErr) }
            hotKey.action()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
        let hotKeyID = EventHotKeyID(signature: OSType(0x534E_4B52), id: id) // "SNKR"
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.carbonModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        guard status == noErr else {
            if let handlerRef { RemoveEventHandler(handlerRef) }
            handlerRef = nil
            return nil
        }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
