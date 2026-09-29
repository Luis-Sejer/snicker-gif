import ServiceManagement
import SwiftUI

enum SettingKeys {
    /// Name copied files like "GIF-3F9A2C71.gif" instead of after the GIF's title.
    static let randomFileNames = "randomFileNames"
    /// Take over ⌃⌘Space from Apple's Emoji & Symbols: Snicker opens at the text cursor and pastes the GIF there.
    static let replaceEmojiPicker = "replaceEmojiPicker"
    /// Paste the chosen GIF into the app Snicker was opened from, however it was opened.
    static let pasteForMe = "pasteForMe"
    /// Show "Favorites", "Recent" and "Trending" next to their icons.
    static let showTabNames = "showTabNames"
}

struct GeneralSettingsView: View {
    @ObservedObject var library: Library
    @ObservedObject var updater: Updater
    let shortcuts: ShortcutStore

    @StateObject private var loginItem = LoginItem()
    @StateObject private var accessibility = AccessibilityAccess()
    @AppStorage(SettingKeys.replaceEmojiPicker) private var replaceEmojiPicker = false
    @AppStorage(SettingKeys.pasteForMe) private var pasteForMe = false
    @AppStorage(SettingKeys.randomFileNames) private var randomFileNames = false
    @AppStorage(StartTab.defaultsKey) private var startTab: StartTab = .trending
    @AppStorage(ContentFilter.defaultsKey) private var contentFilter: ContentFilter = .unrestricted
    @AppStorage(SettingKeys.showTabNames) private var showTabNames = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: Binding(get: { loginItem.isEnabled }, set: loginItem.setEnabled))
                if let error = loginItem.error {
                    Text(error).font(.caption).foregroundStyle(.orange)
                }
                Picker("Open On", selection: $startTab) {
                    ForEach(StartTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                Toggle("Show Tab Names", isOn: $showTabNames)
            } footer: {
                Text("Snicker opens on this tab when it starts, and when you come back after a while. Tabs show as icons unless you turn on their names.")
            }

            Section {
                Toggle("Paste for Me", isOn: $pasteForMe)
                Toggle("Replace Emoji & Symbols", isOn: $replaceEmojiPicker)
                if pasteForMe || replaceEmojiPicker {
                    LabeledContent("Accessibility Permission") {
                        if accessibility.isAllowed {
                            Label("Allowed", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Button("Allow…", action: CursorPaste.requestAccess)
                        }
                    }
                }
            } footer: {
                Text(cursorFooter)
            }
            .onChange(of: replaceEmojiPicker) { shortcuts.refreshAvailability() }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                accessibility.refresh()
            }

            Section {
                Picker("Content", selection: $contentFilter) {
                    ForEach(ContentFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            } footer: {
                Text("From mildest to wildest. Work-Safe hides anything you wouldn’t want popping up in a work chat, Standard hides the most explicit GIFs, and Unrestricted shows everything. Cursed shows only the wild ones: what Work-Safe would hide, plus cursed GIFs for your search. Filtering is done by KLIPY.")
            }

            Section {
                Toggle("Random File Names", isOn: $randomFileNames)
                LabeledContent("Recent GIFs") {
                    Button("Clear", action: library.clearRecents)
                        .disabled(library.recents.isEmpty)
                }
                LabeledContent("Recent Searches") {
                    Button("Clear", action: library.clearSearches)
                        .disabled(library.recentSearches.isEmpty)
                }
            } footer: {
                Text("Random file names stop a pasted GIF’s name from giving away what you searched for.")
            }

            Section {
                LabeledContent("Snicker \(updater.installedVersion)") {
                    if updater.phase == .installing {
                        ProgressView().controlSize(.small)
                    } else if let available = updater.availableVersion {
                        Button("Update to \(available)", action: updater.install)
                    } else {
                        Button("Check for Updates", action: updater.checkNow)
                            .disabled(updater.checkStatus == .checking)
                    }
                }
            } header: {
                Text("Updates")
            } footer: {
                Text(updateStatus)
            }
        }
        .formStyle(.grouped)
        .settingsPane()
    }
}

private extension GeneralSettingsView {
    var cursorFooter: String {
        let shortcut = shortcuts.shortcut(for: .openAtCursor).displayString
        let what = "Paste for Me pastes the GIF you pick into the app you came from. Replace Emoji & Symbols makes \(shortcut) open Snicker at the text cursor, in place of Apple’s emoji picker."
        guard pasteForMe || replaceEmojiPicker, !accessibility.isAllowed else { return what }
        return what + " Both need Snicker allowed under Privacy & Security → Accessibility; until then, GIFs are copied and Snicker opens at the pointer."
    }

    var updateStatus: String {
        if updater.phase == .installing { return "Updating… Snicker will reopen by itself." }
        if updater.phase == .failed { return "Couldn’t update by itself. Download Snicker again from GitHub; it replaces this version." }
        if let available = updater.availableVersion { return "Snicker \(available) is available." }
        switch updater.checkStatus {
        case .checking: return "Checking…"
        case .upToDate: return "You have the latest version."
        case .failed: return "Couldn’t reach GitHub to check for updates."
        case .idle: return "Snicker checks for updates each time you open it."
        }
    }
}

/// Accessibility permission is granted in System Settings, so it is read again whenever Snicker comes back to the front.
@MainActor
private final class AccessibilityAccess: ObservableObject {
    @Published private(set) var isAllowed = CursorPaste.isAllowed

    func refresh() {
        isAllowed = CursorPaste.isAllowed
    }
}

/// Launch at Login lives in System Settings, which can change it too, so it is read fresh each time.
@MainActor
private final class LoginItem: ObservableObject {
    @Published private(set) var error: String?

    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        objectWillChange.send()
    }
}
