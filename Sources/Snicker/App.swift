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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = Self.statusIcon()
        statusItem.button?.setAccessibilityLabel("Snicker")
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        let hostingController = NSHostingController(
            rootView: ContentView(close: { [weak self] in self?.popover.performClose(nil) })
        )
        // Size up front: letting SwiftUI report it after showing makes the popover grow up under the menu bar.
        hostingController.sizingOptions = []
        NSApp.mainMenu = Self.editMenu()
        popover.behavior = .transient
        popover.contentSize = Layout.popoverSize
        popover.contentViewController = hostingController

        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | optionKey)) { [weak self] in
            self?.togglePopover()
        }
    }

    /// Menu bar apps get no main menu, and without an Edit menu ⌘V, ⌘C and friends do nothing in text fields.
    /// It is never shown; it only supplies the key equivalents.
    private static func editMenu() -> NSMenu {
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
        mainMenu.addItem(NSMenuItem()) // the first item is always the app menu
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

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
}

/// Global shortcut via Carbon — the only public API that works without Accessibility permission.
final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void

    init(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.action = action
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue().action()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
        let hotKeyID = EventHotKeyID(signature: OSType(0x534E_4B52), id: 1) // "SNKR"
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
