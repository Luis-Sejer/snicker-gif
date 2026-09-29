import AppKit
import SwiftUI

/// View state lives here rather than in @State: from the macOS 27 SDK @State is a macro whose
/// plugin ships only with full Xcode, and this project should build with the Command Line Tools.
final class ViewState: ObservableObject {
    private static let lastModeKey = "lastMode"

    @Published var query = ""
    /// Remembered across launches for the "Last Used" start tab.
    @Published var mode: BrowseMode = StartTab.current.mode ?? ViewState.lastMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.lastModeKey) }
    }
    @Published var gifs: [Gif] = []
    @Published var suggestions: [String] = []
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var notice: Notice?
    @Published var hoveredID: String?
    @Published var pendingID: String?
    @Published var copiedID: String?
    @Published var apiKeyDraft = ""
    @Published var isEditingKey = false
    /// GIFs only animate while the popover is open; a hidden popover must cost nothing.
    @Published var isShown = false
    /// The result Return copies, moved with the arrow keys.
    @Published var selectedIndex = 0
    @Published var hasNavigated = false
    /// When the popover last closed, so a stale search can be dropped on the next open.
    var closedAt: Date?
    /// Catches the popover's shortcuts while it is open.
    var keyMonitor: Any?
    /// Shown once, in place of the GIFs, after an update.
    @Published var whatsNew: WhatsNew?

    private static var lastMode: BrowseMode {
        UserDefaults.standard.string(forKey: lastModeKey).flatMap(BrowseMode.init) ?? .klipy
    }

    var selectedGif: Gif? {
        gifs.indices.contains(selectedIndex) ? gifs[selectedIndex] : nil
    }
}

enum BrowseMode: String, Equatable {
    case klipy, favorites, recents
}

/// What Snicker opens on: at launch, and when reopened after the search was forgotten.
enum StartTab: String, CaseIterable {
    case trending, favorites, recents, lastUsed

    static let defaultsKey = "startTab"

    static var current: StartTab {
        UserDefaults.standard.string(forKey: defaultsKey).flatMap(StartTab.init) ?? .trending
    }

    var title: String {
        switch self {
        case .trending: "Trending"
        case .favorites: "Favorites"
        case .recents: "Recent"
        case .lastUsed: "Last Used"
        }
    }

    /// Nil for Last Used, which keeps whatever was open.
    var mode: BrowseMode? {
        switch self {
        case .trending: .klipy
        case .favorites: .favorites
        case .recents: .recents
        case .lastUsed: nil
        }
    }
}

/// A short message in the footer, like "Saved to Downloads" or an error.
struct Notice: Equatable {
    let text: String
    let isError: Bool
}

/// Everything a tile can do, passed down as one value.
struct GifActions {
    let copy: (Gif) -> Void
    let copyLink: (Gif) -> Void
    let toggleFavorite: (Gif) -> Void
    let saveToDownloads: (Gif) -> Void
    let openOnKlipy: (Gif) -> Void
    let dragProvider: (Gif) -> NSItemProvider
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
    let settingsMenu: SettingsMenu
    @ObservedObject var shortcuts: ShortcutStore

    /// A key the user entered themselves; it takes precedence over the one built into release builds.
    @AppStorage(Klipy.apiKeyDefaultsKey) private var customApiKey = ""
    /// Name copied files like "GIF-3F9A2C71.gif" instead of after the GIF's title.
    @AppStorage(SettingKeys.randomFileNames) private var randomFileNames = false
    /// Owned by the app delegate, which shares them with the menu bar icon's right-click menu.
    @ObservedObject var state: ViewState
    @ObservedObject var library: Library
    @StateObject private var updater = Updater()
    @FocusState private var searchFocused: Bool

    private static let quickPicks = ["Thank you", "LOL", "Yes", "No", "Wow", "Party", "Facepalm", "Good morning"]
    private static let searchDebounce: Duration = .milliseconds(300)
    private static let copiedLinger: Duration = .milliseconds(550)
    /// Reopening soon after closing picks up where you left off; later, it starts fresh on Trending.
    private static let searchMemory: TimeInterval = 30

    var body: some View {
        Group {
            if apiKey.isEmpty || state.isEditingKey {
                WelcomeView(customApiKey: $customApiKey, state: state, canCancel: !apiKey.isEmpty)
            } else if let whatsNew = state.whatsNew {
                WhatsNewView(whatsNew: whatsNew) { state.whatsNew = nil }
            } else {
                browser
            }
        }
        .frame(width: Layout.popoverSize.width, height: Layout.popoverSize.height)
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didShowNotification)) { _ in
            state.copiedID = nil
            state.notice = nil
            state.isShown = true
            updater.checkIfDue()
            if state.keyMonitor == nil {
                state.keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: handleKey)
            }
            if let closedAt = state.closedAt, Date().timeIntervalSince(closedAt) > Self.searchMemory {
                startFresh()
            }
            // Still true from the last open, so setting it again would be a no-op: reset it first.
            searchFocused = false
            DispatchQueue.main.async { searchFocused = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didCloseNotification)) { _ in
            state.isShown = false
            state.closedAt = Date()
            if let keyMonitor = state.keyMonitor { NSEvent.removeMonitor(keyMonitor) }
            state.keyMonitor = nil
            state.hoveredID = nil
        }
    }

    private func startFresh() {
        state.query = ""
        state.mode = StartTab.current.mode ?? state.mode
        state.selectedIndex = 0
        state.hasNavigated = false
    }

    private var apiKey: String {
        customApiKey.isEmpty ? BundledKey.value : customApiKey
    }

    /// Typing always searches KLIPY; Favorites and Recent apply while the search field is empty.
    private var effectiveMode: BrowseMode {
        state.query.isEmpty ? state.mode : .klipy
    }

    private var actions: GifActions {
        GifActions(
            copy: copy,
            copyLink: copyLink,
            toggleFavorite: library.toggleFavorite,
            saveToDownloads: saveToDownloads,
            openOnKlipy: openOnKlipy,
            dragProvider: { gif in
                library.addRecent(gif)
                return GifFile.dragProvider(for: gif, randomName: randomFileNames)
            }
        )
    }

    // MARK: Browser

    private var browser: some View {
        ScrollViewReader { proxy in
            ScrollView {
                MasonryGrid(
                    state: state,
                    favoriteIDs: library.favoriteIDs,
                    highlightedID: selectionRingID,
                    showsPlaceholders: effectiveMode == .klipy,
                    actions: actions
                )
                .padding(.horizontal, Layout.gridPadding)
            }
            .onChange(of: state.selectedIndex) {
                guard let id = state.selectedGif?.id else { return }
                withAnimation(.smooth) { proxy.scrollTo(id, anchor: .center) }
            }
        }
        .scrollIndicators(.never) // a legacy scroller would steal a column's worth of gutter on the right
        .scrollEdgeEffectStyle(.soft, for: .top)
        // A soft edge let the footer text sit on top of busy GIFs; the hard edge gives it a clear band.
        .scrollEdgeEffectStyle(.hard, for: .bottom)
        .safeAreaInset(edge: .top, spacing: 4) { header }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if updater.showsReminder {
                    updateBanner
                }
                footer
            }
        }
        .overlay { emptyState }
        .task(id: "\(effectiveMode)|\(state.query)") {
            if effectiveMode == .klipy {
                do { try await Task.sleep(for: Self.searchDebounce) } catch { return }
            }
            await load()
        }
        .onChange(of: library.favorites) {
            if effectiveMode == .favorites { show(library.favorites) }
        }
    }

    /// Return copies the selected result; ring it once there is a search or the arrow keys were used.
    private var selectionRingID: String? {
        state.query.isEmpty && !state.hasNavigated ? nil : state.selectedGif?.id
    }

    private var header: some View {
        VStack(spacing: 10) {
            searchField
            chips
        }
        .padding(.top, 12)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
                .accessibilityHidden(true)
            TextField("Search KLIPY", text: $state.query) // KLIPY's attribution rules require this placeholder
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
                .accessibilityHint("\(key(.selectNext)) and \(key(.selectPrevious)) choose a GIF, \(key(.copyGif)) copies it, \(key(.copyLink)) copies its link, and \(key(.toggleFavorite)) favorites it.")
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

    /// Favorites, Recent and Trending, then search suggestions while typing or quick picks otherwise.
    private var chips: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: 6) {
                HStack(spacing: 6) {
                    chip("Favorites", systemImage: "star.fill", isSelected: effectiveMode == .favorites) {
                        state.query = ""
                        state.mode = .favorites
                    }
                    chip("Recent", systemImage: "clock.fill", isSelected: effectiveMode == .recents) {
                        state.query = ""
                        state.mode = .recents
                    }
                    chip("Trending", systemImage: "flame.fill", isSelected: effectiveMode == .klipy && state.query.isEmpty) {
                        state.query = ""
                        state.mode = .klipy
                    }
                    ForEach(chipTerms, id: \.self) { term in
                        chip(term, systemImage: nil, isSelected: state.query.caseInsensitiveCompare(term) == .orderedSame) {
                            state.mode = .klipy
                            state.query = term
                        }
                    }
                }
                .padding(.horizontal, Layout.gridPadding)
                .padding(.vertical, 4)
            }
        }
        .scrollIndicators(.never)
    }

    private var chipTerms: [String] {
        let suggestions = state.suggestions.filter { $0.caseInsensitiveCompare(state.query) != .orderedSame }
        return state.query.isEmpty || suggestions.isEmpty ? Self.quickPicks : suggestions
    }

    @ViewBuilder
    private func chip(_ title: String, systemImage: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let label = Label {
            Text(title)
        } icon: {
            if let systemImage { Image(systemName: systemImage) }
        }
        if isSelected {
            Button(action: action) { label }
                .buttonStyle(.glassProminent)
                .controlSize(.small)
                .accessibilityAddTraits(.isSelected)
        } else {
            Button(action: action) { label }.buttonStyle(.glass).controlSize(.small)
        }
    }

    @ViewBuilder
    private var updateBanner: some View {
        HStack(spacing: 8) {
            switch updater.phase {
            case .idle:
                Label("Snicker \(updater.availableVersion ?? "") is available", systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.tint)
                Spacer(minLength: 8)
                Button("Later", action: updater.remindLater)
                    .buttonStyle(.glass)
                Button("Update", action: updater.install)
                    .buttonStyle(.glassProminent)
            case .installing:
                ProgressView()
                    .controlSize(.small)
                Text("Updating… Snicker will reopen by itself.")
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            case .failed:
                Text("Couldn't update by itself. Download Snicker again from GitHub; it replaces this version.")
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Button("Open GitHub") { NSWorkspace.shared.open(Updater.releasesURL) }
                    .buttonStyle(.glassProminent)
            }
        }
        .font(.caption)
        .controlSize(.small)
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        // Its own glass card: on the scroll edge alone, it disappeared into the GIFs behind it.
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let notice = state.notice {
                Label(notice.text, systemImage: notice.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(notice.isError ? .orange : .green)
            } else {
                Text("\(key(.copyGif)) copy · \(key(.copyLink)) link · \(key(.toggleFavorite)) favorite")
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            klipyAttribution
            settingsButton
        }
        .font(.caption)
        .lineLimit(1)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    /// KLIPY's official mark, tinted like other secondary text so it suits light and dark mode.
    @ViewBuilder
    private var klipyAttribution: some View {
        if let mark = Self.klipyMark {
            Image(nsImage: mark)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 9)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Powered by KLIPY")
        } else {
            Text("Powered by KLIPY")
                .foregroundStyle(.secondary)
        }
    }

    /// Bundled by build.sh; a bare `swift build` has no bundle, so the view falls back to text.
    private static let klipyMark: NSImage? = {
        guard let url = Bundle.main.url(forResource: "powered-by-klipy", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        return image
    }()

    /// A plain button rather than a SwiftUI Menu, so it opens the same menu as right-clicking the menu bar icon.
    private var settingsButton: some View {
        Button("Settings", systemImage: "ellipsis") {
            settingsMenu.make().popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .fixedSize()
    }

    @ViewBuilder
    private var emptyState: some View {
        if let loadError = state.loadError, effectiveMode == .klipy {
            ContentUnavailableView("Couldn’t Load GIFs", systemImage: "wifi.exclamationmark", description: Text(loadError))
        } else if state.gifs.isEmpty && !state.isLoading {
            switch effectiveMode {
            case .favorites:
                ContentUnavailableView(
                    "No Favorites Yet",
                    systemImage: "star",
                    description: Text("Point at a GIF and click its star, or select it and press ⌘D.")
                )
            case .recents:
                ContentUnavailableView("No Recent GIFs", systemImage: "clock", description: Text("GIFs you copy or drag show up here."))
            case .klipy where !state.query.isEmpty:
                ContentUnavailableView.search(text: state.query)
            case .klipy:
                EmptyView()
            }
        }
    }

    // MARK: Loading

    private func load() async {
        switch effectiveMode {
        case .favorites: show(library.favorites)
        case .recents: show(library.recents)
        case .klipy: await loadFromKlipy()
        }
    }

    private func show(_ gifs: [Gif]) {
        withAnimation(.smooth) { state.gifs = gifs }
        state.selectedIndex = 0
        state.loadError = nil
    }

    private func loadFromKlipy() async {
        state.isLoading = true
        defer { state.isLoading = false }
        let query = state.query
        async let suggestions = fetchSuggestions(for: query)
        do {
            show(try await Klipy.fetch(query: query, apiKey: apiKey))
            state.suggestions = await suggestions
        } catch is CancellationError {
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            state.loadError = error.localizedDescription
        }
    }

    /// Suggestions are a nicety: when the lookup fails the quick picks simply stay.
    private func fetchSuggestions(for query: String) async -> [String] {
        guard !query.isEmpty else { return [] }
        return (try? await Klipy.autocomplete(query: query, apiKey: apiKey)) ?? []
    }

    // MARK: Actions

    private func key(_ action: ShortcutAction) -> String {
        shortcuts.shortcut(for: action).displayString
    }

    /// Every popover shortcut goes through here, so all of them can be remapped in Settings.
    private func handleKey(_ event: NSEvent) -> NSEvent? {
        guard state.isShown, !state.isEditingKey, state.whatsNew == nil, !apiKey.isEmpty,
              let action = shortcuts.action(for: event), perform(action) else { return event }
        return nil
    }

    /// False when the action doesn't apply right now, so the key does what it normally would.
    private func perform(_ action: ShortcutAction) -> Bool {
        switch action {
        case .openSnicker: return false
        case .selectNext: return moveSelection(by: 1)
        case .selectPrevious: return moveSelection(by: -1)
        case .showFavorites: show(.favorites)
        case .showRecent: show(.recents)
        case .showTrending: show(.klipy)
        case .copyGif, .copyLink, .toggleFavorite, .saveToDownloads:
            guard let selected = state.selectedGif else { return false }
            switch action {
            case .copyLink: copyLink(selected)
            case .toggleFavorite: library.toggleFavorite(selected)
            case .saveToDownloads: saveToDownloads(selected)
            default: copy(selected)
            }
        }
        return true
    }

    private func show(_ mode: BrowseMode) {
        state.query = ""
        state.mode = mode
    }

    private func moveSelection(by offset: Int) -> Bool {
        guard !state.gifs.isEmpty else { return false }
        state.hasNavigated = true
        state.selectedIndex = min(max(state.selectedIndex + offset, 0), state.gifs.count - 1)
        return true
    }

    private func copy(_ gif: Gif) {
        state.pendingID = gif.id
        state.notice = nil
        Task {
            defer { state.pendingID = nil }
            do {
                try GifFile.copyToPasteboard(try await GifFile.download(gif, randomName: randomFileNames))
                await finishCopying(gif, announcement: "Copied")
            } catch {
                state.notice = Notice(text: error.localizedDescription, isError: true)
            }
        }
    }

    private func copyLink(_ gif: Gif) {
        GifFile.copyLinkToPasteboard(gif)
        Task { await finishCopying(gif, announcement: "Copied link to") }
    }

    private func finishCopying(_ gif: Gif, announcement: String) async {
        library.addRecent(gif)
        withAnimation(.bouncy) { state.copiedID = gif.id }
        AccessibilityNotification.Announcement("\(announcement) \(gif.title.isEmpty ? "GIF" : gif.title)").post()
        try? await Task.sleep(for: Self.copiedLinger)
        close()
    }

    private func saveToDownloads(_ gif: Gif) {
        Task {
            do {
                let saved = try GifFile.saveToDownloads(try await GifFile.download(gif, randomName: randomFileNames))
                state.notice = Notice(text: "Saved \(saved.lastPathComponent) to Downloads", isError: false)
            } catch {
                state.notice = Notice(text: error.localizedDescription, isError: true)
            }
        }
    }

    private func openOnKlipy(_ gif: Gif) {
        guard let pageURL = gif.pageURL else { return }
        NSWorkspace.shared.open(pageURL)
        close()
    }
}

// MARK: - Grid

/// Shortest-column-first masonry, so every GIF keeps its real shape instead of being letterboxed.
private struct MasonryGrid: View {
    @ObservedObject var state: ViewState
    let favoriteIDs: Set<String>
    let highlightedID: String?
    let showsPlaceholders: Bool
    let actions: GifActions

    private static let placeholderRatios: [CGFloat] = [1.3, 0.8, 1, 1.6, 1.1, 0.75, 1.4, 1, 0.9, 1.2, 1.5, 0.85]

    var body: some View {
        HStack(alignment: .top, spacing: Layout.tileSpacing) {
            ForEach(0..<Layout.columnCount, id: \.self) { column in
                LazyVStack(spacing: Layout.tileSpacing) {
                    if state.gifs.isEmpty && state.isLoading && showsPlaceholders {
                        ForEach(placeholders[column], id: \.self) { index in
                            RoundedRectangle(cornerRadius: Layout.tileCornerRadius, style: .continuous)
                                .fill(.quaternary)
                                .aspectRatio(Self.placeholderRatios[index], contentMode: .fit)
                                .accessibilityHidden(true)
                        }
                    } else {
                        ForEach(columns[column]) { gif in
                            GifTile(
                                gif: gif,
                                isFavorite: favoriteIDs.contains(gif.id),
                                isHighlighted: gif.id == highlightedID,
                                isHovered: gif.id == state.hoveredID,
                                isPending: gif.id == state.pendingID,
                                isCopied: gif.id == state.copiedID,
                                isShown: state.isShown,
                                onHover: { hovering in state.hoveredID = hovering ? gif.id : nil },
                                actions: actions
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
    let isFavorite: Bool
    let isHighlighted: Bool
    let isHovered: Bool
    let isPending: Bool
    let isCopied: Bool
    let isShown: Bool
    let onHover: (Bool) -> Void
    let actions: GifActions

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// "Auto-play animated images" in Accessibility settings; when off, a GIF plays only while pointed at or selected.
    @Environment(\.accessibilityPlayAnimatedImages) private var playAnimatedImages

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Layout.tileCornerRadius, style: .continuous)
    }

    private var accessibilityName: String {
        gif.title.isEmpty ? "GIF" : gif.title
    }

    var body: some View {
        AnimatedGif(url: gif.previewURL, animates: isShown && (playAnimatedImages || isHovered || isHighlighted))
            .aspectRatio(gif.aspectRatio, contentMode: .fit)
            .background(.quaternary)
            .overlay { if isPending || isCopied { Color.black.opacity(0.25) } }
            .overlay { statusBadge }
            .overlay(alignment: .topTrailing) { favoriteButton }
            .clipShape(shape)
            .overlay { shape.strokeBorder(Color.accentColor, lineWidth: 2.5).opacity(isHighlighted ? 1 : 0) }
            .scaleEffect(isHovered && !reduceMotion ? 1.04 : 1)
            .shadow(color: .black.opacity(isHovered ? 0.28 : 0), radius: 10, y: 5)
            .zIndex(isHovered ? 1 : 0)
            .animation(.smooth(duration: 0.2), value: isHovered)
            .contentShape(shape)
            .onHover(perform: onHover)
            .onTapGesture { actions.copy(gif) }
            .onDrag { actions.dragProvider(gif) }
            .contextMenu { menu }
            .help(gif.title)
            .accessibilityElement()
            .accessibilityLabel(isFavorite ? "\(accessibilityName), favorite" : accessibilityName)
            .accessibilityAddTraits(isHighlighted ? [.isButton, .isSelected] : .isButton)
            .accessibilityHint("Copies the GIF to the clipboard")
            .accessibilityAction { actions.copy(gif) }
            .accessibilityAction(named: "Copy Link") { actions.copyLink(gif) }
            .accessibilityAction(named: isFavorite ? "Remove from Favorites" : "Add to Favorites") { actions.toggleFavorite(gif) }
            .accessibilityAction(named: "Save to Downloads") { actions.saveToDownloads(gif) }
    }

    @ViewBuilder
    private var menu: some View {
        Button("Copy GIF", systemImage: "doc.on.doc") { actions.copy(gif) }
        Button("Copy Link", systemImage: "link") { actions.copyLink(gif) }
        Button(
            isFavorite ? "Remove from Favorites" : "Add to Favorites",
            systemImage: isFavorite ? "star.slash" : "star"
        ) { actions.toggleFavorite(gif) }
        Divider()
        Button("Save to Downloads", systemImage: "arrow.down.circle") { actions.saveToDownloads(gif) }
        if gif.pageURL != nil {
            Button("Open on KLIPY", systemImage: "safari") { actions.openOnKlipy(gif) }
        }
    }

    @ViewBuilder
    private var favoriteButton: some View {
        if isHovered || isFavorite {
            Button(isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: isFavorite ? "star.fill" : "star") {
                actions.toggleFavorite(gif)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(isFavorite ? .yellow : .white)
            .frame(width: 24, height: 24)
            .glassEffect(.regular.interactive(), in: .circle)
            .padding(6)
            .transition(.opacity)
        }
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
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        } else if isPending {
            ProgressView().controlSize(.small)
        }
    }
}

// MARK: - Welcome

/// Shown when there is no key at all (a source build without one) or when the user chooses their own.
private struct WelcomeView: View {
    @Binding var customApiKey: String
    @ObservedObject var state: ViewState
    let canCancel: Bool

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
                Text(canCancel ? "Use Your Own API Key" : "Welcome to Snicker")
                    .font(.title2.weight(.bold))
                Text(canCancel
                    ? "Snicker includes a KLIPY key. Paste your own free key to use it instead."
                    : "Snicker searches KLIPY’s GIF library. Paste your free API key to get started.")
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
                if canCancel {
                    Button("Cancel") { state.isEditingKey = false }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .keyboardShortcut(.cancelAction)
                }
            }
            Link("Get a key at docs.klipy.com", destination: URL(string: "https://docs.klipy.com")!)
                .font(.caption)
            Spacer()
        }
        .padding(32)
    }

    private func save() {
        guard !trimmedDraft.isEmpty else { return }
        customApiKey = trimmedDraft
        state.isEditingKey = false
    }
}

// MARK: - Animated preview

/// NSImageView animates GIFs natively; SwiftUI's Image does not.
private struct AnimatedGif: NSViewRepresentable {
    let url: URL
    let animates: Bool

    func makeNSView(context: Context) -> NSImageView {
        let view = PassthroughImageView()
        view.imageScaling = .scaleAxesIndependently
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        view.animates = animates
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

/// Bounded, so browsing many searches doesn't keep every preview in memory; the cost is the GIF's byte size.
private enum PreviewCache {
    private static let byteLimit = 24 * 1024 * 1024
    private static let cache: NSCache<NSURL, NSImage> = {
        let cache = NSCache<NSURL, NSImage>()
        cache.totalCostLimit = byteLimit
        return cache
    }()

    static func image(for url: URL) async -> NSImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        guard let (data, _) = try? await URLSession.shared.data(from: url), let image = NSImage(data: data) else { return nil }
        cache.setObject(image, forKey: url as NSURL, cost: data.count)
        return image
    }
}
