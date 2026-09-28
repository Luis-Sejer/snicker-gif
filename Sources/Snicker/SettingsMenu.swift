import AppKit
import ServiceManagement

/// The ⋯ menu, also shown when right-clicking the menu bar icon. Built once, in AppKit, so both stay the same.
@MainActor
final class SettingsMenu: NSObject {
    static let randomFileNamesKey = "randomFileNames"
    private static let supportURL = URL(string: "https://ko-fi.com/snickerapp")!
    private static let repositoryURL = URL(string: "https://github.com/Luis-Sejer/snicker-gif")!

    private let state: ViewState
    private let library: Library
    private let showPopover: () -> Void
    private let defaults = UserDefaults.standard

    init(state: ViewState, library: Library, showPopover: @escaping () -> Void) {
        self.state = state
        self.library = library
        self.showPopover = showPopover
    }

    /// Built fresh each time, so the checkmarks match settings changed elsewhere, like Login Items in System Settings.
    func make() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(item("About Snicker", action: #selector(showAbout), symbol: "info.circle"))
        menu.addItem(.separator())
        menu.addItem(item("Launch at Login", action: #selector(toggleLaunchAtLogin), isOn: SMAppService.mainApp.status == .enabled))
        menu.addItem(item("Random File Names", action: #selector(toggleRandomFileNames), isOn: defaults.bool(forKey: Self.randomFileNamesKey)))
        menu.addItem(.separator())
        let clearRecents = item("Clear Recent GIFs", action: #selector(clearRecents), symbol: "clock.arrow.circlepath")
        clearRecents.isEnabled = !library.recents.isEmpty
        menu.addItem(clearRecents)
        menu.addItem(item("Use Your Own API Key…", action: #selector(editApiKey), symbol: "key"))
        if !customApiKey.isEmpty && !BundledKey.value.isEmpty {
            menu.addItem(item("Use Built-in API Key", action: #selector(useBuiltInApiKey), symbol: "arrow.uturn.backward"))
        }
        menu.addItem(.separator())
        menu.addItem(item("Support Snicker…", action: #selector(openSupport), symbol: "heart"))
        menu.addItem(item("Quit Snicker", action: #selector(quit), symbol: "power"))
        return menu
    }

    private var customApiKey: String {
        defaults.string(forKey: Klipy.apiKeyDefaultsKey) ?? ""
    }

    private func item(_ title: String, action: Selector, symbol: String? = nil, isOn: Bool = false) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = isOn ? .on : .off
        if let symbol {
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        }
        return item
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            state.notice = Notice(text: error.localizedDescription, isError: true)
        }
    }

    // The views read these settings through @AppStorage, which picks up the change on its own.
    @objc private func toggleRandomFileNames() {
        defaults.set(!defaults.bool(forKey: Self.randomFileNamesKey), forKey: Self.randomFileNamesKey)
    }

    @objc private func useBuiltInApiKey() {
        defaults.removeObject(forKey: Klipy.apiKeyDefaultsKey)
    }

    @objc private func clearRecents() {
        library.clearRecents()
    }

    @objc private func editApiKey() {
        state.apiKeyDraft = customApiKey
        state.isEditingKey = true
        showPopover()
    }

    /// The standard About panel shows the icon, name and version; the credits add the links.
    @objc private func showAbout() {
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
