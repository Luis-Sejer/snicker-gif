import ServiceManagement
import SwiftUI

enum SettingKeys {
    /// Name copied files like "GIF-3F9A2C71.gif" instead of after the GIF's title.
    static let randomFileNames = "randomFileNames"
    /// Show "Favorites", "Recent" and "Trending" next to their icons.
    static let showTabNames = "showTabNames"
}

struct GeneralSettingsView: View {
    @ObservedObject var library: Library
    @ObservedObject var updater: Updater

    @StateObject private var loginItem = LoginItem()
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
                Picker("Content", selection: $contentFilter) {
                    ForEach(ContentFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            } footer: {
                Text("Work-Safe hides anything you wouldn’t want popping up in a work chat. Standard hides the most explicit GIFs. Filtering is done by KLIPY.")
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
        // Short enough to never scroll, so the window fits the form instead.
        .scrollDisabled(true)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension GeneralSettingsView {
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
