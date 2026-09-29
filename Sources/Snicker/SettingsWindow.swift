import AppKit
import SwiftUI

/// The standard Mac Settings window: a toolbar of tabs, each a SwiftUI view.
@MainActor
final class SettingsWindow {
    private let makeTabs: () -> [(label: String, symbol: String, view: AnyView)]
    private var window: NSWindow?

    init(makeTabs: @escaping () -> [(label: String, symbol: String, view: AnyView)]) {
        self.makeTabs = makeTabs
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar
        for tab in makeTabs() {
            let hosting = NSHostingController(rootView: tab.view)
            // Each tab sizes the window to fit, and its title becomes the window's title.
            hosting.sizingOptions = [.preferredContentSize]
            hosting.title = tab.label
            let item = NSTabViewItem(viewController: hosting)
            item.label = tab.label
            item.image = NSImage(systemSymbolName: tab.symbol, accessibilityDescription: nil)
            tabs.addTabViewItem(item)
        }
        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}

extension View {
    /// Every tab fits its content up to a height the screen has room for, and scrolls beyond that,
    /// so a growing tab never runs off a small screen.
    func settingsPane() -> some View {
        frame(width: SettingsWindow.paneWidth)
            .frame(maxHeight: SettingsWindow.maxPaneHeight)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension SettingsWindow {
    static let paneWidth: CGFloat = 480
    /// Tall enough for most tabs; a taller one would be a wall of settings even on a big screen.
    private static let tallestPane: CGFloat = 680
    /// The toolbar, the title bar and some breathing room above and below the window.
    private static let windowChrome: CGFloat = 200

    @MainActor static var maxPaneHeight: CGFloat {
        let available = (NSScreen.main?.visibleFrame.height ?? tallestPane + windowChrome) - windowChrome
        return min(tallestPane, available)
    }
}
