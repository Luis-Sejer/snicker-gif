import ServiceManagement
import SwiftUI

enum SettingKeys {
    /// Name copied files like "GIF-3F9A2C71.gif" instead of after the GIF's title.
    static let randomFileNames = "randomFileNames"
}

struct GeneralSettingsView: View {
    @ObservedObject var library: Library

    @StateObject private var loginItem = LoginItem()
    @AppStorage(SettingKeys.randomFileNames) private var randomFileNames = false
    @AppStorage(StartTab.defaultsKey) private var startTab: StartTab = .trending

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
            } footer: {
                Text("Snicker opens here when it starts, and when you come back after a while.")
            }

            Section {
                Toggle("Random File Names", isOn: $randomFileNames)
                LabeledContent("Recent GIFs") {
                    Button("Clear", action: library.clearRecents)
                        .disabled(library.recents.isEmpty)
                }
            } footer: {
                Text("Random file names stop a pasted GIF’s name from giving away what you searched for.")
            }
        }
        .formStyle(.grouped)
        // Short enough to never scroll, so the window fits the form instead.
        .scrollDisabled(true)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
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
