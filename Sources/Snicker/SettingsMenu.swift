import AppKit

/// The ⋯ menu, also shown when right-clicking the menu bar icon. Built once, in AppKit, so both stay the same.
@MainActor
final class SettingsMenu: NSObject {
    private static let supportURL = URL(string: "https://ko-fi.com/snickerapp")!
    private static let repositoryURL = URL(string: "https://github.com/Luis-Sejer/snicker-gif")!

    private let openSettings: () -> Void

    init(openSettings: @escaping () -> Void) {
        self.openSettings = openSettings
    }

    func make() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(item("About Snicker", action: #selector(showAbout), symbol: "info.circle"))
        menu.addItem(item("Settings…", action: #selector(showSettings), symbol: "gearshape", keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(item("Support Snicker…", action: #selector(openSupport), symbol: "heart"))
        menu.addItem(item("Quit Snicker", action: #selector(quit), symbol: "power", keyEquivalent: "q"))
        return menu
    }

    private func item(_ title: String, action: Selector, symbol: String, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return item
    }

    @objc func showSettings() {
        openSettings()
    }

    /// The standard About panel shows the icon, name and version; the credits add the links.
    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: Self.aboutCredits])
    }

    private static var aboutCredits: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let base: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph,
        ]
        func link(_ title: String, _ url: URL) -> NSAttributedString {
            NSAttributedString(string: title, attributes: base.merging([.link: url]) { $1 })
        }
        let credits = NSMutableAttributedString(string: "Made by Luis Sejer Oliver. GIFs powered by KLIPY.\n", attributes: base)
        credits.append(link("Support the creator", supportURL))
        credits.append(NSAttributedString(string: " · ", attributes: base))
        credits.append(link("GitHub", repositoryURL))
        return credits
    }

    @objc private func openSupport() {
        NSWorkspace.shared.open(Self.supportURL)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
