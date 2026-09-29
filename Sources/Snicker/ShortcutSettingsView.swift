import SwiftUI

struct ShortcutSettingsView: View {
    @ObservedObject var store: ShortcutStore
    @AppStorage(SettingKeys.showEmoji) private var showEmoji = false

    var body: some View {
        Form {
            Section {
                row(.openSnicker)
            } footer: {
                Text("Works from any app.")
            }
            Section("While Snicker Is Open") {
                ForEach(ShortcutAction.allCases.filter { !$0.isGlobal && ($0 != .showEmoji || showEmoji) }, id: \.self, content: row)
            }
            Section {
                ForEach(ShortcutAction.favoriteSlots, id: \.self, content: row)
            } header: {
                Text("Favorite Slots")
            } footer: {
                Text("Copy a pinned GIF from any app without opening Snicker. Pin one from a GIF’s right-click menu.")
            }
            Section {
                HStack {
                    Text("Click a shortcut, then press the keys you want. Esc cancels.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Reset All", action: store.resetAll)
                        .disabled(store.custom.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        // Too long to show whole on a small screen, so this tab scrolls at a fixed height.
        .frame(width: 480, height: 560)
        .onDisappear(perform: store.cancelRecording)
    }

    private func row(_ action: ShortcutAction) -> some View {
        let isRecording = store.recording == action
        let shortcut = store.shortcut(for: action)
        return VStack(alignment: .trailing, spacing: 4) {
            LabeledContent(action.title) {
                HStack(spacing: 6) {
                    if store.custom[action] != nil && !isRecording {
                        Button("Reset \(action.title) to \(action.defaultShortcut.displayString)", systemImage: "arrow.uturn.backward") {
                            store.reset(action)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .help("Reset to \(action.defaultShortcut.displayString)")
                    }
                    Button {
                        isRecording ? store.cancelRecording() : store.startRecording(action)
                    } label: {
                        Text(isRecording ? "Press keys…" : shortcut.displayString)
                            .monospaced()
                            .frame(minWidth: 84)
                    }
                    .buttonStyle(.bordered)
                    .tint(isRecording ? .accentColor : nil)
                    .accessibilityLabel(isRecording ? "Recording a shortcut for \(action.title)" : "\(action.title): \(shortcut.displayString)")
                    .accessibilityHint("Press to record a new shortcut")
                }
            }
            if isRecording, let error = store.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}
