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
        popover.behavior = .transient
        popover.contentSize = Layout.popoverSize
        popover.contentViewController = hostingController

        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | optionKey)) { [weak self] in
            self?.togglePopover()
        }
    }

    /// There is no GIF SF Symbol, so draw a template badge that tints with the menu bar like one.
    private static func statusIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 22, height: 16), flipped: false) { rect in
            let badge = NSBezierPath(roundedRect: rect.insetBy(dx: 1.5, dy: 2), xRadius: 3.5, yRadius: 3.5)
            badge.lineWidth = 1.4
            NSColor.black.setStroke()
            badge.stroke()
            let label = NSAttributedString(string: "GIF", attributes: [
                .font: NSFont.systemFont(ofSize: 8, weight: .heavy),
                .foregroundColor: NSColor.black,
                .kern: 0.3,
            ])
            let labelSize = label.size()
            label.draw(at: NSPoint(x: rect.midX - labelSize.width / 2, y: rect.midY - labelSize.height / 2))
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
