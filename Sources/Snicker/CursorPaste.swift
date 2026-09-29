import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// What lets Snicker stand in for Apple's Emoji & Symbols: finding the text cursor in another app, and pasting
/// the chosen GIF there. Both need Accessibility permission; without it Snicker opens at the pointer and only
/// copies. Adapted from Mathias Costa Magnussen's emoji picker (#3).
@MainActor
enum CursorPaste {
    private static let activationTimeout: Duration = .milliseconds(500)
    private static let activationPoll: Duration = .milliseconds(20)
    /// Time for the app's text field to take focus again once the app is in front.
    private static let settleDelay: Duration = .milliseconds(60)
    private static let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!

    static var isAllowed: Bool { AXIsProcessTrusted() }

    /// Adds Snicker to the Accessibility list with its switch off, and opens that list to turn it on.
    static func requestAccess() {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        if !AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary) {
            NSWorkspace.shared.open(settingsURL)
        }
    }

    /// Where the text cursor is, in screen coordinates. Falls back to the focused field's frame for apps
    /// that don't report the cursor, and to nil when nothing focused can be found.
    static func caretRect() -> NSRect? {
        guard isAllowed, let element = focusedElement() else { return nil }
        let rect = cursorBounds(in: element) ?? frame(of: element)
        return rect.map(flipped)
    }

    /// Hands the keyboard back to the app that was in front, then presses ⌘V in it, so what Snicker just put
    /// on the clipboard lands where the cursor is.
    static func paste(into app: NSRunningApplication) async {
        guard isAllowed else { return }
        NSApp.yieldActivation(to: app)
        app.activate()
        let clock = ContinuousClock()
        let deadline = clock.now + activationTimeout
        while NSWorkspace.shared.frontmostApplication != app, clock.now < deadline {
            try? await Task.sleep(for: activationPoll)
        }
        try? await Task.sleep(for: settleDelay)
        let source = CGEventSource(stateID: .hidSystemState)
        for isDown in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: isDown) else { return }
            // Only ⌘: a still-held ⌃ from the shortcut would turn ⌘V into a different command.
            event.flags = .maskCommand
            event.post(tap: .cghidEventTap)
        }
    }

    // MARK: Accessibility queries

    private static func focusedElement() -> AXUIElement? {
        guard let value = attribute(kAXFocusedUIElementAttribute, of: AXUIElementCreateSystemWide()),
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement) // the type ID was checked just above
    }

    private static func cursorBounds(in element: AXUIElement) -> CGRect? {
        guard let range = attribute(kAXSelectedTextRangeAttribute, of: element) else { return nil }
        var bounds: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element, kAXBoundsForRangeParameterizedAttribute as CFString, range, &bounds) == .success
        else { return nil }
        // Some apps answer with an empty rectangle at the screen's corner rather than an error.
        return rect(from: bounds).flatMap { $0.height > 0 ? $0 : nil }
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard let position = attribute(kAXPositionAttribute, of: element), let extent = attribute(kAXSizeAttribute, of: element),
              CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(extent) == AXValueGetTypeID(),
              AXValueGetValue(position as! AXValue, .cgPoint, &origin),
              AXValueGetValue(extent as! AXValue, .cgSize, &size) else { return nil }
        return CGRect(origin: origin, size: size)
    }

    private static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
    }

    private static func rect(from value: CFTypeRef?) -> CGRect? {
        var rect = CGRect.zero
        guard let value, CFGetTypeID(value) == AXValueGetTypeID(), AXValueGetValue(value as! AXValue, .cgRect, &rect) else { return nil }
        return rect
    }

    /// Accessibility measures from the top of the main screen; AppKit from the bottom.
    private static func flipped(_ rect: CGRect) -> NSRect {
        let mainHeight = NSScreen.screens.first?.frame.height ?? 0
        return NSRect(x: rect.minX, y: mainHeight - rect.maxY, width: rect.width, height: rect.height)
    }
}
