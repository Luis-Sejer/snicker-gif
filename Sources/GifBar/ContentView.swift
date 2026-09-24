import AppKit
import SwiftUI

/// View state lives here rather than in @State: from the macOS 27 SDK @State is a macro whose
/// plugin ships only with full Xcode, and this project should build with the Command Line Tools.
final class ViewState: ObservableObject {
    @Published var query = ""
    @Published var gifs: [Gif] = []
    @Published var status: String?
    @Published var apiKeyDraft = ""
}

struct ContentView: View {
    let close: () -> Void

    @AppStorage(Klipy.apiKeyDefaultsKey) private var apiKey = ""
    @StateObject private var state = ViewState()
    @FocusState private var searchFocused: Bool

    private static let searchDebounce: UInt64 = 300_000_000

    var body: some View {
        VStack(spacing: 0) {
            if apiKey.isEmpty {
                ApiKeyForm(apiKey: $apiKey, state: state)
            } else {
                searchField
                Divider()
                results
            }
            Divider()
            footer
        }
        .frame(width: 380, height: 480)
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didShowNotification)) { _ in
            searchFocused = true
        }
    }

    private var searchField: some View {
        TextField("Search GIFs — Enter copies the first", text: $state.query)
            .textFieldStyle(.roundedBorder)
            .focused($searchFocused)
            .onSubmit { if let first = state.gifs.first { copy(first) } }
            .padding(10)
            .task(id: state.query) {
                do { try await Task.sleep(nanoseconds: Self.searchDebounce) } catch { return }
                await load()
            }
    }

    private var results: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 6)], spacing: 6) {
                ForEach(state.gifs) { gif in
                    AnimatedGif(url: gif.previewURL)
                        .frame(height: 90)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                        .onTapGesture { copy(gif) }
                        .onDrag { GifFile.dragProvider(for: gif) }
                        .help(gif.title)
                }
            }
            .padding(8)
        }
    }

    private var footer: some View {
        HStack {
            Text(state.status ?? "Click to copy · drag to drop · ⌘⌥V")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text("Powered by KLIPY").font(.caption2).foregroundStyle(.tertiary)
            Menu {
                Button("Change API key") { apiKey = "" }
                Button("Quit GifBar") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func load() async {
        do {
            state.gifs = try await Klipy.fetch(query: state.query, apiKey: apiKey)
            state.status = state.gifs.isEmpty ? "No results" : nil
        } catch is CancellationError {
        } catch {
            state.status = error.localizedDescription
        }
    }

    private func copy(_ gif: Gif) {
        state.status = "Copying…"
        Task {
            do {
                try GifFile.copyToPasteboard(try await GifFile.download(gif))
                state.status = nil
                close()
            } catch {
                state.status = error.localizedDescription
            }
        }
    }
}

private struct ApiKeyForm: View {
    @Binding var apiKey: String
    @ObservedObject var state: ViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Klipy API key").font(.headline)
            Text("GifBar searches Klipy. Create a free API key in Klipy's developer portal and paste it here.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Link("docs.klipy.com", destination: URL(string: "https://docs.klipy.com")!)
            TextField("API key", text: $state.apiKeyDraft)
                .textFieldStyle(.roundedBorder)
                .onSubmit(save)
            Button("Save", action: save)
                .keyboardShortcut(.defaultAction)
                .disabled(state.apiKeyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            Spacer()
        }
        .padding(16)
        .frame(maxHeight: .infinity)
    }

    private func save() {
        apiKey = state.apiKeyDraft.trimmingCharacters(in: .whitespaces)
    }
}

/// NSImageView animates GIFs natively; SwiftUI's Image does not.
private struct AnimatedGif: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSImageView {
        let view = PassthroughImageView()
        view.animates = true
        view.imageScaling = .scaleProportionallyUpOrDown
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        guard context.coordinator.url != url else { return }
        context.coordinator.url = url
        view.image = nil
        Task { @MainActor in
            let image = await PreviewCache.image(for: url)
            if context.coordinator.url == url { view.image = image }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator { var url: URL? }
}

/// Lets clicks and drags fall through to the SwiftUI gestures.
private final class PassthroughImageView: NSImageView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

private enum PreviewCache {
    private static let cache = NSCache<NSURL, NSImage>()

    static func image(for url: URL) async -> NSImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        guard let (data, _) = try? await URLSession.shared.data(from: url), let image = NSImage(data: data) else { return nil }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
