import AppKit
import SwiftUI

/// View state lives here rather than in @State: from the macOS 27 SDK @State is a macro whose
/// plugin ships only with full Xcode, and this project should build with the Command Line Tools.
final class ViewState: ObservableObject {
    @Published var query = ""
    @Published var gifs: [Gif] = []
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var copyError: String?
    @Published var hoveredID: String?
    @Published var pendingID: String?
    @Published var copiedID: String?
    @Published var apiKeyDraft = ""
}

enum Layout {
    static let popoverSize = CGSize(width: 420, height: 560)
    static let gridPadding: CGFloat = 10
    static let tileSpacing: CGFloat = 6
    static let columnCount = 3
    static let tileCornerRadius: CGFloat = 12
}

struct ContentView: View {
    let close: () -> Void

    @AppStorage(Klipy.apiKeyDefaultsKey) private var apiKey = ""
    @StateObject private var state = ViewState()
    @FocusState private var searchFocused: Bool

    private static let suggestions = ["Thank you", "LOL", "Yes", "No", "Wow", "Party", "Facepalm", "Good morning"]
    private static let searchDebounce: Duration = .milliseconds(300)
    private static let copiedLinger: Duration = .milliseconds(550)

    var body: some View {
        Group {
            if apiKey.isEmpty {
                WelcomeView(apiKey: $apiKey, state: state)
            } else {
                browser
            }
        }
        .frame(width: Layout.popoverSize.width, height: Layout.popoverSize.height)
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didShowNotification)) { _ in
            state.copiedID = nil
            state.copyError = nil
            searchFocused = true
        }
    }

    // MARK: Browser

    private var browser: some View {
        ScrollView {
            MasonryGrid(state: state, highlightedID: enterTargetID, copy: copy)
                .padding(.horizontal, Layout.gridPadding)
        }
        .scrollIndicators(.never) // a legacy scroller would steal a column's worth of gutter on the right
        .scrollEdgeEffectStyle(.soft, for: [.top, .bottom])
        .safeAreaInset(edge: .top, spacing: 4) { header }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .overlay { emptyState }
        .task(id: state.query) {
            do { try await Task.sleep(for: Self.searchDebounce) } catch { return }
            await load()
        }
    }

    /// Enter copies the first result; ring it so that is discoverable.
    private var enterTargetID: String? {
        state.query.isEmpty ? nil : state.gifs.first?.id
    }

    private var header: some View {
        VStack(spacing: 10) {
            searchField
            suggestionChips
        }
        .padding(.top, 12)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
            TextField("Search GIFs", text: $state.query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
                .onSubmit { if let first = state.gifs.first { copy(first) } }
            if state.isLoading {
                ProgressView().controlSize(.small)
            } else if !state.query.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") { state.query = "" }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .glassEffect(.regular.interactive(), in: .capsule)
        .padding(.horizontal, Layout.gridPadding)
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 6) {
                    chip("Trending", systemImage: "flame.fill", query: "")
                    ForEach(Self.suggestions, id: \.self) { chip($0, systemImage: nil, query: $0) }
                }
                .padding(.horizontal, Layout.gridPadding)
                .padding(.vertical, 4)
            }
        }
        .scrollIndicators(.never)
    }

    @ViewBuilder
    private func chip(_ title: String, systemImage: String?, query: String) -> some View {
        let label = Label {
            Text(title)
        } icon: {
            if let systemImage { Image(systemName: systemImage) }
        }
        let action = { state.query = query }
        if state.query.caseInsensitiveCompare(query) == .orderedSame {
            Button(action: action) { label }.buttonStyle(.glassProminent).controlSize(.small)
        } else {
            Button(action: action) { label }.buttonStyle(.glass).controlSize(.small)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let copyError = state.copyError {
                Label(copyError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            } else {
                Text("Click to copy · Drag into any app · ⌘⌥V")
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text("Powered by KLIPY")
                .foregroundStyle(.tertiary)
            Menu {
                Button("Change API Key…", systemImage: "key") { apiKey = "" }
                Divider()
                Button("Quit GifBar", systemImage: "power") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuIndicator(.hidden)
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .fixedSize()
        }
        .font(.caption)
        .lineLimit(1)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var emptyState: some View {
        if let loadError = state.loadError {
            ContentUnavailableView("Couldn’t Load GIFs", systemImage: "wifi.exclamationmark", description: Text(loadError))
        } else if state.gifs.isEmpty && !state.isLoading && !state.query.isEmpty {
            ContentUnavailableView.search(text: state.query)
        }
    }

    // MARK: Actions

    private func load() async {
        state.isLoading = true
        defer { state.isLoading = false }
        do {
            let gifs = try await Klipy.fetch(query: state.query, apiKey: apiKey)
            withAnimation(.smooth) { state.gifs = gifs }
            state.loadError = nil
        } catch is CancellationError {
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            state.loadError = error.localizedDescription
        }
    }

    private func copy(_ gif: Gif) {
        state.pendingID = gif.id
        state.copyError = nil
        Task {
            defer { state.pendingID = nil }
            do {
                try GifFile.copyToPasteboard(try await GifFile.download(gif))
                withAnimation(.bouncy) { state.copiedID = gif.id }
                try? await Task.sleep(for: Self.copiedLinger)
                close()
            } catch {
                state.copyError = error.localizedDescription
            }
        }
    }
}

// MARK: - Grid

/// Shortest-column-first masonry, so every GIF keeps its real shape instead of being letterboxed.
private struct MasonryGrid: View {
    @ObservedObject var state: ViewState
    let highlightedID: String?
    let copy: (Gif) -> Void

    private static let placeholderRatios: [CGFloat] = [1.3, 0.8, 1, 1.6, 1.1, 0.75, 1.4, 1, 0.9, 1.2, 1.5, 0.85]

    var body: some View {
        HStack(alignment: .top, spacing: Layout.tileSpacing) {
            ForEach(0..<Layout.columnCount, id: \.self) { column in
                LazyVStack(spacing: Layout.tileSpacing) {
                    if state.gifs.isEmpty && state.isLoading {
                        ForEach(placeholders[column], id: \.self) { index in
                            RoundedRectangle(cornerRadius: Layout.tileCornerRadius, style: .continuous)
                                .fill(.quaternary)
                                .aspectRatio(Self.placeholderRatios[index], contentMode: .fit)
                        }
                    } else {
                        ForEach(columns[column]) { gif in
                            GifTile(
                                gif: gif,
                                isHighlighted: gif.id == highlightedID,
                                isHovered: gif.id == state.hoveredID,
                                isPending: gif.id == state.pendingID,
                                isCopied: gif.id == state.copiedID,
                                onHover: { hovering in state.hoveredID = hovering ? gif.id : nil },
                                copy: { copy(gif) }
                            )
                        }
                    }
                }
            }
        }
    }

    private var columns: [[Gif]] {
        var columns = Array(repeating: [Gif](), count: Layout.columnCount)
        var heights = Array(repeating: CGFloat.zero, count: Layout.columnCount)
        for gif in state.gifs {
            let shortest = heights.indices.min { heights[$0] < heights[$1] } ?? 0
            columns[shortest].append(gif)
            heights[shortest] += 1 / gif.aspectRatio
        }
        return columns
    }

    private var placeholders: [[Int]] {
        (0..<Layout.columnCount).map { column in
            Array(stride(from: column, to: Self.placeholderRatios.count, by: Layout.columnCount))
        }
    }
}

private struct GifTile: View {
    let gif: Gif
    let isHighlighted: Bool
    let isHovered: Bool
    let isPending: Bool
    let isCopied: Bool
    let onHover: (Bool) -> Void
    let copy: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Layout.tileCornerRadius, style: .continuous)
    }

    var body: some View {
        AnimatedGif(url: gif.previewURL)
            .aspectRatio(gif.aspectRatio, contentMode: .fit)
            .background(.quaternary)
            .overlay { if isPending || isCopied { Color.black.opacity(0.25) } }
            .overlay { statusBadge }
            .clipShape(shape)
            .overlay { shape.strokeBorder(Color.accentColor, lineWidth: 2.5).opacity(isHighlighted ? 1 : 0) }
            .scaleEffect(isHovered && !reduceMotion ? 1.04 : 1)
            .shadow(color: .black.opacity(isHovered ? 0.28 : 0), radius: 10, y: 5)
            .zIndex(isHovered ? 1 : 0)
            .animation(.smooth(duration: 0.2), value: isHovered)
            .contentShape(shape)
            .onHover(perform: onHover)
            .onTapGesture(perform: copy)
            .onDrag { GifFile.dragProvider(for: gif) }
            .help(gif.title)
            .accessibilityElement()
            .accessibilityLabel(gif.title.isEmpty ? "GIF" : gif.title)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Copy", copy)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isCopied {
            Label("Copied", systemImage: "checkmark.circle.fill")
                .font(.callout.weight(.semibold))
                .symbolEffect(.bounce, value: isCopied)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .glassEffect(.regular, in: .capsule)
                .transition(.scale.combined(with: .opacity))
        } else if isPending {
            ProgressView().controlSize(.small)
        }
    }
}

// MARK: - Welcome

private struct WelcomeView: View {
    @Binding var apiKey: String
    @ObservedObject var state: ViewState

    private var trimmedDraft: String {
        state.apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 52))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
            VStack(spacing: 6) {
                Text("Welcome to GifBar")
                    .font(.title2.weight(.bold))
                Text("GifBar searches KLIPY’s GIF library. Paste your free API key to get started.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 10) {
                TextField("KLIPY API key", text: $state.apiKeyDraft)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .onSubmit(save)
                Button(action: save) {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedDraft.isEmpty)
            }
            Link("Get a key at docs.klipy.com", destination: URL(string: "https://docs.klipy.com")!)
                .font(.caption)
            Spacer()
        }
        .padding(32)
    }

    private func save() {
        guard !trimmedDraft.isEmpty else { return }
        apiKey = trimmedDraft
    }
}

// MARK: - Animated preview

/// NSImageView animates GIFs natively; SwiftUI's Image does not.
private struct AnimatedGif: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSImageView {
        let view = PassthroughImageView()
        view.animates = true
        view.imageScaling = .scaleAxesIndependently
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
            guard context.coordinator.url == url else { return }
            view.alphaValue = 0
            view.image = image
            NSAnimationContext.runAnimationGroup({ $0.duration = 0.2; view.animator().alphaValue = 1 }, completionHandler: nil)
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
