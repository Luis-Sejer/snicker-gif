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
