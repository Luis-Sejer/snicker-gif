import SwiftUI

struct AdvancedSettingsView: View {
    let editApiKey: () -> Void

    @AppStorage(Klipy.apiKeyDefaultsKey) private var customApiKey = ""

    var body: some View {
        Form {
            Section {
                LabeledContent(customApiKey.isEmpty ? "Using the built-in key" : "Using your own key") {
                    HStack {
                        if !customApiKey.isEmpty && !BundledKey.value.isEmpty {
                            Button("Use Built-in Key") { customApiKey = "" }
                        }
                        Button("Use Your Own Key…", action: editApiKey)
                    }
                }
            } header: {
                Text("KLIPY API Key")
            } footer: {
                Text("Snicker includes a key, so you don’t need one. Add your own free key from KLIPY if you’d rather use it.")
            }
        }
        .formStyle(.grouped)
        // Short enough to never scroll, so the window fits the form instead.
        .scrollDisabled(true)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }
}
